from typing import *
from dataclasses import dataclass, field
import enum
import io


__all__ = [
    "BlockPosition",
    "BlockFn",
    "Block",
    "Dumper",
    "CodeGen"
]


class BlockPosition(enum.Enum):
    DEFAULT = enum.auto()

    BEFORE_INCLUDES = enum.auto()
    AFTER_INCLUDES = enum.auto()

    BEFORE_CTOR = enum.auto()

    BEFORE_CLASS = enum.auto()
    AFTER_CLASS = enum.auto()

    BEFORE_NAMESPACE = enum.auto()
    AFTER_NAMESPACE = enum.auto()


BlockFn = Callable[["Dumper"], None]
Block = Union[str, BlockFn]


@dataclass
class Param:
    tpe: str
    name: str
    default: str = None

    _decl: str = field(init=False)

    def __post_init__(self) -> None:
        count = self.tpe.count("$")
        if count == 0:
            self._decl = f"{self.tpe} {self.name}"
        elif count == 1:
            self._decl = self.tpe.replace("$", self.name)
        else:
            raise RuntimeError(
                "too many '$'s in the constructor parameter type"
            )

    def asParamDecl(self) -> str:
        return self._decl

    def asParamDeclWithDefault(self) -> str:
        if self.default:
            return f"{self._decl} = {self.default}"
        else:
            return self._decl


class Dumper:
    def __init__(self, indentstr="    ") -> None:
        self._indentstr = indentstr
        self._num_indent = 0
        self._buffer = []

    def indent_in(self) -> "Dumper":
        self._num_indent += 1
        return self

    def indent_out(self) -> "Dumper":
        assert self._num_indent > 0
        self._num_indent -= 1
        return self

    def indent(self) -> "Dumper":
        self.write(self._indentstr * self._num_indent)
        return self

    def writeln(self, ln="") -> "Dumper":
        self.write(f"{ln}\n")
        return self

    def write(self, s) -> "Dumper":
        self._buffer.append(s)
        return self

    def iwriteln(self, ln="") -> "Dumper":
        self.indent()
        self.writeln(ln)
        return self

    def iwrite(self, s) -> "Dumper":
        self.indent()
        self.write(s)
        return self

    def unwrite(self) -> "Dumper":
        assert len(self._buffer) > 0
        self._buffer.pop()
        return self

    def iunwrite(self) -> "Dumper":
        assert len(self._buffer) > 1
        self._buffer.pop()
        self._buffer.pop()
        return self

    def separate(self) -> "Dumper":
        self._buffer.append(None)
        return self

    def generate(self) -> str:
        with io.StringIO() as out:
            separator = False

            for x in self._buffer:
                if separator:
                    if isinstance(x, str):
                        out.write(x)
                        separator = False
                    else:
                        pass
                else:
                    if isinstance(x, str):
                        out.write(x)
                    else:
                        separator = True
                        out.write("\n")

            return out.getvalue()


class CodeGen:
    """Code generator to create a wrapper module implemented in SystemC."""

    def __init__(self) -> None:
        self._className: Optional[str] = None
        self._isFinal: bool = False
        self._usePragmaOnce: bool = False
        self._includeGuardIdentifier: Optional[str] = None
        self._namespace: Optional[str] = None
        self._isInline: bool = False
        self._templateParams: List[Param] = []
        self._baseClasses: List[str] = []
        self._ctorParams: List[Param] = []
        self._ctorParamsWithDefault: List[Param] = []
        self._ctorInits: List[Block] = []
        self._ctorBlocks: List[Block] = []
        self._ctorIsExplicit: bool = False
        self._dtorIsVirtual: bool = False
        self._dtorBlocks: List[Block] = []
        self._publicBlocksBeforeCtor: List[Block] = []
        self._publicBlocks: List[Block] = []
        self._privateBlocks: List[Block] = []
        self._protectedBlocks: List[Block] = []
        self._implBlocks: List[Block] = []
        self._hdrBlocksIncludes: List[Block] = []
        self._implBlocksIncludes: List[Block] = []
        self._hdrBlocksBeforeIncludes: List[Block] = []
        self._hdrBlocksAfterIncludes: List[Block] = []
        self._hdrBlocksBeforeNamespace: List[Block] = []
        self._hdrBlocksAfterNamespace: List[Block] = []
        self._hdrBlocksBeforeClass: List[Block] = []
        self._hdrBlocksAfterClass: List[Block] = []
        self._implBlocksBeforeIncludes: List[Block] = []
        self._implBlocksAfterIncludes: List[Block] = []
        self._implBlocksBeforeNamespace: List[Block] = []
        self._implBlocksAfterNamespace: List[Block] = []

    def _require(self, condition, message) -> None:
        if not condition:
            raise AssertionError(f"Requirement failed! {message}")

    def _assert(self, condition, message) -> None:
        if not condition:
            raise AssertionError(f"Assertion failed! {message}")

    @property
    def className(self) -> str:
        return self._className

    @property
    def qualifiedClassName(self) -> str:
        if self._namespace is not None:
            return f"{self._namespace}::{self._className}"
        return self._className

    @property
    def isInline(self) -> bool:
        """`True` if the code is generated by `genCode()` (header/implementation single file), `False` otherwise."""
        return self._isInline

    @property
    def isSeparateHppCpp(self) -> bool:
        return self._isSeparateHppCpp

    def setClassName(self, className: str) -> "CodeGen":
        self._className = className
        return self

    def makeFinal(self) -> "CodeGen":
        self._isFinal = True
        return self

    def usePragmaOnce(self) -> "CodeGen":
        self._usePragmaOnce = True
        return self

    def useIncludeGuard(self, includeGuardIdentifier: str) -> "CodeGen":
        self._includeGuardIdentifier = includeGuardIdentifier
        return self

    def setNamespace(self, namespace: str) -> "CodeGen":
        self._namespace = namespace
        return self

    def addTemplateParam(self, name, default: str = None, tpe: str = "typename") -> "CodeGen":
        self._templateParams.append(Param(tpe, name, default))
        return self

    def addBaseClass(self, baseClass: str) -> "CodeGen":
        """Appends a new base class.

        Args:
            baseClass (str): Can be prefixed with "public ", "private ", or "protected ". Also can be a template instantiation.
        """
        self._baseClasses.append(baseClass)
        return self

    def addCtorParam(self, tpe: str, name: str, default: str = None) -> "CodeGen":
        if default is None:
            self._ctorParams.append(Param(tpe, name, None))
        else:
            self._ctorParamsWithDefault.append(Param(tpe, name, default))
        return self

    def addCtorInit(self, block: Block) -> "CodeGen":
        self._ctorInits.append(block)
        return self

    def addCtorBlock(self, block: Block) -> "CodeGen":
        self._ctorBlocks.append(block)
        return self

    def makeCtorExplicit(self) -> "CodeGen":
        self._ctorIsExplicit = True
        return self

    def makeDtorVirtual(self) -> "CodeGen":
        self._dtorIsVirtual = True
        return self

    def addDtorBlock(self, block: Block) -> "CodeGen":
        self._dtorBlocks.append(block)
        return self

    def addPublicBlock(self, block: Block, pos: BlockPosition = BlockPosition.DEFAULT) -> "CodeGen":
        self._require(
            pos in [BlockPosition.DEFAULT, BlockPosition.BEFORE_CTOR],
            "invalid 'pos' for 'addPublicBlock'"
        )

        if pos == BlockPosition.BEFORE_CTOR:
            self._publicBlocksBeforeCtor.append(block)
        else:
            self._publicBlocks.append(block)

        return self

    def addPrivateBlock(self, block: Block, pos: BlockPosition = BlockPosition.DEFAULT) -> "CodeGen":
        self._require(pos == BlockPosition.DEFAULT,
                      "invalid 'pos' for 'addPrivateBlock'")
        self._privateBlocks.append(block)
        return self

    def addProtectedBlock(self, block: Block) -> "CodeGen":
        self._protectedBlocks.append(block)
        return self

    def addImplBlock(self, block: Block) -> "CodeGen":
        self._implBlocks.append(block)
        return self

    def _checkInclude(self, include: str) -> str:
        stripped = include.strip()
        if stripped.startswith("<") and stripped.endswith(">"):
            return stripped
        elif stripped.startswith("\"") and stripped.endswith("\""):
            return stripped
        else:
            return None

    def addHdrInclude(self, include: str) -> "CodeGen":
        checked = self._checkInclude(include)
        self._require(checked is not None, "invalid include string")
        self._hdrBlocksIncludes.append(f"#include {checked}")
        return self

    def addHdrIncludeBlock(self, include: Block) -> "CodeGen":
        self._hdrBlocksIncludes.append(include)
        return self

    def addImplInclude(self, include: str) -> "CodeGen":
        checked = self._checkInclude(include)
        self._require(checked is not None, "invalid include string")
        self._implBlocksIncludes.append(f"#include {checked}")
        return self

    def addImplIncludeBlock(self, include: Block) -> "CodeGen":
        self._implBlocksIncludes.append(include)
        return self

    def addHdrBlock(self, block: Block, pos: BlockPosition = BlockPosition.AFTER_CLASS) -> "CodeGen":
        self._require(pos in [
            BlockPosition.BEFORE_INCLUDES,
            BlockPosition.AFTER_INCLUDES,
            BlockPosition.BEFORE_CLASS,
            BlockPosition.AFTER_CLASS,
            BlockPosition.BEFORE_NAMESPACE,
            BlockPosition.AFTER_NAMESPACE
        ], "invalid 'pos' for 'addHdrBlock'")

        if pos == BlockPosition.BEFORE_INCLUDES:
            self._hdrBlocksBeforeIncludes.append(block)
        if pos == BlockPosition.AFTER_INCLUDES:
            self._hdrBlocksAfterIncludes.append(block)
        elif pos == BlockPosition.BEFORE_CLASS:
            self._hdrBlocksBeforeClass.append(block)
        elif pos == BlockPosition.AFTER_CLASS:
            self._hdrBlocksAfterClass.append(block)
        elif pos == BlockPosition.BEFORE_NAMESPACE:
            self._hdrBlocksBeforeNamespace.append(block)
        elif pos == BlockPosition.AFTER_NAMESPACE:
            self._hdrBlocksAfterNamespace.append(block)

        return self

    def addImplBlock(self, block: Block, pos: BlockPosition = BlockPosition.AFTER_CLASS) -> "CodeGen":
        self._require(pos in [
            BlockPosition.DEFAULT,
            BlockPosition.BEFORE_INCLUDES,
            BlockPosition.AFTER_INCLUDES,
            BlockPosition.BEFORE_CLASS,
            BlockPosition.AFTER_CLASS,
            BlockPosition.BEFORE_NAMESPACE,
            BlockPosition.AFTER_NAMESPACE
        ], "invalid 'pos' for 'addImplBlock'")

        if pos == BlockPosition.BEFORE_INCLUDES:
            self._implBlocksBeforeIncludes.append(block)
        if pos == BlockPosition.AFTER_INCLUDES:
            self._implBlocksAfterIncludes.append(block)
        elif pos == BlockPosition.BEFORE_NAMESPACE:
            self._implBlocksBeforeNamespace.append(block)
        elif pos == BlockPosition.AFTER_NAMESPACE:
            self._implBlocksAfterNamespace.append(block)
        else:
            self._implBlocks.append(block)

        return self

    def dumpMemberImpl(
        self,
        d: Dumper,
        tpe: str,
        name: str,
        specifiers: Optional[str] = None
    ) -> None:
        """Dumps member implementation.

        Args:
            d (Dumper): dumper object.
            tpe (str): type. might contain a single '$' for more complicated types.
            name (str): name.
            specifiers (Optional[str], optional): If not 'None', inline behavior is overridden. Defaults to None.

        Raises:
            RuntimeError
        """
        if len(self._templateParams) > 1:
            d.iwriteln("template <")
            d.indent_in()
            for templateParam in self._templateParams:
                d.iwriteln(templateParam.asParamDecl())
            d.indent_out()
            d.iwriteln(">")
        elif len(self._templateParams) == 1:
            d.iwriteln(
                f"template <{self._templateParams[0].asParamDecl()}>"
            )

        if specifiers is not None:
            d.iwriteln(specifiers)
        elif self._isInline:
            d.iwriteln("inline")

        expandedNameList = [self._className]

        if len(self._templateParams) > 0:
            expandedNameList.append("<")
            for templateParam in self._templateParams:
                expandedNameList.append(templateParam.name)
                expandedNameList.append(",")
            expandedNameList.pop()
            expandedNameList.append(">")

        expandedNameList.append("::")
        expandedNameList.append(name)

        expandedName = "".join(expandedNameList)

        count = tpe.count("$")
        if count == 0:
            d.iwrite(f"{tpe} {expandedName}")
        elif count == 1:
            d.iwrite(tpe.replace("$", expandedName))
        else:
            raise RuntimeError(
                "too many '$'s in type"
            )

    def dumpBlock(self, d: Dumper, block: Optional[Block]) -> None:
        if block is not None:
            if isinstance(block, str):
                d.iwriteln(block)
            else:
                block(d)

    def dumpBlocks(self, d: Dumper, blocks: List[Block]) -> None:
        for block in blocks:
            if isinstance(block, str):
                d.iwriteln(block)
            else:
                block(d)

    def _dumpCtorDecl(self, d: Dumper) -> None:
        ctorParams = self._ctorParams + self._ctorParamsWithDefault

        if self._ctorIsExplicit:
            d.iwrite("explicit ")
        else:
            d.iwrite("")

        if len(ctorParams) == 0:
            d.writeln(f"{self._className}();")
        elif len(ctorParams) == 1:
            d.writeln(
                f"{self._className}({ctorParams[0].asParamDeclWithDefault()});"
            )
        else:
            d.writeln(f"{self._className}(")
            d.indent_in()

            for param in ctorParams:
                d.iwrite(param.asParamDeclWithDefault())
                d.writeln(",")

            d.unwrite()
            d.writeln()

            d.indent_out()
            d.iwriteln(f");")

    def _dumpDtorDecl(self, d: Dumper) -> None:
        if self._dtorIsVirtual:
            d.iwriteln(f"virtual ~{self.className}();")
        else:
            d.iwriteln(f"~{self.className}();")

    def _dumpClassDecl(self, d: Dumper) -> None:
        self.dumpBlocks(d, self._hdrBlocksBeforeClass)

        d.iwriteln(f"/** @brief {self._className} */")
        if len(self._templateParams) > 1:
            d.iwriteln("template <")
            d.indent_in()
            for templateParam in self._templateParams:
                d.iwriteln(templateParam.asParamDeclWithDefault())
            d.indent_out()
            d.iwriteln(">")
        elif len(self._templateParams) == 1:
            d.iwriteln(
                f"template <{self._templateParams[0].asParamDeclWithDefault()}>"
            )

        d.iwrite(f"class {self._className}")
        if self._isFinal:
            d.iwrite(" final")
        if len(self._baseClasses) > 1:
            d.writeln(" :")
            d.indent_in()
            for baseClass in self._baseClasses:
                d.iwrite(baseClass)
                d.writeln(",")
            d.unwrite()
            d.indent_out()
            d.iwriteln(f" {{")
        elif len(self._baseClasses) == 1:
            d.writeln(f" : {self._baseClasses[0]} {{")
        else:
            d.writeln(f" {{")

        d.iwriteln("public:")
        d.indent_in()

        d.separate()

        self.dumpBlocks(d, self._publicBlocksBeforeCtor)

        d.separate()

        self._dumpCtorDecl(d)

        d.separate()

        self.dumpBlocks(d, self._publicBlocks)

        d.separate()

        self._dumpDtorDecl(d)

        d.separate()

        d.indent_out()
        d.iwriteln("private:")
        d.indent_in()

        d.separate()

        self.dumpBlocks(d, self._privateBlocks)

        d.separate()

        d.indent_out()
        d.writeln("protected:")
        d.indent_in()

        self.dumpBlocks(d, self._protectedBlocks)

        d.separate()

        d.indent_out()

        d.iwriteln(f"}}; /* class {self._className} */")

        self.dumpBlocks(d, self._hdrBlocksAfterClass)

    def _dumpHdr(self, d: Dumper, beforeIncludeGuardEnd: Optional[Block] = None) -> None:
        if self._usePragmaOnce:
            d.iwriteln("#pragma once")
        elif self._includeGuardIdentifier is not None:
            d.iwriteln(f"#if !defined({self._includeGuardIdentifier})")
            d.iwriteln(f"#define {self._includeGuardIdentifier}")

        d.separate()

        self.dumpBlocks(d, self._hdrBlocksBeforeIncludes)
        self.dumpBlocks(d, self._hdrBlocksIncludes)
        self.dumpBlocks(d, self._hdrBlocksAfterIncludes)

        d.separate()

        self.dumpBlocks(d, self._hdrBlocksBeforeNamespace)
        if self._namespace is not None:
            d.writeln(f"namespace {self._namespace} {{")

        d.separate()

        self._dumpClassDecl(d)

        d.separate()

        if self._namespace is not None:
            d.writeln(f"}} /* namespace {self._namespace} */")
        self.dumpBlocks(d, self._hdrBlocksAfterNamespace)

        d.separate()

        if beforeIncludeGuardEnd is not None:
            if isinstance(beforeIncludeGuardEnd, str):
                d.writeln(beforeIncludeGuardEnd)
            else:
                beforeIncludeGuardEnd(d)

        d.separate()

        if not self._usePragmaOnce and self._includeGuardIdentifier is not None:
            d.writeln(f"#endif /* !defined({self._includeGuardIdentifier}) */")

    def genCodeHdr(self) -> str:
        d = Dumper()
        self._dumpHdr(d)
        return d.generate()

    def _dumpCtorImpl(self, d: Dumper) -> None:
        ctorParams = self._ctorParams + self._ctorParamsWithDefault

        if len(ctorParams) == 0:
            self.dumpMemberImpl(d, "$", self._className)
            d.iwrite(f"()")
        elif len(ctorParams) == 1:
            self.dumpMemberImpl(d, "$", self._className)
            d.iwrite(f"({ctorParams[0].asParamDecl()})")
        else:
            self.dumpMemberImpl(d, "$", self._className)
            d.iwriteln(f"(")
            d.indent_in()

            for param in ctorParams:
                d.iwrite(param.asParamDecl())
                d.writeln(",")

            d.unwrite()
            d.writeln()

            d.indent_out()
            d.iwrite(f")")

        if len(self._ctorInits) > 0:
            d.iwriteln(" :")
            d.indent_in()

            for init in self._ctorInits:
                if isinstance(init, str):
                    # no new line after
                    d.iwrite(init)
                    d.writeln(",")
                else:
                    init(d)

            d.unwrite()
            d.writeln(f" {{")

            d.indent_out()
        else:
            d.writeln(f" {{")

        d.indent_in()
        d.separate()
        self.dumpBlocks(d, self._ctorBlocks)
        d.indent_out()

        d.iwriteln(f"}}")

    def _dumpDtorImpl(self, d: Dumper) -> None:
        self.dumpMemberImpl(d, "$", f"~{self._className}()")
        d.iwriteln(f" {{")

        d.indent_in()
        d.separate()
        self.dumpBlocks(d, self._dtorBlocks)
        d.indent_out()

        d.iwriteln(f"}}")

    def _dumpImpl(self, d: Dumper) -> None:
        self.dumpBlocks(d, self._implBlocksBeforeIncludes)
        self.dumpBlocks(d, self._implBlocksIncludes)
        self.dumpBlocks(d, self._implBlocksAfterIncludes)

        d.separate()

        self.dumpBlocks(d, self._implBlocksBeforeNamespace)
        if self._namespace is not None:
            d.writeln(f"namespace {self._namespace} {{")

        d.separate()

        self._dumpCtorImpl(d)

        d.separate()

        self._dumpDtorImpl(d)

        d.separate()

        self.dumpBlocks(d, self._implBlocks)

        d.separate()

        if self._namespace is not None:
            d.writeln(f"}} /* namespace {self._namespace} */")
        self.dumpBlocks(d, self._hdrBlocksAfterNamespace)

        d.separate()

    def genCodeImpl(self, indentStr="    ") -> str:
        self._isInline = False
        d = Dumper(indentstr=indentStr)
        self._dumpImpl(d)
        return d.generate()

    def genCode(self, indentStr="    ") -> str:
        self._isInline = True
        d = Dumper(indentstr=indentStr)
        self._dumpHdr(d, self._dumpImpl)
        return d.generate()


def test() -> None:
    class SeparatedBlock:
        def __init__(self, s: str) -> None:
            self._s = s

        def __call__(self, d: "Dumper") -> None:
            d.separate()
            d.iwriteln(self._s)

    def addMacroTestBlock(d: Dumper) -> None:
        d.iwriteln("#ifdef USE_XAPI")
        d.iwriteln("#define api_call xapi_call")
        d.iwriteln("#endif")
        d.separate()

    c = (
        CodeGen()
        .useIncludeGuard("__MYFILE_INCLUDED__")
        .addHdrInclude("<iostream>")
        .addHdrInclude("<string>")
        .addImplInclude("\"myfile.hpp\"")
        .setNamespace("my_namespace")
        .addHdrBlock(addMacroTestBlock, BlockPosition.BEFORE_CLASS)
        # .useInline()
        .addTemplateParam("T", default="int")
        .addCtorParam("int", "x_", 15)
        .addCtorParam("std::string const&", "y_", 15)
        .addCtorParam("int (*$)(int, int)", "y_", "nullptr")
        .addCtorParam("std::string const&", "name")
        .addCtorInit(f"jnbrq::object{{ name }}")
        .addCtorInit(f"x{{ x_ }}")
        .addPublicBlock(f"int x{{8}};")
        .addPublicBlock(SeparatedBlock(f"void printData() {{ std::cout << x << std::endl; }}"))
        .makeDtorVirtual()
        .setClassName("MyClass")
        .addBaseClass("private jnbrq::object")
    )

    print(c.genCodeHdr())
    print(c.genCodeImpl())
    print(c.genCode())


if __name__ == "__main__":
    test()

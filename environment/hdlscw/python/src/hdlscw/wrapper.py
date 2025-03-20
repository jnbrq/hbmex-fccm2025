import hdlinfo
import abc
import dataclasses
import argparse
import typing
from typing import *

from . import codegen


__all__ = [
    "InterfaceHandler",
    "StatefulInterfaceHandler",
    "registerInterfaceHandlerCustom",
    "registerInterfaceHandler",
    "getInterfaceHandler",
    "registeredInterfaceHandlers",
    "WrapperConfig",
    "Wrapper"
]


_interfaceHandlers: Dict[str, Type["InterfaceHandler"]] = {}

T = TypeVar('T')
TT = TypeVar('TT')


class InterfaceHandler(abc.ABC):
    @staticmethod
    @abc.abstractmethod
    def processInterface(wrapper: "Wrapper", cg: codegen.CodeGen, interface: hdlinfo.Interface) -> bool:
        """Executed when the `InterfaceHandler` should process an interface.

        Args:
            wrapper (Wrapper): the wrapper.
            cg (codegen.Codegen): associated code generator.
            interface (Interface): the interface.

        Returns:
            bool: `True` if the interface transform could process the interface, `False` otherwise.
        """


class StatefulInterfaceHandler(abc.ABC):
    def __init__(self, wrapper: "Wrapper", cg: codegen.CodeGen) -> None:
        """The constructor of a stateful interface handler. Guaranteed to be executed only once."""
        self._wrapper = wrapper
        self._cg = cg

    @property
    def wrapper(self) -> "Wrapper":
        return self._wrapper

    @property
    def cg(self) -> codegen.CodeGen:
        return self._cg

    def getOption(self, name: str, t: Callable[[str], T], default: T) -> T:
        return self.wrapper.config.requestOption(name, t, default)

    def getOptionStr(self, name: str, default: str) -> str:
        return self.getOption(name, str, default)

    def getOptionInt(self, name: str, default: int) -> int:
        return self.getOption(name, int, default)

    @staticmethod
    @abc.abstractmethod
    def checkKind(kind: str) -> bool:
        """Used to check if this interface handler can be used for handling an interface with the given kind.

        Args:
            kind (str): Interface kind.

        Returns:
            bool: `True` if the interface can be handled.
        """
        return False

    @abc.abstractmethod
    def processInterface(self, interface: hdlinfo.Interface) -> None:
        """The handler might modify the wrapper and the codegen from the interface.

        Args:
            interface (hdlinfo.Interface): 
        """
        pass


def transformStatefulInterfaceHandler(t: Type[StatefulInterfaceHandler]) -> Type[InterfaceHandler]:
    attrName = f"{t.__qualname__.replace(".", "_")}_Wrapped"

    class StatelessInterfaceHandler(InterfaceHandler):
        @staticmethod
        def processInterface(wrapper: "Wrapper", cg: codegen.CodeGen, interface: hdlinfo.Interface) -> bool:
            if not t.checkKind(interface.kind):
                return False

            o: StatefulInterfaceHandler = wrapper.getAttr(attrName)

            if o is None:
                o = wrapper.setAttr(attrName, t(wrapper, cg))

            o.processInterface(interface)
            return True

    return StatelessInterfaceHandler


def registerInterfaceHandlerCustom(name: str) -> Callable[[Type[T]], Type[T]]:
    def wrap(cls: Type[TT]) -> Type[TT]:
        if name in _interfaceHandlers:
            # TODO have a custom exception class
            raise RuntimeError(
                "attempt to register an interface handler with an already taken name"
            )
        cls = transformStatefulInterfaceHandler(cls) \
            if issubclass(cls, StatefulInterfaceHandler) else cls
        if not issubclass(cls, InterfaceHandler):
            raise RuntimeError(
                "Attempt to register an interface handler not deriving from 'InterfaceHandler'!"
            )
        _interfaceHandlers[name] = cls
        return cls
    return wrap


def registerInterfaceHandler(cls: Type[T]) -> Type[T]:
    name = cls.__qualname__
    if name in _interfaceHandlers:
        # TODO have a custom exception class
        raise RuntimeError(
            "attempt to register an interface handler with an already taken name")
    cls = transformStatefulInterfaceHandler(cls) \
        if issubclass(cls, StatefulInterfaceHandler) else cls
    if not issubclass(cls, InterfaceHandler):
        raise RuntimeError(
            "Attempt to register an interface handler not deriving from 'InterfaceHandler'!"
        )
    _interfaceHandlers[name] = cls
    return cls


def getInterfaceHandler(name: str) -> Optional[Type["InterfaceHandler"]]:
    return _interfaceHandlers.get(name, None)


def registeredInterfaceHandlers() -> Iterator["InterfaceHandler"]:
    return _interfaceHandlers.values()


_alreadyRequestedOptions: List[str] = []


def camelToKebab(s: str):
    return ''.join(['-' + c.lower() if c.isupper() else c for c in s]).lstrip('-')


def camelToSnake(s: str):
    return ''.join(['_' + c.lower() if c.isupper() else c for c in s]).lstrip('_')


class TypeUtils:
    @staticmethod
    def isOptional(t: Type) -> bool:
        origin = typing.get_origin(t)
        args = typing.get_args(t)
        return (
            origin == typing.Union and
            len(args) == 2 and
            args[1] == type(None)
        )

    @staticmethod
    def isDict(t: Type) -> bool:
        origin = typing.get_origin(t)
        return origin == typing.Dict

    @staticmethod
    def isList(t: Type) -> bool:
        origin = typing.get_origin(t)
        return origin == typing.List

    @staticmethod
    def isTuple(t: Type) -> bool:
        origin = typing.get_origin(t)
        return origin == typing.Tuple

    @staticmethod
    def typeArgument(t: Type) -> Type:
        args = typing.get_args(t)
        assert len(args) == 1
        return args[0]

    @staticmethod
    def typeArguments(t: Type) -> Tuple[Type]:
        return typing.get_args(t)


def _field(default: Optional[T] = None, default_factory: Optional[Callable[[], T]] = None, help: Optional[str] = None) -> dataclasses.Field:
    if default_factory is not None:
        assert default is None
        return dataclasses.field(default_factory=default_factory, metadata={"help": help})

    return dataclasses.field(default=default, metadata={"help": help})


@dataclasses.dataclass(frozen=True)
class WrapperConfig:
    verilatedModuleName: str = _field(
        "V$", help="Name of the Verilated module that is being wrapped. '$' replaces the module name in the hdlinfo file.")
    verilatedIncludeStr: str = _field(
        "<$.h>", help="Include string for the Verilated module. '$' replaces the Verilated module name.")
    outputClassName: str = _field(
        "Sc$", help="Output wrapper class name. '$' replaces the module name in the hdlinfo file.")
    includeGuardStr: str = _field(
        "__$_HPP_INCLUDED__", help="Include guard form. Should be all upper case. '$' replaces the output wrapper class name.")
    includeHppFile: bool = _field(
        True, help="Generated CPP file should include the generated HPP file.")
    hppIncludeStr: Optional[str] = _field(
        "<$.hpp>", help="Include string. '$' replaces the output wrapper class name.")
    markFinal: bool = _field(True, help="Marks the wrapper class 'final'.")
    templated: bool = _field(
        False, help="Makes the wrapper class templated on 'VerilatedModule'.")
    hdlscwIncludeStr: str = _field(
        "<hdlscw/$>", help="Include string for hdlscw headers. '$' replaces the header file name")
    inheritsWrapperBase: bool = _field(
        True, help="Makes the class inherit 'hdlscw::wrapper_base'.")
    implementTraceVerilated: bool = _field(
        True, help="Implements the 'traceVerilated' function.")
    useTracedTestMacro: bool = _field(
        True, help="Wraps the 'traceVerilated' function between #if defined(...)/#endif.")
    tracedTestMacroIdentifier: Optional[str] = _field(
        "VERILATED_TRACE_ENABLED", help="Macro identifier for the condition of #if defined(...).")
    systemcIncludeStr: str = _field(
        "<$>", help="Include string for SystemC libraries. '$' replaces the header file name, such as 'systemc'.")
    printRequestedOptions: bool = _field(
        True, help="Prints accessed options by interface handlers. Useful for debugging.")

    # supposed to passed by command line
    options: Dict[str, str] = dataclasses.field(default_factory=lambda: {})

    def requestOption(self, s: str, t: Callable[[str], T], default: T = "") -> T:
        if self.printRequestedOptions:
            if s not in _alreadyRequestedOptions:
                print(f"[info] WrapperConfig: option '{
                      s}' is accessed (default = '{default}')")
                _alreadyRequestedOptions.append(s)
        if (v := self.options.get(s, None)) is not None:
            return t(v)
        return default

    @staticmethod
    def configureArgParser(argParser: argparse.ArgumentParser) -> None:
        g = argParser.add_argument_group("Wrapper configuration")

        for field in dataclasses.fields(WrapperConfig):
            kebabName = camelToKebab(field.name)

            if field.name == "options":
                continue

            t = field.type

            if TypeUtils.isOptional(field.type):
                t = TypeUtils.typeArguments(t)[0]

            helpText = field.metadata["help"]

            if field.default is not None:
                helpText = f"{helpText} (default = '{field.default}')"

            if t in (str, int, float):
                g.add_argument(f"--{kebabName}", type=t,
                               default=field.default, help=helpText)
            elif t == bool:
                g.add_argument(
                    f"--{kebabName}", type=t, default=field.default, choices=[True, False], help=helpText)
            else:
                raise TypeError(
                    f"not recognized type for configuring the argument parser: '{t}'")

        g.add_argument("-o", "--option", action="append",
                       nargs=2, help="Adds an option: -o NAME VALUE")

    @staticmethod
    def fromNamespace(ns: argparse.Namespace) -> "WrapperConfig":
        kw = {}

        for field in dataclasses.fields(WrapperConfig):
            snakeName = camelToSnake(field.name)

            if field.name == "options":
                continue

            if (x := getattr(ns, snakeName, None)) is not None:
                kw[field.name] = x

        # now, parse the options
        if ns.option is not None:
            kw["options"] = {}
            for name, value in ns.option:
                kw["options"][name] = value

        return WrapperConfig(**kw)


class Wrapper:
    def __init__(
        self,
        module: hdlinfo.Module,
        config: WrapperConfig
    ) -> None:
        self._attr = {}
        self._codeGen = codegen.CodeGen()
        self._module = module
        self._config = config

        self._initialize()

    @property
    def cg(self) -> codegen.CodeGen:
        return self._codeGen

    @property
    def module(self) -> hdlinfo.Module:
        return self._module

    @property
    def config(self) -> WrapperConfig:
        return self._config

    def getReset(self, name: str, activeHigh: bool) -> str:
        """Returns the name of the reset port with requested polarity.

        Args:
            name (str): requested port name.
            activeHigh (bool): Active high if True, active low otherwise.

        Returns:
            str: port name.

        Raises:
            KeyError: requested port cannot be found.
        """
        if (ports := self.module.filterPorts(lambda port: port.kind == hdlinfo.PortKind.reset and port.name == name)) is not None:
            for port in ports:
                if activeHigh and port.sensitivity == hdlinfo.PortSensitivity.resetActiveHigh:
                    return f"{port.name}"
                elif not activeHigh and port.sensitivity == hdlinfo.PortSensitivity.resetActiveLow:
                    return f"{port.name}"
                else:
                    return f"{port.name}_INVERTED_"
        raise KeyError(f"request reset port '{name}' not found")

    def getClock(self, name: str) -> str:
        """Returns the name of the clock port.

        Args:
            name (str): _description_

        Returns:
            str: _description_

        Raises:
            KeyError: requested port cannot be found.
        """
        if (ports := self.module.filterPorts(lambda port: port.kind == hdlinfo.PortKind.clock and port.name == name)) is not None:
            for port in ports:
                return f"{port.name}"
        raise KeyError(f"request clock port '{name}' not found")

    def getAttr(self, name: str) -> Any:
        return self._attr.get(name, None)

    def setAttr(self, name: str, value: T = None) -> T:
        self._attr[name] = value
        return value

    def _initialize(self) -> None:
        cfg = self.config
        cg = self.cg
        module = self.module

        def initBasic() -> None:
            if cfg.markFinal:
                cg.makeFinal()

            outputClassName = cfg.outputClassName.replace("$", module.name)

            cg.setClassName(outputClassName)
            cg.makeCtorExplicit()
            cg.addBaseClass("public sc_core::sc_module")

            cg.addPublicBlock(f"SC_HAS_PROCESS({outputClassName});")
            cg.addPublicBlock(lambda d: d.separate())

            def instantiateVerilatedModule(className: str):
                cg.addPrivateBlock(f"{className} verilatedModule_;")

            if not cfg.templated:
                className = cfg.verilatedModuleName.replace("$", module.name)
                instantiateVerilatedModule(className)

                cg.addHdrInclude(
                    cfg.verilatedIncludeStr.replace("$", className)
                )
                cg.addHdrIncludeBlock(lambda d: d.separate())
            else:
                cg.addTemplateParam("VerilatedModule")
                instantiateVerilatedModule("VerilatedModule")

            cg.addHdrInclude(cfg.systemcIncludeStr.replace("$", "systemc"))
            cg.addHdrInclude(cfg.systemcIncludeStr.replace("$", "tlm"))
            cg.addHdrIncludeBlock(lambda d: d.separate())
            cg.useIncludeGuard(cfg.includeGuardStr.replace(
                "$", outputClassName.upper()))

            cg.addCtorParam("sc_core::sc_module_name const& $",
                            "moduleName", '""')
            cg.addCtorInit(f"sc_module{{ moduleName }}")
            cg.addCtorInit(f"verilatedModule_(\"verilatedModule\")")

            def implIncludeBlock(d: codegen.Dumper) -> None:
                if cfg.includeHppFile and not cg.isInline:
                    includeStr = cfg.hppIncludeStr.replace(
                        "$", outputClassName)
                    isValid = (includeStr.startswith("<") and includeStr.endswith(">")) or \
                        (includeStr.startswith("\"") and includeStr.endswith("\""))
                    if not isValid:
                        # TODO have a specific exception class
                        raise RuntimeError(
                            f"hppIncludeStr is not valid: {includeStr}")
                    d.iwriteln(f"#include {includeStr}")

            cg.addImplIncludeBlock(implIncludeBlock)

        initBasic()

        def processPorts() -> None:
            # processes ports
            # (1) extracts and exports interrupt ports
            # (2) internally creates a inverted versions of resets (to be used by interfaces)

            def data_type(p: hdlinfo.Port) -> str:
                if p.isBus:
                    w = abs(p.busRange[0] - p.busRange[1]) + 1
                    return f"sc_dt::sc_bv<{w}>"
                else:
                    # TODO make sure that this is not sc_bv<1>
                    return "bool"

            def port_type(p: hdlinfo.Port) -> str:
                assert p.direction in [
                    hdlinfo.PortDirection.input, hdlinfo.PortDirection.output]
                d = p.direction.removesuffix("put")
                return f"sc_core::sc_{d}<{data_type(p)}>"

            def signal_type(p: hdlinfo.Port) -> str:
                return f"sc_core::sc_signal<{data_type(p)}>"

            def processClockPorts() -> None:
                ports = list(self._module.filterPorts(
                    lambda port: port.kind == hdlinfo.PortKind.clock))

                assert all(
                    [not x.isBus for x in ports]
                ), "buses of clocks not supported"

                # TODO add more checks? like no bidirectional ports etc.

                def publicBlock(d: codegen.Dumper) -> None:
                    d.iwriteln("/* BEGIN: clock ports (decl) */")
                    for port in ports:
                        dir = port.direction.removesuffix("put")
                        d.iwriteln(f"sc_core::sc_{dir}_clk {port.name};")
                    d.iwriteln("/* END: clock ports (decl) */")
                    d.separate()

                def ctorBlock(d: codegen.Dumper) -> None:
                    d.iwriteln("/* BEGIN: clock ports (conn) */")
                    for port in ports:
                        d.iwriteln(
                            f"verilatedModule_.{port.name}({port.name});"
                        )
                    d.iwriteln("/* END: clock ports (conn) */")
                    d.separate()

                def ctorInit(d: codegen.Dumper) -> None:
                    for port in ports:
                        d.iwrite(f"{port.name}(\"{port.name}\")")
                        d.writeln(",")

                self.cg.addCtorInit(ctorInit)
                self.cg.addPublicBlock(publicBlock)
                self.cg.addCtorBlock(ctorBlock)

            processClockPorts()

            def processResetPorts() -> None:
                ports = list(self._module.filterPorts(
                    lambda port: port.kind in [
                        hdlinfo.PortKind.reset, hdlinfo.PortKind.asyncReset]
                ))

                def publicBlock(d: codegen.Dumper) -> None:
                    d.separate()

                    d.iwriteln("/* BEGIN: reset ports (decl) */")
                    for port in ports:
                        d.iwriteln(f"{port_type(port)} {port.name};")
                    d.iwriteln("/* END: reset ports (decl) */")

                    d.separate()

                def privateBlock(d: codegen.Dumper) -> None:
                    d.separate()

                    d.iwriteln("/* BEGIN: inverted reset signals */")
                    for port in ports:
                        if port.direction == hdlinfo.PortDirection.input:
                            d.iwriteln(f"{signal_type(port)} {
                                       port.name}_INVERTED_;")
                    d.iwriteln("/* END: inverted reset signals */")
                    d.separate()
                    d.iwriteln("void generateInvertedResetPorts();")

                    d.separate()

                def ctorBlock(d: codegen.Dumper) -> None:
                    d.iwriteln("/* BEGIN: reset ports (conn) */")
                    for port in ports:
                        d.iwriteln(
                            f"verilatedModule_.{port.name}({port.name});"
                        )
                    d.iwriteln("/* END: reset ports (conn) */")
                    d.separate()
                    d.iwriteln("/* generate inverted resets */")
                    d.iwriteln("SC_METHOD(generateInvertedResetPorts);")
                    d.iwriteln("sensitive")
                    d.indent_in()
                    for port in ports:
                        if port.direction == hdlinfo.PortDirection.input:
                            d.iwriteln(f"<< {port.name}")
                    d.indent_out()
                    d.iwriteln(";")

                    d.separate()

                def implBlock(d: codegen.Dumper) -> None:
                    self.cg.dumpMemberImpl(
                        d, "void $()", "generateInvertedResetPorts")
                    d.iwriteln(f" {{")
                    d.indent_in()
                    d.separate()
                    for port in ports:
                        if port.direction == hdlinfo.PortDirection.input:
                            d.iwriteln(
                                f"{port.name}_INVERTED_.write(!{port.name}.read());")
                    d.separate()
                    d.indent_out()
                    d.iwriteln(f"}}")

                def ctorInit(d: codegen.Dumper) -> None:
                    for port in ports:
                        d.iwrite(f"{port.name}(\"{port.name}\")")
                        d.writeln(",")

                self.cg.addCtorInit(ctorInit)
                self.cg.addPublicBlock(publicBlock)
                self.cg.addPrivateBlock(privateBlock)
                self.cg.addCtorBlock(ctorBlock)
                self.cg.addImplBlock(implBlock)

            processResetPorts()

            def processInterruptPorts() -> None:
                ports = list(self._module.filterPorts(
                    lambda port: port.kind == hdlinfo.PortKind.interrupt
                ))

                def publicBlock(d: codegen.Dumper) -> None:
                    d.iwriteln("/* BEGIN: interrupt ports (decl) */")
                    for port in ports:
                        d.iwriteln(f"{port_type(port)} {port.name};")
                    d.iwriteln("/* END: interrupt ports (decl) */")
                    d.separate()

                def ctorBlock(d: codegen.Dumper) -> None:
                    d.iwriteln("/* BEGIN: interrupt ports (conn) */")
                    for port in ports:
                        d.iwriteln(
                            f"verilatedModule_.{port.name}({port.name});"
                        )
                    d.iwriteln("/* END: interrupt ports (conn) */")
                    d.separate()

                def ctorInit(d: codegen.Dumper) -> None:
                    for port in ports:
                        d.iwrite(f"{port.name}(\"{port.name}\")")
                        d.writeln(",")

                self.cg.addCtorInit(ctorInit)
                self.cg.addPublicBlock(publicBlock)
                self.cg.addCtorBlock(ctorBlock)

            processInterruptPorts()

            def processDataPorts() -> None:
                ports = list(self._module.filterPorts(
                    lambda port: port.kind == hdlinfo.PortKind.data
                ))

                def publicBlock(d: codegen.Dumper) -> None:
                    d.iwriteln("/* BEGIN: data ports (decl) */")
                    for port in ports:
                        d.iwriteln(f"{port_type(port)} {port.name};")
                    d.iwriteln("/* END: data ports (decl) */")
                    d.separate()

                def ctorBlock(d: codegen.Dumper) -> None:
                    d.iwriteln("/* BEGIN: data ports (conn) */")
                    for port in ports:
                        d.iwriteln(
                            f"verilatedModule_.{port.name}({port.name});"
                        )
                    d.iwriteln("/* END: data ports (conn) */")
                    d.separate()

                def ctorInit(d: codegen.Dumper) -> None:
                    for port in ports:
                        d.iwrite(f"{port.name}(\"{port.name}\")")
                        d.writeln(",")

                self.cg.addCtorInit(ctorInit)
                self.cg.addPublicBlock(publicBlock)
                self.cg.addCtorBlock(ctorBlock)

            processDataPorts()

        processPorts()

        def inheritWrapperBase() -> None:
            cg.addHdrInclude(cfg.hdlscwIncludeStr.replace(
                "$", "wrapper_base.hpp"))
            cg.addHdrIncludeBlock(lambda d: d.separate())

            cg.addBaseClass("public hdlscw::wrapper_base")
            cg.makeDtorVirtual()

            def publicBlock(d: codegen.Dumper) -> None:
                d.iwriteln(
                    "sc_core::sc_module* getThisModule() noexcept override {")
                d.indent_in()
                d.iwriteln("return this;")
                d.indent_out()
                d.iwriteln("}")

                d.separate()

                d.iwriteln(
                    "sc_core::sc_module const* getThisModule() const noexcept override {")
                d.indent_in()
                d.iwriteln("return this;")
                d.indent_out()
                d.iwriteln("}")

                d.separate()

                d.iwriteln(
                    "sc_core::sc_module* getVerilatedModule() noexcept override {")
                d.indent_in()
                d.iwriteln("return &verilatedModule_;")
                d.indent_out()
                d.iwriteln("}")

                d.separate()

                d.iwriteln(
                    "sc_core::sc_module const* getVerilatedModule() const noexcept override {")
                d.indent_in()
                d.iwriteln("return &verilatedModule_;")
                d.indent_out()
                d.iwriteln("}")

                d.separate()

                if cfg.implementTraceVerilated:
                    if cfg.useTracedTestMacro:
                        d.iwriteln(
                            f"#if defined({cfg.tracedTestMacroIdentifier})")

                    d.iwriteln(
                        "void traceVerilated(VerilatedVcdC* tfp, int levels, int options = 0) override {")
                    d.indent_in()
                    d.iwriteln(
                        "return verilatedModule_.trace(tfp, levels, options);")
                    d.indent_out()
                    d.iwriteln("}")

                    # TODO what about SystemC module's trace function?
                    # maybe, we should provide a function for it.

                    if cfg.useTracedTestMacro:
                        d.iwriteln(f"#endif")

                    d.separate()

            def ctorBlock(d: codegen.Dumper) -> None:
                d.iwriteln("/* BEGIN: register ports */")
                for port in self.module.ports:
                    d.iwriteln(f'set("{port.name}", {port.name});')
                d.iwriteln("/* END: register ports */")
                d.separate()

            cg.addPublicBlock(publicBlock)
            cg.addCtorBlock(ctorBlock)

        if cfg.inheritsWrapperBase:
            inheritWrapperBase()

        def processInterfaces() -> None:
            for interface in module.interfaces:
                done = False

                if "hdlscw.interfaceHandler" in interface.args:
                    interfaceHandlerName: str = interface.args["hdlscw.interfaceHandler"]
                    interfaceHandler = getInterfaceHandler(
                        interfaceHandlerName)

                    if interfaceHandler is None:
                        print(f"[warn] wrapper: requested interface handler could not be found '{
                              interfaceHandlerName}'")
                    else:
                        done = interfaceHandler.processInterface(
                            self, cg, interface)

                        if not done:
                            print(f"[warn] wrapper: requested interface handler failed '{
                                  interfaceHandlerName}'")

                if not done:
                    for interfaceHandler in registeredInterfaceHandlers():
                        done = interfaceHandler.processInterface(
                            self, cg, interface)

                        if done:
                            break

                if not done:
                    # TODO have a custom exception class
                    raise RuntimeError(f"interface could not be handled: name = '{
                                       interface.name}', kind = '{interface.kind}'")

        processInterfaces()

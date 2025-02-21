from typing import *
from dataclasses import dataclass, field
from hdlscw import codegen, wrapper
from .common import *
import hdlinfo
import re

T = TypeVar("T")
__all__ = ["ElasticProtocol", "translate", "mark"]

_protocolMap: Dict[str, "ElasticProtocol"] = {}
_protocolPattern = r'^(chext\.elastic\.Interface|readyValid|hdlinfo\.elastic\.Interface)\[([\w\.-]+)\]$'

@dataclass
class Marked(Generic[T]):
    obj: T
    props: Dict[str, Any]


def mark(t: T, **kwargs) -> Marked[T]:
    return Marked(t, kwargs)

def translate(t: str) -> Marked[str]:
    return mark(t, translate=True)

@dataclass(frozen=True)
class ElasticProtocol:
    protocolName: str
    includeStr: List[Union[str, Marked[str]]] = field(default_factory=list)
    bitsSignalType: Union[str, Callable[[hdlinfo.Interface], str]] = "bool"
    portsToSignals: List[Tuple[str, str]] = field(default_factory=list)

    def __post_init__(self) -> None:
        if self.protocolName in _protocolMap:
            raise RuntimeError(f"An elastic protocol with name '{self.protocolName}' already exists!")

        _protocolMap[self.protocolName] = self


@wrapper.registerInterfaceHandler
class ElasticProtocolHandler(wrapper.StatefulInterfaceHandler):
    def __init__(self, wrapper: wrapper.Wrapper, cg: codegen.CodeGen) -> None:
        super().__init__(wrapper, cg)

        self._includeBlocks: List[codegen.Block] = []
        self._publicBlocks: List[codegen.Block] = []
        self._ctorInitBlocks: List[codegen.Block] = []
        self._ctorBlocks: List[codegen.Block] = []

        self._includeStr = self.getOptionStr("chext_test.includeStr", "<$>")

        def hdrInclude(d: codegen.Dumper) -> None:
            d.iwriteln(f"/* BEGIN: chext_test includes for 'elastic' */")
            d.iwriteln(f"#include {self._mkIncludeStr('chext_test/elastic/Driver.hpp')}")
            dumpBlockList(d, self._includeBlocks)
            d.iwriteln(f"/* END: chext_test includes for 'elastic' */")

            d.separate()
        
        def public(d: codegen.Dumper) -> None:
            d.iwriteln(f"/* BEGIN: chext_test public for 'elastic' */")
            dumpBlockList(d, self._publicBlocks)
            d.iwriteln(f"/* END: chext_test public for 'elastic' */")

            d.separate()
        
        def ctorInit(d: codegen.Dumper) -> None:
            dumpBlockList(d, self._ctorInitBlocks)

        def ctor(d: codegen.Dumper) -> None:
            d.iwriteln(f"/* BEGIN: chext_test ctor for 'elastic' */")
            dumpBlockList(d, self._ctorBlocks)
            d.iwriteln(f"/* END: chext_test ctor for 'elastic' */")

            d.separate()

        cg.addHdrIncludeBlock(hdrInclude)
        cg.addPublicBlock(public)
        cg.addCtorInit(ctorInit)
        cg.addCtorBlock(ctor)

    def _mkIncludeStr(self, s: str) -> str:
        return self._includeStr.replace("$", s)

    @staticmethod
    def checkKind(kind: str) -> bool:
        match = re.match(_protocolPattern, kind)
        if match:
            protocolName = match.group(2)
            if protocolName not in _protocolMap:
                print(f"[warn] Elastic protocol is not registered: {protocolName}")
                return False
            return True
        else:
            return False


    def processInterface(self, interface: hdlinfo.Interface) -> None:
        # since checkKind is a static method (as a result of which we instantiate the handler)
        # we should process the interface.kind again. Is that ideal? No, but I do not really
        # think there is a better way...
        protocolName = re.match(_protocolPattern, interface.kind).group(2)
        ep = _protocolMap[protocolName]

        bitsSignalType = None
        if isinstance(ep.bitsSignalType, str):
            bitsSignalType = ep.bitsSignalType
        else:
            bitsSignalType = ep.bitsSignalType(interface)
        name = interface.name

        role = None
        if interface.role == "source":
            role = "Source"
        elif interface.role == "sink":
            role = "Sink"
        else:
            raise RuntimeError(f"Invalid interface role: {interface.role}")
        
        if ep.includeStr is not None:
            if isinstance(ep.includeStr, Marked) and isinstance(ep.includeStr.obj, str):
                if ep.includeStr.props.get("translate", False):
                    self._includeBlocks.append(f"#include {self._mkIncludeStr(ep.includeStr.obj)}")
                else:
                    self._includeBlocks.append(f"#include {ep.includeStr.obj}")
            elif isinstance(ep.includeStr, str):
                self._includeBlocks.append(f"#include {ep.includeStr}")
            else:
                raise RuntimeError(f"Invalid includeStr: {ep.includeStr}.")

        def publicBlock(d: codegen.Dumper) -> None:
            d.iwriteln(f"chext_test::elastic::{role}<{bitsSignalType}> {interface.name};")

        def ctorInitBlock(d: codegen.Dumper) -> None:
            clock = self.wrapper.getClock(interface.associatedClock)
            reset = self.wrapper.getReset(interface.associatedReset, True)
            d.iwrite(f"{name}(\"{name}\", {clock}, {reset})")
            d.writeln(",")

        def ctorBlock(d: codegen.Dumper) -> None:
            for (port, signal) in ep.portsToSignals:
                d.iwriteln(f"verilatedModule_.{name}_{port}(this->{name}.{signal});")

            d.separate()

        self._publicBlocks.append(publicBlock)
        self._ctorInitBlocks.append(ctorInitBlock)
        self._ctorBlocks.append(ctorBlock)

def registerBasicElasticProtocols():
    def registerData():
        def signalType(interface: hdlinfo.Interface) -> str:
            if "width" not in interface.args:
                raise RuntimeError("chext.elastic.Data: interface missing argument 'width'.")
            
            width = interface.args["width"]

            if not isinstance(width, int):
                raise RuntimeError("chext.elastic.Data: interface argument 'width' must be an integer.")

            return f"sc_core::sc_signal<sc_dt::sc_bv<{width}>>"
        
        ElasticProtocol(
            "chext.elastic.Data",
            None,
            signalType,
            [
                ("bits", "bits"),
                ("ready", "ready"),
                ("valid", "valid")
            ]
        )
    
    def registerDataLast():
        def signalType(interface: hdlinfo.Interface) -> str:
            if "width" not in interface.args:
                raise RuntimeError("chext.elastic.Data: interface missing argument 'width'.")
            
            width = interface.args["width"]

            if not isinstance(width, int):
                raise RuntimeError("chext.elastic.Data: interface argument 'width' must be an integer.")

            return f"chext_test::elastic::DataLastSignals<{width}>"

        ElasticProtocol(
            "chext.elastic.DataLast",
            translate("chext_test/elastic/DataLast.hpp"),
            signalType,
            [
                ("bits_data", "bits.data"),
                ("bits_last", "bits.last"),
                ("ready", "ready"),
                ("valid", "valid")
            ]
        )

    registerData()
    registerDataLast()

registerBasicElasticProtocols()

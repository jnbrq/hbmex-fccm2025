from hdlinfo.protocols.amba import axi4
import hdlinfo
from hdlscw import codegen, wrapper
from typing import *
from .common import *

__all__ = []

T = TypeVar('T')


_SIGNAL_MAP = {
    "ARREADY": "ar.ready",
    "ARVALID": "ar.valid",
    "ARID": "ar.bits.id",
    "ARADDR": "ar.bits.addr",
    "ARLEN": "ar.bits.len",
    "ARSIZE": "ar.bits.size",
    "ARBURST": "ar.bits.burst",
    "ARLOCK": "ar.bits.lock",
    "ARCACHE": "ar.bits.cache",
    "ARPROT": "ar.bits.prot",
    "ARQOS": "ar.bits.qos",
    "ARREGION": "ar.bits.region",
    "ARUSER": "ar.bits.user",

    "RREADY": "r.ready",
    "RVALID": "r.valid",
    "RID": "r.bits.id",
    "RDATA": "r.bits.data",
    "RRESP": "r.bits.resp",
    "RLAST": "r.bits.last",
    "RUSER": "r.bits.user",

    "AWREADY": "aw.ready",
    "AWVALID": "aw.valid",
    "AWID": "aw.bits.id",
    "AWADDR": "aw.bits.addr",
    "AWLEN": "aw.bits.len",
    "AWSIZE": "aw.bits.size",
    "AWBURST": "aw.bits.burst",
    "AWLOCK": "aw.bits.lock",
    "AWCACHE": "aw.bits.cache",
    "AWPROT": "aw.bits.prot",
    "AWQOS": "aw.bits.qos",
    "AWREGION": "aw.bits.region",
    "AWUSER": "aw.bits.user",

    "WREADY": "w.ready",
    "WVALID": "w.valid",
    "WDATA": "w.bits.data",
    "WSTRB": "w.bits.strb",
    "WLAST": "w.bits.last",
    "WUSER": "w.bits.user",

    "BREADY": "b.ready",
    "BVALID": "b.valid",
    "BID": "b.bits.id",
    "BRESP": "b.bits.resp",
    "BUSER": "b.bits.user"
}


@wrapper.registerInterfaceHandlerCustom("InterfaceHandlerAxi4")
class Axi4InterfaceHandler(wrapper.StatefulInterfaceHandler):
    def __init__(self, wrapper: wrapper.Wrapper, cg: codegen.CodeGen) -> None:
        super().__init__(wrapper, cg)

        self._publicBlocks: List[codegen.Block] = []
        self._ctorInitBlocks: List[codegen.Block] = []
        self._ctorBlocks: List[codegen.Block] = []

        includeStr = self.getOptionStr("chext_test.includeStr", "<$>")

        def mkIncludeStr(s: str) -> str:
            return includeStr.replace("$", s)

        def hdrInclude(d: codegen.Dumper) -> None:
            d.iwriteln("/* BEGIN: chext_test includes for 'amba/axi4' */")
            d.iwriteln(f"#include {mkIncludeStr('chext_test/amba/axi4/full/Driver.hpp')}")
            d.iwriteln(f"#include {mkIncludeStr('chext_test/amba/axi4/lite/Driver.hpp')}")
            d.iwriteln("/* END: chext_test includes for 'amba/axi4' */")

            d.separate()

        def public(d: codegen.Dumper) -> None:
            d.iwriteln("/* BEGIN: chext_test public for 'amba/axi4' */")
            dumpBlockList(d, self._publicBlocks)
            d.iwriteln("/* END: chext_test public for 'amba/axi4' */")

            d.separate()

        def ctorInit(d: codegen.Dumper) -> None:
            dumpBlockList(d, self._ctorInitBlocks)

        def ctor(d: codegen.Dumper) -> None:
            d.iwriteln("/* BEGIN: chext_test ctor for 'amba/axi4' */")
            dumpBlockList(d, self._ctorBlocks)
            d.iwriteln("/* END: chext_test ctor for 'amba/axi4' */")

            d.separate()

        cg.addHdrIncludeBlock(hdrInclude)
        cg.addPublicBlock(public)
        cg.addCtorInit(ctorInit)
        cg.addCtorBlock(ctor)

    def processInterface(self, interface: hdlinfo.Interface) -> None:
        if "config" not in interface.args:
            raise Exception(f"interface '{interface.name}' with kind '{interface.kind}' has no 'config'!")

        cfg: axi4.Config = interface.args["config"]
        tpe = "lite" if cfg.lite else "full"

        role = None
        if interface.role == "slave":
            role = "Slave"
        elif interface.role == "master":
            role = "Master"
        else:
            raise RuntimeError(f"Invalid interface role: {interface.role}")

        paramsList = []

        if tpe == "lite":
            paramsList.append(str(cfg.wAddr))
            paramsList.append(str(cfg.wData))
        else:
            paramsList.append(str(cfg.wId))
            paramsList.append(str(cfg.wAddr))
            paramsList.append(str(cfg.wData))
            paramsList.append(str(cfg.wUserAR))
            paramsList.append(str(cfg.wUserR))
            paramsList.append(str(cfg.wUserAW))
            paramsList.append(str(cfg.wUserW))
            paramsList.append(str(cfg.wUserB))
            paramsList.append("true" if cfg.axi3Compat else "false")

        params = ",".join(paramsList)
        name = interface.name

        def publicBlock(d: codegen.Dumper) -> None:
            d.iwriteln(f"chext_test::amba::axi4::{tpe}::{role}<{params}> {name};")

        def ctorInitBlock(d: codegen.Dumper) -> None:
            clock = self.wrapper.getClock(interface.associatedClock)
            reset = self.wrapper.getReset(interface.associatedReset, True)
            d.iwrite(f"{name}(\"{name}\", {clock}, {reset})")
            d.writeln(",")

        def ctorBlock(d: codegen.Dumper) -> None:
            for signal in cfg.signals:
                d.iwriteln(f"verilatedModule_.{name}_{signal}(this->{name}.{_SIGNAL_MAP[signal]});")
            d.separate()

        self._publicBlocks.append(publicBlock)
        self._ctorInitBlocks.append(ctorInitBlock)
        self._ctorBlocks.append(ctorBlock)

    @staticmethod
    def checkKind(kind: str) -> bool:
        return kind == "axi4" or kind == "axi4_rtl"

from chext_test import ElasticProtocol
import hdlinfo
import math


def registerAddrLenSizeBurstBundle() -> None:
    def signalName(interface: hdlinfo.Interface) -> str:
        wAddr = interface.args["wAddr"]
        return f"protocols::AddrLenSizeBurstSignals<{wAddr}>"

    portsToSignals = [
        ("bits_addr", "bits.addr"),
        ("bits_len", "bits.len"),
        ("bits_size", "bits.size"),
        ("bits_burst", "bits.burst"),
        ("ready", "ready"),
        ("valid", "valid")
    ]

    ElasticProtocol(
        "chext.amba.axi4.full.components.addrgen.AddrLenSizeBurstBundle",
        includeStr='"Protocols.hpp"',
        bitsSignalType=signalName,
        portsToSignals=portsToSignals
    )


registerAddrLenSizeBurstBundle()


def registerAddrSizeLastBundle() -> None:
    def signalName(interface: hdlinfo.Interface) -> str:
        wAddr = interface.args["wAddr"]
        return f"protocols::AddrSizeLastSignals<{wAddr}>"

    portsToSignals = [
        ("bits_addr", "bits.addr"),
        ("bits_size", "bits.size"),
        ("bits_last", "bits.last"),
        ("ready", "ready"),
        ("valid", "valid")
    ]

    ElasticProtocol(
        "chext.amba.axi4.full.components.addrgen.AddrSizeLastBundle",
        includeStr='"Protocols.hpp"',
        bitsSignalType=signalName,
        portsToSignals=portsToSignals
    )


registerAddrSizeLastBundle()

def registerAddrSizeStrobeLastBundle() -> None:
    def signalName(interface: hdlinfo.Interface) -> str:
        wAddr = interface.args["wAddr"]
        wData = interface.args["wData"]
        wStrobe = wData // 8
        wIndex = int(math.log2(wStrobe))
        return f"protocols::AddrSizeStrobeLastSignals<{wAddr}, {wStrobe}, {wIndex}>"

    portsToSignals = [
        ("bits_addr", "bits.addr"),
        ("bits_size", "bits.size"),
        ("bits_strb", "bits.strb"),
        ("bits_lowerByteIndex", "bits.lowerByteIndex"),
        ("bits_upperByteIndex", "bits.upperByteIndex"),
        ("bits_last", "bits.last"),
        ("ready", "ready"),
        ("valid", "valid")
    ]

    ElasticProtocol(
        "chext.amba.axi4.full.components.addrgen.AddrSizeStrobeLastBundle",
        includeStr='"Protocols.hpp"',
        bitsSignalType=signalName,
        portsToSignals=portsToSignals
    )

registerAddrSizeStrobeLastBundle()

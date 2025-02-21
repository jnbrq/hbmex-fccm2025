import chext_test
import hdlinfo

def signalName(interface: hdlinfo.Interface) -> str:
    return f"PacketSignals<{interface.args.get("dataWidth", 32)}>"

chext_test.ElasticProtocol(
    "Packet",
    "<Packet.hpp>",
    signalName,
    [
        ("bits_data", "bits.data"),
        ("bits_id", "bits.id"),
        ("ready", "ready"),
        ("valid", "valid")
    ]
)

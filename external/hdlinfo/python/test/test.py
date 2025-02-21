import hdlinfo
from pprint import pprint

# we need this line to load the protocols provided by hdlinfo
from hdlinfo.protocols import amba

import dataclasses


@hdlinfo.register_dataclass_adv("MyModuleConfig")
@dataclasses.dataclass(frozen=True)
class MyModuleConfig:
    internalBufferSize: int
    numOutstandingReadRequests: int
    numOutstandingWriteRequests: int


def main() -> None:
    from hdlinfo import Module, Interface, Port, PortDirection, PortKind, PortSensitivity

    pprint(Module.fromJsonFile("./test/testInput.hdlinfo.json"))

    Module(
        "OtherModule",
        [
            Port("clock", PortDirection.input, PortKind.clock),
            Port("reset", PortDirection.input, PortKind.reset, PortSensitivity.resetActiveHigh),
            Port("data", PortDirection.output, PortKind.data, isBus=True, busRange=(31, 0))
        ],
        [
            Interface(
                name="S_AXIL",
                kind="axi4",
                role="slave",
                args={
                    "config": amba.axi4.Config(lite=True, wAddr=32, wData=64)
                }
            )
        ]
    ).toJsonFile("./test/testOutput.hdlinfo.json")


if __name__ == "__main__":
    main()

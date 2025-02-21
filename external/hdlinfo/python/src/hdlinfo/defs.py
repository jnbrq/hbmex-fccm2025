from .json import register_dataclass, TypedObject, from_json, from_dict, to_json, to_dict
from dataclasses import dataclass, field
from typing import Tuple, List, Callable, Iterable, Dict

__all__ = [
    "PortDirection",
    "PortKind",
    "PortSensitivity",
    "Port",
    "Interface",
    "Module"
]


class PortDirection:
    none = "none"
    input = "input"
    output = "output"
    bidirectional = "bidirectional"


class PortKind:
    none = "none"

    clock = "clock"
    reset = "reset"
    asyncReset = "asyncReset"
    data = "data"
    interrupt = "interrupt"


class PortSensitivity:
    none = "none"

    resetActiveHigh = "resetActiveHigh"
    resetActiveLow = "resetActiveLow"

    clockRising = "clockRising"
    clockFalling = "clockFalling"

    interruptHigh = "interruptHigh"
    interruptLow = "interruptLow"
    interruptRising = "interruptRising"
    interruptFalling = "interruptFalling"


@register_dataclass
@dataclass(frozen=True)
class Port:
    name: str
    direction: str = PortDirection.none
    kind: str = PortKind.none
    sensitivity: str = PortSensitivity.none
    isBus: bool = False
    busRange: Tuple[int, int] = (0, 0)
    frequencyMHz: float = 100.0
    associatedClock: str = ""
    associatedReset: str = ""
    args: Dict[str, TypedObject] = field(default_factory=lambda: {})


@register_dataclass
@dataclass(frozen=True)
class Interface:
    name: str
    role: str
    kind: str
    associatedClock: str = ""
    associatedReset: str = ""
    args: Dict[str, TypedObject] = field(default_factory=lambda: {})


@register_dataclass
@dataclass(frozen=True)
class Module:
    name: str
    ports: List[Port] = field(default_factory=lambda: ())
    interfaces: List[Interface] = field(default_factory=lambda: ())
    args: Dict[str, TypedObject] = field(default_factory=lambda: {})

    def filterPorts(self, cond: Callable[[Port], bool]) -> Iterable[Port]:
        for port in self.ports:
            if cond(port):
                yield port

    def filterInterfaces(self, cond: Callable[[Port], Interface]) -> Iterable[Interface]:
        for interface in self.interfaces:
            if cond(interface):
                yield interface

    @staticmethod
    def fromJson(jsonContent: str) -> "Module":
        return from_json(Module, jsonContent)

    def toJson(self, *args, **kwargs) -> str:
        return to_json(self, *args, **kwargs)

    @staticmethod
    def fromJsonFile(filePath: str) -> "Module":
        with open(filePath) as f:
            return Module.fromJson(f.read())

    def toJsonFile(self, filePath: str, *args, **kwargs) -> None:
        with open(filePath, "w") as f:
            f.write(self.toJson(*args, **kwargs))

    @staticmethod
    def fromDict(d: Dict) -> "Module":
        return from_dict(Module, d)

    def toDict(self) -> Dict:
        return to_dict(self)

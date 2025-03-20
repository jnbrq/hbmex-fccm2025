from ...json import *
from typing import List
from functools import cached_property

__all__ = ["Config", "kind"]

kind = "axi4s"


@register_dataclass_adv("hdlinfo.protocols.amba.axi4s.Config", aliases=["chext.amba.axi4s.Config"])
@dataclass(frozen=True)
class Config:
    wData: int

    hasReady: bool = True
    hasKeep: bool = True
    hasStrobe: bool = True
    hasLast: bool = True
    hasData: bool = True

    wId: int = 0
    wDest: int = 0
    wUser: int = 0

    def __post_init__(self):
        if self.wData < 8:
            raise ValueError("wData must be at least 8")
        if not (self.wData % 8 == 0):
            raise ValueError("wData must be divisible by 8")
        if any([x < 0 for x in [self.wId, self.wDest, self.wUser]]):
            raise ValueError("wId, wDest, and wUser must be greater than or equal to 0")

    @cached_property
    def signals(self) -> List[str]:
        result = ["TVALID"]

        if self.hasReady:
            result.append("TREADY")

        if self.hasKeep:
            result.append("TKEEP")

        if self.hasStrobe:
            result.append("TSTRB")

        if self.hasLast:
            result.append("TLAST")

        if self.hasData:
            result.append("TDATA")

        if self.wId > 0:
            result.append("TID")

        if self.wDest > 0:
            result.append("TDEST")

        if self.wUser > 0:
            result.append("TUSER")

        return result

from hdlscw import codegen
from typing import *

T = TypeVar('T')

__all__ = ["dumpBlockList"]


def dumpBlockList(d: codegen.Dumper, l: List[codegen.Block]) -> None:
    for x in l:
        if isinstance(x, str):
            d.iwriteln(x)
        else:
            x(d)

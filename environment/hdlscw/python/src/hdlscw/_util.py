from typing import *

__all__ = [
    "printAsList"
]


def printAsList(obj: object, nameList: List[str], prefix: str = "", print=print) -> None:
    for name in nameList:
        if isinstance(obj, dict):
            v = obj[name]
        else:
            v = getattr(obj, name)

        print(f"{prefix}.{name} = {v}")

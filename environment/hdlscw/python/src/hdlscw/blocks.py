from . import codegen
from typing import *

__all__ = [
    "RawBlock",
    "SeparateBlock"
]


class RawBlock:
    def __init__(
        self,
        rawData: str,
        noIndent: bool = False,
        extraIndent: int = 0,
        newLine: bool = True,
        separateAfter: bool = False
    ) -> None:
        self._rawData = rawData
        self._noIndent = noIndent
        self._extraIndent = extraIndent
        self._newLine = newLine
        self._separateAfter = separateAfter

    def __call__(
        self,
        dumper: codegen.Dumper
    ) -> None:
        for i in range(self._extraIndent):
            dumper.indent_in()

        if self._noIndent:
            if self._newLine:
                dumper.writeln(self._rawData)
            else:
                dumper.write(self._rawData)
        else:
            if self._newLine:
                dumper.iwriteln(self._rawData)
            else:
                dumper.iwrite(self._rawData)

        if self._separateAfter:
            dumper.separate()

        for i in range(self._extraIndent):
            dumper.indent_out()


class SeparateBlock:
    def __init__(self) -> None:
        pass

    def __call__(
        self,
        dumper: codegen.Dumper
    ) -> None:
        dumper.separate()


class BlockHolder:
    def __init__(self, numSegments: int) -> None:
        assert numSegments > 0
        self._ll = [[] for x in range(numSegments)]

    def append(self, b: Union[codegen.Block, "BlockHolder"], idx: int = 0) -> None:
        assert idx < len(self._ll) and idx >= 0
        self._ll[idx].append(b)

    def __call__(self, d: codegen.Dumper) -> None:
        for l in self._ll:
            for b in l:
                if isinstance(b, str):
                    d.iwriteln(b)
                else:
                    b(d)

import pprint
import re
from dataclasses import dataclass
from typing import *

vWorkloadName = [
    'amazon-2008',
    'cit-Patents',
    'com-Youtube',
    'cont11_l',
    'dblp-2010',
    'eu-2005',
    'flickr',
    'in-2004',
    'ljournal-2008',
    'road_usa',
    'webbase-1M',
    'wikipedia-20061104'
]


@dataclass
class WorkloadData:
    name: str

    ptrValues: int
    ptrColumnIndices: int
    ptrRowLengths: int
    ptrInputVector: int
    ptrOutputVector: int

    szValues: int
    szColumnIndices: int
    szRowLengths: int
    szInput: int
    szOutput: int

    numRows: int
    numCols: int
    numValues: int


REGEX_PARSE0 = re.compile(
    r"ptrValues: (0x[0-9a-fA-F]+), ptrColumnIndices: (0x[0-9a-fA-F]+), ptrRowLengths: (0x[0-9a-fA-F]+)")
REGEX_PARSE1 = re.compile(r"ptrInputVector: (0x[0-9a-fA-F]+), ptrOutputVector: (0x[0-9a-fA-F]+)")
REGEX_PARSE2 = re.compile(r"numValues: (\d+), numRows: (\d+)")
REGEX_PARSE3 = re.compile(
    r"szValues: (\d+), szColumnIndices: (\d+), szRowLengths: (\d+), szInput: (\d+), szOutput: (\d+)")
REGEX_PARSE4 = re.compile(r"file = .*?([^/\\]+)\.csr, numRows = (\d+), numCols = (\d+), numValues = (\d+)")


def parseFile(fname: str) -> Dict[str, WorkloadData]:
    with open(fname) as f:
        l: List[WorkloadData] = []

        ptrValues: int = None
        ptrColumnIndices: int = None
        ptrRowLengths: int = None
        ptrInputVector: int = None
        ptrOutputVector: int = None

        szValues: int = None
        szColumnIndices: int = None
        szRowLengths: int = None
        szInput: int = None
        szOutput: int = None

        numRows: int = None
        numCols: int = None
        numValues: int = None

        def parse0(line: str) -> Optional[Tuple[int, int, int]]:
            match = REGEX_PARSE0.search(line)
            if match:
                return tuple(int(match.group(i), 16) for i in range(1, 4))
            return None

        def parse1(line: str) -> Optional[Tuple[int, int]]:
            match = REGEX_PARSE1.search(line)
            if match:
                return tuple(int(match.group(i), 16) for i in range(1, 3))
            return None

        def parse2(line: str) -> Optional[Tuple[int, int]]:
            match = REGEX_PARSE2.search(line)
            if match:
                return tuple(int(match.group(i)) for i in range(1, 3))
            return None

        def parse3(line: str) -> Optional[Tuple[int, int, int, int, int]]:
            match = REGEX_PARSE3.search(line)
            if match:
                return tuple(int(match.group(i)) for i in range(1, 6))
            return None

        def parse4(line: str) -> Optional[Tuple[str, int, int, int]]:
            match = REGEX_PARSE4.search(line)
            if match:
                return (match.group(1), int(match.group(2)), int(match.group(3)), int(match.group(4)))
            return None

        for line in f.readlines():
            if (t := parse0(line)) is not None:
                ptrValues, ptrColumnIndices, ptrRowLengths = t
            elif (t := parse1(line)) is not None:
                ptrInputVector, ptrOutputVector = t
            elif (t := parse2(line)) is not None:
                pass  # Skipped as requested.
            elif (t := parse3(line)) is not None:
                szValues, szColumnIndices, szRowLengths, szInput, szOutput = t
            elif (t := parse4(line)) is not None:
                name, numRows, numCols, numValues = t
                l.append(WorkloadData(
                    name=name,
                    ptrValues=ptrValues,
                    ptrColumnIndices=ptrColumnIndices,
                    ptrRowLengths=ptrRowLengths,
                    ptrInputVector=ptrInputVector,
                    ptrOutputVector=ptrOutputVector,
                    szValues=szValues,
                    szColumnIndices=szColumnIndices,
                    szRowLengths=szRowLengths,
                    szInput=szInput,
                    szOutput=szOutput,
                    numRows=numRows,
                    numCols=numCols,
                    numValues=numValues,
                ))

        return {data.name: data for data in l}


# pprint.pp(parseFile("exp1.txt"))

def generateLatexTable(dWorkloadData: Dict[str, WorkloadData]) -> str:
    header = r"""
\begin{tblr}{
    hline{1-Z} = {1pt},
    row{1-Z} = {font=\footnotesize},
    row{1} = {font=\footnotesize\bfseries},
    rows = {rowsep=1pt},
    columns = {colsep=1pt},
    colspec={X[0.5,c]X[2.5,c]X[1.5,c]X[1,c]X[1,c]X[1.5,c]}
}
Index & Name & Input Size [MiB] & Rows [M] & Cols [M] & Non-zeros [M] \\
"""
    rows = []
    for index, name in enumerate(vWorkloadName):
        data = dWorkloadData[name]
        vector_size_mib = data.szInput / (1024 ** 2)  # Convert bytes to MiB
        rows_m = data.numRows / 1_000_000  # Convert to millions
        cols_m = data.numCols / 1_000_000
        non_zero_count_m = data.numValues / 1_000_000
        rows.append(
            f"W{index} & {name.replace("_", r"\_")} & {vector_size_mib:.2f} & {rows_m:.2f} & {cols_m:.2f} & {non_zero_count_m:.2f} \\\\"
        )

    footer = r"""
\end{tblr}
"""
    return header + "\n".join(rows) + footer


# Example usage
data = parseFile("exp1.txt")
latexTable = generateLatexTable(data)
print(latexTable)

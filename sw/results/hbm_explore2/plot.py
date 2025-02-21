from pprint import pp
from dataclasses import dataclass, replace
from typing import *
import re

import matplotlib.pyplot as plt
import math

NUM_PCS_REGEX = r"distribute among (\d+) PCs"
ID_MODE_LEN_REGEX = (
    r"idMode\s*=\s*(\w+).*?len\s*=\s*(\d+)"
)
RESULT_REGEX = r"avgCyclesPerBeat\s*=\s*([\d.]+)"


@dataclass
class DataPoint:
    frequencyMHz: int
    numPcs: int
    idMode: str
    len: int
    cyclesPerBeat: float


def parseFile(fname: str) -> List[DataPoint]:
    with open(fname) as f:
        l: List[DataPoint] = []

        frequencyMHz: int = None
        numPcs: int = None
        idModeLen: Tuple[str, int] = None

        def extractNumPcs(line: str) -> Optional[int]:
            match = re.search(NUM_PCS_REGEX, line)
            return int(match.group(1)) if match else None

        def extractIdModeLen(line: str) -> Optional[Tuple[str, int]]:
            match = re.search(ID_MODE_LEN_REGEX, line)
            return (match.group(1), int(match.group(2))) if match else None

        def extractResult(line: str) -> Optional[float]:
            match = re.search(RESULT_REGEX, line)
            return float(match.group(1)) if match else None

        for line in f.readlines():
            if "Clock frequency is 300 MHz" in line:
                frequencyMHz = 300
            elif "Clock frequency is 450 MHz" in line:
                frequencyMHz = 450
            if "single PC (512 MB)" in line:
                numPcs = 1
            elif (numPcs_ := extractNumPcs(line)) is not None:
                numPcs = numPcs_
            elif (idModeLen_ := extractIdModeLen(line)) is not None:
                idModeLen = idModeLen_
            elif (result_ := extractResult(line)) is not None:
                l.append(
                    DataPoint(
                        frequencyMHz,
                        numPcs,
                        idModeLen[0],
                        idModeLen[1],
                        result_
                    )
                )

    return l


dataPoints: List[DataPoint] = []


def loadDataNoRAMA():
    dataPoints.extend(parseFile("output_450MHz_reorder.txt"))


def loadDataRAMA():
    dataPointsNew = parseFile("../hbm_explore3/output_defaultRama_reorder.txt")
    dataPoints.extend([
        replace(dp, idMode="ID_ZERO_RAMA")
        for dp in dataPointsNew
        if dp.idMode == "ID_ZERO" and dp.frequencyMHz == 450
    ])


loadDataNoRAMA()
loadDataRAMA()

# pp(dataPoints)

# autopep8: off
from matplotlib.figure import Figure
from matplotlib.axes import Axes

def create_figure(
    width: float = 6.4,
    height: float = 4.8,
    nrows: int = 1,
    ncols: int = 1,
    **kwargs
) -> Tuple[Figure, List[Axes]]:
    fig = plt.figure(figsize=(width, height))
    axs = fig.subplots(nrows, ncols, sharex=True, sharey=True, **kwargs)

    # these are the desired margins in terms of figure units
    left = 0.640
    bottom = 0.480
    right = 0.128
    top = 0.270
    wspace = 0.140
    hspace = 0.270

    left_p = left / width
    bottom_p = bottom / height
    right_p = 1 - right / width
    top_p = 1 - top / height
    wspace_p = wspace * ncols / (width - (left + right) - wspace * (ncols - 1))
    hspace_p = hspace * nrows / (height - (top + bottom) - hspace * (nrows - 1))

    fig.subplots_adjust(
        left_p, bottom_p, right_p, top_p, wspace_p, hspace_p
    )
    return (fig, axs)
# autopep8: on


def plotOne(
    ax: plt.Axes,
    filterFn: Callable[[DataPoint], bool],
    title: str,
    annoList: List[List[Tuple[float, str]]]
) -> None:
    filtered_points = [dp for dp in dataPoints if filterFn(dp)]

    for index, (idMode, label, color, marker) in enumerate([
        ("ID_ZERO_RAMA", "Single ID/RAMA", "tab:orange", "v"),
        ("ID_MASK_INDEX", "6-bit IDs", "tab:blue", "^"),
        ("ID_SHIFT_MASK_ADDR", "Unique ID per PC", "tab:green", "o")
    ]):
        subset = [
            dp for dp in filtered_points
            if dp.idMode == idMode
        ]

        vx = [dp.numPcs for dp in subset]
        vy = [dp.cyclesPerBeat for dp in subset]
        ax.plot(vx, vy, marker=marker, label=label, color=color, linestyle="-")

        for index2, (x, y) in enumerate(zip(vx, vy)):
            ax.annotate(
                f"{y:.2f}",
                (x, y),
                (0, annoList[index][index2][0]),
                xycoords="data",
                textcoords="offset fontsize",
                color=color,
                ha=annoList[index][index2][1]
            )

    ax.grid()
    ax.set_xscale("log", base=2)
    ax.set_yscale("log", base=2)
    ax.set_ylim([2 ** (-0.05), 2 ** (2.05)])
    ax.set_xticks([1, 2, 4, 8, 16])
    ax.set_title(title)


def plotFigure() -> None:
    """
    Plots the figure to be included in the paper.
    """
    from matplotlib import pyplot as plt
    fig, axs = create_figure(height=3.4, ncols=3)

    # autopep8: off
    annoList = [
        [(3, "left"), (2.1, "left"), (0.8, "center"), (0.9, "center"), (1.2, "right")],
        [(2, "left"), (1.05, "left"), (0.75, "center"), (1, "center"), (1, "right")],
        [(1, "left"), (-1.1, "right"), (0.8, "left"), (1, "center"), (0.8, "right")]
    ]
    plotOne(axs[0], lambda dp: dp.len == 0, "Single-beat", annoList)

    annoList = [
        [(3, "left"), (2.0, "left"), (2, "center"), (2, "center"), (2, "right")],
        [(2, "left"), (1.0, "left"), (1, "center"), (1, "center"), (1, "right")],
        [(1, "left"), (-1.2, "right"), (0.7, "left"), (0.7, "center"), (1, "right")]
    ]
    plotOne(axs[1], lambda dp: dp.len == 1, "2-beat", annoList)

    annoList = [
        [(3, "left"), (3, "center"), (3, "center"), (3, "center"), (3, "right")],
        [(2, "left"), (2, "center"), (2, "center"), (2, "center"), (2, "right")],
        [(1, "left"), (1, "center"), (1, "center"), (1, "center"), (1, "right")]
    ]
    plotOne(axs[2], lambda dp: dp.len == 3, "3-beat", annoList)
    # autopep8: on

    axs[2].legend()

    fig.supxlabel("Number of Pseudo Channels", weight="bold")
    fig.supylabel("Cycles/Beat", weight="bold")

    fig.savefig("HBMex-hbm_explore2.pdf")


plotFigure()

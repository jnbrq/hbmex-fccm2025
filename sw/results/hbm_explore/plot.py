from pprint import pp
from dataclasses import dataclass
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
    axiReorder: bool
    lookaheadReorder: bool
    numPcs: int
    idMode: str
    len: int
    cyclesPerBeat: float


def parseFile(fname: str, axiReorder: bool, lookaheadReorder: bool) -> List[DataPoint]:
    with open(fname) as f:
        l: List[DataPoint] = []

        frequencyMHz: int = None
        numPcs: int = None
        idModeLen: Tuple[str, int] = None

        # discard experiments that stripe over SID
        discard = True

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
            elif "single PC (512 MB)" in line:
                numPcs = 1
            elif (numPcs_ := extractNumPcs(line)) is not None:
                numPcs = numPcs_
            elif (idModeLen_ := extractIdModeLen(line)) is not None:
                idModeLen = idModeLen_
            elif (result_ := extractResult(line)) is not None:
                if discard:
                    continue

                l.append(
                    DataPoint(
                        frequencyMHz,
                        axiReorder,
                        lookaheadReorder,
                        numPcs,
                        idModeLen[0],
                        idModeLen[1],
                        result_
                    )
                )
            elif "Distinct PCs" in line:
                discard = False
            elif "Stacks are also" in line:
                discard = True

    return l


dataPoints: List[DataPoint] = []

dataPoints.extend(parseFile("output_reorder.txt", True, True))
dataPoints.extend(parseFile("output_noReorder.txt", False, True))
dataPoints.extend(parseFile("output_noReorderNoLookahead.txt", False, False))


# autopep8: off
from matplotlib.figure import Figure
from matplotlib.axes import Axes

def create_figure(
    width: float = 6.4,
    height: float = 4.8,
    nrows: int = 1,
    ncols: int = 1,
    left_extra: float = 0.0,
    bottom_extra: float = 0.0,
    right_extra: float = 0.0,
    top_extra: float = 0.0,
    **kwargs
) -> Tuple[Figure, List[Axes]]:
    fig = plt.figure(figsize=(width, height))
    axs = fig.subplots(nrows, ncols, sharex=True, sharey=True, **kwargs)

    # these are the desired margins in terms of figure units
    left = 0.640 + left_extra
    bottom = 0.480 + bottom_extra
    right = 0.128 + right_extra
    top = 0.270 + top_extra
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


def plotOne(ax: plt.Axes, filterFn: Callable[[DataPoint], bool], title: str) -> None:
    filtered_points = [dp for dp in dataPoints if filterFn(dp)]

    texts = []

    for idMode, label, color, marker in [
        ("ID_MASK_INDEX", "6-bit IDs", "tab:blue", "^"),
        ("ID_SHIFT_MASK_ADDR", "Unique ID per PC", "tab:green", "o")
    ]:
        subset = [
            dp for dp in filtered_points
            if dp.idMode == idMode
        ]

        x = [dp.numPcs for dp in subset]
        y = [dp.cyclesPerBeat for dp in subset]
        ax.plot(x, y, marker=marker, label=label, color=color, linestyle="-")

        for i, (xi, yi) in enumerate(zip(x, y)):
            scale_x = 1.0
            scale_y = 1.0

            if i == 0:
                if idMode == "ID_SHIFT_MASK_ADDR":
                    scale_y = 1.10
                else:
                    scale_y = 1.25
            else:
                if idMode == "ID_SHIFT_MASK_ADDR":
                    scale_y = 0.85
                else:
                    scale_y = 1.10

            if i == 0:
                scale_x = 1.2
            if i == 1:
                if idMode == "ID_SHIFT_MASK_ADDR":
                    scale_x = 0.85
                else:
                    scale_x = 1.1
            elif i == 4:
                scale_x = 0.9

            t = ax.text(xi * scale_x, yi * scale_y, f"{yi:.2f}", ha="center", va="center", color=color)
            texts.append(t)

    ax.grid()
    ax.set_xscale("log", base=2)
    ax.set_yscale("log", base=2)
    ax.set_ylim([math.pow(2, -0.3), math.pow(2, 2.4)])
    ax.set_title(title)


def plotFigure() -> None:
    """
    Plots the figure to be included in the paper.
    """
    from matplotlib import pyplot as plt
    fig, axs = create_figure(nrows=2, ncols=2)

    def get_ax(i: int, j: int) -> plt.Axes:
        return axs[i, j]

    # autopep8: off
    plotOne(get_ax(0, 0), lambda dp: dp.frequencyMHz == 450 and dp.axiReorder and dp.lookaheadReorder, "450 MHz, AXI Reorder")
    plotOne(get_ax(0, 1), lambda dp: dp.frequencyMHz == 300 and dp.axiReorder and dp.lookaheadReorder, "300 MHz, AXI Reorder")
    plotOne(get_ax(1, 0), lambda dp: dp.frequencyMHz == 450 and not dp.axiReorder and dp.lookaheadReorder, "450 MHz, No AXI Reorder")
    plotOne(get_ax(1, 1), lambda dp: dp.frequencyMHz == 300 and not dp.axiReorder and dp.lookaheadReorder, "300 MHz, No AXI Reorder")
    # autopep8: on

    get_ax(0, 1).legend()

    fig.supxlabel("Number of Pseudo Channels", weight="bold")
    fig.supylabel("Cycles/Beat", weight="bold")

    fig.savefig("HBMex-hbm_explore.pdf")


def plotFigurePresentation() -> None:
    """
    Plots the figure to be included in the presentation.
    """
    from matplotlib import pyplot as plt
    fig, axs = create_figure(width=6.4 * 0.7, height=4.8 * 0.7, top_extra=0.3, nrows=1, ncols=1)

    # autopep8: off
    plotOne(axs, lambda dp: dp.frequencyMHz == 450 and dp.axiReorder and dp.lookaheadReorder, "")
    # autopep8: on

    fig.legend(loc="upper right", ncol=3)

    fig.supxlabel("Number of Pseudo Channels", weight="bold")
    fig.supylabel("Cycles/Beat", weight="bold")

    fig.savefig("HBMex-hbm_explore_presentation.pdf")


plotFigure()
plotFigurePresentation()

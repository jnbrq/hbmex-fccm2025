
from dataclasses import dataclass
from typing import *

import matplotlib.pyplot as plt
import math
import pprint
import enum
import re


class ExperimentType(enum.Enum):
    RAMA_IP = enum.auto()
    HBMEX_IP_0 = enum.auto()
    HBMEX_IP_1 = enum.auto()


STRIPE_INDEX_REGEX = r"stripe\s+index\s+=\s+(\d+)"
RESULT_REGEX = r"numRows\s*=\s*(\d+),\s*numCols\s*=\s*(\d+),\s*numValues\s*=\s*(\d+),.*?totalCycles\s*=\s*(\d+),\s*cyclesPerValue\s*=\s*([\d.]+)"


@dataclass
class DataPoint:
    exp: ExperimentType
    numPcs: int
    numRows: int
    numCols: int
    numValues: int
    totalCycles: int
    cyclesPerValue: float


def parseFile(fname: str, experimentType: ExperimentType) -> List[DataPoint]:
    with open(fname) as f:
        l: List[DataPoint] = []
        stripeIndex: int = None

        def extractStripeIndex(line: str) -> Optional[int]:
            match = re.search(STRIPE_INDEX_REGEX, line)
            return int(match.group(1)) if match else None

        def extractResult(line: str) -> Tuple[int, int, int, int, float]:
            match = re.search(RESULT_REGEX, line)
            return (
                int(match.group(1)),
                int(match.group(2)),
                int(match.group(3)),
                int(match.group(4)),
                float(match.group(5))
            ) if match else None

        for line in f.readlines():
            # we need `is not None`, stripeIndex_ might be 0, a falsy value
            if (stripeIndex_ := extractStripeIndex(line)) is not None:
                stripeIndex = stripeIndex_
            elif (result_ := extractResult(line)) is not None:
                dp = DataPoint(
                    experimentType,
                    (1 << stripeIndex),
                    result_[0],
                    result_[1],
                    result_[2],
                    result_[3],
                    result_[4]
                )
                l.append(dp)

    return l


dataPoints: List[DataPoint] = []

dataPoints.extend(parseFile("exp1.txt", ExperimentType.RAMA_IP))
dataPoints.extend(parseFile("exp2.txt", ExperimentType.HBMEX_IP_0))
dataPoints.extend(parseFile("exp3.txt", ExperimentType.HBMEX_IP_1))

# pprint.pp(dataPoints)

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


def avg(l: List[float]) -> float:
    return sum(l) / len(l)


def plotOne(ax: plt.Axes, filterFn: Callable[[DataPoint], bool], title: str) -> None:
    vAvgNzPerRow = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192]
    vExp = [ExperimentType.RAMA_IP, ExperimentType.HBMEX_IP_0, ExperimentType.HBMEX_IP_1]
    vExpLabel = ["RAMA IP", "HBMex 64 IDs", "HBMex ID/PC"]
    vExpColor = ["tab:orange", "tab:blue", "tab:green"]

    ddvData = {
        exp: {
            avgNzPerRow: [
                dp.cyclesPerValue
                for dp in dataPoints
                if filterFn(dp) and dp.exp == exp and (dp.numValues / dp.numRows) == avgNzPerRow
            ]
            for avgNzPerRow in vAvgNzPerRow
        }
        for exp in vExp
    }

    vToCompare = []

    resultLast = None

    for exp, expLabel, expColor in zip(vExp, vExpLabel, vExpColor):
        vx = vAvgNzPerRow
        vy = [avg(ddvData[exp][x]) for x in vx]
        resultLast = vy[-1]

        if title != "1 PC":
            # for the first 5 values, draw a best fit line and annotate the values
            avgy = avg(vy[0:5])
            annoText = [f"{avgy:.2f}"] + [f"{(toCompare - avgy) / toCompare * 100:.2f}%" for toCompare in vToCompare]
            vToCompare.append(avgy)

            ax.plot([vAvgNzPerRow[0], vAvgNzPerRow[5-1] * 1.7], [avgy, avgy], color=expColor, linestyle="-")
            ax.text(vAvgNzPerRow[5-1] * 1.8, avgy, ", ".join(annoText), color=expColor, va="center")

        ax.plot(vx, vy, marker="o", label=expLabel, color=expColor)

    # for the last value, we just add a basic annotation
    ax.text(
        vAvgNzPerRow[-1] * 0.85,
        resultLast * 0.85,
        f"{resultLast:.2f}",
        color=vExpColor[-1],
        va="center",
        ha="center"
    )

    if title == "1 PC":
        ax.text(8, 2.00 * 1.2, f"{2.00:.2f}", color=vExpColor[0], va="center", ha="center")

    ax.grid()
    ax.set_title(title)
    ax.set_xscale("log", base=2)
    ax.set_yscale("log", base=2)
    ax.set_xticks(vAvgNzPerRow)


def plotFigure() -> None:
    """
    Plots the figure to be included in the paper.
    """
    from matplotlib import pyplot as plt
    fig, axs = create_figure(nrows=2, ncols=2)

    def get_ax(i: int, j: int) -> plt.Axes:
        return axs[i, j]

    # autopep8: off
    plotOne(get_ax(0, 0), lambda dp: dp.numPcs == 1, "1 PC")
    plotOne(get_ax(0, 1), lambda dp: dp.numPcs == 2, "2 PCs")
    plotOne(get_ax(1, 0), lambda dp: dp.numPcs == 4, "4 PCs")
    plotOne(get_ax(1, 1), lambda dp: dp.numPcs == 8, "8 PCs")
    # autopep8: on

    get_ax(0, 0).legend()

    fig.supxlabel("Average NZ/row", weight="bold")
    fig.supylabel("Cycles/NZ", weight="bold")

    fig.savefig("HBMex-spmv_exp_sweep.pdf")


plotFigure()

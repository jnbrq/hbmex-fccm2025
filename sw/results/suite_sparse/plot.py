
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
RESULT_REGEX = r"file = workloads/suite_sparse/(.*?).csr, numRows = (\d+), numCols = (\d+), numValues = (\d+).*?totalCycles = (\d+), cyclesPerValue = ([\d.]+)"


@dataclass
class DataPoint:
    exp: ExperimentType
    numPcs: int
    workloadName: str
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
                match.group(1),
                int(match.group(2)),
                int(match.group(3)),
                int(match.group(4)),
                int(match.group(5)),
                float(match.group(6))
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
                    result_[4],
                    result_[5]
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


def avg(l: List[float]) -> float:
    return sum(l) / len(l)


def plotOne(ax: plt.Axes, filterFn: Callable[[DataPoint], bool], title: str) -> List[plt.Artist]:
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

    vExp = [ExperimentType.RAMA_IP, ExperimentType.HBMEX_IP_0, ExperimentType.HBMEX_IP_1]
    vExpLabel = ["RAMA IP", "HBMex 64 IDs", "HBMex ID/PC"]
    vExpColor = ["tab:orange", "tab:blue", "tab:green"]

    ddvData = {
        exp: {
            workloadName: [
                dp.cyclesPerValue
                for dp in dataPoints
                if filterFn(dp) and dp.exp == exp and dp.workloadName == workloadName
            ]
            for workloadName in vWorkloadName
        }
        for exp in vExp
    }

    barWidth = 1.2
    numBarsPerSegment = len(vExp)
    numSegments = len(vWorkloadName)
    internalSpacing = 0
    externalSpacing = 0.5
    segmentWidth = barWidth * numBarsPerSegment + internalSpacing * (numBarsPerSegment - 1) + externalSpacing

    def calc_vx(index: Union[int, float]) -> List[float]:
        return [i * segmentWidth + index * (barWidth + internalSpacing) for i in range(numSegments)]

    plots = []

    def doPlot() -> None:
        # bars
        for index, (exp, expLabel, expColor) in enumerate(zip(vExp, vExpLabel, vExpColor)):
            vx = calc_vx(index)
            vy = [avg(ddvData[exp][workloadName]) for workloadName in vWorkloadName]

            plots.append(
                ax.bar(
                    vx, vy,
                    width=barWidth,
                    label=expLabel,
                    color=expColor,
                    align="edge",
                    edgecolor="black"
                )
            )

            for x, y in zip(vx, vy):
                ax.text(x + barWidth / 2 + 0.08, 0.2, f"{y:.2f}", rotation="vertical", color="white", ha="center")

        ax.grid(axis="y", alpha=0.40)

        vTicks = calc_vx(numBarsPerSegment / 2)
        ax.set_xticks(vTicks)
        ax.set_xticklabels([f"W{i}" for i in range(len(vWorkloadName))])

        ax.set_xlim([vTicks[0] - barWidth * 1.8, vTicks[-1] + barWidth * 1.8])

        ax.set_title(title)

    def doAnnotate() -> None:
        # annotations
        vAnnoWorkload = [
            True,
            True,
            True,
            True,
            True,
            True,
            False,
            True,
            True,
            True,
            True,
            True,
        ]

        x0 = calc_vx(0)
        x1 = calc_vx(1)
        x2 = calc_vx(2)

        for workloadIndex, (annoWorkload, workloadName) in enumerate(zip(vAnnoWorkload, vWorkloadName)):
            if not annoWorkload:
                continue

            y0 = avg(ddvData[ExperimentType.RAMA_IP][workloadName])
            y1 = avg(ddvData[ExperimentType.HBMEX_IP_0][workloadName])
            y2 = avg(ddvData[ExperimentType.HBMEX_IP_1][workloadName])

            t0 = f""
            t1 = f"{(y0 - y1)/y0 * 100:.1f}%"
            t2 = f"{(y0 - y2)/y0 * 100:.1f}%"

            ax.text(x0[workloadIndex] + barWidth / 2 + 0.08, y0 + 0.2, t0,  rotation="vertical", color="black", ha="center")
            ax.text(x1[workloadIndex] + barWidth / 2 + 0.08, y1 + 0.2, t1, rotation="vertical", color="black", ha="center")
            ax.text(x2[workloadIndex] + barWidth / 2 + 0.08, y2 + 0.2, t2, rotation="vertical", color="black", ha="center")

    # ax.set_yscale("log", base=10)
    # ax.set_ylim([1, 8])

    doPlot()
    doAnnotate()

    return plots


def plotFigure() -> None:
    """
    Plots the figure to be included in the paper.
    """
    from matplotlib import pyplot as plt
    fig, axs = create_figure(nrows=4, ncols=1, width=6.4, height=8.4, top_extra=0.3)

    # autopep8: off
    plots = plotOne(axs[0], lambda dp: dp.numPcs == 1, "1 PC")
    plotOne(axs[1], lambda dp: dp.numPcs == 2, "2 PCs")
    plotOne(axs[2], lambda dp: dp.numPcs == 4, "4 PCs")
    plotOne(axs[3], lambda dp: dp.numPcs == 8, "8 PCs")
    # autopep8: on

    # axs[0].legend(loc="upper left", ncol=3)
    fig.legend(handles=plots, loc="upper right", ncol=3)

    fig.supxlabel("Workload", weight="bold")
    fig.supylabel("Cycles/NZ", weight="bold")

    fig.savefig("HBMex-suite_sparse.pdf")


plotFigure()

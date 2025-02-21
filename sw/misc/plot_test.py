
from dataclasses import dataclass
from typing import *

import matplotlib.pyplot as plt
import math
import pprint
import enum
import re

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
    top = 0.240
    wspace = 0.140
    hspace = 0.310

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


def plotFigure() -> None:
    for nrows in [1, 2, 3]:
        for ncols in [1, 2, 3]:
            fig, _ = create_figure(nrows=nrows, ncols=ncols)
            fig.savefig(f"plot_test_{nrows}_{ncols}.pdf")


plotFigure()

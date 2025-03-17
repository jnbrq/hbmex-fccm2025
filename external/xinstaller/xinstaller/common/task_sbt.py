# TODO add SbtPublishLocal task here
# Make sure that .ivy2 path is set correctly

# also create a scripts directory for activating stuff
# and maybe the kernel driver and the pci hot plug thingy

from typing import *
from .framework import *


class SbtPublishLocal(Task):
    def __init__(self, context: Context, name: str, proj_dirpath: str):
        super().__init__(context, f"sbt:publish_local:{name}", True)
        self._proj_dirpath = proj_dirpath

    def main(self):
        self.ctx.needs_command("sbt")
        self.ctx.run_command(
            [
                "sbt",
                f"-Dsbt.ivy.home={self.ctx.prefix(".ivy2")}",
                "publishLocal"
            ],
            cwd=self.ctx.source(self._proj_dirpath)
        )


__all__ = [
    "SbtPublishLocal"
]

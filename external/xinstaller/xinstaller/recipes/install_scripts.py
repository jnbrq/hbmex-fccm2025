from ..common import *


class InstallScripts(Task):
    def __init__(self, context: Context):
        super().__init__(context, "install:scripts")

        self._scripts = [
            "activate-hbmex.sh", "pci_hot_plug.sh"
        ]

    def main(self):
        self.ctx.needs_command("bash")
        self.ctx.needs_command("ln")

        import os

        for script in self._scripts:
            self.ctx.run_command(
                ["ln", "-s", self.ctx.source(f"../scripts/{script}"), self.ctx.prefix("bin/")]
            )

        with open(self.ctx.prefix(".hbmex_repo"), "w") as f:
            f.write(self.ctx.source("../../"))


__all__ = ["InstallScripts"]

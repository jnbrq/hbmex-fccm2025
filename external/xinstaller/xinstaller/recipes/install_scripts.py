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

        for script in self._scripts:
            self.ctx.run_command(
                ["ln", self.ctx.source(f"../scripts/{script}"), self.ctx.prefix("bin/")]
            )


__all__ = ["InstallScripts"]

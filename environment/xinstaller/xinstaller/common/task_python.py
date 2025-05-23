from typing import *

from .framework import *


class PythonCreateVenv(Task):
    def __init__(self, context):
        super().__init__(context, "python:create_venv", True)

    def main(self):
        self.context.run_command(["python3", "-m", "venv", self.ctx.prefix()])

        import os

        for a, b in zip(
            ["Activate.ps1", "activate.fish", "activate.csh", "activate"],
            ["ActivatePython.ps1", "activate-python.fish", "activate-python.csh", "activate-python"]
        ):
            os.rename(self.ctx.prefix("bin/" + a), self.ctx.prefix("bin/" + b))


class PythonPipInstallLocal(Task):
    def __init__(self, context: Context, name: str, src_path: str):
        super().__init__(context, f"python:pip_install_local:{name}", name)
        self._src_path = src_path

    def main(self):
        self.context.run_sh(
            f". {self.ctx.prefix('bin/activate-python')} ; python3 -m pip install -e .",
            cwd=self.ctx.source(self._src_path)
        )


class PythonPipInstall(Task):
    def __init__(self, context: Context, name: str, packages: str):
        super().__init__(context, f"python:pip_install:{name}", name)
        self._packages = packages

    def main(self):
        for package in self._packages:
            if not self.context.run_sh(
                f". {self.ctx.prefix('bin/activate-python')} ; python3 -m pip install {package}",
                fail_ok=True
            ):
                self.ctx.log(f"cannot install: {package}")


__all__ = [
    "PythonCreateVenv",
    "PythonPipInstallLocal",
    "PythonPipInstall"
]

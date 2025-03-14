from typing import *
from ..common import *


class PythonCreateVenv(Task):
    def __init__(self, context):
        super().__init__(context, "python:create_venv", True)

    def main(self):
        self.context.run_command(["python3", "-m", "venv", self.ctx.prefix()])


__all__ = ["PythonCreateVenv"]  # , "PythonInstallDir"]

from typing import *
from ..common import *


class AptUpdate(Task):
    def __init__(self, context):
        super().__init__(context, "apt:update")

    def main(self):
        self.ctx.needs_command("apt-get")
        self.ctx.run_command_sudo(["apt-get", "update", "-y"])


class AptInstall(Task):
    def __init__(self, context: Context, name: str, package_names: List[str]):
        super().__init__(context, "apt:install:" + name)
        self._package_names = list(package_names)

    def main(self):
        self.ctx.needs_command("apt-get")

        for package in self._package_names:
            if not self.ctx.run_command_sudo(["apt-get", "install", "-y", package], fail_ok=True):
                self.ctx.log(f"cannot install: {package}")


___all__ = [
    "AptUpdate",
    "AptInstall"
]

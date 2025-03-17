from typing import *
from ..common import *


class InstallCMake(Task):
    def __init__(self, context: Context, link: str):
        super().__init__(context, "install:cmake")

        self._link = link

    def main(self):
        self.ctx.needs_command("wget")
        self.ctx.needs_command("sh")

        import tempfile

        with tempfile.TemporaryDirectory() as temp_dir:
            self.ctx.log(f"temporary directory: {temp_dir}")

            def download_cmake() -> None:
                self.ctx.run_command(
                    ["wget", self._link, "-O", "cmake_installer.sh"],
                    cwd=temp_dir
                )

            def install_cmake() -> None:
                self.ctx.run_command(["chmod", "+x", f"{temp_dir}/cmake_installer.sh"])
                self.ctx.run_command(
                    [
                        "sh",
                        f"{temp_dir}/cmake_installer.sh",
                        f"--prefix={self.ctx.prefix()}",
                        "--exclude-subdir",
                        "--skip-license"
                    ],
                    cwd=temp_dir
                )

            download_cmake()
            install_cmake()


__all__ = ["InstallCMake"]

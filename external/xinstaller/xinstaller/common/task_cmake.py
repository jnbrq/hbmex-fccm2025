from typing import *

from .framework import *
import os


class CMakeTarRemote(Task):
    def __init__(
        self,
        context: Context,
        basename: str,
        tar_link: str,
        cmake_args: List[str]
    ):
        super().__init__(context, f"cmake:tar_remote:{basename}")

        self._tar_link = tar_link
        self._cmake_args = list(cmake_args)

    def main(self) -> None:
        import tempfile

        self.ctx.needs_command("cmake")
        self.ctx.needs_command("tar")
        self.ctx.needs_command("ninja")

        with tempfile.TemporaryDirectory() as temp_dir:
            self.ctx.run_command(
                ["wget", self._tar_link, "-O", f"{temp_dir}/source.tar.gz"],
                cwd=temp_dir
            )

            self.ctx.run_command(
                ["tar", "-xzf", f"{temp_dir}/source.tar.gz", "-C", f"{temp_dir}/"]
            )

            dirs = [d for d in os.listdir(temp_dir) if os.path.isdir(os.path.join(temp_dir, d))]
            assert len(dirs) == 1

            os.rename(os.path.join(temp_dir, dirs[0]), os.path.join(temp_dir, "source"))

            self.ctx.run_command(
                ["mkdir", "-p", f"{temp_dir}/build"]
            )

            self.ctx.run_command(
                [
                    "cmake",
                    "-S", f"{temp_dir}/source",
                    "-B", f"{temp_dir}/build",
                    "-G", f"Ninja",
                    f"-DCMAKE_INSTALL_PREFIX={self.ctx.prefix()}",
                    f"-DCMAKE_PREFIX_PATH={self.ctx.prefix()}"
                ] + self._cmake_args
            )

            self.ctx.run_command(
                [
                    "cmake",
                    "--build", "."
                ],
                cwd=f"{temp_dir}/build"
            )

            self.ctx.run_command(
                [
                    "cmake",
                    "--install", ".",
                    "--strip"
                ],
                cwd=f"{temp_dir}/build"
            )


class CMakeLocal(Task):
    def __init__(
        self,
        context: Context,
        basename: str,
        src_path: str,
        cmake_args: List[str]
    ):
        super().__init__(context, f"cmake:local:{basename}")

        self._src_path = src_path
        self._cmake_args = list(cmake_args)

    def main(self) -> None:
        import tempfile

        self.ctx.needs_command("cmake")
        self.ctx.needs_command("ninja")

        with tempfile.TemporaryDirectory() as temp_dir:
            self.ctx.run_command(
                ["mkdir", "-p", f"{temp_dir}/build"]
            )

            self.ctx.run_command(
                [
                    "cmake",
                    "-S", self.ctx.source(self._src_path),
                    "-B", f"{temp_dir}/build",
                    "-G", f"Ninja",
                    f"-DCMAKE_INSTALL_PREFIX={self.ctx.prefix()}",
                    f"-DCMAKE_PREFIX_PATH={self.ctx.prefix()}"
                ] + self._cmake_args
            )

            self.ctx.run_command(
                ["ninja", "install/strip"],
                cwd=f"{temp_dir}/build"
            )


__all__ = [
    "CMakeTarRemote",
    "CMakeLocal"
]

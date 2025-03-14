from ..common import *


class InstallSystemC(Task):
    def __init__(self, context: Context, link: str):
        super().__init__(context, "install:systemc")

        self._link = link

    def main(self):
        self.ctx.needs_command("git")
        self.ctx.needs_command(self.ctx.prefix("bin/cmake"))
        self.ctx.needs_command("ninja")
        self.ctx.needs_command("tar")

        import tempfile

        with tempfile.TemporaryDirectory() as temp_dir:
            self.ctx.run_command(
                ["wget", self._link, "-O", f"{temp_dir}/systemc.tar.gz"],
                cwd=temp_dir
            )

            self.ctx.run_command(
                ["tar", "-xzf", f"{temp_dir}/systemc.tar.gz", "-C", f"{temp_dir}/"]
            )

            self.ctx.run_command(
                ["sh", "-c", f"cd {temp_dir} ; mv systemc-* systemc"]
            )

            self.ctx.run_command(
                ["mkdir", "-p", f"{temp_dir}/build-release"]
            )

            self.ctx.run_command(
                [
                    self.ctx.prefix("bin/cmake"),
                    "-S", f"{temp_dir}/systemc",
                    "-B", f"{temp_dir}/build-release",
                    "-G", f"Ninja",
                    "-DENABLE_EXAMPLES=OFF",
                    "-DCMAKE_BUILD_TYPE=Release",
                    f"-DCMAKE_INSTALL_PREFIX={self.ctx.prefix()}",
                    f"-DCMAKE_PREFIX_PATH={self.ctx.prefix()}"
                ]
            )

            self.ctx.run_command(
                ["ninja"],
                cwd=f"{temp_dir}/build-release"
            )

            self.ctx.run_command(
                ["ninja", "install"],
                cwd=f"{temp_dir}/build-release"
            )


__all__ = ["InstallSystemC"]

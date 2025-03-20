from ..common import *


class InstallSbtDebian(Task):
    def __init__(self, context: Context):
        super().__init__(context, "install:sbt")

    def main(self):
        self.ctx.needs_command("apt")
        self.ctx.needs_command("sh")
        self.ctx.needs_command("tee")

        # source: https://www.scala-sbt.org/1.x/docs/Installing-sbt-on-Linux.html

        self.ctx.run_command_sudo(
            ["apt-get", "update", "-y"]
        )

        if not (self.ctx.has_command("java") and self.ctx.has_command("javac")):
            self.ctx.run_command_sudo(
                ["apt-get", "install", "-y", "default-jdk", "default-jre"]
            )

        self.ctx.run_command_sudo(
            ["apt-get", "install", "-y", "apt-transport-https", "curl", "gnupg"]
        )

        self.ctx.run_sh_sudo(
            'echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list'
        )

        self.ctx.run_sh_sudo(
            'echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | tee /etc/apt/sources.list.d/sbt_old.list'
        )

        self.ctx.run_sh_sudo(
            'curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/scalasbt-release.gpg --import'
        )

        self.ctx.run_command_sudo(
            [
                "chmod", "644", "/etc/apt/trusted.gpg.d/scalasbt-release.gpg"
            ]
        )

        self.ctx.run_command_sudo(
            ["apt-get", "update", "-y"]
        )

        self.ctx.run_command_sudo(
            ["apt-get", "install", "-y", "sbt"]
        )


__all__ = ["InstallSbtDebian"]

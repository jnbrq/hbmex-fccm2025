from src.common import *
from src.recipes import *


def install() -> None:
    ctx = Context(prefix=shexpand("$HOME/.local/opt/hdlstuff"))

    # You can comment the following actions if you need to
    AptUpdate(ctx)
    AptInstall(ctx, "utils", ["wget", "curl", "tar", "git"])
    AptInstall(ctx, "cpp-stuff", ["g++", "gcc", "gdb", "ninja-build", "make"])
    AptInstall(ctx, "python3-stuff", ["python3", "python3-pip"])
    AptInstall(ctx, "gtkwave", ["gtkwave"])
    InstallSbtDebian(ctx)

    # InstallAptPackage(context, "c++", ["build-essential", "gdb"])

    InstallCMake(ctx, "https://github.com/Kitware/CMake/releases/download/v3.31.6/cmake-3.31.6-linux-x86_64.sh")
    InstallSystemC(ctx, "https://github.com/accellera-official/systemc/archive/refs/tags/3.0.1.tar.gz")
    # InstallVerilator(context)

    ctx.run()
    ctx.remove_logs()

install()

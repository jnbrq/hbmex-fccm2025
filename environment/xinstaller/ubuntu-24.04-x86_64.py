from xinstaller.common import *
from xinstaller.recipes import *


def install() -> None:
    ctx = Context(prefix=shexpand("../../.prefix"))

    AptInstall(ctx, "utils", ["wget", "curl", "tar", "git"])
    AptInstall(ctx, "cpp-stuff", ["g++", "gcc", "gdb", "ninja-build", "make"])
    AptInstall(ctx, "python3-stuff", ["python3", "python3-pip", "python3-venv", "python3-setuptools"])
    AptInstall(ctx, "gtkwave", ["gtkwave"])

    InstallSbtDebian(ctx)

    InstallCMake(ctx, "https://github.com/Kitware/CMake/releases/download/v3.31.6/cmake-3.31.6-linux-x86_64.sh")

    # add other boost dependencies
    InstallBoost(ctx, "https://github.com/boostorg/boost/releases/download/boost-1.87.0/boost-1.87.0-cmake.tar.gz")

    InstallFmt(ctx, "https://github.com/fmtlib/fmt/archive/refs/tags/11.1.4.tar.gz")

    InstallSystemC(ctx, "https://github.com/accellera-official/systemc/archive/refs/tags/3.0.1.tar.gz")

    AptInstall(ctx, "verilator-deps", [
        "git", "help2man", "perl", "python3", "make",
        "g++",  # Both compilers
        "libgz",  # Non-Ubuntu (ignore if gives error)
        "libfl2", "libfl-dev",  # Ubuntu only (ignore if gives error)
        "zlibc", "zlib1g", "zlib1g-dev",  # Ubuntu only (ignore if gives error)
        "ccache",  # If present at build, needed for run
        "mold",  # If present at build, needed for run
        "libgoogle-perftools-dev", "numactl",
        "perl-doc",
        "autoconf", "flex", "bison"
    ])
    InstallVerilator(ctx, "https://github.com/verilator/verilator/archive/refs/tags/v5.034.tar.gz")

    PythonCreateVenv(ctx)

    PythonPipInstallLocal(ctx, "hdlinfo_python", "../hdlinfo/python")
    PythonPipInstallLocal(ctx, "hdlscw_python", "../hdlscw/python")
    PythonPipInstallLocal(ctx, "hdlscw_python", "../hdlscw/python")
    PythonPipInstallLocal(ctx, "chext-test_python", "../chext-test/python")

    PythonPipInstall(ctx, "plotting_stuff", ["numpy", "matplotlib"])

    CMakeLocal(ctx, "hdlscw_cpp", "../hdlscw/cpp", cmake_args=[
        "-DCMAKE_BUILD_TYPE=Release", "-DCMAKE_INSTALL_MODE=ABS_SYMLINK"
    ])

    CMakeLocal(ctx, "chext-test_cpp", "../chext-test/cpp", cmake_args=[
        "-DCMAKE_BUILD_TYPE=Release", "-DCMAKE_INSTALL_MODE=ABS_SYMLINK"
    ])

    SbtPublishLocal(ctx, "hdlinfo_scala", "../hdlinfo/scala")
    SbtPublishLocal(ctx, "chext_scala", "../chext")

    InstallScripts(ctx)

    ctx.run()
    ctx.log(f"Please activate the environment using: '. {ctx.prefix("bin/activate-hbmex.sh")}'")
    ctx.remove_logs()


install()

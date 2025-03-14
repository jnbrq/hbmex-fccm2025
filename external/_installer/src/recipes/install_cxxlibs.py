from ..common import *


class InstallVerilator(CMakeTarRemote):
    def __init__(self, context, tar_link):
        super().__init__(context, "verilator", tar_link, ["-DCMAKE_BUILD_TYPE=Release"])

    def main(self):
        import os
        os.unsetenv("VERILATOR_ROOT")
        return super().main()


class InstallSystemC(CMakeTarRemote):
    def __init__(self, context, tar_link):
        super().__init__(context, "systemc", tar_link, ["-DENABLE_EXAMPLES=OFF", "-DCMAKE_BUILD_TYPE=Release"])


class InstallBoost(CMakeTarRemote):
    def __init__(self, context, tar_link):
        super().__init__(context, "boost", tar_link, ["-DCMAKE_BUILD_TYPE=Release"])


class InstallFmt(CMakeTarRemote):
    def __init__(self, context, tar_link):
        super().__init__(context, "fmt", tar_link, [
            "-DCMAKE_BUILD_TYPE=Release",
            "-DFMT_DOC=OFF",
            "-DFMT_TEST=OFF"
        ])


__all__ = [
    "InstallVerilator",
    "InstallSystemC",
    "InstallBoost",
    "InstallFmt",
]

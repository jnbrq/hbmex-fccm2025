from ..codegen import Dumper
import argparse
from typing import *
import os

Path = Union[str, os.PathLike]


def c_escape(x):
    return x


class CMakeGenSrc:
    @staticmethod
    def configureArgParser(argParser: argparse.ArgumentParser) -> None:
        g = argParser.add_argument_group("CMake generated_source")

        g.add_argument("--gensrc-outdir", type=str, required=True,
                       help="Output directory for generated artifacts.")
        g.add_argument("--gensrc-cmake", type=str, required=True,
                       help="Output file describing the generation.")
        g.add_argument("--gensrc-prefix", type=str, required=True,
                       help="CMake prefix to be added to generated artifacts.")
        g.add_argument("--gensrc-debug", action="store_true",
                       help="Verbose debug output.")

    def __init__(self) -> None:
        self._ready = False

        self._inputFiles: List[Path] = []
        self._outputFiles: List[Path] = []
        self._targetSources: List[str] = []

    def _relCwd(self, path: Path) -> Path:
        if os.path.isabs(path):
            return path
        return os.path.sep.join([self._cwd, path])

    def _relOutdir(self, path: Path) -> Path:
        if os.path.isabs(path):
            return path
        return os.path.sep.join([self._outdir, path])

    def getArguments(self, ns: argparse.Namespace, cwd: Optional[Path] = None) -> None:
        self._ready = True

        self._cwd = cwd if cwd is not None else os.getcwd()
        self._outdir = self._relCwd(ns.gensrc_outdir)
        self._cmake = self._relOutdir(ns.gensrc_cmake)
        self._prefix = ns.gensrc_prefix
        self._debug = ns.gensrc_debug

    @property
    def ready(self) -> bool:
        return self._ready

    def inputFile(self, inputFile: Path) -> Path:
        inputFile = self._relCwd(inputFile)
        self._inputFiles.append(inputFile)
        return inputFile

    def outputFile(self, outputFile: Path, isTargetSource: bool = True) -> Path:
        outputFile = self._relOutdir(outputFile)
        print(f"making directory: {os.path.dirname(outputFile)}")
        os.makedirs(os.path.dirname(outputFile), exist_ok=True)
        self._outputFiles.append(outputFile)
        if isTargetSource:
            self._targetSources.append(outputFile)
        return outputFile

    def write(self) -> None:
        with open(self._cmake, "w") as f:
            prefix = self._prefix
            d = Dumper("  ")

            d.iwriteln(f"set(")
            d.indent_in()
            d.iwriteln(f"{prefix}_INPUT_FILES")
            for inputFile in self._inputFiles:
                d.iwriteln(f"\"{c_escape(inputFile)}\"")
            d.indent_out()
            d.iwriteln(f")")
            d.separate()

            d.iwriteln(f"set(")
            d.indent_in()
            d.iwriteln(f"{prefix}_OUTPUT_FILES")
            for outputFile in self._outputFiles:
                d.iwriteln(f"\"{c_escape(outputFile)}\"")
            d.indent_out()
            d.iwriteln(f")")
            d.separate()

            d.iwriteln(f"set(")
            d.indent_in()
            d.iwriteln(f"{prefix}_TARGET_SOURCES")
            for targetSource in self._targetSources:
                d.iwriteln(f"\"{c_escape(targetSource)}\"")
            d.indent_out()
            d.iwriteln(f")")
            d.separate()

            f.write(d.generate())

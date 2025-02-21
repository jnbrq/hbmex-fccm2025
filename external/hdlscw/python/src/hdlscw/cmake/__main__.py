import argparse
import hdlinfo
from ..wrapper import *
from .._util import *
from .gensrc import CMakeGenSrc
import sys
from typing import *
import dataclasses
import importlib
import runpy


def main() -> None:
    argParser = argparse.ArgumentParser(prog="hdlscw")
    cmakeGenSrc = CMakeGenSrc()

    g = argParser.add_argument_group("hdlscw")
    g.add_argument(
        "--import-package", "-i",
        type=str, required=False, action="append", nargs=1,
        help="Python packages that provide 'InterfaceHandler's to load prior to generation."
    )
    g.add_argument(
        "--run", "-r",
        type=str, required=False, action="append", nargs=1,
        help="Execute the provided Python scripts, these scripts might register new 'InterfaceHandler's or protocols. Executed after '-i's."
    )
    g.add_argument("--input-hdlinfo", type=str, required=True,
                   help="Input .hdlinfo.json file.")
    g.add_argument("--single-file", action="store_true",
                   help="Single file (hpp) mode.")
    g.add_argument("--output-hpp", type=str,
                   required=True, help="Output hpp file. Relative to '--gensrc-outdir'")
    g.add_argument("--output-cpp", type=str,
                   help="Output cpp file, not used in single file mode. Relative to '--gensrc-outdir'")

    CMakeGenSrc.configureArgParser(argParser)

    WrapperConfig.configureArgParser(argParser)

    ns = argParser.parse_args(sys.argv[1:])

    if ns.import_package is not None:
        for import_package in ns.import_package:
            name = import_package[0]
            print(f"importing: {name}")
            importlib.import_module(name)

    if ns.run is not None:
        for x in ns.run:
            run_path: str = x[0]
            runpy.run_path(run_path)

    inputHdlInfo = ns.input_hdlinfo
    singleFile = ns.single_file
    outputHpp = ns.output_hpp
    outputCpp = ns.output_cpp

    if not singleFile:
        if outputCpp is None:
            raise RuntimeError(
                "--output-cpp parameter is required if not in single file mode."
            )

    wrapperConfig = WrapperConfig.fromNamespace(ns)
    cmakeGenSrc.getArguments(ns)

    print("wrapper generation:")
    printAsList(locals(), ["inputHdlInfo", "singleFile",
                "outputHpp", "outputCpp"], "hdlscw")
    printAsList(wrapperConfig, [x.name for x in dataclasses.fields(
        wrapperConfig) if x.name != "options"], "hdlscw.wrapperConfig")
    printAsList(wrapperConfig.options, sorted(
        wrapperConfig.options.keys()), "hdlscw.wrapperConfig.options")

    wrapper = Wrapper(hdlinfo.Module.fromJsonFile(inputHdlInfo), wrapperConfig)

    cmakeGenSrc.inputFile(inputHdlInfo)

    if singleFile:
        with open(cmakeGenSrc.outputFile(outputHpp), "w") as f:
            f.write(wrapper.cg.genCode("    "))
    else:
        with open(cmakeGenSrc.outputFile(outputHpp), "w") as f:
            f.write(wrapper.cg.genCodeHdr())

        with open(cmakeGenSrc.outputFile(outputCpp), "w") as f:
            f.write(wrapper.cg.genCodeImpl())

    cmakeGenSrc.write()


main()

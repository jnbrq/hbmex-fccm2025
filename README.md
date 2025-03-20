# HBMex: An Attachment for Nonbursting Accelerators to Enhance HBM Performance

This repository contains the source code of the experiments presented in the HBMex paper submitted to FCCM 2025.

## Repository Structure

HBMex source code consists of the following parts:

1. RTL generation using Chisel3 (in `rtl/`),
2. RTL verification using SystemC (i.e., simulations) (in `rtl/sysc_tb/`),
3. Bitstream generation using Vivado for Alveo U55C, (in `fpga/vivado/alveo_u55c/`, there are 7 vivado projects)
4. running the host-side software. (in `sw/`)

The `external/` directory contains the external dependencies that must be installed first. Please read `external/INSTALL.md` for more information.

## Test System

We primarily tested HBMex on the following setup:

1. Operating system: Ubuntu 24.04.1 LTS x86_64
2. Linux kernel version: 6.8.0-55-generic
3. Vivado version: 2024.1
4. C++ compiler: gcc version 13.3.0
5. Python version: Python 3.12.3


## Step 0: Getting Started

Install the dependencies using the installation script. We describe the process in `external/INSTALL.md`.

In all the readme documents, `${HBMEX_REPO}` refers to the root path of this repository, `${HBMEX_PREFIX}` refers to the directory in which the dependencies are installed. These two variables must be defined in the terminals you use to build and execute HBMex components:

```bash

# define the repository path
# replace ... with the absolute path of the repo
export HBMEX_REPO="..."

# activate the installation environment
# replace ... with the HBMex installation prefix
# please check the output of the installation script
. .../bin/activate-hbmex.sh
```

## Step 1: Generating the RTL

> **NOTE:** You can skip this step if you are not interested in synthesizing the bitstreams from scratch and running the SystemC testbenches.




## Step 2: Runnning the SystemC testbenches

> **NOTE:** You can skip this step.

## Step 3: Synthesizing the Bitstreams

> **NOTE:** You can skip this step if you use the bitstreams we provide.

**Step 1:** If you have created the RTL in the previous steps, you should copy the generated Verilog files (`.v`) to the Vivado sources directory, for each project. The emitted files are in `rtl/emit/`, the project source files are in `fpga/vivado/alveo_u55c/<proj_name>/<proj_name>.srcs/sources_1/imports/`.

Projects and the names of the RTL files are:

| Vivado Project Name `<proj_name>`   | Verilog File     | Description        |
|-------------------------------------|------------------|--------------------|
| ReadEngineExp0                      | ReadEngineExp0.v | Figure 6.          |
| ReadEngineExp0_noReorder            | ReadEngineExp0.v | Figure 6.          |
| ReadEngineExp0_noReorderNoLookahead | ReadEngineExp0.v |                    |
| ReadEngineExp1                      | ReadEngineExp1.v | Figure 7.          |
| SpmvExp1                            | SpmvExp1.v       | Figures 10 and 11. |
| SpmvExp2                            | SpmvExp2.v       | Figures 10 and 11. |
| SpmvExp3                            | SpmvExp3.v       | Figures 10 and 11. |

**Step 2:** Make sure that Vivado binaries are available in the `$PATH`:
```bash
# replace `$XILINX_ROOT` with your Vivado installation path
. $XILINX_ROOT/Vivado/2022.2/settings64.sh
```

**Step 3:** Open and start the runs for each project in `fpga/vivado/alveo_u55c/`:
```bash
vivado "${HBMEX_REPO}/fpga/vivado/alveo_u55c/<proj_name>/*.xpr"
```

> **NOTE:** For each project, we have 3 implementation runs with different parameters. You can start the default run only to save time.

## Step 4: Running the Experiments

Please check `sw/README.md` for more on running the experiments.

# HBMex: An Attachment for Nonbursting Accelerators to Enhance HBM Performance

This repository contains the source code of the experiments presented in our research paper:

> Canberk Sönmez, Mohamed Shahawy, and Paolo Ienne. HBMex: An Attachment for Nonbursting Accelerators to Enhance HBM Performance. To appear in _Proceedings of the 33rd IEEE Annual International Symposium on Field-Programmable Custom Computing Machines (FCCM)_, Fayetteville, Arkansas, USA, May 2025.

Please cite our paper if you use our components in your projects or academic works.

## Repository Structure

HBMex source code consists of the following parts:

1. RTL generation using Chisel3 (in `rtl/`),
2. RTL verification using SystemC (i.e., simulations) (in `rtl/sysc_tb/`),
3. Bitstream generation using Vivado for Alveo U55C, (in `fpga/vivado/alveo_u55c/`, there are 7 vivado projects)
4. running the host-side software. (in `sw/`)

The `environment/` directory contains the external dependencies that must be installed first.

## Test System

We primarily tested HBMex on the following setup:

1. Operating system: Ubuntu 24.04.1 LTS x86_64
2. Linux kernel version: 6.8.0-55-generic
3. Vivado version: 2024.1
4. C++ compiler: gcc version 13.3.0
5. Python version: Python 3.12.3


## Step 0: Getting Started

Install the dependencies using the installation script. We describe the process in [environment/INSTALL.md](environment/INSTALL.md).

In all the readme documents, `${HBMEX_REPO}` refers to the root path of this repository, `${HBMEX_PREFIX}` refers to the directory in which the dependencies are installed. These two variables must be defined in the terminals you use to build and execute HBMex components:

```bash
# activate the installation environment
# replace ... with the HBMex installation prefix
# please check the output of the installation script
. .../bin/activate-hbmex.sh

# now, HBMEX_REPO and HBMEX_PREFIX are defined.
```

## Step 1: Generating the RTL

> **NOTE:** You can skip this step if you are not interested in synthesizing the bitstreams from scratch and running the SystemC testbenches.

Please refer to [rtl/README.md](rtl/README.md) for details.

## Step 2: Runnning the SystemC testbenches

> **NOTE:** You can skip this step.

Please refer to [rtl/sysc_tb/README.md](rtl/sysc_tb/README.md) for details.

## Step 3: Synthesizing the Bitstreams

> **NOTE:** You can skip this step if you use the bitstreams we provide.

Please refer to [fpga/vivado/alveo_u55c/README.md](fpga/vivado/alveo_u55c/README.md) for details.

## Step 4: Running the Experiments

Please check [sw/README.md](sw/README.md) for more on running the experiments.

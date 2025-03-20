# External Dependencies

The project uses Chisel3 as the HDL (Hardware Description Language).
It depends on our in-house libraries, `chext` and `hdlinfo`, for generating the RTL.
`chext` provides primitives for creating elastic circuits and AXI infrastructure.

Additionally, we have our own SystemC-based verification framework to verify elastic circuits. This framework requires CMake, Verilator and Several C++ and Python libraries (including `hdlscw` and `chext-test`).

The software that communicates with the FPGA to execute experiments depends on:

Xilinx XDMA IP driver, which is located under `dma_ip_drivers/XDMA/linux-kernel/xdma`.
Note: You should clone the Git submodules first by running:

```bash
git submodule update --init --recursive
```

Several other C++ libraries, such as `Boost` and `fmt`.

For generating plots, you need to install the following Python packages: `numpy` and `matplotlib`.

## Dependency Installation Script

All dependencies (except the kernel driver) can be installed using the provided script.
The script is designed for Ubuntu 24.04, though it can theoretically be modified to support other Ubuntu versions and Debian-based distributions.

To install the dependencies:

Navigate to the installer directory:

```bash
cd xinstaller
python3 ubuntu-24.04-x86_64.py
```

Once the installation is complete, you can activate the environment by executing the command provided by the script.

## Installing the Kernel Driver


**[Go back](../README.md#step-0-getting-started) to the main document.**

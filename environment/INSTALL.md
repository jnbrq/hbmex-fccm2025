# Installing the Environment

The project uses Chisel3 as the HDL (Hardware Description Language).
It depends on our in-house libraries, `chext` and `hdlinfo`, for generating the RTL.
`chext` provides primitives for creating elastic circuits and AXI infrastructure.
Additionally, we have our own SystemC-based verification framework to verify elastic circuits. This framework requires CMake, Verilator and Several C++ and Python libraries (including `hdlscw` and `chext-test`).
The software that communicates with the FPGA to execute experiments depends on the Xilinx XDMA IP driver and several other C++ libraries, such as `Boost` and `fmt`.
For generating plots, you need to install the following Python packages: `numpy` and `matplotlib`.

Most dependencies can be installed using the automated installation script.

## Installation Script

All dependencies (except the kernel driver) and helper utilities can be installed using the provided script.
The script is designed for Ubuntu 24.04, though it can theoretically be modified to support other Ubuntu versions and Debian-based distributions.

To install the dependencies:

Navigate to the installer directory:

```bash
cd "${HBMEX_REPO}/environment/xinstaller"
python3 ubuntu-24.04-x86_64.py
```

Once the installation is complete, you can activate the environment by executing the command provided by the script.

## Installing the Kernel Driver

```bash
# install packages
sudo apt update
sudo apt install -y build-essential linux-headers-$(uname -r)

# clone the submodule
cd "${HBMEX_REPO}/environment"
git submodule update --init --recursive

# navigate to the directory
cd "${HBMEX_REPO}/environment/dma_ip_drivers/XDMA/linux-kernel/xdma"
make clean
make -j

# insert the module
sudo insmod "${HBMEX_REPO}/environment/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko"

```

**[Go back](../README.md#step-0-getting-started) to the main document.**

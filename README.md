This repository contains the code for the HBMex paper submitted to FCCM 2025.

Directory structure:

- `fpga/vivado/alveo_u55c/`: Contains the Vivado projects for Alveo U55C.
- `rtl/`: Contains the Chisel project for generating the hardware.
- `rtl/sysc_tb`: SystemC-based testbenches.
- `sw/`: Software that was used to drive the experiments. Bitstreams must be uploaded first before running them.
- `external/`: External dependencies that must be installed first.

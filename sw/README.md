# `sw`

This folder contains the source code of the HBMex software used for conducting the experiments.

## Building the software with CMake

Please open a Bash shell in `${HBMEX_ROOT}`, and write the following commands:

```bash
mkdir -p sw/build
cd sw/build
cmake .. -G Ninja -D CMAKE_PREFIX_PATH="${HBMEX_PREFIX}" -D CMAKE_INSTALL_PREFIX="${HBMEX_PREFIX}" -D CMAKE_BUILD_TYPE=Release
ninja
cd ..  # return back to the software directory

```

## SpMV Experiments

SpMV experiments are used to generate Figures 10 and 11.

```bash

# === STEP 0: make that the software is build as described earlier ===


# === STEP 1: prepare spmv_explore matrices ===
cd "${HBMEX_ROOT}/sw/workloads/spmv_explore"


# source code: ${HBMEX_ROOT}/sw/src/spmv_explore_generate.cpp
./generate.sh



# === STEP 2: prepare SuiteSparse matrices ===
cd "${HBMEX_ROOT}/sw/workloads/suite_sparse"

# download the matrices in MatrixMarket format
# make sure that you have `tar` and `wget` installed
./downloads.sh

# convert the download matrices to the CSR format
# source code: ${HBMEX_ROOT}/sw/src/mm2csr.cpp
./convert.sh


# == STEP 3: flash the bitstream to the FPGA/perform a PCIe hotplug ===
# for each experiment: SpmvExp1, SpmvExp2, SpmvExp3


# === STEP 4: For each bitstream, run the experiments ===
cd "${HBMEX_ROOT}/sw"
build/spmv_explore > spmv_explore/exp_sweep/exp1.txt  # change for exp1, exp2, exp3
build/suite_sparse > spmv_explore/suite_sparse/exp1.txt  # change for exp1, exp2, exp3

```

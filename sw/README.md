# `sw`

This folder contains the source code of the HBMex software used for conducting the experiments.

## Building the software with CMake

Please open a Bash shell in `${HBMEX_REPO}`, and write the following commands:

```bash
# activate the installation environment
# replace ... with the HBMex installation prefix
# please check the output of the installation script
. .../bin/activate-hbmex.sh

cd "${HBMEX_REPO}/sw"
mkdir build && cd build
cmake .. -G Ninja -D CMAKE_PREFIX_PATH="${HBMEX_PREFIX}" -D CMAKE_INSTALL_PREFIX="${HBMEX_PREFIX}"
ninja
```

## Using PCI hotplug script `pci_hot_plug.sh`

This script automates the hot removal and re-initialization of PCIe devices connected through root and upstream ports. It is intended to be used after reflashing bitstreams to FPGA devices, ensuring the system properly re-enumerates the PCIe hierarchy and re-establishes communication with the FPGA.

```bash
sudo pci_hot_plug.sh <N> <upstream_ports...> <root_ports...> <link_control_offsets...>
```

1. `N`: Number of devices (i.e., number of upstream ports to be reverted).
2. `upstream_ports`: N space-separated PCI BDFs (`Bus:Device.Function`s) of upstream ports (e.g., 01:00.0).
3. `root_ports`: N space-separated PCI BDFs of the corresponding root ports (e.g., 00:01.1).
4. `link_control_offsets`: N hex values (without 0x) corresponding to the Link Control register base addresses for each root port (e.g., 70).

Example for our bitstreams (replace PCI BDFs as needed):

```bash
pci_hot_plug.sh 1 01:00.0 00:01.1 70
```

Extra resources:
1. [Debugging PCIe Issues using lspci and setpci](https://adaptivesupport.amd.com/s/article/1148199)
2. [PCIe Hot Reset on Linux](https://alexforencich.com/wiki/en/pcie/hot-reset-linux)
3. [Original source code](https://github.com/fpgasystems/sgrt/blob/main/cli/program/pci_hot_plug.sh)

## Memory Access Microbenchmarks

Memory access microbenchmarks are used to generate Figures 6 and 7.

```bash
# === STEP 0: make that the software is build as described earlier ===


# === STEP 1: run the experiments ===
cd "${HBMEX_REPO}/sw"

# DO FIRST: flash the bitstream `ReadEngineExp0` to the FPGA and perform a PCI hotplug
echo "hbm_explore/output_reorder" ; build/hbm_explore > ./results/hbm_explore/output_reorder.txt
echo "hbm_explore2/output_450MHz_reorder" ; build/hbm_explore2 > ./results/hbm_explore2/output_450MHz_reorder.txt

# DO FIRST: flash the bitstream `ReadEngineExp0_noReorder` to the FPGA and perform a PCI hotplug
echo "hbm_explore/output_noReorder" ; build/hbm_explore > ./results/hbm_explore/output_noReorder.txt

# DO FIRST: flash the bitstream `ReadEngineExp0_noReorderNoLookahead` to the FPGA and perform a PCI hotplug
echo "hbm_explore/output_noReorderNoLookahead" ; build/hbm_explore > ./results/hbm_explore/output_noReorderNoLookahead.txt

# DO FIRST: flash the bitstream `ReadEngineExp1` to the FPGA and perform a PCI hotplug
echo "hbm_explore3/output_defaultRama_reorder" ; build/hbm_explore3 > ./results/hbm_explore3/output_defaultRama_reorder.txt

# === STEP 3: plot the graphs ===

cd "${HBMEX_REPO}/sw/results/hbm_explore"
python3 ./plot.py # generates: HBMex-hbm_explore.pdf, Figure 6

cd "${HBMEX_REPO}/sw/results/hbm_explore2"
python3 ./plot.py # generates: HBMex-hbm_explore2.pdf, Figure 7

```

## SpMV Experiments

SpMV experiments are used to generate Figures 10 and 11.

**Note:** Steps 1 and 2 prepare the input matrices and they might take a long time.
For this reason, we also provide already-prepared assets.
Please check `${HBMEX_REPO}/ASSETS.md` and skip these steps if you use the already-prepared assets.

```bash
# === STEP 0: make that the software is build as described earlier ===


# === STEP 1: prepare spmv_explore matrices ===
cd "${HBMEX_REPO}/sw/workloads/spmv_explore"

# might take a long time, took around 10 minutes on our up-to-date server.
# generates up to 2 GiB of data.
# source code: ${HBMEX_REPO}/sw/src/spmv_explore_generate.cpp
./generate.sh


# === STEP 2: prepare SuiteSparse matrices ===
cd "${HBMEX_REPO}/sw/workloads/suite_sparse"

# download the matrices in MatrixMarket format
# make sure that you have `tar` and `wget` installed
./download.sh

# convert the download matrices to the CSR format
# source code: ${HBMEX_REPO}/sw/src/mm2csr.cpp
./convert.sh

# remove the mtx files to save space
rm -rf *.mtx


# === STEP 3: run the experiments ===

cd "${HBMEX_REPO}/sw"

# please note that these experiments might take a long time

# you can check the output text files to check the progress:
#     spmv_explore: runs 56 SpMV operations in total
#     suite_sparse: runs 240 SpMV operations in total
# search "Total number of mismatches" to see how many SpMV operations are complete

# you can find the source codes in the following files:
#     spmv_explore --> ${HBMEX_REPO}/sw/src/spmv_explore.cpp
#     suite_sparse --> ${HBMEX_REPO}/sw/src/suite_sparse.cpp

# just copy and paste the following code blocks

# DO FIRST: for SpmvExp1, flash the bitstream to the FPGA and perform a PCI hotplug
echo "spmv_explore" ; build/spmv_explore > ./results/spmv_explore/exp_sweep/exp1.txt
echo "suite_sparse" ; build/suite_sparse > ./results/suite_sparse/exp1.txt
echo "done."

# DO FIRST: for SpmvExp2, flash the bitstream to the FPGA and perform a PCI hotplug
echo "spmv_explore" ; build/spmv_explore > ./results/spmv_explore/exp_sweep/exp2.txt
echo "suite_sparse" ; build/suite_sparse > ./results/suite_sparse/exp2.txt
echo "done."

# DO FIRST: for SpmvExp3, flash the bitstream to the FPGA and perform a PCI hotplug
echo "spmv_explore" ; build/spmv_explore > ./results/spmv_explore/exp_sweep/exp3.txt
echo "suite_sparse" ; build/suite_sparse > ./results/suite_sparse/exp3.txt
echo "done."


# === STEP 4: plot the graphs ===

cd "${HBMEX_REPO}/sw/results/spmv_explore/exp_sweep"
python3 ./plot.py # generates: HBMex-spmv_exp_sweep.pdf, Figure 10

cd "${HBMEX_REPO}/sw/results/suite_sparse"
python3 ./plot.py # generates: HBMex-suite_sparse.pdf, Figure 11

```

**[Go back](../README.md#step-4-running-the-experiments) to the main document.**

## Notes

**Note 1:** In the log files, stripe index refers to the number of PCs targeted:

| Stripe Index | Number of PCs |
|--------------|---------------|
| 0            | 1             |
| 1            | 2             |
| 2            | 4             |
| 3            | 8             |

**Note 2:** If you see "An old result is being discarded..." repeated many times in an output text file, please make sure that you performed a PCI hotplug.

**Note 3:** We observed a bug in the RAMA IP that occasionally causes errors in some workloads when multiple PCs are targeted.
These errors are seemingly random and affect a small portion of the result; therefore, they do not affect the performance figures.
Since the source code of the RAMA IP is not available, we could not identify the bug.
However, with our HBMex IPs, there are no problems.

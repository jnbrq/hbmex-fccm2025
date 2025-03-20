# `sw`

This folder contains the source code of the HBMex software used for conducting the experiments.

## Building the software with CMake

Please open a Bash shell in `${HBMEX_REPO}`, and write the following commands:

```bash
mkdir -p sw/build
cd sw/build
cmake .. -G Ninja -D CMAKE_PREFIX_PATH="${HBMEX_PREFIX}" -D CMAKE_INSTALL_PREFIX="${HBMEX_PREFIX}"
ninja

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

```

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

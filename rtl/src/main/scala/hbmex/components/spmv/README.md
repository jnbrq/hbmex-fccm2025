# Sparse Matrix-Vector multiplication module

In this folder, we provide an implementation of a batch sparse matrix-vector multiplication (SpMV) accelerator.
The implementation is specialized to be connected to HBM modules present on Xilinx Alveo U55C FPGAs and alike.
Therefore, some parameter of the implementation are hardcoded:

1. Latency-sensitive ports have a data width of 256-bits, each value is 32-bits wide (fp32), and each beat can carry values belonging to 8 different vectors.
2. Resultingly, the batch size is 8, the accelerator performs SpMV of one sparse matrix with 8 vectors in parallel.
3. We have strict alignment requirements: the number of rows in matrices must be a multiple of 8, pointers must be aligned to 32 etc. This is to ensure that we never underutilize any HBM beats.

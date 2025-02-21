# Sparse Matrix-Vector multiplication module

In this folder, we provide an implementation of a batch sparse matrix-vector multiplication (SpMV) accelerator.
The implementation is specialized to be connected to HBM modules present on Xilinx Alveo U55C FPGAs and alike.
Therefore, some parameter of the implementation are hardcoded:

1. Latency-sensitive ports have a data width of 256-bits, each value is 32-bits wide (fp32), and each beat can carry values belonging to 8 different vectors.
2. Resultingly, the batch size is 8, the accelerator performs SpMV of one sparse matrix with 8 vectors in parallel.
3. Latency-sensitive ports issue many AXI requests, with lots of different IDs. There are in total 4096 IDs in flight.
4. The accelerator can have up to 128 tasks in its queues. These tasks can be started either by a start signal or by writing to a memory-mapped register.
5. We have strict alignment requirements: the number of rows in matrices must be a multiple of 8, pointers must be aligned to 32 etc. This is to ensure that we never underutilize any HBM beats.

For ID parallelization, I will use only 8 ID bits. The RAMA IP supports only 6 bits at most, so we are already 4x better. It synthesizes sufficiently well, I can achieve 300 MHz. Also, if I target 4 MCs, their total AXI reorder queue size is 256 elements, matching 8 ID bits.
So, it is kind of a magic number. In case that is not enough, I can develop a hierarchical ID parallizer that can go up to 2048 outstanding transactions.

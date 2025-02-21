#ifndef SPMV_UTILS_HPP_INCLUDED
#define SPMV_UTILS_HPP_INCLUDED

#include <spmv/Defs.hpp>

namespace spmv {

void verifyAndReportMismatches(
    const spmv::DenseMatrix& expectedMatrix,
    const spmv::DenseMatrix& receivedMatrix,
    const spmv::CompressedSparseMatrix& compressedSparseMatrix,
    double tolerance,
    int maxMismatchesToPrint = 20
) {
    double accumulatedRelativeError = 0.0;
    std::uint64_t totalCount = 0;
    int mismatchCount = 0;

    for (spmv::index_t row = 0; row < expectedMatrix.numRows; ++row) {
        for (spmv::index_t col = 0; col < expectedMatrix.numCols; ++col) {
            auto expected = expectedMatrix.get(row, col);
            auto received = receivedMatrix.get(row, col);

            double relativeDifference = std::abs(expected - received) / std::max(std::abs(expected), 1e-10f);
            accumulatedRelativeError += relativeDifference * relativeDifference;
            totalCount++;

            if (relativeDifference > tolerance) {
                mismatchCount++;

                // Print only the first `maxMismatchesToPrint` mismatches
                if (mismatchCount <= maxMismatchesToPrint) {
                    fmt::print(
                        "Mismatch at ({}, {}): Expected: {}, Received: {}, Relative Difference: {}\n",
                        row, col, expected, received, relativeDifference
                    );
                    fmt::print(
                        "Note that the CSR matrix has {} non-zero values in the corresponding row.\n",
                        compressedSparseMatrix.lengths[row]
                    );
                }
            }
        }
    }

    fmt::print("Total number of mismatches: {}\n", mismatchCount);

    if (mismatchCount > maxMismatchesToPrint) {
        fmt::print("... and {} more mismatches not printed.\n", mismatchCount - maxMismatchesToPrint);
    }

    fmt::print(
        "RMS relative error: among mismatches: {}, all data points: {}\n",
        std::sqrt(accumulatedRelativeError / mismatchCount),
        std::sqrt(accumulatedRelativeError / totalCount)
    );
}

} // namespace spmv

#endif /* SPMV_UTILS_HPP_INCLUDED */

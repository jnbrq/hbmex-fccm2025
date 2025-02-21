#include <fmt/core.h>
#include <spmv/linalg.hpp>

int main() {
    unsigned N = 4;

    linalg::SparseMatrix<linalg::real_t, linalg::RowMajor> spm(N, N);
    /*
    for (int i = 0; i < N; ++i)
        for (int j = 0; j < N; ++j)
            spm.set(i, j, i + j);
    */
    for (int i = 0; i < N; ++i)
        spm.set(i, i, 1.0);

    for (int i = 0; i < N; ++i)
        for (int j = 0; j < 2; ++j)
            spm.set(i, (i + j + 1) % N, 2.0);

    auto cspm = spm.toCompressedSparseMatrix();

    for (auto x : cspm.lengths) {
        fmt::print("{}, ", x);
    }
    fmt::print("\n");

    for (auto x : cspm.offsets) {
        fmt::print("{}, ", x);
    }
    fmt::print("\n");

    for (auto x : cspm.indices) {
        fmt::print("{}, ", x);
    }
    fmt::print("\n");

    for (auto x : cspm.values) {
        fmt::print("{}, ", x);
    }
    fmt::print("\n");

    auto spm2 = cspm.toSparseMatrix();

    for (int i = 0; i < N; ++i) {
        for (int j = 0; j < N; ++j)
            fmt::print("{} ", spm.get(i, j));
        fmt::print("\n");
    }

    fmt::print("\n");

    for (int i = 0; i < N; ++i) {
        for (int j = 0; j < N; ++j)
            fmt::print("{} ", spm2.get(i, j));
        fmt::print("\n");
    }

    fmt::print("\n");

    linalg::DenseMatrix<linalg::real_t, linalg::RowMajor> m(4, 4);
    m.set(0, 0, 2.0);
    m.set(1, 0, 1.0);
    m.set(2, 0, 1.0);
    m.set(3, 0, 1.0);

    m.set(0, 1, 1.0);
    m.set(1, 1, 2.0);
    m.set(2, 1, 1.0);
    m.set(3, 1, 1.0);

    m.set(0, 2, 1.0);
    m.set(1, 2, 1.0);
    m.set(2, 2, 2.0);
    m.set(3, 2, 1.0);

    m.set(0, 3, 1.0);
    m.set(1, 3, 1.0);
    m.set(2, 3, 1.0);
    m.set(3, 3, 2.0);

    auto m2 = linalg::sparseMatrixProduct(spm.toCompressedSparseMatrix(), m);
    for (int i = 0; i < N; ++i) {
        for (int j = 0; j < N; ++j)
            fmt::print("{} ", m2.get(i, j));
        fmt::print("\n");
    }

    fmt::print("\n");

    return 0;
}
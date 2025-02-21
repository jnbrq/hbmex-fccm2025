#include <boost/endian.hpp>
#include <linalg/linalg.hpp>

int main(int argc, char** argv) {
    using compressed_t = linalg::types::CompressedSparseMatrix<double, unsigned, linalg::RowMajor>;
    using compressed2_t = linalg::types::CompressedSparseMatrix<double, unsigned, linalg::ColumnMajor>;
    using sparse_t = linalg::types::SparseMatrix<double, linalg::RowMajor>;
    using sparse2_t = linalg::types::SparseMatrix<double, linalg::ColumnMajor>;
    using dense_t = linalg::types::DenseMatrix<float, linalg::ColumnMajor>;
    using dense2_t = linalg::types::DenseMatrix<uint16_t, linalg::ColumnMajor>;
    using dense3_t = linalg::types::DenseMatrix<uint64_t, linalg::ColumnMajor>;
    using dense4_t = linalg::types::DenseMatrix<boost::endian::big_uint32_at, linalg::ColumnMajor>;

    {
        sparse_t sp1(4, 4);
        sp1.set(0, 0, 3.14);
        sp1.set(0, 1, 5);
        sp1.set(1, 1, 2);
        sp1.set(2, 2, 3);
        sp1.set(3, 3, 4'000'000);

        auto csp1 = linalg::algos::copy<compressed_t>(sp1);
        auto sp2 = linalg::algos::copy<sparse_t>(csp1);

        auto d1 = linalg::algos::copy<dense_t>(sp1);
        auto d2 = linalg::algos::copy<dense_t>(sp2);
        auto d3 = linalg::algos::copy<dense2_t>(sp1);

        d1.print();
        fmt::print("\n");

        d2.print();
        fmt::print("\n");

        d3.print();
        fmt::print("\n");

        auto csp2 = linalg::algos::copy<compressed_t>(sp1);
        auto spTemp = linalg::algos::copy<sparse2_t>(csp2);
        auto csp3 = linalg::algos::copy<compressed2_t>(spTemp);

        auto d4 = linalg::algos::copy<dense3_t>(d1);

        d4.print();
        fmt::print("\n");
    }

    {
        sparse_t spm(8, 8);

        for (unsigned i = 0; i < 8; ++i)
            spm.set(i, i, 1.0);

        auto cspm = linalg::algos::copy<compressed_t>(spm);

        dense_t m(8, 1);

        for (unsigned i = 0; i < 8; ++i)
            m.set(i, 0, i);

        auto result = linalg::algos::product<dense4_t>(cspm, m);
        auto result2 = linalg::algos::copy<dense3_t>(result);

        result2.print();
        fmt::print("\n");
    }

    return 0;
}

#ifndef LINALG_ALGOS_Product_HPP_INCLUDED
#define LINALG_ALGOS_Product_HPP_INCLUDED

#include <linalg/types/CompressedSparse.hpp>
#include <linalg/types/Dense.hpp>

#include <linalg/Defs.hpp>
#include <linalg/Exception.hpp>

namespace linalg::algos {

namespace detail {

template<typename R, typename T, typename U, typename Enable = void>
struct Product_Impl {
    static R product(T const& t, U const& u) {
        LINALG_NOT_IMPLEMENTED;
    }
};

template<
    typename DataTypeR_, StorageOrder StorageOrderR_,
    typename DataTypeT_, typename IndexTypeT_, StorageOrder StorageOrderT_,
    typename DataTypeU_, StorageOrder StorageOrderU_>
inline types::DenseMatrix<DataTypeR_, StorageOrderR_> sparseMatrixProductImpl(
    types::CompressedSparseMatrix<DataTypeT_, IndexTypeT_, StorageOrderT_> const& t,
    types::DenseMatrix<DataTypeU_, StorageOrderU_> const& u
) {
    if (StorageOrderT_ == RowMajor)
        LINALG_REQUIRE(t.numCols == u.numRows);
    else
        LINALG_REQUIRE(u.numCols == t.numRows);

    size_t numRows = StorageOrderT_ == RowMajor ? t.numRows : u.numRows;
    size_t numCols = StorageOrderT_ == RowMajor ? u.numCols : t.numCols;
    size_t jCount = StorageOrderT_ == RowMajor ? numCols : numRows;

    types::DenseMatrix<DataTypeR_, StorageOrderR_> result(numRows, numCols);

    index_t j = 0;

    for (index_t j = 0; j < jCount; ++j) {
        index_t idxValue = 0;
        index_t i = 0;

        for (auto length : t.lengths) {
            DataTypeR_ acc = DataTypeR_(0);

            for (index_t k = 0; k < length; ++k) {
                auto index = t.indices[idxValue];
                auto value = t.values[idxValue];

                if constexpr (StorageOrderT_ == RowMajor)
                    acc += value * u.get(index, j);
                else
                    acc += value * u.get(j, index);

                idxValue++;
            }

            if constexpr (StorageOrderT_ == RowMajor)
                result.set(i, j, acc);
            else
                result.set(j, i, acc);

            i++;
        }
    }

    return result;
}

template<
    typename DataTypeR_, StorageOrder StorageOrderR_,
    typename DataTypeT_, typename IndexTypeT_,
    typename DataTypeU_, StorageOrder StorageOrderU_>
struct Product_Impl<
    types::DenseMatrix<DataTypeR_, StorageOrderR_>,
    types::CompressedSparseMatrix<DataTypeT_, IndexTypeT_, RowMajor>,
    types::DenseMatrix<DataTypeU_, StorageOrderU_>,
    void> {
    using R = types::DenseMatrix<DataTypeR_, StorageOrderR_>;
    using T = types::CompressedSparseMatrix<DataTypeT_, IndexTypeT_, RowMajor>;
    using U = types::DenseMatrix<DataTypeU_, StorageOrderU_>;

    static R product(T const& t, U const& u) {
        return sparseMatrixProductImpl<DataTypeR_, StorageOrderR_>(t, u);
    }
};

template<
    typename DataTypeR_, StorageOrder StorageOrderR_,
    typename DataTypeT_, StorageOrder StorageOrderT_,
    typename DataTypeU_, typename IndexTypeU_>
struct Product_Impl<
    types::DenseMatrix<DataTypeR_, StorageOrderR_>,
    types::DenseMatrix<DataTypeT_, StorageOrderT_>,
    types::CompressedSparseMatrix<DataTypeU_, IndexTypeU_, ColumnMajor>,
    void> {
    using R = types::DenseMatrix<DataTypeR_, StorageOrderR_>;
    using T = types::DenseMatrix<DataTypeT_, StorageOrderT_>;
    using U = types::CompressedSparseMatrix<DataTypeU_, IndexTypeU_, ColumnMajor>;

    static R product(T const& t, U const& u) {
        return sparseMatrixProductImpl<DataTypeR_, StorageOrderR_>(u, t);
    }
};

} // namespace detail

template<typename R, typename T, typename U>
inline R product(T const& t, U const& u) {
    return detail::Product_Impl<R, T, U>::product(t, u);
}

} // namespace linalg::algos

#endif /* LINALG_ALGOS_Product_HPP_INCLUDED */

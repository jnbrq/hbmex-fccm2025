#ifndef LINALG_ALGOS_COPY_HPP_INCLUDED
#define LINALG_ALGOS_COPY_HPP_INCLUDED

#include <linalg/Defs.hpp>
#include <linalg/Exception.hpp>

#include <linalg/types/CompressedSparse.hpp>
#include <linalg/types/Dense.hpp>
#include <linalg/types/Sparse.hpp>

namespace linalg::algos {

namespace detail {

template<typename R, typename T, typename Enable = void>
struct Copy_Impl {
    static R copy(T const& t) {
        LINALG_NOT_IMPLEMENTED;
    }
};

template<
    typename DataTypeR_, typename IndexTypeR_, StorageOrder StorageOrderR_,
    typename DataTypeT_, StorageOrder StorageOrderT_>
struct Copy_Impl<
    types::CompressedSparseMatrix<DataTypeR_, IndexTypeR_, StorageOrderR_>,
    types::SparseMatrix<DataTypeT_, StorageOrderT_>,
    void> {
    using R = types::CompressedSparseMatrix<DataTypeR_, IndexTypeR_, StorageOrderR_>;
    using T = types::SparseMatrix<DataTypeT_, StorageOrderT_>;

    static R copy(T const& t) {
        LINALG_REQUIRE(StorageOrderR_ == StorageOrderT_);

        std::vector<DataTypeR_> values(t.nonZeros());
        std::vector<IndexTypeR_> indices(t.nonZeros());
        std::vector<IndexTypeR_> lengths(t.storageLength());

        {
            index_t idxValue = 0;

            for (index_t idxStorage = 0; idxStorage < t.storageLength(); ++idxStorage) {
                index_t count = 0;
                for (auto const& [index, value] : t.storage(idxStorage)) {
                    values[idxValue] = value;
                    indices[idxValue] = index;
                    idxValue++;
                    count++;
                }

                lengths[idxStorage] = count;
            }
        }

        return {
            (IndexTypeR_)t.numRows,
            (IndexTypeR_)t.numCols,
            (IndexTypeR_)t.nonZeros(),
            std::move(values),
            std::move(indices),
            std::move(lengths)
        };
    }
};

template<
    typename DataTypeR_, StorageOrder StorageOrderR_,
    typename DataTypeT_, typename IndexTypeT_, StorageOrder StorageOrderT_>
struct Copy_Impl<
    types::SparseMatrix<DataTypeR_, StorageOrderR_>,
    types::CompressedSparseMatrix<DataTypeT_, IndexTypeT_, StorageOrderT_>,
    void> {
    using R = types::SparseMatrix<DataTypeR_, StorageOrderR_>;
    using T = types::CompressedSparseMatrix<DataTypeT_, IndexTypeT_, StorageOrderT_>;

    static R copy(T const& t) {
        R result(t.numRows, t.numCols);

        index_t idxValue = 0;
        index_t i = 0;

        for (auto length : t.lengths) {
            for (index_t j = 0; j < length; ++j) {
                index_t index = t.indices[idxValue];
                DataTypeR_ value = t.values[idxValue];

                if constexpr (StorageOrderT_ == RowMajor)
                    result.set(i, index, value);
                else
                    result.set(index, i, value);

                idxValue++;
            }

            i++;
        }

        return result;
    }
};

template<
    typename DataTypeR_, StorageOrder StorageOrderR_,
    typename DataTypeT_, StorageOrder StorageOrderT_>
struct Copy_Impl<
    types::DenseMatrix<DataTypeR_, StorageOrderR_>,
    types::SparseMatrix<DataTypeT_, StorageOrderT_>,
    void> {
    using R = types::DenseMatrix<DataTypeR_, StorageOrderR_>;
    using T = types::SparseMatrix<DataTypeT_, StorageOrderT_>;

    static R copy(T const& t) {
        R result(t.numRows, t.numCols);

        // TODO optimize as a function of the storage order
        for (index_t i = 0; i < t.numRows; ++i) {
            for (index_t j = 0; j < t.numCols; ++j) {
                result.set(i, j, t.get(i, j));
            }
        }

        return result;
    }
};

template<
    typename DataTypeR_, StorageOrder StorageOrderR_,
    typename DataTypeT_, typename IndexTypeT_, StorageOrder StorageOrderT_>
struct Copy_Impl<
    types::DenseMatrix<DataTypeR_, StorageOrderR_>,
    types::CompressedSparseMatrix<DataTypeT_, IndexTypeT_, StorageOrderT_>,
    void> {
    using R = types::DenseMatrix<DataTypeR_, StorageOrderR_>;
    using T = types::CompressedSparseMatrix<DataTypeT_, IndexTypeT_, StorageOrderT_>;

    static R copy(T const& t) {
        R result(t.numRows, t.numCols);

        index_t idxValue = 0;
        index_t i = 0;

        for (auto length : t.lengths) {
            for (index_t j = 0; j < length; ++j) {
                index_t index = t.indices[idxValue];
                DataTypeR_ value = t.values[idxValue];

                if constexpr (StorageOrderT_ == RowMajor)
                    result.set(i, index, value);
                else
                    result.set(index, i, value);

                idxValue++;
            }

            i++;
        }

        return result;
    }
};

template<
    typename DataTypeR_, StorageOrder StorageOrderR_,
    typename DataTypeT_, StorageOrder StorageOrderT_>
struct Copy_Impl<
    types::DenseMatrix<DataTypeR_, StorageOrderR_>,
    types::DenseMatrix<DataTypeT_, StorageOrderT_>,
    void> {
    using R = types::DenseMatrix<DataTypeR_, StorageOrderR_>;
    using T = types::DenseMatrix<DataTypeT_, StorageOrderT_>;

    static R copy(T const& t) {
        R result(t.numRows, t.numCols);

        // TODO optimize as a function of the storage order
        for (index_t i = 0; i < t.numRows; ++i) {
            for (index_t j = 0; j < t.numCols; ++j) {
                result.set(i, j, t.get(i, j));
            }
        }

        return result;
    }
};

template<
    typename DataTypeR_, StorageOrder StorageOrderR_,
    typename DataTypeT_, StorageOrder StorageOrderT_>
struct Copy_Impl<
    types::SparseMatrix<DataTypeR_, StorageOrderR_>,
    types::SparseMatrix<DataTypeT_, StorageOrderT_>,
    void> {
    using R = types::SparseMatrix<DataTypeR_, StorageOrderR_>;
    using T = types::SparseMatrix<DataTypeT_, StorageOrderT_>;

    static R copy(T const& t) {
        // TODO later make sure that this function works for other cases
        LINALG_REQUIRE(StorageOrderR_ == StorageOrderT_);

        R result(t.numRows, t.numCols);

        for (index_t idxStorage = 0; idxStorage < t.storageLength(); ++idxStorage) {
            index_t count = 0;
            auto& targetStorage = *result.storageUnsafe(idxStorage);

            for (auto const& [index, value] : t.storage(idxStorage)) {
                targetStorage[index] = value;
            }
        }

        return result;
    }
};

} // namespace detail

template<typename R, typename T>
inline R copy(T const& t) {
    return detail::Copy_Impl<R, T>::copy(t);
}

} // namespace linalg::algos

#endif /* LINALG_ALGOS_COPY_HPP_INCLUDED */

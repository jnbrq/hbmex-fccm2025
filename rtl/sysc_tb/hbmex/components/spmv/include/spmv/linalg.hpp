#ifndef LINALG_HPP_INCLUDED
#define LINALG_HPP_INCLUDED

#include <fmt/core.h>

#include <cassert>
#include <cstdint>

#include <map>
#include <type_traits>
#include <vector>

#ifndef MIN
#    define MIN(x, y) (((x) < (y)) ? (x) : (y))
#endif

namespace linalg {

using real_t = float;
using index_t = std::uint32_t;
using size_t = std::uint32_t;

namespace detail {

std::vector<index_t> mkOffsets(std::vector<size_t> const& lengths) {
    std::vector<index_t> result(lengths.size() + 1);

    index_t idx = 0, last = 0;
    result[idx++] = 0;

    for (auto length : lengths) {
        last += length;
        result[idx++] = last;
    }

    return result;
}

} // namespace detail

enum StorageOrder {
    RowMajor,
    ColumnMajor
};

inline constexpr StorageOrder reverseStorageOrder(StorageOrder storageOrder) {
    if (storageOrder == RowMajor)
        return ColumnMajor;
    return RowMajor;
}

template<typename DataType_, StorageOrder StorageOrder_>
struct DenseMatrix;

template<typename DataType_, StorageOrder StorageOrder_>
struct SparseMatrix;

template<typename DataType_, StorageOrder StorageOrder_>
struct CompressedSparseMatrix;

template<typename DataType_, StorageOrder StorageOrder_>
struct DenseMatrix {
    const size_t numRows;
    const size_t numCols;

    DenseMatrix(size_t numRows, size_t numCols)
        : numRows { numRows }
        , numCols { numCols }
        , storage_(numRows * numCols) {}

    real_t get(index_t row, index_t col) const noexcept {
        assert(row < numRows && col < numCols);

        if constexpr (StorageOrder_ == RowMajor)
            return storage_[row * numCols + col];
        else
            return storage_[col * numRows + row];
    }

    void set(index_t row, index_t col, real_t value) noexcept {
        assert(row < numRows && col < numCols);

        if constexpr (StorageOrder_ == RowMajor)
            storage_[row * numCols + col] = value;
        else
            storage_[col * numRows + row] = value;
    }

    real_t* data() noexcept {
        return storage_.data();
    }

    real_t const* data() const noexcept {
        return storage_.data();
    }

    void clear() noexcept {
        auto data = storage_.data();
        for (index_t i = 0; i < (numRows * numCols); ++i)
            data[i] = DataType_(0);
    }

    void print() const {
        for (index_t i = 0; i < numRows; ++i) {
            for (index_t j = 0; j < numCols; ++j) {
                fmt::print("{}, ", get(i, j));
            }
            fmt::print("\n");
        }
    }

private:
    std::vector<DataType_> storage_;
};

template<typename DataType_, StorageOrder StorageOrder_>
struct SparseMatrix {

    SparseMatrix(size_t numRows, size_t numCols)
        : numRows { numRows }
        , numCols { numCols }
        , storage_(numRows) {
        //
    }

    const size_t numRows, numCols;

    real_t get(index_t row, index_t col) const {
        assert(row < numRows && col < numCols);

        if (StorageOrder_ == ColumnMajor)
            std::swap(row, col);

        auto m = storage_[row];
        if (auto it = m.find(col); it != m.end()) {
            return it->second;
        }

        return real_t(0);
    }

    void set(index_t row, index_t col, real_t value) {
        assert(row < numRows && col < numCols);

        if (StorageOrder_ == ColumnMajor)
            std::swap(row, col);

        auto& x = storage_[row];
        if (auto it = x.find(col); it != x.end()) {
            it->second = value;
        } else {
            storage_[row][col] = value;
            nonZeros_++;
        }
    }

    size_t nonZeros() const noexcept {
        return nonZeros_;
    }

    void clear() noexcept {
        nonZeros_ = 0;

        for (auto& v : storage_)
            v.clear();
    }

    /*
    void addExplicitZeros(size_t additionalZeros) {
        assert(nonZeros() + addExplicitZeros <= (numRows * numCols));
        size_t maxLength = StorageOrder_ == RowMajor ? numCols : numRows;

        for (auto& v : storage_) {
            if (additionalZeros == 0)
                break;

            size_t x = MIN(additionalZeros, maxLength - v.size());

            additionalZeros -= x;
        }
    }
    */

    CompressedSparseMatrix<DataType_, StorageOrder_> toCompressedSparseMatrix() const {
        std::vector<size_t> lengths(numRows);

        size_t numValues = 0;
        {
            index_t idxLength = 0;

            for (auto const& v : storage_) {
                auto len = v.size();
                lengths[idxLength] = len;
                numValues += len;
                idxLength++;
            }
        }

        std::vector<real_t> values(numValues);
        std::vector<index_t> indices(numValues);

        {
            index_t idxValue = 0;

            for (auto const& v : storage_) {
                for (auto const& [index, value] : v) {
                    values[idxValue] = value;
                    indices[idxValue] = index;
                    idxValue++;
                }
            }
        }

        return CompressedSparseMatrix<DataType_, StorageOrder_>(
            numRows,
            numCols,
            numValues,
            std::move(values),
            std::move(indices),
            std::move(lengths)
        );
    }

private:
    std::vector<std::map<index_t, real_t>> storage_;
    size_t nonZeros_ { 0 };
};

template<typename DataType_, StorageOrder StorageOrder_>
struct CompressedSparseMatrix {
    const size_t numRows;
    const size_t numCols;
    const size_t numValues;

    const std::vector<DataType_> values;
    const std::vector<index_t> indices;
    const std::vector<size_t> lengths;
    const std::vector<index_t> offsets;

    const StorageOrder storageOrder = StorageOrder_;

    CompressedSparseMatrix(
        size_t numRows,
        size_t numCols,
        size_t numValues,
        std::vector<real_t> values_,
        std::vector<index_t> indices_,
        std::vector<size_t> lengths_
    )
        : numRows { numRows }
        , numCols { numCols }
        , numValues { numValues }
        , values { std::move(values_) }
        , indices { std::move(indices_) }
        , lengths { std::move(lengths_) }
        , offsets { detail::mkOffsets(lengths) } {

        assert(values.size() == numValues);
        assert(indices.size() == numValues);
        assert(offsets.back() == numValues);

        size_t totalLength = 0;
        for (auto length : lengths) {
            totalLength += length;
        }
        assert(numValues == totalLength);

        for (auto index : indices) {
            if constexpr (StorageOrder_ == RowMajor)
                assert(index < numCols);
            else
                assert(index < numRows);
        }
    }

    SparseMatrix<DataType_, StorageOrder_> toSparseMatrix() {
        SparseMatrix<DataType_, StorageOrder_> result {
            numRows,
            numCols
        };

        index_t idxValue = 0;
        index_t i = 0;

        for (auto length : lengths) {
            for (index_t j = 0; j < length; ++j) {
                index_t index = indices[idxValue];
                index_t value = values[idxValue];

                if constexpr (StorageOrder_ == RowMajor)
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

namespace detail {

template<typename DataType_, StorageOrder StorageOrderSparse_, StorageOrder StorageOrderDense_>
inline DenseMatrix<DataType_, StorageOrderDense_> sparseMatrixProductImpl(
    CompressedSparseMatrix<DataType_, StorageOrderSparse_> cspm,
    DenseMatrix<DataType_, StorageOrderDense_> m
) {
    if (StorageOrderSparse_ == RowMajor)
        assert(cspm.numCols == m.numRows);
    else
        assert(m.numCols == cspm.numRows);

    size_t numRows = StorageOrderSparse_ == RowMajor ? cspm.numRows : m.numRows;
    size_t numCols = StorageOrderSparse_ == RowMajor ? m.numCols : cspm.numCols;
    size_t jCount = StorageOrderSparse_ == RowMajor ? numCols : numRows;

    DenseMatrix<DataType_, StorageOrderDense_> result(numRows, numCols);

    index_t j = 0;

    for (index_t j = 0; j < jCount; ++j) {
        index_t idxValue = 0;
        index_t i = 0;

        for (auto length : cspm.lengths) {
            DataType_ acc = DataType_(0);

            for (index_t k = 0; k < length; ++k) {
                auto index = cspm.indices[idxValue];
                auto value = cspm.values[idxValue];

                if constexpr (StorageOrderSparse_ == RowMajor)
                    acc += value * m.get(index, j);
                else
                    acc += value * m.get(j, index);

                idxValue++;
            }

            if constexpr (StorageOrderSparse_ == RowMajor)
                result.set(i, j, acc);
            else
                result.set(j, i, acc);

            i++;
        }
    }

    return result;
}

} // namespace detail

template<typename DataType_, StorageOrder StorageOrder_>
inline DenseMatrix<DataType_, StorageOrder_> sparseMatrixProduct(
    CompressedSparseMatrix<DataType_, RowMajor> cspm,
    DenseMatrix<DataType_, StorageOrder_> m
) {
    return detail::sparseMatrixProductImpl(cspm, m);
}

template<typename DataType_, StorageOrder StorageOrder_>
inline DenseMatrix<DataType_, StorageOrder_> sparseMatrixProduct(
    DenseMatrix<DataType_, StorageOrder_> m,
    CompressedSparseMatrix<DataType_, ColumnMajor> cspm
) {
    return detail::sparseMatrixProductImpl(cspm, m);
}

template<typename DataType_, StorageOrder StorageOrder_>
inline bool isSame(
    DenseMatrix<DataType_, StorageOrder_> const& m1,
    DenseMatrix<DataType_, StorageOrder_> const& m2,
    std::type_identity_t<DataType_> tolerance = DataType_(0)
) {
    if (m1.numRows != m2.numRows)
        return false;

    if (m1.numCols != m2.numCols)
        return false;

    auto data1 = m1.data();
    auto data2 = m2.data();

    size_t N = m1.numRows * m1.numCols;

    for (index_t i = 0; i < N; ++i) {
        if (std::abs(data1[i] - data2[i]) > tolerance) {
            return false;
        }
    }

    return true;
}

} // namespace linalg

#endif // LINALG_HPP_INCLUDED

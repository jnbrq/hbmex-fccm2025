#ifndef LINALG_TYPES_DENSE_HPP_INCLUDED
#define LINALG_TYPES_DENSE_HPP_INCLUDED

#include <linalg/Defs.hpp>
#include <linalg/Exception.hpp>

#include <fmt/core.h>

namespace linalg::types {

template<typename DataType_, StorageOrder StorageOrder_>
struct DenseMatrix {
    const size_t numRows;
    const size_t numCols;

    DenseMatrix(size_t numRows, size_t numCols)
        : numRows { numRows }
        , numCols { numCols }
        , storage_(numRows * numCols) {}

    DataType_ get(index_t row, index_t col) const LINALG_NOEXCEPT {
        LINALG_REQUIRE(row < numRows && col < numCols);

        if constexpr (StorageOrder_ == RowMajor)
            return storage_[row * numCols + col];
        else
            return storage_[col * numRows + row];
    }

    void set(index_t row, index_t col, DataType_ value) LINALG_NOEXCEPT {
        LINALG_REQUIRE(row < numRows && col < numCols);

        if constexpr (StorageOrder_ == RowMajor)
            storage_[row * numCols + col] = value;
        else
            storage_[col * numRows + row] = value;
    }

    DataType_* data() noexcept {
        return storage_.data();
    }

    DataType_ const* data() const noexcept {
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

} // namespace linalg::types

#endif /* LINALG_TYPES_DENSE_HPP_INCLUDED */

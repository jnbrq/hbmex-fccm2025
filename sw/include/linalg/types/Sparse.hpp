#ifndef LINALG_TYPES_SPARSE_HPP_INCLUDED
#define LINALG_TYPES_SPARSE_HPP_INCLUDED

#include <linalg/Defs.hpp>
#include <linalg/Exception.hpp>

#include <map>
#include <vector>

namespace linalg::types {

template<typename DataType_, StorageOrder StorageOrder_>
struct SparseMatrix {

    SparseMatrix(size_t numRows, size_t numCols)
        : numRows { numRows }
        , numCols { numCols }
        , storage_(numRows) {
        //
    }

    const size_t numRows, numCols;

    DataType_ get(index_t row, index_t col) const {
        LINALG_REQUIRE(row < numRows && col < numCols);

        if (StorageOrder_ == ColumnMajor)
            std::swap(row, col);

        auto m = storage_[row];
        if (auto it = m.find(col); it != m.end()) {
            return it->second;
        }

        return DataType_(0);
    }

    void set(index_t row, index_t col, DataType_ value) {
        LINALG_REQUIRE(row < numRows && col < numCols);

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

    void setIfImplicitZero(index_t row, index_t col, DataType_ value) {
        LINALG_REQUIRE(row < numRows && col < numCols);

        if (StorageOrder_ == ColumnMajor)
            std::swap(row, col);

        auto& x = storage_[row];
        if (auto it = x.find(col); it == x.end()) {
            x[col] = value;
            nonZeros_++;
        }
    }

    bool isImplicitZero(index_t row, index_t col) const {
        LINALG_REQUIRE(row < numRows && col < numCols);

        if (StorageOrder_ == ColumnMajor)
            std::swap(row, col);

        auto const& x = storage_[row];
        auto it = x.find(col);
        return it == x.end();
    }

    size_t nonZeros() const noexcept {
        return nonZeros_;
    }

    void clear() noexcept {
        nonZeros_ = 0;

        for (auto& v : storage_)
            v.clear();
    }

    size_t storageLength() const noexcept {
        return storage_.size();
    }

    /**
     * @note After modifying the storage, call `updateNonZeros`,
     */
    std::map<index_t, real_t>* storageUnsafe() noexcept {
        return storage_.data();
    }

    /**
     * @note After modifying the storage, call `updateNonZeros`,
     */
    std::map<index_t, real_t>& storageUnsafe(index_t i) LINALG_NOEXCEPT {
        LINALG_REQUIRE(i < storage_.size());
        return storage_[i];
    }

    void updateNonZeros() noexcept {
        nonZeros_ = 0;

        for (auto const& v : storage_) {
            nonZeros_ += v.size();
        }
    }

    std::map<index_t, real_t> const* storage() const noexcept {
        return storage_.data();
    }

    std::map<index_t, real_t> const& storage(index_t i) const LINALG_NOEXCEPT {
        LINALG_REQUIRE(i < storage_.size());
        return storage_[i];
    }

private:
    std::vector<std::map<index_t, real_t>> storage_;
    size_t nonZeros_ { 0 };
};

} // namespace linalg::types

#endif /* LINALG_TYPES_SPARSE_HPP_INCLUDED */

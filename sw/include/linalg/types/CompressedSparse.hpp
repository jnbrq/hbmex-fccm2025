#ifndef LINALG_TYPES_COMPRESSEDSPARSE_HPP_INCLUDED
#define LINALG_TYPES_COMPRESSEDSPARSE_HPP_INCLUDED

#include <linalg/Defs.hpp>
#include <linalg/Exception.hpp>

#include <type_traits>
#include <vector>

namespace linalg::types {

namespace detail {

template<typename IndexType_>
std::vector<IndexType_> mkOffsets(std::vector<IndexType_> const& lengths) {
    std::vector<IndexType_> result(lengths.size() + 1);

    IndexType_ idx = 0, last = 0;
    result[idx++] = 0;

    for (auto length : lengths) {
        last += length;
        result[idx++] = last;
    }

    return result;
}

} // namespace detail

/// @brief
/// @note We have so many template arguments, because this class is supposed to
/// be exchanged over file system or memory. We want to support as many
/// representations as possible.
/// @tparam DataType_
/// @tparam IndexType_
/// @tparam StorageOrder_
template<
    typename DataType_ = real_t,
    typename IndexType_ = index_t,
    StorageOrder StorageOrder_ = RowMajor>
struct CompressedSparseMatrix {
    const size_t numRows;
    const size_t numCols;
    const size_t numValues;

    const std::vector<DataType_> values;
    const std::vector<IndexType_> indices;
    const std::vector<IndexType_> lengths;
    const std::vector<IndexType_> offsets;

    CompressedSparseMatrix(
        size_t numRows,
        size_t numCols,
        size_t numValues,
        std::vector<DataType_> values_,
        std::vector<IndexType_> indices_,
        std::vector<IndexType_> lengths_
    )
        : numRows { numRows }
        , numCols { numCols }
        , numValues { numValues }
        , values { std::move(values_) }
        , indices { std::move(indices_) }
        , lengths { std::move(lengths_) }
        , offsets { detail::mkOffsets(lengths) } {

        LINALG_REQUIRE(values.size() == numValues);
        LINALG_REQUIRE(indices.size() == numValues);
        LINALG_REQUIRE(offsets.back() == numValues);

        size_t totalLength = 0;
        for (auto length : lengths) {
            totalLength += length;
        }
        LINALG_REQUIRE(numValues == totalLength);

        for (auto index : indices) {
            if constexpr (StorageOrder_ == RowMajor)
                LINALG_REQUIRE(index < numCols);
            else
                LINALG_REQUIRE(index < numRows);
        }
    }
};

}; // namespace linalg::types

#endif /* LINALG_TYPES_COMPRESSEDSPARSE_HPP_INCLUDED */

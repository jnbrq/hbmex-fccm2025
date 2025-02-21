#ifndef LINALG_DEFS_HPP_INCLUDED
#define LINALG_DEFS_HPP_INCLUDED

#include <cstdint>

namespace linalg {

using real_t = double;
using index_t = std::uint64_t;
using size_t = std::uint64_t;

using byte_t = std::uint8_t;

enum StorageOrder {
    RowMajor,
    ColumnMajor
};

inline constexpr StorageOrder reverseStorageOrder(StorageOrder storageOrder) {
    if (storageOrder == RowMajor)
        return ColumnMajor;
    return RowMajor;
}

} // namespace linalg

#ifndef MIN
#    define MIN(x, y) (((x) < (y)) ? (x) : (y))
#endif

#endif /* LINALG_DEFS_HPP_INCLUDED */

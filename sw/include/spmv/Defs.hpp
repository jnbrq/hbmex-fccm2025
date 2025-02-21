#ifndef SPMV_DEFS_HPP_INCLUDED
#define SPMV_DEFS_HPP_INCLUDED

#include <boost/endian.hpp>
#include <fmt/boost/endian.hpp>

#include <linalg/linalg.hpp>

namespace spmv {

using real_t = boost::endian::little_float32_at;
using index_t = boost::endian::little_uint32_at;

using DenseMatrix = linalg::types::DenseMatrix<
    real_t,
    linalg::RowMajor>;

using SparseMatrix = linalg::types::SparseMatrix<
    real_t,
    linalg::RowMajor>;

using CompressedSparseMatrix = linalg::types::CompressedSparseMatrix<
    real_t,
    index_t,
    linalg::RowMajor>;

} // namespace spmv

#endif /* SPMV_DEFS_HPP_INCLUDED */

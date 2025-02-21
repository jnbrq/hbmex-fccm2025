#ifndef SPMV_UTIL_HPP_INCLUDED
#define SPMV_UTIL_HPP_INCLUDED

#include <boost/endian.hpp>

namespace boost::endian {

template<order Order, typename T, std::size_t N, align Align>
T format_as(endian_arithmetic<Order, T, N, Align> const& x) {
    return x.value();
}

} // namespace boost::endian

#endif /* SPMV_UTIL_HPP_INCLUDED */

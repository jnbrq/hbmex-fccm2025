#ifndef UTIL_HPP_INCLUDED
#define UTIL_HPP_INCLUDED

#include <systemc>
#include <type_traits>

namespace chext_test::util {

namespace detail {

template<typename T, typename Enable = void>
struct bv_from_impl;

template<typename T>
struct bv_from_impl<T, std::enable_if_t<std::is_integral_v<T>>> {
    static auto bv_from(T t, int width = (sizeof(T) * CHAR_BIT)) {
        sc_dt::sc_bv_base result(width > 0 ? width : 32);
        result = t;
        return result;
    }
};

} // namespace detail

template<typename T>
inline auto bv_from(T t) {
    return detail::bv_from_impl<T>::bv_from(t);
}

template<typename T>
inline auto bv_from(T t, int width) {
    return detail::bv_from_impl<T>::bv_from(t, width);
}

// TODO do this in a more concrete way?
#define LOG2_IMPL(type, return_type, clz)              \
    inline constexpr return_type log2(type x) {        \
        return (sizeof(type) * CHAR_BIT) - 1 - clz(x); \
    }

LOG2_IMPL(unsigned char, uint8_t, __builtin_clz);
LOG2_IMPL(unsigned short, uint8_t, __builtin_clz);
LOG2_IMPL(unsigned int, uint8_t, __builtin_clz);
LOG2_IMPL(unsigned long, uint8_t, __builtin_clzl);
LOG2_IMPL(unsigned long long, uint8_t, __builtin_clzll);

#undef LOG2_IMPL

} // namespace chext_test::util

#ifndef MIN
#    define MIN(x, y) (((x) < (y)) ? (x) : (y))
#endif

#ifndef MAX
#    define MAX(x, y) (((x) > (y)) ? (x) : (y))
#endif

#endif /* UTIL_HPP_INCLUDED */

#ifndef JQR_TUPLE_HPP_INCLUDED
#define JQR_TUPLE_HPP_INCLUDED

#include <tuple>
#include <type_traits>

namespace jqr::tuple_utils {

namespace detail {

template<typename T, typename Tuple>
struct has_type;

template<typename T, typename... Ts>
struct has_type<T, std::tuple<Ts...>> : std::disjunction<std::is_same<T, Ts>...> {};

template<typename T, typename Tuple, bool = has_type<T, Tuple>::value>
struct get_or_else_impl;

template<typename T, typename... Ts>
struct get_or_else_impl<T, std::tuple<Ts...>, true> {
    static constexpr T get(const std::tuple<Ts...>& tpl, const T& t) noexcept {
        return std::get<T>(tpl);
    }
};

template<typename T, typename... Ts>
struct get_or_else_impl<T, std::tuple<Ts...>, false> {
    static constexpr T get(const std::tuple<Ts...>& tpl, const T& t) {
        return t;
    }
};

template<typename T, typename... Ts>
inline constexpr T get_or_else(const std::tuple<Ts...>& tpl, const T& t) {
    return get_or_else_impl<T, std::tuple<Ts...>>::get(tpl, t);
}

template<typename T, typename Tuple1, typename Tuple2>
inline constexpr T get_or_else(const Tuple1& tpl1, const Tuple2& tpl2, const T& t) {
    return get_or_else(tpl1, get_or_else(tpl2, t));
}

template<typename T, typename Tuple1, typename Tuple2, typename Tuple3>
inline constexpr T get_or_else(const Tuple1& tpl1, const Tuple2& tpl2, const Tuple3& tpl3, const T& t) {
    return get_or_else(tpl1, get_or_else(tpl2, get_or_else(tpl3, t)));
}

} // namespace detail

using detail::get_or_else;
using detail::has_type;

} // namespace jqr::tuple_utils

#endif /* JQR_TUPLE_HPP_INCLUDED */

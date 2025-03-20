#ifndef JQR_CORE_HPP_INCLUDED
#define JQR_CORE_HPP_INCLUDED

#include "inspect.hpp"
#include "tuple_utils.hpp"

#include <type_traits>

namespace jqr {

namespace opts {

#define JQR_DEFINE_OPT(name, type) \
    struct name {                  \
        type v;                    \
    };

} // namespace opts

JQR_DEFINE_INSPECT(has_members, std::declval<T>().members())
JQR_DEFINE_INSPECT(is_jqr, (typename T::__jqr)0)

template<typename T>
inline constexpr auto members_of(T& t) {
    static_assert(has_members_v<T>, "T::members must be present!");
    return t.members();
}

template<typename T, typename... Options>
struct member_proxy {
    using type = T;

    const char* name;

    // this member makes `constexpr` not viable
    T& t;

    std::tuple<Options...> options;
};

template<typename T, typename... Options>
inline constexpr auto make_member_proxy(const char* name, T& t, Options... options) {
    return member_proxy<T, Options...> { name, t, std::make_tuple(options...) };
}

namespace detail {

template<typename T, typename Enable = void>
struct get_options_impl {
    static constexpr auto impl(T const& t) { return std::make_tuple(); }
};

template<typename T>
struct get_options_impl<T, std::void_t<decltype(std::declval<T>().__jqr_options())>> {
    static constexpr auto impl(T const& t) { return t.__jqr_options(); }
};

} // namespace detail

template<typename T>
constexpr auto get_options(T const& t) {
    return detail::get_options_impl<T>::impl(t);
}

}; // namespace jqr

/**
 * @brief Adapts a struct member.
 *
 */
#define JQR_MEMBER(x, ...) jqr::make_member_proxy(#x, x __VA_OPT__(, ) __VA_ARGS__)

/**
 * @brief Declares a jqr-enabled struct.
 *
 */
#define JQR_DECL(name, ...)                                    \
    static constexpr const char* type_name() { return #name; } \
    using __jqr = void;                                        \
    using this_type = name;                                    \
                                                               \
    constexpr auto members() noexcept {                        \
        return std::make_tuple(__VA_ARGS__);                   \
    }                                                          \
                                                               \
    constexpr auto members() const noexcept {                  \
        return std::make_tuple(__VA_ARGS__);                   \
    }

#define JQR_OPTIONS(...)                     \
    constexpr auto __jqr_options() const {   \
        return std::make_tuple(__VA_ARGS__); \
    }

#endif /* JQR_CORE_HPP_INCLUDED */

#ifndef JQR_HASH_HPP_INCLUDED
#define JQR_HASH_HPP_INCLUDED

#include "core.hpp"
#include "inspect.hpp"
#include "tuple_utils.hpp"

#include <cstdint>
#include <utility>

namespace jqr {

using hash_result_t = std::size_t;

JQR_DEFINE_INSPECT(has_hash, std::declval<T>().hash(std::make_tuple()))
JQR_DEFINE_INSPECT(has_std_hash, std::declval<std::hash<T>>()(std::declval<T>()))

template<typename T>
constexpr hash_result_t hash(T const& t);

namespace opts {

JQR_DEFINE_OPT(hash, bool)

} // namespace opts

namespace detail {

class hash_impl {
    struct component {
        hash_result_t hash;
        bool take = true;

        constexpr std::uintmax_t operator,(std::uintmax_t n) const {
            if (!take)
                return n;

            return n ^ (hash);
        }
    };

public:
    template<class Members>
    static constexpr hash_result_t impl(const Members& tuple) {
        constexpr auto fn = [](const auto&... xs) {
            return (
                component {
                    jqr::hash(xs.t),
                    tuple_utils::get_or_else(xs.options, opts::hash { true }).v //
                },
                ..., 0
            );
        };
        return std::hash<std::uintmax_t>()(
            std::apply(fn, tuple)
        );
    }
};

} // namespace detail

template<typename T, typename Enable = void>
struct mk_hash {
    template<typename... Options>
    static hash_result_t do_hash(T const&) {
        return 0;
    }
};

template<typename T>
struct mk_hash<T, std::enable_if_t<jqr::is_jqr_v<T> && has_hash_v<T>>> {
    template<typename... Options>
    static hash_result_t do_hash(T const& t) {
        return t.hash();
    }
};

template<typename T>
struct mk_hash<T, std::enable_if_t<jqr::is_jqr_v<T> && !has_hash_v<T>>> {
    template<typename... Options>
    static hash_result_t do_hash(T const& t) {
        return detail::hash_impl::impl(t.members());
    }
};

template<typename T>
struct mk_hash<T, std::enable_if_t<!jqr::is_jqr_v<T> && has_std_hash_v<T>>> {
    template<typename... Options>
    static hash_result_t do_hash(T const& t) {
        return std::hash<T> {}(t);
    }
};

template<typename T>
inline constexpr hash_result_t hash(T const& t) {
    return mk_hash<T>::do_hash(t);
}

} // namespace jqr

#define JQR_DEFINE_STD_HASH(type)                          \
    template<>                                             \
    struct std::hash<type> {                               \
        constexpr size_t operator()(type const& t) const { \
            return jqr::hash(t);                           \
        }                                                  \
    };

#endif /* JQR_HASH_HPP_INCLUDED */

#ifndef JQR_COMP_EQ_HPP_INCLUDED
#define JQR_COMP_EQ_HPP_INCLUDED

#include "core.hpp"

namespace jqr {

JQR_DEFINE_INSPECT(has_comp_eq, std::declval<T>() == std::declval<T>())

namespace opts {

JQR_DEFINE_OPT(comp_eq, bool)

}

template<typename T>
constexpr bool comp_eq(T const& t1, T const& t2);

template<typename T, typename Enable = void>
struct mk_comp_eq {
    static constexpr auto do_comp_eq(T const& t1, T const& t2) {
        return false;
    }
};

template<typename T>
struct mk_comp_eq<T, std::enable_if_t<jqr::is_jqr_v<T>>> {
    static constexpr auto do_comp_eq(T const& t1, T const& t2) {
        using tuple_utils::get_or_else;

        // clang-format off
        return std::apply([&](auto const& ...x1s) {
            return std::apply([&](auto const& ...x2s) {
                auto fn = [&](auto const& x1, auto const& x2) {
                    if (!get_or_else(x1.options, opts::comp_eq{ true }).v)
                        return true;
                    
                    return jqr::comp_eq(x1.t, x2.t);
                };

                return (fn(x1s, x2s) && ...);
            }, t2.members());
        }, t1.members());
        // clang-format on
    }
};

template<typename T>
struct mk_comp_eq<T, std::enable_if_t<!jqr::is_jqr_v<T> && has_comp_eq_v<T>>> {
    static constexpr auto do_comp_eq(T const& t1, T const& t2) {
        return t1 == t2;
    }
};

template<typename T>
constexpr bool comp_eq(T const& t1, T const& t2) {
    return mk_comp_eq<T>::do_comp_eq(t1, t2);
}

} // namespace jqr

#define JQR_COMP_EQ                                 \
    bool operator==(this_type const& other) const { \
        return ::jqr::comp_eq(*this, other);        \
    }                                               \
                                                    \
    bool operator!=(this_type const& other) const { \
        return !(*this == other);                   \
    }

#endif /* JQR_COMP_EQ_HPP_INCLUDED */

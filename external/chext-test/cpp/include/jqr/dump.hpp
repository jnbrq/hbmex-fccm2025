#ifndef JQR_DUMP_HPP_INCLUDED
#define JQR_DUMP_HPP_INCLUDED

#include "core.hpp"
#include "inspect.hpp"
#include "tuple_utils.hpp"

#include <fmt/format.h>

namespace jqr {

JQR_DEFINE_INSPECT(has_dump, std::declval<T>().dump(std::declval<fmt::memory_buffer&>(), std::make_tuple()))

namespace opts {

JQR_DEFINE_OPT(dump, bool)
JQR_DEFINE_OPT(dump_name, bool)
JQR_DEFINE_OPT(dump_fmt, const char*)
JQR_DEFINE_OPT(dump_class, bool)
JQR_DEFINE_OPT(dump_paren, bool)

} // namespace opts

template<typename T, typename Enable = void>
struct has_custom_dumper : std::false_type {};

template<typename T>
constexpr bool has_custom_dumper_v = has_custom_dumper<T>::value;

template<typename T, typename... Options>
void dump(T const& t, fmt::memory_buffer& buf, std::tuple<Options...> const& options = std::make_tuple());

template<typename T, typename... Options>
inline std::string to_string(T const& t, std::tuple<Options...> const& options = std::make_tuple()) {
    auto buf = fmt::memory_buffer {};
    dump(t, buf, options);
    return std::string { buf.data(), buf.size() };
}

template<typename T, typename Enable = void>
struct mk_dump {
    template<typename... Options>
    static void do_dump(T const&, fmt::memory_buffer& buf, std::tuple<Options...> const&) {
        buf.append(std::string_view("???"));
    }
};

template<typename T>
struct mk_dump<T, std::enable_if_t<is_jqr_v<T> && has_dump_v<T>>> {
    template<typename... Options>
    static void do_dump(T const& t, fmt::memory_buffer& buf, std::tuple<Options...> const& options) {
        t.dump(buf, options);
    }
};

template<typename T>
struct mk_dump<T, std::enable_if_t<is_jqr_v<T> && !has_dump_v<T>>> {
    template<typename... Options>
    static void do_dump(T const& t, fmt::memory_buffer& buf, std::tuple<Options...> const& options) {
        using tuple_utils::get_or_else;

        auto fallback_options = get_options(t);

        if (get_or_else(options, fallback_options, opts::dump_class { true }).v)
            buf.append(std::string_view(t.type_name()));

        if (get_or_else(options, fallback_options, opts::dump_paren { true }).v)
            buf.append(std::string_view("("));
        else if (get_or_else(options, fallback_options, opts::dump_class { true }).v)
            buf.append(std::string_view(": "));

        bool printSeparator = false;

        auto fn = [&](auto x) {
            if (get_or_else(x.options, opts::dump { true }).v) {
                if (printSeparator)
                    buf.append(std::string_view(", "));

                printSeparator = true;

                if (get_or_else(x.options, opts::dump_name { true }).v) {
                    buf.append(std::string_view(x.name));
                    buf.append(std::string_view("="));
                }

                jqr::dump(x.t, buf, x.options);
            }
        };

        std::apply([&](auto... x) { (fn(x), ...); }, t.members());

        if (get_or_else(options, fallback_options, opts::dump_paren { true }).v)
            buf.append(std::string_view(")"));
    }
};

template<typename T>
struct mk_dump<T, std::enable_if_t<!is_jqr_v<T> && !has_custom_dumper_v<T> && fmt::is_formattable<T>::value>> {
    template<typename... Options>
    static void do_dump(T const& t, fmt::memory_buffer& buf, std::tuple<Options...> const& options) {
        using tuple_utils::get_or_else;
        fmt::format_to(std::back_inserter(buf), fmt::runtime(get_or_else(options, opts::dump_fmt { "{}" }).v), t);
    }
};

template<typename T, typename... Options>
inline void dump(T const& t, fmt::memory_buffer& buf, std::tuple<Options...> const& options) {
    mk_dump<T>::do_dump(t, buf, options);
}

} // namespace jqr

#define JQR_TO_STRING                                                \
    template<typename... Options>                                    \
    std::string to_string(Options... options) const {                \
        return ::jqr::to_string(*this, std::make_tuple(options...)); \
    }

#define JQR_OSTREAM                                                         \
    friend std::ostream& operator<<(std::ostream& os, this_type const& t) { \
        return (os << ::jqr::to_string(t));                                 \
    }

namespace fmt {

template<typename T>
struct formatter<T, std::enable_if_t<jqr::is_jqr_v<T>, char>> : fmt::formatter<std::string> {
    auto format(const T& t, format_context& ctx) const {
        return formatter<std::string>::format(jqr::to_string(t), ctx);
    }
};

}; // namespace fmt

#endif /* JQR_DUMP_HPP_INCLUDED */

#ifndef CHEXT_TEST_ELASTIC_CONVERT_HPP_INCLUDED
#define CHEXT_TEST_ELASTIC_CONVERT_HPP_INCLUDED

#include <fmt/format.h>

#include <string>
#include <type_traits>
#include <typeindex>

#include <systemc>

#include <chext_test/util/Exception.hpp>

namespace chext_test::elastic {

template<typename From, typename To, typename Enable = void>
struct Converter {
    static To convert(From const& from) {
        throw chext_test::util::Exception(
            fmt::format(
                "Conversion does not exist from '{}' to '{}'.",
                typeid(From).name(),
                typeid(To).name()
            )
        );
    }
};

template<typename From, typename To>
struct Converter<From, To, std::enable_if_t<std::is_integral_v<From> && std::is_integral_v<To>>> {
    static constexpr To convert(From const& from) {
        return static_cast<To>(from);
    }
};

template<unsigned W, typename To>
struct Converter<sc_dt::sc_bv<W>, To, std::enable_if_t<std::is_integral_v<To>>> {
    static To convert(sc_dt::sc_bv<W> const& from) {
        return To(from.to_uint64());
    }
};

template<unsigned W>
struct Converter<sc_dt::sc_bv<W>, std::string, void> {
    static std::string convert(sc_dt::sc_bv<W> const& from) {
        return from.to_string();
    }
};

template<typename From, unsigned W>
struct Converter<From, sc_dt::sc_bv<W>, std::enable_if_t<std::is_integral_v<From>>> {
    static sc_dt::sc_bv<W> convert(From const& from) {
        return sc_dt::sc_bv<W>(from);
    }
};

template<unsigned W>
struct Converter<std::string, sc_dt::sc_bv<W>, void> {
    static sc_dt::sc_bv<W> convert(std::string const& from) {
        return sc_dt::sc_bv<W>(from.c_str());
    }
};

} // namespace chext_test::elastic

#endif /* CHEXT_TEST_ELASTIC_CONVERT_HPP_INCLUDED */

#ifndef PROTOCOLS_HPP_INCLUDED
#define PROTOCOLS_HPP_INCLUDED

#include <jqr/comp_eq.hpp>
#include <jqr/core.hpp>
#include <jqr/dump.hpp>

#include <fmt/core.h>

#include <systemc>

namespace protocols {

namespace detail {

using namespace sc_core;
using namespace sc_dt;

struct AddrLenSizeBurst {
    sc_bv_base addr;
    uint8_t len;
    uint8_t size;
    uint8_t burst;

    JQR_DECL(
        AddrLenSizeBurst,
        JQR_MEMBER(addr),
        JQR_MEMBER(len),
        JQR_MEMBER(size),
        JQR_MEMBER(burst)
    )

    JQR_TO_STRING
    JQR_OSTREAM
    JQR_COMP_EQ
};

template<unsigned wAddr>
struct AddrLenSizeBurstSignals {
    using value_type = AddrLenSizeBurst;

    AddrLenSizeBurstSignals(const char* name)
        : addr(fmt::format("{}_addr", name).c_str())
        , len(fmt::format("{}_len", name).c_str())
        , size(fmt::format("{}_size", name).c_str())
        , burst(fmt::format("{}_burst", name).c_str()) {}

    sc_signal<sc_bv<wAddr>, SC_MANY_WRITERS> addr;
    sc_signal<sc_bv<8>, SC_MANY_WRITERS> len;
    sc_signal<sc_bv<3>, SC_MANY_WRITERS> size;
    sc_signal<sc_bv<2>, SC_MANY_WRITERS> burst;

    void readTo(value_type& x) const {
        x.~value_type();

        new (&x) value_type {
            addr.read(),
            (uint8_t)len.read().to_uint(),
            (uint8_t)size.read().to_uint(),
            (uint8_t)burst.read().to_uint()
        };
    }

    void writeFrom(value_type const& x) {
        addr.write(x.addr);
        len.write(x.len);
        size.write(x.size);
        burst.write(x.burst);
    }
};

struct AddrSizeLast {
    sc_bv_base addr;
    uint8_t size;
    bool last;

    JQR_DECL(
        AddrSizeLast,
        JQR_MEMBER(addr),
        JQR_MEMBER(size),
        JQR_MEMBER(last)
    )

    JQR_TO_STRING
    JQR_OSTREAM
    JQR_COMP_EQ
};

template<unsigned wAddr>
struct AddrSizeLastSignals {
    using value_type = AddrSizeLast;

    AddrSizeLastSignals(const char* name)
        : addr(fmt::format("{}_addr", name).c_str())
        , size(fmt::format("{}_size", name).c_str())
        , last(fmt::format("{}_last", name).c_str()) {}

    sc_signal<sc_bv<wAddr>, SC_MANY_WRITERS> addr;
    sc_signal<sc_bv<3>, SC_MANY_WRITERS> size;
    sc_signal<bool, SC_MANY_WRITERS> last;

    void readTo(value_type& x) const {
        x.~value_type();

        new (&x) value_type {
            addr.read(),
            (uint8_t)size.read().to_uint(),
            last.read()
        };
    }

    void writeFrom(value_type const& x) {
        addr.write(x.addr);
        size.write(x.size);
        last.write(x.last);
    }
};

struct AddrSizeStrobeLast {
    sc_bv_base addr;
    uint8_t size;
    sc_bv_base strb;
    sc_bv_base lowerByteIndex;
    sc_bv_base upperByteIndex;
    bool last;

    JQR_DECL(
        AddrSizeStrobeLast,
        JQR_MEMBER(addr),
        JQR_MEMBER(size),
        JQR_MEMBER(strb),
        JQR_MEMBER(lowerByteIndex),
        JQR_MEMBER(upperByteIndex),
        JQR_MEMBER(last)
    )

    JQR_TO_STRING
    JQR_OSTREAM
    JQR_COMP_EQ
};

template<
    unsigned wAddr,
    unsigned wStrobe,
    unsigned wIndex>
struct AddrSizeStrobeLastSignals {
    using value_type = AddrSizeStrobeLast;

    AddrSizeStrobeLastSignals(const char* name)
        : addr(fmt::format("{}_addr", name).c_str())
        , size(fmt::format("{}_size", name).c_str())
        , strb(fmt::format("{}_strb", name).c_str())
        , lowerByteIndex(fmt::format("{}_lowerByteIndex", name).c_str())
        , upperByteIndex(fmt::format("{}_upperByteIndex", name).c_str())
        , last(fmt::format("{}_last", name).c_str()) {}

    sc_signal<sc_bv<wAddr>, SC_MANY_WRITERS> addr;
    sc_signal<sc_bv<3>, SC_MANY_WRITERS> size;
    sc_signal<sc_bv<wStrobe>, SC_MANY_WRITERS> strb;
    sc_signal<sc_bv<wIndex>, SC_MANY_WRITERS> lowerByteIndex;
    sc_signal<sc_bv<wIndex>, SC_MANY_WRITERS> upperByteIndex;
    sc_signal<bool, SC_MANY_WRITERS> last;

    void readTo(value_type& x) const {
        x.~value_type();

        new (&x) value_type {
            addr.read(),
            (uint8_t)size.read().to_uint(),
            strb.read(),
            lowerByteIndex.read(),
            upperByteIndex.read(),
            last.read()
        };
    }

    void writeFrom(value_type const& x) {
        addr.write(x.addr);
        size.write(x.size);
        strb.write(x.strb);
        lowerByteIndex.write(x.lowerByteIndex);
        upperByteIndex.write(x.upperByteIndex);
        last.write(x.last);
    }
};

} // namespace detail

using detail::AddrLenSizeBurst;
using detail::AddrLenSizeBurstSignals;
using detail::AddrSizeLast;
using detail::AddrSizeLastSignals;
using detail::AddrSizeStrobeLast;
using detail::AddrSizeStrobeLastSignals;

} // namespace protocols

#endif /* PROTOCOLS_HPP_INCLUDED */

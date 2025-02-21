#ifndef CHEXT_TEST_AMBA_AXI4_FULL_PACKETS_HPP_INCLUDED
#define CHEXT_TEST_AMBA_AXI4_FULL_PACKETS_HPP_INCLUDED

#include <systemc>

#include <chext_test/util/ScDump.hpp>
#include <jqr/comp_eq.hpp>
#include <jqr/dump.hpp>

namespace chext_test::amba::axi4::full {

namespace detail {

using sc_dt::sc_bv;
using sc_dt::sc_bv_base;
using std::uint8_t;

namespace o = jqr::opts;
using chext_test::util::ScDumpOptions;

struct Packets {
    struct Address {
        sc_bv_base id;
        sc_bv_base addr;
        uint8_t len;
        uint8_t size;
        uint8_t burst;
        uint8_t lock;
        uint8_t cache;
        uint8_t prot;
        uint8_t qos;
        uint8_t region;
        sc_bv_base user { sc_bv<32>(0) };

        JQR_DECL(
            Address,
            JQR_MEMBER(id, ScDumpOptions { .numrep = sc_dt::SC_HEX, .hasPrefix = true, .groupWidth = 4 }),
            JQR_MEMBER(addr, ScDumpOptions { .numrep = sc_dt::SC_HEX, .hasPrefix = true, .groupWidth = 4 }),
            JQR_MEMBER(len, o::dump_fmt { "{0:#04x}=0d{0:03d}" }),
            JQR_MEMBER(size, o::dump_fmt { "{0:#05b}=0d{0:1d}" }),
            JQR_MEMBER(burst, o::dump_fmt { "{:#04b}" }),
            JQR_MEMBER(lock, o::dump_fmt { "{:#04b}" }),
            JQR_MEMBER(cache, o::dump_fmt { "{:#06b}" }),
            JQR_MEMBER(prot, o::dump_fmt { "{:#06b}" }),
            JQR_MEMBER(qos, o::dump_fmt { "{:#06b}" }),
            JQR_MEMBER(region, o::dump_fmt { "{:#03x}" }),
            JQR_MEMBER(user, ScDumpOptions { .numrep = sc_dt::SC_HEX, .hasPrefix = true, .groupWidth = 4 })
        )

        JQR_TO_STRING
        JQR_OSTREAM
        JQR_COMP_EQ
    };

    using WriteAddress = Address;
    using ReadAddress = Address;

    struct ReadData {
        sc_bv_base id;
        sc_bv_base data;
        uint8_t resp;
        bool last;
        sc_bv_base user { sc_bv<32>(0) };

        JQR_DECL(
            ReadData,
            JQR_MEMBER(id, ScDumpOptions { .numrep = sc_dt::SC_HEX, .hasPrefix = true, .groupWidth = 4 }),
            JQR_MEMBER(data, ScDumpOptions { .numrep = sc_dt::SC_HEX, .hasPrefix = true, .groupWidth = 4 }),
            JQR_MEMBER(resp, o::dump_fmt { "{:#04b}" }),
            JQR_MEMBER(last, o::dump_fmt { "{:#03b}" }),
            JQR_MEMBER(user, ScDumpOptions { .numrep = sc_dt::SC_HEX, .hasPrefix = true, .groupWidth = 4 })
        )

        JQR_TO_STRING
        JQR_OSTREAM
        JQR_COMP_EQ
    };

    struct WriteData {
        sc_bv_base data;
        sc_bv_base strb;
        bool last;
        sc_bv_base user { sc_bv<32>(0) };

        JQR_DECL(
            WriteData,
            JQR_MEMBER(data, ScDumpOptions { .numrep = sc_dt::SC_HEX, .hasPrefix = true, .groupWidth = 4 }),
            JQR_MEMBER(strb, ScDumpOptions { .numrep = sc_dt::SC_BIN, .hasPrefix = true, .groupWidth = 4 }),
            JQR_MEMBER(last, o::dump_fmt { "{:#03b}" }),
            JQR_MEMBER(user, ScDumpOptions { .numrep = sc_dt::SC_HEX, .hasPrefix = true, .groupWidth = 4 })
        )

        JQR_TO_STRING
        JQR_OSTREAM
        JQR_COMP_EQ
    };

    struct WriteResponse {
        sc_bv_base id;
        uint8_t resp;
        sc_bv_base user { sc_bv<32>(0) };

        JQR_DECL(
            WriteResponse,
            JQR_MEMBER(id, ScDumpOptions { .numrep = sc_dt::SC_HEX, .hasPrefix = true, .groupWidth = 4 }),
            JQR_MEMBER(resp, o::dump_fmt { "{:#04b}" }),
            JQR_MEMBER(user, ScDumpOptions { .numrep = sc_dt::SC_HEX, .hasPrefix = true, .groupWidth = 4 })
        )

        JQR_TO_STRING
        JQR_OSTREAM
        JQR_COMP_EQ
    };
};

} // namespace detail

using detail::Packets;

} // namespace chext_test::amba::axi4::full

#endif /* CHEXT_TEST_AMBA_AXI4_FULL_PACKETS_HPP_INCLUDED */

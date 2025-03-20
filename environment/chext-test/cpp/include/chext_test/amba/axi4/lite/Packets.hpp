#ifndef CHEXT_TEST_AMBA_AXI4_LITE_PACKETS_HPP_INCLUDED
#define CHEXT_TEST_AMBA_AXI4_LITE_PACKETS_HPP_INCLUDED

#include <systemc>

#include <jqr/comp_eq.hpp>
#include <jqr/dump.hpp>

namespace chext_test::amba::axi4::lite {

namespace detail {

using sc_dt::sc_bv_base;

using std::uint8_t;

namespace o = jqr::opts;
using chext_test::util::ScDumpOptions;

struct Packets {
    struct Address {
        sc_bv_base addr;
        uint8_t prot;

        JQR_DECL(
            Address,
            JQR_MEMBER(addr, ScDumpOptions { .numrep = sc_dt::SC_HEX, .hasPrefix = true, .groupWidth = 4 }),
            JQR_MEMBER(prot, o::dump_fmt { "{:#06b}" })
        )

        JQR_TO_STRING
        JQR_OSTREAM
        JQR_COMP_EQ
    };

    using WriteAddress = Address;
    using ReadAddress = Address;

    struct ReadData {
        sc_bv_base data;
        uint8_t resp;

        JQR_DECL(
            ReadData,
            JQR_MEMBER(data, ScDumpOptions { .numrep = sc_dt::SC_HEX, .hasPrefix = true, .groupWidth = 4 }),
            JQR_MEMBER(resp, o::dump_fmt { "{:#04b}" })
        )

        JQR_TO_STRING
        JQR_OSTREAM
        JQR_COMP_EQ
    };

    struct WriteData {
        sc_bv_base data;
        sc_bv_base strb;

        JQR_DECL(
            WriteData,
            JQR_MEMBER(data, ScDumpOptions { .numrep = sc_dt::SC_HEX, .hasPrefix = true, .groupWidth = 4 }),
            JQR_MEMBER(strb, ScDumpOptions { .numrep = sc_dt::SC_HEX, .hasPrefix = true, .groupWidth = 4 })
        )

        JQR_TO_STRING
        JQR_OSTREAM
        JQR_COMP_EQ
    };

    struct WriteResponse {
        uint8_t resp;

        JQR_DECL(
            WriteResponse,
            JQR_MEMBER(resp, o::dump_fmt { "{:#04b}" })
        )

        JQR_TO_STRING
        JQR_OSTREAM
        JQR_COMP_EQ
    };
};

} // namespace detail

using detail::Packets;

} // namespace chext_test::amba::axi4::lite

#endif /* CHEXT_TEST_AMBA_AXI4_LITE_PACKETS_HPP_INCLUDED */

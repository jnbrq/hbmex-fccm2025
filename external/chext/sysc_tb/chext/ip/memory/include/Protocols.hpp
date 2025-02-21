#include <systemc>

#include <jqr/comp_eq.hpp>
#include <jqr/core.hpp>
#include <jqr/dump.hpp>
#include <jqr/hash.hpp>

#include <chext_test/util/ScDump.hpp>

namespace protocols {

template<typename T>
using Signal = sc_core::sc_signal<T, sc_core::SC_MANY_WRITERS>;

static constexpr auto dumpOptions = chext_test::util::ScDumpOptions {
    .numrep = sc_dt::SC_HEX,
    .hasPrefix = true,
    .groupWidth = 4
};

struct ReadRequest {
    sc_dt::sc_bv_base addr;

    JQR_DECL(
        ReadRequest,
        JQR_MEMBER(addr, dumpOptions)
    )

    JQR_TO_STRING
    JQR_OSTREAM
    JQR_COMP_EQ
};

template<unsigned wAddr>
struct ReadRequestSignals {
    using value_type = ReadRequest;

    Signal<sc_dt::sc_bv<wAddr>> addr;
};

struct ReadResponse {
    sc_dt::sc_bv_base data;

    JQR_DECL(
        ReadResponse,
        JQR_MEMBER(data, dumpOptions)
    )

    JQR_TO_STRING
    JQR_OSTREAM
    JQR_COMP_EQ
};

template<unsigned wData>
struct ReadResponseSignals {
    using value_type = ReadResponse;

    Signal<sc_dt::sc_bv<wData>> data;
};

struct WriteRequest {
    sc_dt::sc_bv_base addr;
    sc_dt::sc_bv_base data;
    sc_dt::sc_bv_base strb;

    JQR_DECL(
        WriteRequest,
        JQR_MEMBER(addr, dumpOptions),
        JQR_MEMBER(data, dumpOptions),
        JQR_MEMBER(strb, dumpOptions)
    )

    JQR_TO_STRING
    JQR_OSTREAM
    JQR_COMP_EQ
};

template<unsigned wAddr, unsigned wData>
struct WriteRequestSignals {
    using value_type = WriteRequest;

    Signal<sc_dt::sc_bv<wAddr>> addr;
    Signal<sc_dt::sc_bv<wData>> data;
    Signal<sc_dt::sc_bv<(wData >> 3)>> strb;
};

struct WriteResponse {
    JQR_DECL(
        WriteResponse
    )

    JQR_TO_STRING
    JQR_OSTREAM
    JQR_COMP_EQ
};

struct WriteResponseSignals {
    using value_type = WriteResponse;

    // nothing
};

} // namespace protocols

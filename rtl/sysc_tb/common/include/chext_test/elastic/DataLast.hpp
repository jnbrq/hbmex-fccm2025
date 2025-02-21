#ifndef CHEXT_TEST_ELASTIC_DATALAST_HPP_INCLUDED
#define CHEXT_TEST_ELASTIC_DATALAST_HPP_INCLUDED

#include <chext_test/util/ScDump.hpp>

#include <jqr/comp_eq.hpp>
#include <jqr/dump.hpp>

#include <systemc>

namespace chext_test::elastic {

struct DataLast {
    sc_dt::sc_bv_base data;
    bool last;

    JQR_DECL(
        DataLast,
        JQR_MEMBER(
            data,
            chext_test::util::ScDumpOptions {
                .numrep = sc_dt::SC_HEX,
                .hasPrefix = true,
                .groupWidth = 4 }
        ),
        JQR_MEMBER(last)
    )

    JQR_TO_STRING
    JQR_OSTREAM
    JQR_COMP_EQ
};

template<unsigned W>
struct DataLastSignals {
    using value_type = DataLast;

    sc_core::sc_signal<sc_dt::sc_bv<W>> data;
    sc_core::sc_signal<bool> last;

    DataLastSignals(const char* name)
        : data(fmt::format("{}_data", name).c_str())
        , last(fmt::format("{}_last", name).c_str()) {}

    void writeFrom(value_type const& packet) {
        data.write(packet.data);
        last.write(packet.last);
    }

    void readTo(value_type& packet) const {
        packet.~value_type();

        new (&packet) value_type {
            .data = data.read(),
            .last = last.read()
        };
    }
};

} // namespace chext_test::elastic

#endif // CHEXT_TEST_ELASTIC_DATALAST_HPP_INCLUDED

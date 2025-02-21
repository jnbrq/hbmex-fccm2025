#ifndef PROTOCOLS_HPP_INCLUDED
#define PROTOCOLS_HPP_INCLUDED

#include <jqr/comp_eq.hpp>
#include <jqr/dump.hpp>

#include <systemc>

struct ReadStreamTask {
    uint64_t address;
    uint64_t length;

    JQR_DECL(
        ReadStreamTask,
        JQR_MEMBER(address),
        JQR_MEMBER(length)
    )

    JQR_TO_STRING
    JQR_OSTREAM
    JQR_COMP_EQ
};

struct ReadStreamTaskSignals {
    using value_type = ReadStreamTask;

    sc_core::sc_signal<sc_dt::sc_bv<64>> address;
    sc_core::sc_signal<sc_dt::sc_bv<64>> length;

    ReadStreamTaskSignals(const char* name)
        : address(fmt::format("{}_address", name).c_str())
        , length(fmt::format("{}_length", name).c_str()) {}

    void writeFrom(value_type const& packet) {
        address.write(packet.address);
        length.write(packet.length);
    }

    void readTo(value_type& packet) const {
        packet.~value_type();

        new (&packet) value_type {
            .address = address.read().to_uint64(),
            .length = length.read().to_uint64()
        };
    }
};

struct WriteStreamTask {
    uint64_t address;
    uint64_t length;

    JQR_DECL(
        WriteStreamTask,
        JQR_MEMBER(address),
        JQR_MEMBER(length)
    )

    JQR_TO_STRING
    JQR_OSTREAM
    JQR_COMP_EQ
};

struct WriteStreamTaskSignals {
    using value_type = WriteStreamTask;

    sc_core::sc_signal<sc_dt::sc_bv<64>> address;
    sc_core::sc_signal<sc_dt::sc_bv<64>> length;

    WriteStreamTaskSignals(const char* name)
        : address(fmt::format("{}_address", name).c_str())
        , length(fmt::format("{}_length", name).c_str()) {}

    void writeFrom(value_type const& packet) {
        address.write(packet.address);
        length.write(packet.length);
    }

    void readTo(value_type& packet) const {
        packet.~value_type();

        new (&packet) value_type {
            .address = address.read().to_uint64(),
            .length = length.read().to_uint64()
        };
    }
};

#endif // PROTOCOLS_HPP_INCLUDED

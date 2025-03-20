#ifndef CHEXT_TEST_UTIL_READYVALID_HPP_INCLUDED
#define CHEXT_TEST_UTIL_READYVALID_HPP_INCLUDED

#include <chext_test/util/BoolWrapper.hpp>
#include <chext_test/util/Exception.hpp>
#include <systemc>

namespace chext_test::util {

template<bool PosEdgeClock = true, bool ActiveHighReset = true>
struct ReadyValid {
    template<
        typename ClockT,
        typename ResetT,
        typename ReadyT,
        typename ValidT,
        typename PokeDataFn //
        >
    static inline void send(
        ClockT const& clock,
        ResetT const& reset,
        ReadyT const& ready,
        ValidT& valid,
        PokeDataFn pokeDataFn
    ) {
        auto clock_ = constBoolWrapper<!PosEdgeClock>(clock);
        auto reset_ = constBoolWrapper<!ActiveHighReset>(reset);

        // wait until all the transitions happen
        sc_core::wait(sc_core::SC_ZERO_TIME);

        // if the clock is high, it is after a posedge
        while (clock_.read() || reset_.read())
            sc_core::wait(clock_.negedge_event());

        // we attempt sending the packet at negedge
        pokeDataFn();
        valid.write(true);

        do {
            sc_core::wait(reset_.posedge_event() | clock_.posedge_event());
        } while (!ready.read() || reset_.read());

        if (reset_.read())
            throw Exception("Reset asserted during transmission!");

        sc_core::wait(clock_.negedge_event());

        // we stop asserting the valid at negedge
        valid.write(false);
    }

    template<
        typename ClockT,
        typename ResetT,
        typename ReadyT,
        typename ValidT,
        typename PeekDataFn //
        >
    static inline void receive(
        ClockT const& clock,
        ResetT const& reset,
        ReadyT& ready,
        ValidT const& valid,
        PeekDataFn peekDataFn
    ) {
        auto clock_ = constBoolWrapper<!PosEdgeClock>(clock);
        auto reset_ = constBoolWrapper<!ActiveHighReset>(reset);

        sc_core::wait(sc_core::SC_ZERO_TIME);

        while (clock_.read() || reset_.read())
            sc_core::wait(clock_.negedge_event());

        ready.write(true);

        do {
            sc_core::wait(reset_.posedge_event() | clock_.posedge_event());
        } while (!valid.read() || reset_.read());

        if (reset_.read())
            throw Exception("Reset asserted during transmission!");

        peekDataFn();

        sc_core::wait(clock_.negedge_event());
        ready.write(false);
    }
};

}; // namespace chext_test::util

#endif /* CHEXT_TEST_UTIL_READYVALID_HPP_INCLUDED */

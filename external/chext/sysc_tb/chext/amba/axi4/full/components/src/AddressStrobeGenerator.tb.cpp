#define SC_ALLOW_DEPRECATED_IEEE_API

#include <AddressStrobeGeneratorTestTop1_1.hpp>
#include <chext_test/chext_test.hpp>

using namespace sc_core;
using namespace sc_dt;
using namespace chext_test;

using namespace protocols;

// TODO make these ones an enum later (and include in protocol?)
// The same goes for other flags, too.
#define BURST_FIXED 0
#define BURST_INCR 1
#define BURST_WRAP 2

class AddressStrobeGeneratorTestbench : public TestBenchBase {
public:
    SC_HAS_PROCESS(AddressStrobeGeneratorTestbench);

    AddressStrobeGeneratorTestbench()
        : TestBenchBase(sc_module_name("tb"))
        , dut { "dut" }
        , clock { "clock", 2.0, SC_NS }
        , reset { "reset" } {

        dut.clock(clock);
        dut.reset(reset);
    }

private:
    AddressStrobeGeneratorTestTop1_1 dut;

    sc_clock clock;
    sc_signal<bool> reset;

    void entry() override {
        test1();

        finish();
    }

    void testName(const char* name) {
        fmt::print("{:=^100}\n", fmt::format(" {} ", name));
    }

    void runTest(std::vector<AddrLenSizeBurst> const& sourcePackets, std::vector<AddrSizeStrobeLast> const& sinkPackets) {
        resetDut();

        sc_join j;

        SC_SPAWN_TO(j) {
            for (auto const& sourcePacket : sourcePackets) {
                fmt::print("{:>12} {:70} @t={}\n", "Sent: ", sourcePacket, sc_time_stamp().to_string());
                dut.source.send(sourcePacket);
            }
        };

        SC_SPAWN_TO(j) {
            for (auto const& expectedSinkPacket : sinkPackets) {
                auto sinkPacket = dut.sink.receive();
                fmt::print("{:>12} {:70} @t={}\n", "Received: ", sinkPacket, sc_time_stamp().to_string());
                EXPECT_EQ(sinkPacket, expectedSinkPacket);
            }
        };

        j.wait();

        fmt::print("\n");
    }

    void test1() {
        testName("chext.amba.axi4.full.components.AddressStrobeGenerator.INCR (32B)");

        std::vector<AddrLenSizeBurst> sourcePackets;
        std::vector<AddrSizeStrobeLast> sinkPackets;

        sourcePackets.push_back(AddrLenSizeBurst { .addr = sc_bv<32>(0x3000), .len = 0, .size = 0, .burst = 1 });
        sourcePackets.push_back(AddrLenSizeBurst { .addr = sc_bv<32>(0x5024), .len = 1, .size = 0, .burst = 1 });
        sourcePackets.push_back(AddrLenSizeBurst { .addr = sc_bv<32>(0x6008), .len = 3, .size = 0, .burst = 1 });
        sourcePackets.push_back(AddrLenSizeBurst { .addr = sc_bv<32>(0xA000), .len = 3, .size = 3, .burst = 1 });
        sourcePackets.push_back(AddrLenSizeBurst { .addr = sc_bv<32>(0xA001), .len = 3, .size = 3, .burst = 1 });
        sourcePackets.push_back(AddrLenSizeBurst { .addr = sc_bv<32>(0xA009), .len = 1, .size = 3, .burst = 1 });

        sinkPackets.push_back(AddrSizeStrobeLast { sc_bv<32>(0x3000), 0, sc_bv<16>(0x0001), sc_bv<4>(0), sc_bv<4>(0), true });

        sinkPackets.push_back(AddrSizeStrobeLast { sc_bv<32>(0x5024), 0, sc_bv<16>(0x0010), sc_bv<4>(4), sc_bv<4>(4), false });
        sinkPackets.push_back(AddrSizeStrobeLast { sc_bv<32>(0x5025), 0, sc_bv<16>(0x0020), sc_bv<4>(5), sc_bv<4>(5), true });

        sinkPackets.push_back(AddrSizeStrobeLast { sc_bv<32>(0x6008), 0, sc_bv<16>(0x0100), sc_bv<4>(8), sc_bv<4>(8), false });
        sinkPackets.push_back(AddrSizeStrobeLast { sc_bv<32>(0x6009), 0, sc_bv<16>(0x0200), sc_bv<4>(9), sc_bv<4>(9), false });
        sinkPackets.push_back(AddrSizeStrobeLast { sc_bv<32>(0x600a), 0, sc_bv<16>(0x0400), sc_bv<4>(10), sc_bv<4>(10), false });
        sinkPackets.push_back(AddrSizeStrobeLast { sc_bv<32>(0x600b), 0, sc_bv<16>(0x0800), sc_bv<4>(11), sc_bv<4>(11), true });

        sinkPackets.push_back(AddrSizeStrobeLast { sc_bv<32>(0xA000), 3, sc_bv<16>(0x00FF), sc_bv<4>(0), sc_bv<4>(7), false });
        sinkPackets.push_back(AddrSizeStrobeLast { sc_bv<32>(0xA008), 3, sc_bv<16>(0xFF00), sc_bv<4>(8), sc_bv<4>(15), false });
        sinkPackets.push_back(AddrSizeStrobeLast { sc_bv<32>(0xA010), 3, sc_bv<16>(0x00FF), sc_bv<4>(0), sc_bv<4>(7), false });
        sinkPackets.push_back(AddrSizeStrobeLast { sc_bv<32>(0xA018), 3, sc_bv<16>(0xFF00), sc_bv<4>(8), sc_bv<4>(15), true });

        sinkPackets.push_back(AddrSizeStrobeLast { sc_bv<32>(0xA001), 3, sc_bv<16>(0x00FE), sc_bv<4>(1), sc_bv<4>(7), false });
        sinkPackets.push_back(AddrSizeStrobeLast { sc_bv<32>(0xA008), 3, sc_bv<16>(0xFF00), sc_bv<4>(8), sc_bv<4>(15), false });
        sinkPackets.push_back(AddrSizeStrobeLast { sc_bv<32>(0xA010), 3, sc_bv<16>(0x00FF), sc_bv<4>(0), sc_bv<4>(7), false });
        sinkPackets.push_back(AddrSizeStrobeLast { sc_bv<32>(0xA018), 3, sc_bv<16>(0xFF00), sc_bv<4>(8), sc_bv<4>(15), true });

        sinkPackets.push_back(AddrSizeStrobeLast { sc_bv<32>(0xA009), 3, sc_bv<16>(0xFE00), sc_bv<4>(9), sc_bv<4>(15), false });
        sinkPackets.push_back(AddrSizeStrobeLast { sc_bv<32>(0xA010), 3, sc_bv<16>(0x00FF), sc_bv<4>(0), sc_bv<4>(7), true });

        runTest(sourcePackets, sinkPackets);
    }

    void resetDut() {
        wait(clock.negedge_event());
        reset.write(true);

        wait(clock.negedge_event());
        wait(clock.negedge_event());

        reset.write(false);

        wait(clock.negedge_event());
    }
};

int sc_main(int argc, char** argv) {
    AddressStrobeGeneratorTestbench tb;
    tb.start();

    return 0;
}

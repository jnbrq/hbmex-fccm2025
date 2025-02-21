#define SC_ALLOW_DEPRECATED_IEEE_API

#include <AddressGeneratorTestTop1_1.hpp>
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

class AddressGeneratorTestbench : public TestBenchBase {
public:
    SC_HAS_PROCESS(AddressGeneratorTestbench);

    AddressGeneratorTestbench()
        : TestBenchBase(sc_module_name("tb"))
        , dut { "dut" }
        , clock { "clock", 2.0, SC_NS }
        , reset { "reset" } {

        dut.clock(clock);
        dut.reset(reset);
    }

private:
    AddressGeneratorTestTop1_1 dut;

    sc_clock clock;
    sc_signal<bool> reset;

    void entry() override {
        test1();
        test2();
        test3();

        finish();
    }

    void testName(const char* name) {
        fmt::print("{:=^100}\n", fmt::format(" {} ", name));
    }

    void runTest(std::vector<AddrLenSizeBurst> const& sourcePackets, std::vector<AddrSizeLast> const& sinkPackets) {
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
        testName("chext.amba.axi4.full.components.AddressGenerator.INCR");

        std::vector<AddrLenSizeBurst> sourcePackets;
        std::vector<AddrSizeLast> sinkPackets;

        sourcePackets.push_back(AddrLenSizeBurst { .addr = sc_bv<32>(0x3000), .len = 0, .size = 4, .burst = 1 });
        sourcePackets.push_back(AddrLenSizeBurst { .addr = sc_bv<32>(0x5024), .len = 1, .size = 4, .burst = 1 });
        sourcePackets.push_back(AddrLenSizeBurst { .addr = sc_bv<32>(0x6008), .len = 3, .size = 4, .burst = 1 });
        sourcePackets.push_back(AddrLenSizeBurst { .addr = sc_bv<32>(0x7000), .len = 7, .size = 4, .burst = 1 });
        sourcePackets.push_back(AddrLenSizeBurst { .addr = sc_bv<32>(0x8000), .len = 15, .size = 4, .burst = 1 });
        sourcePackets.push_back(AddrLenSizeBurst { .addr = sc_bv<32>(0xa000), .len = 255, .size = 4, .burst = 1 });

        sinkPackets.push_back(AddrSizeLast { .addr = sc_bv<32>(0x3000), .size = 4, .last = true });
        sinkPackets.push_back(AddrSizeLast { .addr = sc_bv<32>(0x5024), .size = 4, .last = false });
        sinkPackets.push_back(AddrSizeLast { .addr = sc_bv<32>(0x5030), .size = 4, .last = true });

        sinkPackets.push_back(AddrSizeLast { .addr = sc_bv<32>(0x6008), .size = 4, .last = false });
        for (int i = 0; i < 3; ++i)
            sinkPackets.push_back(AddrSizeLast { .addr = sc_bv<32>(0x6010 + i * 0x10), .size = 4, .last = i == 2 });

        for (int i = 0; i < 8; ++i)
            sinkPackets.push_back(AddrSizeLast { .addr = sc_bv<32>(0x7000 + i * 0x10), .size = 4, .last = i == 7 });

        for (int i = 0; i < 16; ++i)
            sinkPackets.push_back(AddrSizeLast { .addr = sc_bv<32>(0x8000 + i * 0x10), .size = 4, .last = i == 15 });

        for (int i = 0; i < 256; ++i)
            sinkPackets.push_back(AddrSizeLast { .addr = sc_bv<32>(0xa000 + i * 0x10), .size = 4, .last = i == 255 });

        runTest(sourcePackets, sinkPackets);
    }

    void test2() {
        testName("chext.amba.axi4.full.components.AddressGenerator.WRAP");

        std::vector<AddrLenSizeBurst> sourcePackets;
        std::vector<AddrSizeLast> sinkPackets;

        sourcePackets.push_back(AddrLenSizeBurst { .addr = sc_bv<32>(0xa010), .len = 3, .size = 4, .burst = 2 });

        sinkPackets.push_back(AddrSizeLast { .addr = sc_bv<32>(0xa010), .size = 4, .last = false });
        sinkPackets.push_back(AddrSizeLast { .addr = sc_bv<32>(0xa020), .size = 4, .last = false });
        sinkPackets.push_back(AddrSizeLast { .addr = sc_bv<32>(0xa030), .size = 4, .last = false });
        sinkPackets.push_back(AddrSizeLast { .addr = sc_bv<32>(0xa000), .size = 4, .last = true });

        runTest(sourcePackets, sinkPackets);
    }

    void test3() {
        testName("chext.amba.axi4.full.components.AddressGenerator.FIXED");

        std::vector<AddrLenSizeBurst> sourcePackets;
        std::vector<AddrSizeLast> sinkPackets;

        sourcePackets.push_back(AddrLenSizeBurst { .addr = sc_bv<32>(0xa010), .len = 3, .size = 4, .burst = 0 });

        sinkPackets.push_back(AddrSizeLast { .addr = sc_bv<32>(0xa010), .size = 4, .last = false });
        sinkPackets.push_back(AddrSizeLast { .addr = sc_bv<32>(0xa010), .size = 4, .last = false });
        sinkPackets.push_back(AddrSizeLast { .addr = sc_bv<32>(0xa010), .size = 4, .last = false });
        sinkPackets.push_back(AddrSizeLast { .addr = sc_bv<32>(0xa010), .size = 4, .last = true });

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
    AddressGeneratorTestbench tb;
    tb.start();

    return 0;
}

#include <DownscaleTestTop1_1.hpp>
#include <DownscaleTestTop1_2.hpp>

#include <verilated_vcd_sc.h>

#include <ReadWriteTester.hpp>
#include <chext_test/chext_test.hpp>

#include <systemc>

using namespace sc_core;
using namespace sc_dt;

using namespace chext_test;
using namespace chext_test::amba;

struct DownscaleTestbench : virtual TestBenchBase, axi4::full::ReadWriteTester {
    SC_HAS_PROCESS(DownscaleTestbench);

    DownscaleTestbench()
        : TestBenchBase(sc_module_name("tb"))
        , dut1 { "dut1" }
        , dut2 { "dut2" }
        , clock { "clock", 2.0, SC_NS }
        , reset { "reset" } {

        dut1.clock(clock);
        dut1.reset(reset);

        dut2.clock(clock);
        dut2.reset(reset);
    }

    DownscaleTestTop1_1 dut1;
    DownscaleTestTop1_2 dut2;

private:
    sc_clock clock;
    sc_signal<bool> reset;

    void entry() override {
        SC_SPAWN {
            while (true) {
                fmt::print("\r{:=^100}", fmt::format("  t = {}  ", sc_time_stamp().to_string()));
                std::cout.flush();
                wait(100, SC_US);
            }
        };

        resetDUTs();

        readWriteTest(dut1.S_AXI_TEST, dut1.S_AXI_TEST, 0x00, 1024);
        readWriteTest(dut1.S_AXI_NORMAL, dut1.S_AXI_TEST, 0x00, 1024);
        readWriteTest(dut1.S_AXI_TEST, dut1.S_AXI_NORMAL, 0x00, 1024);

        readWriteTest(dut2.S_AXI_TEST, dut2.S_AXI_TEST, 0x00, 1024);
        readWriteTest(dut2.S_AXI_NORMAL, dut2.S_AXI_TEST, 0x00, 1024);
        readWriteTest(dut2.S_AXI_TEST, dut2.S_AXI_NORMAL, 0x00, 1024);

        fmt::print("\r{:~^100}\n", fmt::format("  simulation time: {}  ", sc_time_stamp().to_string()));

        finish();
    }

    void resetDUTs() {
        wait(clock.negedge_event());
        reset.write(true);

        wait(clock.negedge_event());
        wait(clock.negedge_event());

        reset.write(false);

        wait(clock.negedge_event());
    }
};

int sc_main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    DownscaleTestbench testBench;

    sc_start(SC_ZERO_TIME);

    std::unique_ptr<VerilatedVcdSc> trace_file = std::make_unique<VerilatedVcdSc>();
    testBench.dut1.traceVerilated(trace_file.get(), 99);
    testBench.dut2.traceVerilated(trace_file.get(), 99);
    trace_file->open("DownscaleTestbench.vcd");

    testBench.start();

    trace_file->close();

    return 0;
}

#include <IdSerializeTestTop1_1.hpp>

#include <verilated_vcd_sc.h>

#include <ReadWriteTester.hpp>
#include <chext_test/chext_test.hpp>

#include <systemc>

using namespace sc_core;
using namespace sc_dt;

using namespace chext_test;
using namespace chext_test::amba;

struct IdSerializeTestbench : virtual TestBenchBase, axi4::full::ReadWriteTester {
    SC_HAS_PROCESS(IdSerializeTestbench);

    IdSerializeTestbench()
        : TestBenchBase(sc_module_name("tb"))
        , dut { "dut" }
        , clock { "clock", 2.0, SC_NS }
        , reset { "reset" } {

        dut.clock(clock);
        dut.reset(reset);
    }

    IdSerializeTestTop1_1 dut;

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

        readWriteTest(dut.S_AXI_TEST, dut.S_AXI_TEST, 0x00, 1024);
        readWriteTest(dut.S_AXI_NORMAL, dut.S_AXI_TEST, 0x00, 1024);
        readWriteTest(dut.S_AXI_TEST, dut.S_AXI_NORMAL, 0x00, 1024);

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

    IdSerializeTestbench testBench;

    sc_start(SC_ZERO_TIME);

    std::unique_ptr<VerilatedVcdSc> trace_file = std::make_unique<VerilatedVcdSc>();
    testBench.dut.traceVerilated(trace_file.get(), 99);
    trace_file->open("IdSerializeTestbench.vcd");

    testBench.start();

    trace_file->close();

    return 0;
}

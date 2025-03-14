#include <ReadEngineTop1_1.hpp>

#include <systemc>

using namespace sc_core;
using namespace sc_dt;

#include <read_engine/ReadEngine.hpp>

#include <verilated_vcd_sc.h>

#include <chext_test/TestBench.hpp>

#include <chext_test/amba/axi4/full/hal.hpp>
#include <chext_test/amba/axi4/lite/hal.hpp>
#include <chext_test/util/hal.hpp>

#include <fmt/format.h>

#include <memory>

struct MyTestBench : chext_test::TestBenchBase {
    SC_HAS_PROCESS(MyTestBench);

    MyTestBench()
        : TestBenchBase {}
        , clock { "clock", 2.0, sc_core::SC_NS }
        , reset { "reset" }
        , dut { "dut" } {
        dut.clock(clock);
        dut.reset(reset);

        S_AXI_CTRL = chext_test::amba::axi4::lite::wrapSlave(dut.S_AXI_CTRL);
        S_AXI_DESC = chext_test::amba::axi4::full::wrapSlave(dut.S_AXI_DESC);
        S_AXI_DATA = chext_test::amba::axi4::full::wrapSlave(dut.S_AXI_DATA);
    }

    virtual ~MyTestBench() = default;

    sc_clock clock;
    sc_signal<bool> reset;

    ReadEngineTop1_1 dut;

protected:
    std::shared_ptr<hal::Memory> S_AXI_CTRL;
    std::shared_ptr<hal::Memory> S_AXI_DESC;
    std::shared_ptr<hal::Memory> S_AXI_DATA;

    void entry() override {
        resetDut();

        read_engine::ReadEngine readEngine(
            read_engine::Config { .log2numDesc = 12 },
            S_AXI_CTRL,
            S_AXI_DESC,
            chext_test::util::halSleep
        );

        read_engine::Desc descs[] = {
            read_engine::Desc::mkAddr(0x1000, 0x1, 15),
            read_engine::Desc::mkAddr(0x2000, 0x2, 15),
            read_engine::Desc::mkAddr(0x3000, 0x3, 15)
        };

        readEngine.copyDesc(descs, 3, 0, true);
        readEngine.task(0, 3);
        readEngine.start();

        readEngine.waitUntilComplete();

        finish();
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
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    MyTestBench testBench;

    sc_start(SC_ZERO_TIME);

    std::unique_ptr<VerilatedVcdSc> trace_file = std::make_unique<VerilatedVcdSc>();
    testBench.dut.traceVerilated(trace_file.get(), 99);
    trace_file->open(fmt::format("{}.vcd", "ReadEngineTop1_1").c_str());

    testBench.start();

    trace_file->close();

    return 0;
}

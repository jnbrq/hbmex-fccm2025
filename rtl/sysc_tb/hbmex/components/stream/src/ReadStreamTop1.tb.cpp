#include <chext_test/chext_test.hpp>
#include <chext_test/util/Spawn.hpp>
#include <systemc>
#include <verilated_vcd_sc.h>

#include <ReadStreamTop1_1.hpp>

using namespace chext_test;
using namespace sc_core;
using namespace sc_dt;

class TestBench : public chext_test::TestBenchBase {
public:
    SC_HAS_PROCESS(TestBench);

    TestBench()
        : TestBenchBase(sc_module_name("tb"))
        , dut { "dut" }
        , clock { "clock", 2.0, SC_NS }
        , reset { "reset" } {

        dut.clock(clock);
        dut.reset(reset);
    }

    ReadStreamTop1_1 dut;

private:
    sc_clock clock;
    sc_signal<bool> reset;

    void entry() override {
        resetDut();

        sc_join j;
        constexpr auto length = 4096;

        SC_SPAWN_TO(j) {
            /* these should be skipped */
            dut.sourceTask.send({ .address = 0x0'D8000, .length = 0 });
            dut.sourceTask.send({ .address = 0x0'D8000, .length = 0 });
            dut.sourceTask.send({ .address = 0x0'D8000, .length = 0 });
            dut.sourceTask.send({ .address = 0x0'D8000, .length = 0 });

            dut.sourceTask.send({ .address = 0x0'8000, .length = length });
            dut.sourceTask.send({ .address = 0x2'8000, .length = length });
            dut.sourceTask.send({ .address = 0x0A'8000, .length = 1 });
            dut.sourceTask.send({ .address = 0x0B'8000, .length = 1 });
            dut.sourceTask.send({ .address = 0x0C'8000, .length = 1 });
            dut.sourceTask.send({ .address = 0x0D'8000, .length = 1 });
            dut.sourceTask.send({ .address = 0x0E'8000, .length = 1 });
            dut.sourceTask.send({ .address = 0x0F'8000, .length = 1 });
            dut.sourceTask.send({ .address = 0x10'8000, .length = 1 });
            dut.sourceTask.send({ .address = 0x20'8000, .length = 1 });
        };

        SC_SPAWN_TO(j) {
            for (unsigned i = 0; i < length; ++i) {
                fmt::print("[{}]: 0x{:016x}\n", i, dut.sinkData.receive().to_uint64());
            }

            for (unsigned i = 0; i < length; ++i) {
                fmt::print("[{}]: 0x{:016x}\n", i, dut.sinkData.receive().to_uint64());
            }

            for (unsigned i = 0; i < 8; ++i) {
                fmt::print("[{}]: 0x{:016x}\n", i, dut.sinkData.receive().to_uint64());
            }
        };

        j.wait();

        finish();
    }

    void testName(const char* name) {
        fmt::print("{:=^100}\n", fmt::format(" {} ", name));
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

    TestBench tb;

    sc_start(SC_ZERO_TIME);

    std::unique_ptr<VerilatedVcdSc> trace_file = std::make_unique<VerilatedVcdSc>();
    tb.dut.traceVerilated(trace_file.get(), 99);
    trace_file->open(fmt::format("{}.vcd", "ReadStreamTop1").c_str());

    tb.start();

    trace_file->close();

    return 0;
}

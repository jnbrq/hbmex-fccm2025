#include <chext_test/chext_test.hpp>
#include <chext_test/util/Spawn.hpp>
#include <systemc>
#include <verilated_vcd_sc.h>

#include <RowReduceTop.hpp>

using namespace chext_test;
using namespace sc_core;
using namespace sc_dt;

inline sc_bv<32> fp32_to_bv(float f) {
    static_assert(sizeof(f) == 4);
    std::uint32_t cast = *reinterpret_cast<std::uint32_t*>(&f);
    return { cast };
}

inline float bv_to_fp32(const sc_bv<32>& bv) {
    static_assert(sizeof(float) == 4);
    std::uint32_t bits = bv.to_uint();
    return *reinterpret_cast<float*>(&bits);
}

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

    RowReduceTop dut;

private:
    sc_clock clock;
    sc_signal<bool> reset;

    void entry() override {
        resetDut();

        sc_join j;

#if 0
        SC_SPAWN_TO(j) {
            for (unsigned i = 0; i < 100; ++i) {
                dut.sourceElem.send(fp32_to_bv(4.1));
                dut.sourceElem.send(fp32_to_bv(8.0));
                dut.sourceElem.send(fp32_to_bv(20.8));
                dut.sourceElem.send(fp32_to_bv(5.0));
                dut.sourceElem.send(fp32_to_bv(5.0));
                dut.sourceElem.send(fp32_to_bv(5.0));
                dut.sourceElem.send(fp32_to_bv(3.1));
                dut.sourceElem.send(fp32_to_bv(4.1));
                dut.sourceElem.send(fp32_to_bv(8.0));
                dut.sourceElem.send(fp32_to_bv(20.8));
                dut.sourceElem.send(fp32_to_bv(5.0));
                dut.sourceElem.send(fp32_to_bv(5.0));
                dut.sourceElem.send(fp32_to_bv(5.0));
                dut.sourceElem.send(fp32_to_bv(3.1));
            }
        };

        SC_SPAWN_TO(j) {
            for (unsigned i = 0; i < 100; ++i) {
                dut.sourceCount.send(3);
                dut.sourceCount.send(4);
                dut.sourceCount.send(3);
                dut.sourceCount.send(4);
            }
        };

        SC_SPAWN_TO(j) {
            for (unsigned i = 0; i < 100; ++i) {
                fmt::print("received: {}\n", bv_to_fp32(dut.sinkResult.receive()));
                fmt::print("received: {}\n", bv_to_fp32(dut.sinkResult.receive()));
                fmt::print("received: {}\n", bv_to_fp32(dut.sinkResult.receive()));
                fmt::print("received: {}\n", bv_to_fp32(dut.sinkResult.receive()));
            }
        };

#endif

#if 0
        SC_SPAWN_TO(j) {
            for (unsigned i = 0; i < 100; ++i) {
                dut.sourceElem.send(fp32_to_bv(4.1));
                dut.sourceElem.send(fp32_to_bv(8.0));

                dut.sourceElem.send(fp32_to_bv(4.1));
                dut.sourceElem.send(fp32_to_bv(8.0));
                dut.sourceElem.send(fp32_to_bv(4.1));
                dut.sourceElem.send(fp32_to_bv(8.0));
                dut.sourceElem.send(fp32_to_bv(4.1));
                dut.sourceElem.send(fp32_to_bv(8.0));
                dut.sourceElem.send(fp32_to_bv(4.1));
                dut.sourceElem.send(fp32_to_bv(8.0));
            }
        };

        SC_SPAWN_TO(j) {
            for (unsigned i = 0; i < 100; ++i) {
                dut.sourceCount.send(2);
                dut.sourceCount.send(8);
            }
        };

        SC_SPAWN_TO(j) {
            for (unsigned i = 0; i < 100; ++i) {
                fmt::print("received: {}\n", bv_to_fp32(dut.sinkResult.receive()));
                fmt::print("received: {}\n", bv_to_fp32(dut.sinkResult.receive()));
            }
        };

#endif

#if 0
        SC_SPAWN_TO(j) {
            for (unsigned i = 0; i < 32; ++i) {
                for (unsigned j = 0; j < 1024; ++j) {
                    dut.sourceElem.send(fp32_to_bv(1.0));
                }
            }
        };

        SC_SPAWN_TO(j) {
            for (unsigned i = 0; i < 32; ++i) {
                dut.sourceCount.send(1024);
            }
        };

        SC_SPAWN_TO(j) {
            for (unsigned i = 0; i < 32; ++i) {
                fmt::print("received: {}\n", bv_to_fp32(dut.sinkResult.receive()));
            }
        };
#endif

#if 1
        constexpr unsigned I = 4096;
        constexpr unsigned J = 8;
        constexpr unsigned totalCount = I * J;

        SC_SPAWN_TO(j) {
            for (unsigned i = 0; i < I; ++i) {
                for (unsigned j = 0; j < J; ++j)
                    dut.sourceElem.send(fp32_to_bv(j * 2.2));
            }
        };

        SC_SPAWN_TO(j) {
            for (unsigned i = 0; i < I; ++i) {
                dut.sourceCount.send(J);
            }
        };

        SC_SPAWN_TO(j) {
            for (unsigned i = 0; i < I; ++i) {
                fmt::print("received: {}\n", bv_to_fp32(dut.sinkResult.receive()));
            }
        };
#endif

        j.wait();

        double totalCycles = sc_time_stamp().to_seconds() / (2e-9);
        double cyclesPerValue = totalCycles / totalCount;
        fmt::print("done: {} cycles, {} cycles/value\n", totalCycles, cyclesPerValue);

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
    trace_file->open(fmt::format("{}.vcd", "RowReduceTop").c_str());

    tb.start();

    trace_file->close();

    return 0;
}

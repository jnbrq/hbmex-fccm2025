#include <chext_test/chext_test.hpp>
#include <chext_test/util/Spawn.hpp>
#include <systemc>
#include <verilated_vcd_sc.h>

#include <random>

#include <WriteStreamTop1_1.hpp>

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

    WriteStreamTop1_1 dut;

private:
    sc_clock clock;
    sc_signal<bool> reset;

    void entry() override {
        resetDut();

        {
            testName("Random accesses");
            sc_join j;

            constexpr unsigned totalBeats = 5 << 10;
            constexpr unsigned totalTasks = 128;

            SC_SPAWN_TO(j) {
                std::random_device rd;
                std::mt19937 gen(rd());
                std::uniform_int_distribution<unsigned> dist(0, 10);

                unsigned sentBeats = 0;
                for (unsigned i = 0; i < totalTasks; ++i) {
                    unsigned length = (totalBeats / totalTasks) - dist(gen);

                    length = (i == totalTasks - 1)
                        ? (totalBeats - sentBeats)
                        : std::min(length, totalBeats - sentBeats);

                    dut.sourceWriteTask.send({ .address = sentBeats * 4, .length = length });
                    fmt::print("sent task: length = {}\n", length);

                    sentBeats += length;
                }
            };

            SC_SPAWN_TO(j) {
                for (unsigned i = 0; i < totalBeats; ++i) {
                    dut.sourceWriteData.send((i << 16) + i);
                }
            };

            SC_SPAWN_TO(j) {
                for (unsigned i = 0; i < totalTasks; ++i) {
                    fmt::print("received: {}, i = {}\n", dut.sinkWriteDone.receive().to_uint(), i);
                }
            };

            j.wait();

            SC_SPAWN_TO(j) {
                dut.sourceReadTask.send({ .address = 0, .length = totalBeats });
            };

            SC_SPAWN_TO(j) {
                for (unsigned i = 0; i < totalBeats; ++i) {
                    auto received = dut.sinkReadData.receive().to_uint();
                    auto expected = ((i << 16) + i);

                    fmt::print("i = {}: received = 0x{:08x}, expected = 0x{:08x}\n", i, received, expected);
                    ASSERT_EQ(received, expected);
                }
            };

            j.wait();
        }
        {
            testName("Corner cases");

            sc_join j;
            constexpr unsigned totalTasks = 270;
            unsigned sentBeats = 0;

            SC_SPAWN_TO(j) {

                for (unsigned i = 0; i < totalTasks; ++i) {
                    unsigned length = i;

                    dut.sourceWriteTask.send({ .address = sentBeats * 4, .length = length });
                    fmt::print("sent task: length = {}\n", length);

                    sentBeats += length;
                }
            };

            SC_SPAWN_TO(j) {
                for (unsigned i = 0; i < totalTasks; ++i) {
                    for (unsigned j = 0; j < i; ++j) {
                        dut.sourceWriteData.send((i << 16) + j);
                    }
                }
            };

            SC_SPAWN_TO(j) {
                for (unsigned i = 0; i < totalTasks; ++i) {
                    if (i == 0)
                        // no response will be received for length = 0
                        continue;

                    fmt::print("received: {}, i = {}\n", dut.sinkWriteDone.receive().to_uint(), i);
                }
            };

            j.wait();

            SC_SPAWN_TO(j) {
                dut.sourceReadTask.send({ .address = 0, .length = sentBeats });
            };

            SC_SPAWN_TO(j) {
                for (unsigned i = 0; i < totalTasks; ++i) {
                    for (unsigned j = 0; j < i; ++j) {
                        auto received = dut.sinkReadData.receive().to_uint();
                        auto expected = ((i << 16) + j);

                        fmt::print("i = {}, j = {}: received = 0x{:08x}, expected = 0x{:08x}\n", i, j, received, expected);
                        ASSERT_EQ(received, expected);
                    }
                }
            };

            j.wait();
        }

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
    trace_file->open(fmt::format("{}.vcd", "WriteStreamTop1").c_str());

    tb.start();

    trace_file->close();

    return 0;
}

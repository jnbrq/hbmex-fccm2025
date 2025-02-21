#include <chext_test/chext_test.hpp>
#include <chext_test/util/Spawn.hpp>
#include <systemc>
#include <verilated_vcd_sc.h>

#include <RowReduceSingleTop.hpp>

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

    RowReduceSingleTop dut;

private:
    sc_clock clock;
    sc_signal<bool> reset;

    void entry() override {
        resetDut();

        SC_SPAWN {
            dut.sourceElem.send({ .data = fp32_to_bv(4.1), .last = false });
            dut.sourceElem.send({ .data = fp32_to_bv(8.0), .last = false });
            dut.sourceElem.send({ .data = fp32_to_bv(20.8), .last = true });
            dut.sourceElem.send({ .data = fp32_to_bv(5.0), .last = false });
            dut.sourceElem.send({ .data = fp32_to_bv(5.0), .last = false });
            dut.sourceElem.send({ .data = fp32_to_bv(5.0), .last = false });
            dut.sourceElem.send({ .data = fp32_to_bv(3.1), .last = true });
        };

        SC_SPAWN {
            fmt::print("received: {}\n", bv_to_fp32(dut.sinkResult.receive()));
            fmt::print("received: {}\n", bv_to_fp32(dut.sinkResult.receive()));
        };

        wait(1000, SC_NS);

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
    trace_file->open(fmt::format("{}.vcd", "RowReduceSingleTop").c_str());

    tb.start();

    trace_file->close();

    return 0;
}

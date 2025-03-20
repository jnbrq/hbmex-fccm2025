#include <chext_test/elastic/Driver.hpp>
#include <chext_test/util/Spawn.hpp>
using namespace chext_test::elastic;

#include <iostream>

#include <systemc>
using namespace sc_core;
using namespace sc_dt;

#include <VElasticModule.h>
#include <verilated_vcd_sc.h>

#include <fmt/core.h>

struct ElasticModule : sc_module {
    SC_HAS_PROCESS(ElasticModule);

    sc_in_clk clock;
    sc_in<bool> reset;

    ElasticModule(sc_module_name const& name = "ElasticModule")
        : sc_module { name }
        , clock("clock")
        , reset("reset")
        , source1 { "source1", clock, reset }
        , source2 { "source2", clock, reset }
        , sink { "sink", clock, reset }
        , verilatedModule("dut") {

        verilatedModule.clock(clock);
        verilatedModule.reset(reset);

        verilatedModule.source1_bits(source1.bits);
        verilatedModule.source1_ready(source1.ready);
        verilatedModule.source1_valid(source1.valid);

        verilatedModule.source2_bits(source2.bits);
        verilatedModule.source2_ready(source2.ready);
        verilatedModule.source2_valid(source2.valid);

        verilatedModule.sink_bits(sink.bits);
        verilatedModule.sink_ready(sink.ready);
        verilatedModule.sink_valid(sink.valid);
    }

public:
    Source<sc_signal<sc_bv<32>, SC_MANY_WRITERS>> source1;
    Source<sc_signal<sc_bv<32>, SC_MANY_WRITERS>> source2;
    Sink<sc_signal<sc_bv<32>, SC_MANY_WRITERS>> sink;

public:
    VElasticModule verilatedModule;
};

struct Testbench : sc_module {
    SC_HAS_PROCESS(Testbench);

    Testbench(sc_module_name const& name = "Testbench")
        : sc_module { name }
        , dut { "elasticModule" }
        , clock_("clock")
        , reset_("reset") {

        dut.reset(reset_);
        dut.clock(clock_);

        SC_THREAD(thread0);
    }

    bool isDone() const noexcept {
        return done_;
    }

    ElasticModule dut;

private:
    sc_clock clock_;
    sc_signal<bool> reset_;
    bool done_ { false };

    void thread0() {
        wait(clock_.negedge_event());
        reset_.write(true);

        wait(clock_.negedge_event());
        wait(clock_.negedge_event());

        reset_.write(false);

        wait(clock_.negedge_event());

        // this is without dynamic polymorphism

        sc_join j1;
        wait(20, SC_NS);

        SC_SPAWN_TO(j1) {
            for (int i = 0; i < 8; ++i)
                dut.source1.send(i * 10 + 3);
        };

        SC_SPAWN_TO(j1) {
            for (int i = 0; i < 8; ++i)
                dut.source2.send(i * 20 + 3);
        };

        SC_SPAWN_TO(j1) {
            for (int i = 0; i < 8; ++i)
                // dut.sink.receive();
                std::cout << "received: " << dut.sink.receive() << std::endl;
        };

        j1.wait();

        // with dynamic polymorphism

        SinkBase& sink = dut.sink;
        sc_join j2;

        wait(20, SC_NS);

        SC_SPAWN_TO(j2) {
            dut.source1.send(30);
            dut.source1.sendAsString("0d98");
        };

        SC_SPAWN_TO(j2) {
            dut.source2.sendAsUInt64(30);
            dut.source2.sendAsString("0d30");
        };

        SC_SPAWN_TO(j2) {
            auto x = sink.receiveAsUInt64();
            std::cout << "received: " << x << std::endl;
            std::cout << "received: " << sink.receiveAsInt64() << std::endl;
        };

        j2.wait();

        done_ = true;
    }
};

int sc_main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    Testbench testbench;

    sc_start(SC_ZERO_TIME);

    std::unique_ptr<VerilatedVcdSc> trace_file = std::make_unique<VerilatedVcdSc>();
    testbench.dut.verilatedModule.trace(trace_file.get(), 99);
    trace_file->open("ElasticModule.vcd");

    while (!testbench.isDone())
        sc_start(50, SC_NS);

    trace_file->close();

    return 0;
}

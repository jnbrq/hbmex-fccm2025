#include <chext_test/amba/axi4/full/Driver.hpp>
#include <chext_test/amba/axi4/lite/Driver.hpp>
#include <chext_test/elastic/Driver.hpp>
#include <chext_test/util/Spawn.hpp>

using namespace chext_test::elastic;
using namespace chext_test::amba;

#include <fmt/core.h>

#include <systemc>
using namespace sc_core;
using namespace sc_dt;

#include <VAxiModule.h>
#include <verilated_vcd_sc.h>

struct AxiModule : sc_module {
    SC_HAS_PROCESS(AxiModule);

    sc_in_clk clock;
    sc_in<bool> reset;

    AxiModule(sc_module_name const& name = "AxiModule")
        : sc_module { name }
        , clock("clock")
        , reset("reset")
        , s_axi { "s_axi", clock, reset }
        , s_axi_lite { "s_axi_lite", clock, reset }
        , verilatedModule("dut") {

        verilatedModule.clock(clock);
        verilatedModule.reset(reset);

        // S_AXI
        verilatedModule.S_AXI_ARREADY(s_axi.ar.ready);
        verilatedModule.S_AXI_ARVALID(s_axi.ar.valid);
        verilatedModule.S_AXI_ARID(s_axi.ar.bits.id);
        verilatedModule.S_AXI_ARADDR(s_axi.ar.bits.addr);
        verilatedModule.S_AXI_ARLEN(s_axi.ar.bits.len);
        verilatedModule.S_AXI_ARSIZE(s_axi.ar.bits.size);
        verilatedModule.S_AXI_ARBURST(s_axi.ar.bits.burst);
        verilatedModule.S_AXI_ARLOCK(s_axi.ar.bits.lock);
        verilatedModule.S_AXI_ARCACHE(s_axi.ar.bits.cache);
        verilatedModule.S_AXI_ARPROT(s_axi.ar.bits.prot);
        verilatedModule.S_AXI_ARQOS(s_axi.ar.bits.qos);
        verilatedModule.S_AXI_ARREGION(s_axi.ar.bits.region);

        verilatedModule.S_AXI_RREADY(s_axi.r.ready);
        verilatedModule.S_AXI_RVALID(s_axi.r.valid);
        verilatedModule.S_AXI_RID(s_axi.r.bits.id);
        verilatedModule.S_AXI_RDATA(s_axi.r.bits.data);
        verilatedModule.S_AXI_RRESP(s_axi.r.bits.resp);
        verilatedModule.S_AXI_RLAST(s_axi.r.bits.last);

        verilatedModule.S_AXI_AWREADY(s_axi.aw.ready);
        verilatedModule.S_AXI_AWVALID(s_axi.aw.valid);
        verilatedModule.S_AXI_AWID(s_axi.aw.bits.id);
        verilatedModule.S_AXI_AWADDR(s_axi.aw.bits.addr);
        verilatedModule.S_AXI_AWLEN(s_axi.aw.bits.len);
        verilatedModule.S_AXI_AWSIZE(s_axi.aw.bits.size);
        verilatedModule.S_AXI_AWBURST(s_axi.aw.bits.burst);
        verilatedModule.S_AXI_AWLOCK(s_axi.aw.bits.lock);
        verilatedModule.S_AXI_AWCACHE(s_axi.aw.bits.cache);
        verilatedModule.S_AXI_AWPROT(s_axi.aw.bits.prot);
        verilatedModule.S_AXI_AWQOS(s_axi.aw.bits.qos);
        verilatedModule.S_AXI_AWREGION(s_axi.aw.bits.region);

        verilatedModule.S_AXI_WREADY(s_axi.w.ready);
        verilatedModule.S_AXI_WVALID(s_axi.w.valid);
        verilatedModule.S_AXI_WDATA(s_axi.w.bits.data);
        verilatedModule.S_AXI_WSTRB(s_axi.w.bits.strb);
        verilatedModule.S_AXI_WLAST(s_axi.w.bits.last);

        verilatedModule.S_AXI_BREADY(s_axi.b.ready);
        verilatedModule.S_AXI_BVALID(s_axi.b.valid);
        verilatedModule.S_AXI_BID(s_axi.b.bits.id);
        verilatedModule.S_AXI_BRESP(s_axi.b.bits.resp);

        // S_AXI_LITE
        verilatedModule.S_AXI_LITE_ARREADY(s_axi_lite.ar.ready);
        verilatedModule.S_AXI_LITE_ARVALID(s_axi_lite.ar.valid);
        verilatedModule.S_AXI_LITE_ARADDR(s_axi_lite.ar.bits.addr);
        verilatedModule.S_AXI_LITE_ARPROT(s_axi_lite.ar.bits.prot);

        verilatedModule.S_AXI_LITE_RREADY(s_axi_lite.r.ready);
        verilatedModule.S_AXI_LITE_RVALID(s_axi_lite.r.valid);
        verilatedModule.S_AXI_LITE_RDATA(s_axi_lite.r.bits.data);
        verilatedModule.S_AXI_LITE_RRESP(s_axi_lite.r.bits.resp);

        verilatedModule.S_AXI_LITE_AWREADY(s_axi_lite.aw.ready);
        verilatedModule.S_AXI_LITE_AWVALID(s_axi_lite.aw.valid);
        verilatedModule.S_AXI_LITE_AWADDR(s_axi_lite.aw.bits.addr);
        verilatedModule.S_AXI_LITE_AWPROT(s_axi_lite.aw.bits.prot);

        verilatedModule.S_AXI_LITE_WREADY(s_axi_lite.w.ready);
        verilatedModule.S_AXI_LITE_WVALID(s_axi_lite.w.valid);
        verilatedModule.S_AXI_LITE_WDATA(s_axi_lite.w.bits.data);
        verilatedModule.S_AXI_LITE_WSTRB(s_axi_lite.w.bits.strb);

        verilatedModule.S_AXI_LITE_BREADY(s_axi_lite.b.ready);
        verilatedModule.S_AXI_LITE_BVALID(s_axi_lite.b.valid);
        verilatedModule.S_AXI_LITE_BRESP(s_axi_lite.b.bits.resp);
    }

public:
    axi4::full::Slave<8, 12, 64> s_axi;
    axi4::lite::Slave<12, 64> s_axi_lite;

public:
    VAxiModule verilatedModule;
};

struct Testbench : sc_module {
    SC_HAS_PROCESS(Testbench);

    Testbench(sc_module_name const& name = "Testbench")
        : sc_module { name }
        , dut { "axiModule" }
        , clock_("clock")
        , reset_("reset") {

        dut.reset(reset_);
        dut.clock(clock_);

        SC_THREAD(thread0);
    }

    bool isDone() const noexcept {
        return done_;
    }

    AxiModule dut;

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

        sc_join j;

        SC_SPAWN_TO(j) {
            axi4::full::Packets::WriteAddress aw;
            aw.id = 85;
            aw.addr = 0x0000;
            aw.burst = 1;
            aw.len = 3;
            aw.size = 3;

            dut.s_axi.sendAW(aw);
        };

        SC_SPAWN_TO(j) {
            for (int i = 0; i < 4; ++i) {
                axi4::full::Packets::WriteData w;
                w.data = 0x1000 * i + i;
                w.strb = 0xFF;
                w.last = i == 3;

                dut.s_axi.sendW(w);
            }
        };

        SC_SPAWN_TO(j) {
            dut.s_axi.receiveB();
        };

        j.wait();

        SC_SPAWN_TO(j) {
            axi4::full::Packets::ReadAddress ar;
            ar.id = 12;
            ar.addr = 0x0000;
            ar.burst = 1;
            ar.len = 3;
            ar.size = 3;

            dut.s_axi.sendAR(ar);
        };

        SC_SPAWN_TO(j) {
            for (int i = 0; i < 4; ++i) {
                axi4::full::Packets::ReadData r = dut.s_axi.receiveR();
                fmt::print("data = {}\n", r);
            }

            done_ = true;
        };

        SC_SPAWN_TO(j) {
            axi4::lite::Packets::ReadAddress ar;
            ar.addr = 0x0AA0;

            dut.s_axi_lite.sendAR(ar);
        };

        SC_SPAWN_TO(j) {
            for (int i = 0; i < 4; ++i) {
                auto r = dut.s_axi_lite.receiveR();
                fmt::print("data = {}\n", r);
            }

            done_ = true;
        };

        j.wait();
    }
};

int sc_main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    Testbench testbench;

    sc_start(SC_ZERO_TIME);

    std::unique_ptr<VerilatedVcdSc> trace_file = std::make_unique<VerilatedVcdSc>();
    testbench.dut.verilatedModule.trace(trace_file.get(), 99);
    trace_file->open("AxiModule.vcd");

    while (!testbench.isDone())
        sc_start(50, SC_NS);

    trace_file->close();

    return 0;
}

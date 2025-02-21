#include <ScProviders.hpp>
#include <Testbench.hpp>

#include <fmt/core.h>

Testbench::Testbench(ModuleGen moduleGen)
    : sc_module(sc_core::sc_module_name("tb"))
    , clock("clock", 2, sc_core::SC_NS)
    , reset("reset")
    , dut(moduleGen("dut")) {
    {

        using namespace sc_providers;
        S_AXI_MEM = wrapTlmTargetSocket(dut->get<tlm::tlm_target_socket<>>("S_AXI_MEM"), "drv_0");
        S_AXIL_CTRL = wrapTlmTargetSocket(dut->get<tlm::tlm_target_socket<>>("S_AXIL_CTRL"), "drv_1");
        S_AXI_DESC = wrapTlmTargetSocket(dut->get<tlm::tlm_target_socket<>>("S_AXI_DESC"), "drv_2");

        auto& dut_clock = dut->get<sc_core::sc_in_clk>("clock");
        auto& dut_reset = dut->get<sc_core::sc_in<bool>>("reset");

        dut_clock(clock);
        dut_reset(reset);
    }

    SgdmaMultiConfig sgdmaMultiCfg {
        4,
        SgdmaConfig {
            14 }
    };

    sgdmaMulti_ = std::make_unique<SgdmaMulti>(
        sgdmaMultiCfg,
        S_AXIL_CTRL,
        S_AXI_DESC,
        sc_providers::scSleep
    );

    SC_THREAD(thread);
}

bool Testbench::isDone() {
    return isDone_;
}

void Testbench::thread() {
    using namespace sc_core;
    using namespace sc_dt;

    reset.write(true);
    wait(10, SC_NS);
    reset.write(false);

    // we should make sure that the reset signal propagates
    wait(10, SC_NS);

    auto& sgdma0 = (*sgdmaMulti_)[0];
    SgdmaDesc descs[2] = {
        SgdmaDesc::genAR(0x0000, 255),
        SgdmaDesc::genAW(0x1000, 255)
    };
    sgdma0.copyDesc(descs, 2);
    sgdma0.sgdmaTask(0, 2, false);
    sgdma0.start();
    sgdma0.waitUntilComplete();

    fmt::print("cycles = {}\n", sgdma0.cycles());

    isDone_ = true;
}

Testbench::~Testbench() {
}

#include <ProtocolConverterTest1.hpp>
#include <Testbench.hpp>

#include <verilated_vcd_sc.h>

using namespace sc_core;
using namespace sc_dt;

int sc_main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
#if defined(VERILATED_TRACE_ENABLED)
    Verilated::traceEverOn(true);
#endif

    Testbench testbench(moduleGenFor<ProtocolConverterTest1>());

    sc_start(SC_ZERO_TIME);

#if defined(VERILATED_TRACE_ENABLED)
    std::unique_ptr<VerilatedVcdSc> trace_file = std::make_unique<VerilatedVcdSc>();
    testbench.dut->traceVerilated(trace_file.get(), 99);
    trace_file->open("ProtocolConverterTest1.vcd");
#endif

    while (!testbench.isDone()) {
        sc_start(50, SC_NS);
    }

#if defined(VERILATED_TRACE_ENABLED)
    trace_file->close();
#endif

    return 0;
}

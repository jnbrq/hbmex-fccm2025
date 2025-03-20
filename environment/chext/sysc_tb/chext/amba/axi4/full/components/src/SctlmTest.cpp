#include <chext_test/chext_test.hpp>

#include <sctlm/tlm_lib/drivers/memory.hpp>
#include <sctlm/tlm_lib/modules/iconnect.hpp>
#include <sctlm/tlm_lib/modules/memory.hpp>

#include <SctlmTest.hpp>

#include <systemc>
using namespace sc_core;
using namespace sc_dt;

#include <fmt/core.h>
#include <vector>

template<typename T>
void vecEq(std::vector<T> const& buf1, std::vector<T> const& buf2) {
    if (buf1.size() != buf2.size()) {
        fmt::print("Sizes do not match: {} != {}\n", buf1.size(), buf2.size());
        return;
    }

    for (unsigned idx = 0; idx < buf1.size(); idx++) {
        fmt::print(
            "{0:#02x} {2} {1:#02x} {3}\n", //
            buf1[idx], buf2[idx], //
            buf1[idx] == buf2[idx] ? "==" : "!=", //
            buf1[idx] == buf2[idx] ? "" : "*"
        );
    }
}

struct SctlmTestTB : chext_test::TestBenchBase {
    SctlmTestTB(sc_module_name name = "tb")
        : TestBenchBase { name }
        , dut { "dut" }
        , clock { "clock", 2, SC_NS }
        , reset { "reset" }
        , memory { "memory", sc_time(60, SC_NS), (1 << 20), 8 }
        , iconnect { "iconnect", 2, 1 }
        , driverDirect { "driverDirect" }
        , driverIndirect { "driverIndirect" } {

        dut.clock(clock);
        dut.reset(reset);

        iconnect.initiator_socket(0)->bind(memory.socket);
        iconnect.target_socket(0)->bind(driverDirect.socket);
        iconnect.target_socket(1)->bind(dut.M_AXI);
        iconnect.memmap(0x0000, 1 << 20, 0);
        driverIndirect.socket.bind(dut.S_AXI);
    }

private:
    SctlmTest dut;

    sc_clock clock;
    sc_signal<bool> reset;

    sctlm::tlm_lib::modules::memory memory;
    sctlm::tlm_lib::modules::iconnect iconnect;

    // goes directly to the memory
    sctlm::tlm_lib::drivers::memory_interface driverDirect;

    // goes over the protocol converter
    sctlm::tlm_lib::drivers::memory_interface driverIndirect;

protected:
    void entry() override {
        driverDirect.write64(0, 0xCAFE'BABE);
        // fmt::print("{:#x}\n", driverDirect.read64(0));
        // fmt::print("{:#x}\n", driverIndirect.read64(0));

        constexpr unsigned numBytes = 128;

        std::vector<uint8_t> buffer1(numBytes);
        for (unsigned idx = 0; idx < numBytes; ++idx)
            buffer1[idx] = (uint8_t)(idx & 0xFF);

        driverIndirect.write(0x2, buffer1.size(), buffer1.data());

        std::vector<uint8_t> buffer2(numBytes);
        driverDirect.read(0x2, buffer2.size(), buffer2.data());

        vecEq(buffer1, buffer2);

        finish();
    }
};

int sc_main(int argc, char** argv) {
    SctlmTestTB tb;
    sc_start(5, SC_US);
    return 0;
}

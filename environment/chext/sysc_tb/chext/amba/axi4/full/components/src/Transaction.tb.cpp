#include <fmt/core.h>
#include <systemc>

#include <chext_test/chext_test.hpp>

#include <Transaction.hpp>

#include <DownscaleTestTop1_1.hpp>
#include <UpscaleTestTop1_1.hpp>
#include <verilated_vcd_sc.h>

#include <chrono>
#include <random>

using namespace sc_core;
using namespace sc_dt;

using namespace chext_test;
using namespace chext_test::amba;

#define LOG_ENABLED false

struct TransactionTestCase {
    uint16_t wData;

    uint64_t addr;
    uint8_t len;
    uint8_t size;
    uint8_t burst;

    void run() const {
        fmt::print("{}\n", *this);

        axi4::full::Transaction transaction { wData };
        transaction.reset(addr, len, size, burst);

        axi4::full::Beat b;
        while (transaction.nextBeat(b)) {
            fmt::print("{}\n", b);
        }
    }

    // clang-format off
    JQR_DECL(
        TransactionTestCase,
        JQR_MEMBER(wData, jqr::opts::dump_fmt { "{:#06d}" }),
        JQR_MEMBER(addr, jqr::opts::dump_fmt { "{:#018x}" }),
        JQR_MEMBER(len, jqr::opts::dump_fmt { "{:#04x}" }),
        JQR_MEMBER(size, jqr::opts::dump_fmt { "{:#03d}" }),
        JQR_MEMBER(burst, jqr::opts::dump_fmt { "{:#04b}" })
    )
    // clang-format on
};

struct ReadWriteTestCase {
    uint64_t addr;
    uint64_t numBytes;

    void run(axi4::full::SlaveBase& slave) {
        std::vector<uint8_t> rdVector(numBytes);
        std::vector<uint8_t> wrVector(numBytes);

        uint8_t* rdPtr = rdVector.data();
        uint8_t const* wrPtr = wrVector.data();
    }
};

std::vector<TransactionTestCase> transactionTestCases {
    { .wData = 32 /* 4B */, .addr = 0x0000, 3, 0, 0 },
    { .wData = 32 /* 4B */, .addr = 0x0000, 3, 1, 0 },
    { .wData = 32 /* 4B */, .addr = 0x0000, 3, 2, 0 },

    { .wData = 32 /* 4B */, .addr = 0x0000, 3, 0, 1 },
    { .wData = 32 /* 4B */, .addr = 0x0000, 3, 1, 1 },
    { .wData = 32 /* 4B */, .addr = 0x0000, 3, 2, 1 },

    { .wData = 32 /* 4B */, .addr = 0x0000, 3, 0, 2 },
    { .wData = 32 /* 4B */, .addr = 0x0000, 3, 1, 2 },
    { .wData = 32 /* 4B */, .addr = 0x0000, 3, 2, 2 },

    { .wData = 32 /* 4B */, .addr = 0x0001, 3, 0, 1 },
    { .wData = 32 /* 4B */, .addr = 0x0001, 3, 1, 1 },
    { .wData = 32 /* 4B */, .addr = 0x0001, 3, 2, 1 },

    { .wData = 32 /* 4B */, .addr = 0x0002, 3, 0, 1 },
    { .wData = 32 /* 4B */, .addr = 0x0002, 3, 1, 1 },
    { .wData = 32 /* 4B */, .addr = 0x0002, 3, 2, 1 },

    { .wData = 32 /* 4B */, .addr = 0x0003, 3, 0, 1 },
    { .wData = 32 /* 4B */, .addr = 0x0003, 3, 1, 1 },
    { .wData = 32 /* 4B */, .addr = 0x0003, 3, 2, 1 },

    { .wData = 32 /* 4B */, .addr = 0x0005, 3, 0, 1 },
    { .wData = 32 /* 4B */, .addr = 0x0005, 3, 1, 1 },
    { .wData = 32 /* 4B */, .addr = 0x0005, 3, 2, 1 },

    { .wData = 64 /* 8B */, .addr = 0x0000, 3, 0, 0 },
    { .wData = 64 /* 8B */, .addr = 0x0000, 3, 1, 0 },
    { .wData = 64 /* 8B */, .addr = 0x0000, 3, 2, 0 },
    { .wData = 64 /* 8B */, .addr = 0x0000, 3, 3, 0 },

    { .wData = 64 /* 8B */, .addr = 0x0000, 3, 0, 1 },
    { .wData = 64 /* 8B */, .addr = 0x0000, 3, 1, 1 },
    { .wData = 64 /* 8B */, .addr = 0x0000, 3, 2, 1 },
    { .wData = 64 /* 8B */, .addr = 0x0000, 3, 3, 1 },

    { .wData = 64 /* 8B */, .addr = 0x0000, 3, 0, 2 },
    { .wData = 64 /* 8B */, .addr = 0x0000, 3, 1, 2 },
    { .wData = 64 /* 8B */, .addr = 0x0000, 3, 2, 2 },
    { .wData = 64 /* 8B */, .addr = 0x0000, 3, 3, 2 },

    { .wData = 64 /* 8B */, .addr = 0x0001, 3, 0, 1 },
    { .wData = 64 /* 8B */, .addr = 0x0001, 3, 1, 1 },
    { .wData = 64 /* 8B */, .addr = 0x0001, 3, 2, 1 },
    { .wData = 64 /* 8B */, .addr = 0x0001, 3, 3, 1 },

    { .wData = 64 /* 8B */, .addr = 0x0002, 3, 0, 1 },
    { .wData = 64 /* 8B */, .addr = 0x0002, 3, 1, 1 },
    { .wData = 64 /* 8B */, .addr = 0x0002, 3, 2, 1 },
    { .wData = 64 /* 8B */, .addr = 0x0002, 3, 3, 1 },

    { .wData = 64 /* 8B */, .addr = 0x0003, 3, 0, 1 },
    { .wData = 64 /* 8B */, .addr = 0x0003, 3, 1, 1 },
    { .wData = 64 /* 8B */, .addr = 0x0003, 3, 2, 1 },
    { .wData = 64 /* 8B */, .addr = 0x0003, 3, 3, 1 },

    { .wData = 64 /* 8B */, .addr = 0x0005, 3, 0, 1 },
    { .wData = 64 /* 8B */, .addr = 0x0005, 3, 1, 1 },
    { .wData = 64 /* 8B */, .addr = 0x0005, 3, 2, 1 },
    { .wData = 64 /* 8B */, .addr = 0x0005, 3, 3, 1 }
};

namespace buffer_utils {

namespace detail {

static std::mt19937 mt(879821);
static std::uniform_int_distribution<> dist(0, 1024);

} // namespace detail

template<typename BufferT>
void reset(BufferT& buffer) {
    using value_type = std::remove_reference_t<decltype(*std::begin(buffer))>;

    for (auto it = std::begin(buffer); it != std::end(buffer); ++it)
        *it = ((value_type)0);
}

template<typename BufferT>
void linearInit(BufferT& buffer) {
    using value_type = std::remove_reference_t<decltype(*std::begin(buffer))>;

    value_type idx = (value_type)0;
    for (auto it = std::begin(buffer); it != std::end(buffer); ++it)
        *it = (idx++);
}

template<typename BufferT>
void randomInit(BufferT& buffer) {
    using value_type = std::remove_reference_t<decltype(*std::begin(buffer))>;

    for (auto it = std::begin(buffer); it != std::end(buffer); ++it)
        *it = ((value_type)detail::dist(detail::mt));
}

} // namespace buffer_utils

class TransactionTestBench : public TestBenchBase {
public:
    SC_HAS_PROCESS(DownscaleTestbench);

    TransactionTestBench()
        : TestBenchBase(sc_module_name("tb"))
        , dut1 { "dut1" }
        , dut2 { "dut2" }
        , clock { "clock", 2.0, SC_NS }
        , reset { "reset" } {

        dut1.clock(clock);
        dut1.reset(reset);

        dut2.clock(clock);
        dut2.reset(reset);
    }

    DownscaleTestTop1_1 dut1;
    UpscaleTestTop1_1 dut2;

private:
    sc_clock clock;
    sc_signal<bool> reset;

    void entry() override {
        fmt::print("Testing for: {}\n", dut1.S_AXI_NORMAL.config());
        readWriteTestCase(dut1.S_AXI_NORMAL, dut1.S_AXI_NORMAL, 0x00, 1024);

        fmt::print("Testing for: {}\n", dut2.S_AXI_NORMAL.config());
        readWriteTestCase(dut2.S_AXI_NORMAL, dut2.S_AXI_NORMAL, 0x00, 1024);

        fmt::print("simulation time: {}\n", sc_time_stamp().to_string());

        finish();
    }

    void readWriteTestCase(
        axi4::full::SlaveBase& writeSlave,
        axi4::full::SlaveBase& readSlave,
        uint64_t addr,
        uint64_t numBytes
    ) {
        using axi4::full::read;
        using axi4::full::write;

        std::vector<uint8_t> rdBuffer(numBytes), wrBuffer(numBytes);

        fmt::print("linearInit test for addr = {:#018x}, numBytes = {}\n", addr, numBytes);
        for (uint64_t offset = 0; offset < 32; ++offset) {
            for (int size = -1; size < 2; ++size) {
                fmt::print("for size = {}\n", size);
                buffer_utils::linearInit(wrBuffer);
                write(writeSlave, addr + offset, numBytes, wrBuffer.data(), size, LOG_ENABLED);
                read(readSlave, addr + offset, numBytes, rdBuffer.data(), size, LOG_ENABLED);
                ASSERT_(rdBuffer == wrBuffer);
            }
        }

        fmt::print("randomInit test for addr = {:#018x}, numBytes = {}\n", addr, numBytes);
        for (uint64_t offset = 0; offset < 32; ++offset) {
            for (int size = -1; size < 2; ++size) {
                fmt::print("for size = {}\n", size);
                buffer_utils::randomInit(wrBuffer);
                write(writeSlave, addr + offset, numBytes, wrBuffer.data(), size, LOG_ENABLED);
                read(readSlave, addr + offset, numBytes, rdBuffer.data(), size, LOG_ENABLED);
                ASSERT_(rdBuffer == wrBuffer);
            }
        }
    }
};

int sc_main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    fmt::print("Transaction test:\n");
    for (auto const& testCase : transactionTestCases) {
        testCase.run();
    }

    fmt::print("SystemC module test:\n");

    TransactionTestBench testBench;

    sc_start(SC_ZERO_TIME);

    std::unique_ptr<VerilatedVcdSc> trace_file = std::make_unique<VerilatedVcdSc>();
    testBench.dut1.traceVerilated(trace_file.get(), 99);
    testBench.dut2.traceVerilated(trace_file.get(), 99);
    trace_file->open("Transaction.tb.vcd");

    testBench.start();

    trace_file->close();
    return 0;
}

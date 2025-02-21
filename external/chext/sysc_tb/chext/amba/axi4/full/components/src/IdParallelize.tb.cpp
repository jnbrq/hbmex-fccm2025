#include <IdParallelizeTestTop2_1.hpp>
#include <IdParallelizeTestTop2_2.hpp>
#include <IdParallelizeTestTop2_3.hpp>
#include <IdParallelizeTestTop2_4.hpp>
#include <IdParallelizeTestTop2_5.hpp>
#include <IdParallelizeTestTop2_6.hpp>

#include <verilated_vcd_sc.h>

#include <systemc>

#include <Util.hpp>
#include <chext_test/chext_test.hpp>

#include <random>

using namespace sc_core;
using namespace sc_dt;

using namespace chext_test;
using namespace chext_test::util;

using namespace chext_test::amba;

template<typename Dut>
struct DutTester {
    DutTester(
        const std::string& name,
        bool logEnabled
    )
        : dut { fmt::format("{}_dut", name).c_str() }
        , name { name }
        , logEnabled { logEnabled }
        , clock { fmt::format("{}_clock", name).c_str(), 2.0, SC_NS }
        , reset { fmt::format("{}_reset", name).c_str() }
        , numThreads { 1u << dut.M_AXI.config().wId }
        , arFifos { numThreads }
        , rFifo {}
        , awFifos { numThreads }
        , bFifo {} {

        dut.clock(clock);
        dut.reset(reset);
    }

    void run() {
        entry();
    }

    Dut dut;

private:
    std::string name;
    bool logEnabled;

    sc_clock clock;
    sc_signal<bool> reset;

    unsigned numThreads;

    std::vector<sc_fifo<axi4::full::Packets::ReadAddress>> arFifos;
    sc_fifo<axi4::full::Packets::ReadData> rFifo;

    std::vector<sc_fifo<axi4::full::Packets::WriteAddress>> awFifos;
    sc_fifo<axi4::full::Packets::WriteResponse> bFifo;

    // test params
    unsigned numReadTransactions = 4096;
    unsigned numWriteTransactions = 4096;
    unsigned addrOffset = 16;

    std::mt19937 mt { 566542 };
    std::uniform_int_distribution<> distBeats { 0, 31 };
    std::uniform_int_distribution<> distWait { 20, 50 };

    bool enableWaits { false };
    bool zeroLen { false };

    template<typename... Ts>
    void print(fmt::format_string<Ts...> fmt, Ts&&... args) {
        fmt::print(fmt, std::forward<Ts>(args)...);
    }

    template<typename... Ts>
    void printLog(fmt::format_string<Ts...> fmt, Ts&&... args) {
        if (logEnabled)
            fmt::print(fmt, std::forward<Ts>(args)...);
    }

    void randomWait() {
        if (enableWaits)
            wait(distWait(mt), SC_NS);
    }

    void entry() {
        print("DutTester: started {}\n", name);
        resetDUT();

        for (unsigned id = 0; id < numThreads; ++id) {
            sc_spawn([this, id] { idThread(id); });
        }

        sc_spawn([this] { m_axi_ar(); });
        sc_spawn([this] { m_axi_r(); });

        sc_spawn([this] { m_axi_aw(); });
        sc_spawn([this] { m_axi_b(); });

        auto test = [this] {
            print("DutTester: enableWaits = {}, zeroLen = {}\n", enableWaits, zeroLen);

            sc_join j;

            j.add_process(sc_spawn([this] { s_axi_ar(); }));
            j.add_process(sc_spawn([this] { s_axi_r(); }));
            j.add_process(sc_spawn([this] { s_axi_aw(); }));
            j.add_process(sc_spawn([this] { s_axi_b(); }));

            j.wait();
        };

#if 1
        enableWaits = false;
        zeroLen = false;
        test();

        enableWaits = true;
        zeroLen = false;
        test();
#endif

        enableWaits = false;
        zeroLen = true;
        test();

#if 1
        enableWaits = true;
        zeroLen = true;
        test();
#endif
    }

    void s_axi_ar() {
        for (uint64_t i = 0; i < numReadTransactions; ++i) {
            axi4::full::Packets::ReadAddress ar {
                .id = bv_from(i & (numThreads - 1)),
                .addr = bv_from(i << addrOffset),
                .len = zeroLen ? (uint8_t)0 : (uint8_t)distBeats(mt)
            };

            randomWait();

            dut.S_AXI.sendAR(ar);
            printLog("[{:^20}] [{:^20}] dut.S_AXI.sendAR({})\n", sc_time_stamp().to_string(), "s_axi_ar", ar);
        }
    }

    void s_axi_r() {
        for (unsigned i = 0; i < numReadTransactions; ++i) {
            for (unsigned j = 0;; ++j) {
                randomWait();
                auto r = dut.S_AXI.receiveR();
                printLog("[{:^20}] [{:^20}] dut.S_AXI.receiveR() = {}\n", sc_time_stamp().to_string(), "s_axi_r", r);

                auto received = r.data.to_uint64();
                auto expected = (((uint64_t)i) << addrOffset) + j;

                if (received != expected) {
                    fmt::print("[{:^20}] [{:^20}] Error: {} != {}\n", sc_time_stamp().to_string(), "s_axi_r", received, expected);
                    throw std::logic_error("Assertion error!");
                }

                if (r.last)
                    break;
            }
        }
    }

    void m_axi_ar() {
        while (true) {
            randomWait();
            auto ar = dut.M_AXI.receiveAR();
            printLog("[{:^20}] [{:^20}] dut.M_AXI.receiveAR() = {}\n", sc_time_stamp().to_string(), "m_axi_ar", ar);

            arFifos.at(ar.id.to_uint64()).write(ar);
        }
    }

    void m_axi_r() {
        while (true) {
            auto r = rFifo.read();

            randomWait();
            dut.M_AXI.sendR(r);
            printLog("[{:^20}] [{:^20}] dut.M_AXI.sendR({})\n", sc_time_stamp().to_string(), "m_axi_r", r);
        }
    }

    void s_axi_aw() {
        for (uint64_t i = 0; i < numWriteTransactions; ++i) {
            axi4::full::Packets::WriteAddress aw {
                .id = bv_from(i & (numThreads - 1)),
                .addr = bv_from(i << addrOffset),
                .len = zeroLen ? (uint8_t)0 : (uint8_t)distBeats(mt) // we do not test the W channel
            };

            randomWait();

            dut.S_AXI.sendAW(aw);
            printLog("[{:^20}] [{:^20}] dut.S_AXI.sendAW({})\n", sc_time_stamp().to_string(), "s_axi_aw", aw);
        }
    }

    void s_axi_b() {
        for (unsigned i = 0; i < numWriteTransactions; ++i) {
            randomWait();
            auto b = dut.S_AXI.receiveB();
            printLog("[{:^20}] [{:^20}] dut.S_AXI.receiveB() = {}\n", sc_time_stamp().to_string(), "s_axi_b", b);

            auto received = b.user.to_uint64();
            auto expected = (((uint64_t)i) << addrOffset);

            if (received != expected) {
                fmt::print("[{:^20}] [{:^20}] Error: {} != {}\n", sc_time_stamp().to_string(), "s_axi_b", received, expected);
                throw std::logic_error("Assertion error!");
            }
        }
    }

    void m_axi_aw() {
        while (true) {
            randomWait();
            auto aw = dut.M_AXI.receiveAW();
            printLog("[{:^20}] [{:^20}] dut.M_AXI.receiveAW() = {}\n", sc_time_stamp().to_string(), "m_axi_aw", aw);

            awFifos.at(aw.id.to_uint64()).write(aw);
        }
    }

    void m_axi_b() {
        while (true) {
            auto b = bFifo.read();

            randomWait();
            dut.M_AXI.sendB(b);
            printLog("[{:^20}] [{:^20}] dut.M_AXI.sendB({})\n", sc_time_stamp().to_string(), "m_axi_b", b);
        }
    }

    void idThread(uint32_t id) {
        sc_join j;

        SC_SPAWN_TO(j) {
            while (true) {
                auto ar = arFifos[id].read();
                printLog("[{:^20}] [{:^20}] arFifos[id].read() = {}\n", sc_time_stamp().to_string(), fmt::format("idThread({:^4d}).rd", id), ar);

                for (unsigned j = 0; j <= ar.len; ++j) {
                    axi4::full::Packets::ReadData r {
                        .id = bv_from(id),
                        .data = bv_from(ar.addr.to_uint64() + j),
                        .resp = 0,
                        .last = (j == ar.len)
                    };

                    randomWait();
                    rFifo.write(r);
                }

                randomWait();
            }
        };

        SC_SPAWN_TO(j) {
            while (true) {
                auto aw = awFifos[id].read();
                printLog("[{:^20}] [{:^20}] arFifos[id].read() = {}\n", sc_time_stamp().to_string(), fmt::format("idThread({:^4d}).wr", id), aw);

                // we assume that W channel works correctly (it is passthrough)

                axi4::full::Packets::WriteResponse b {
                    .id = bv_from(id),
                    .resp = 0,
                    .user = aw.addr
                };

                randomWait();
                bFifo.write(b);
            }
        };

        j.wait();
    }

    void resetDUT() {
        wait(clock.negedge_event());
        reset.write(true);

        wait(clock.negedge_event());
        wait(clock.negedge_event());

        reset.write(false);

        wait(clock.negedge_event());
    }
};

struct MyTestBench : virtual TestBenchBase {
    SC_HAS_PROCESS(MyTestBench);

    MyTestBench(bool logEnabled = true)
        : TestBenchBase(sc_module_name("tb"))
        , tester1 { "tester1", logEnabled }
        , tester2 { "tester2", logEnabled }
        , tester3 { "tester3", logEnabled }
        , tester4 { "tester4", logEnabled }
        , tester5 { "tester5", logEnabled }
        , tester6 { "tester6", logEnabled } {
    }

    DutTester<IdParallelizeTestTop2_1> tester1;
    DutTester<IdParallelizeTestTop2_2> tester2;
    DutTester<IdParallelizeTestTop2_3> tester3;
    DutTester<IdParallelizeTestTop2_4> tester4;
    DutTester<IdParallelizeTestTop2_5> tester5;
    DutTester<IdParallelizeTestTop2_6> tester6;

private:
    sc_clock clock;
    sc_signal<bool> reset;

    void entry() {
        tester1.run();
        tester2.run();
        tester3.run();
        tester4.run();
        tester5.run();
        tester6.run();

        finish();
    }
};

int sc_main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    MyTestBench testBench { true };

    sc_start(SC_ZERO_TIME);

    std::unique_ptr<VerilatedVcdSc> trace_file = std::make_unique<VerilatedVcdSc>();
    testBench.tester1.dut.traceVerilated(trace_file.get(), 99);
    testBench.tester2.dut.traceVerilated(trace_file.get(), 99);
    testBench.tester3.dut.traceVerilated(trace_file.get(), 99);
    trace_file->open("MyTestBench.vcd");

    testBench.start();

    trace_file->close();

    return 0;
}

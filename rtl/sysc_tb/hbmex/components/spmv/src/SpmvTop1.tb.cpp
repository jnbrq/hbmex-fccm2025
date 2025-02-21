#include <chext_test/amba/axi4/full/hal.hpp>
#include <chext_test/chext_test.hpp>
#include <chext_test/util/Spawn.hpp>
#include <systemc>
#include <verilated_vcd_sc.h>

#include <SpmvTop1_1.hpp>

#include <spmv/Spmv.hpp>

#include <random>

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
        , reset { "reset" }
        , manager(amba::axi4::full::wrapSlave(dut.s_axi)) {

        dut.clock(clock);
        dut.reset(reset);
    }

    SpmvTop1_1 dut;

private:
    sc_clock clock;
    sc_signal<bool> reset;
    spmv::Manager manager;

    void test(
        std::string const& name,
        linalg::size_t numRows,
        linalg::size_t numCols,
        linalg::size_t numValues,
        linalg::size_t numTasks
    ) {
        testName(name.c_str());
        fmt::print(
            "numRows = {}, numCols = {}, numValues = {}, numTasks = {}\n",
            numRows, numCols, numValues, numTasks
        );

        using SparseMatrix = linalg::SparseMatrix<linalg::real_t, linalg::RowMajor>;
        using DenseMatrix = linalg::DenseMatrix<linalg::real_t, linalg::RowMajor>;

        std::random_device rd;
        std::mt19937 gen(rd());

        std::uniform_int_distribution<linalg::index_t> rowDist(0, numRows - 1);
        std::uniform_int_distribution<linalg::index_t> colDist(0, numCols - 1);
        std::uniform_real_distribution<linalg::real_t> realDist(0.0, 1.0);

        hal::addr_t addrValues = 0x0000'0000ull;
        hal::addr_t addrColumnIndices = 0x0200'0000ull;
        hal::addr_t addrRowLengths = 0x0100'0000ull;

        hal::addr_t addrInputMatrix = 0x0300'0000ull;
        hal::addr_t addrOutputMatrix = 0x0400'0000ull;

        std::vector<spmv::Task> tasks;
        std::vector<DenseMatrix> expected;

        SparseMatrix spm(numRows, numCols);
        DenseMatrix m(numCols, 8);

        for (linalg::size_t i = 0; i < numTasks; ++i) {
            spm.clear();
            m.clear();

            fmt::print("Writing test data #{}: ", i);

            while (spm.nonZeros() != numValues) {
                spm.set(rowDist(gen), colDist(gen), realDist(gen));
            }

            // for (unsigned i = 0; i < numRows; ++i) {
            //     unsigned x = rowDist(gen);
            //     spm.set(i, x, 2);
            //     spm.set(i, (x + 4) % numRows, 2);
            // }

            auto cspm = spm.toCompressedSparseMatrix();

            // for (auto length: cspm.lengths) {
            //     fmt::print("{}, ", length);
            // }
            // fmt::print("\n");

            tasks.emplace_back(
                spmv::Task {
                    .ptrValues = addrValues,
                    .ptrColumnIndices = addrColumnIndices,
                    .ptrRowLengths = addrRowLengths,
                    .ptrInputVector = addrInputMatrix,
                    .ptrOutputVector = addrOutputMatrix,
                    .numValues = cspm.numValues / 8,
                    .numRows = cspm.numRows / 8 //
                } //
            );

            manager.writeCompressedSparseMatrix(
                cspm,
                addrValues,
                addrColumnIndices,
                addrRowLengths
            );

            fmt::print("cspm, ");

            for (linalg::index_t i = 0; i < m.numRows; ++i)
                for (linalg::index_t j = 0; j < m.numCols; ++j)
                    m.set(i, j, realDist(gen));

            manager.writeBatchVector(m, addrInputMatrix);
            fmt::print("m, DONE.\n");

            assert(spm.nonZeros() == numValues);

            expected.push_back(linalg::sparseMatrixProduct(cspm, m));
            addrOutputMatrix += numRows * 8 * sizeof(linalg::real_t);
        }

        fmt::print("All the test data is written.\n");

        sc_join j;

        SC_SPAWN_TO(j) {
            size_t idx = 0;

            for (auto const& task : tasks) {
                dut.sourceTask.send(task.to_bv());
                fmt::print("Task #{} is sent!\n", idx);
                idx++;
            }
        };

        SC_SPAWN_TO(j) {
            size_t idx = 0;

            for (auto const& task : tasks) {
                auto c = dut.sinkDone.receive().to_uint64();
                fmt::print(
                    "Task {} is complete! Took: {} cycles, {} cycles/value\n",
                    idx, c, ((double)c) / (task.numValues * 8)
                );
                idx++;
            }
        };

        j.wait();

        // reset to the original
        addrOutputMatrix = 0x0400'0000ull;

        for (auto const& mExpected : expected) {
            auto mReceived = manager.readBatchVector(numRows, addrOutputMatrix);

            if (linalg::isSame(mReceived, mExpected, 1e-5)) {
                fmt::print("received matches expected :-)\n");
            } else {
                fmt::print("received does not match expected :-(\n");

                fmt::print("Expected: \n");
                mExpected.print();

                fmt::print("Received: \n");
                mReceived.print();

                ASSERT_(false);
            }
        }
    }

    void entry() override {
        resetDut();

#if 1
        test("Basic test", 8, 8, 8, 4);
        test("Basic test", 8, 8, 16, 4);
        test("Basic test", 8, 8, 24, 4);
        test("Basic test", 8, 8, 32, 4);
        test("large test", 2048, 2048, 2048, 2);
        test("large test", 4096, 4096, 4096 * 1, 1);
        test("large test", 4096, 4096, 4096 * 2, 1);
        test("large test", 4096, 4096, 4096 * 3, 1);
        test("large test", 4096, 4096, 4096 * 4, 1);
        test("large test", 8192, 8192, 8192 * 1, 1);
        test("large test", 8192, 8192, 8192 * 2, 1);
        test("large test", 8192, 8192, 8192 * 3, 1);
        test("large test", 8192, 8192, 8192 * 4, 1);
        test("large test", 8192, 8192, 8192 * 5, 1);
#endif

        // test("large test", 4096, 4096, 4096 * 2, 1);

        // test("Basic test", 8, 8, 16, 1);
#if 0
        unsigned N = 4096;

        std::random_device rd;
        std::mt19937 gen(rd());
        std::uniform_int_distribution<linalg::index_t> indexDist(0, N - 1);
        std::uniform_real_distribution<linalg::real_t> realDist(0.0, 1.0);

        hal::addr_t addrValues = 0x0000'0000;
        hal::addr_t addrColumnIndices = 0x0200'0000;
        hal::addr_t addrRowLengths = 0x0100'0000;

        hal::addr_t addrInputMatrix = 0x300'0000;
        hal::addr_t addrOutputMatrix = 0x400'0000;

        linalg::SparseMatrix<linalg::real_t, linalg::RowMajor> spm(N, N);

        // while (spm.nonZeros() != 4 * N + 8) {
        //     spm.set(indexDist(gen), indexDist(gen), 1);
        // }
        for (unsigned i = 0; i < N; ++i) {
            unsigned x = indexDist(gen);
            spm.set(i, x, 2);
            spm.set(i, (x + 4) % N, 2);
        }

        linalg::DenseMatrix<linalg::real_t, linalg::RowMajor> m(N, 8);

        for (std::size_t i = 0; i < m.numRows; ++i) {
            for (std::size_t j = 0; j < m.numCols; ++j) {
                linalg::real_t random_value = realDist(gen);
                m.set(i, j, random_value);
            }
        }
        fmt::print("\n");

        auto cspm = spm.toCompressedSparseMatrix();

        manager.writeCompressedSparseMatrix(
            cspm,
            addrValues,
            addrColumnIndices,
            addrRowLengths
        );

        fmt::print("Compressed sparse matrix is written!\n");

        manager.writeBatchVector(m, addrInputMatrix);
        fmt::print("Batch vector is written!\n");

        sc_join j;

        SC_SPAWN_TO(j) {
            hal::addr_t addrValues = 0x0000'0000;
            hal::addr_t addrColumnIndices = 0x0200'0000;
            hal::addr_t addrRowLengths = 0x0100'0000;

            hal::addr_t addrInputMatrix = 0x0300'0000;
            hal::addr_t addrOutputMatrix = 0x0400'0000;

            auto task = spmv::Task {
                .ptrValues = addrValues,
                .ptrColumnIndices = addrColumnIndices,
                .ptrRowLengths = addrRowLengths,
                .ptrInputVector = addrInputMatrix,
                .ptrOutputVector = addrOutputMatrix,
                .numValues = cspm.numValues / 8,
                .numRows = cspm.numRows / 8
            };

            dut.sourceTask.send(task.to_bv());
            fmt::print("Task is sent!\n");
        };

        SC_SPAWN_TO(j) {
            auto t = dut.sinkDone.receive().to_uint64();
            fmt::print("received: {} c, {} c/value\n", t, ((double)t) / cspm.numValues);
        };

        j.wait();

        auto mReceived = manager.readBatchVector(N, addrOutputMatrix);
        fmt::print("Batch vector is read!\n");

        fmt::print("Received vector:\n");
        mReceived.print();

        fmt::print("Sent vector:\n");
        m.print();

        auto mExpected = linalg::sparseMatrixProduct(cspm, m);
        fmt::print("Expected vector:\n");
        mExpected.print();

#endif

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
    trace_file->open(fmt::format("{}.vcd", "SpmvTop1").c_str());

    tb.start();

    trace_file->close();

    return 0;
}

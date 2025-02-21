#include <chext_test/chext_test.hpp>
#include <chext_test/util/Spawn.hpp>
#include <systemc>
#include <verilated_vcd_sc.h>

#include <cmath>
#include <limits>
#include <random>

#include <ElasticTop.hpp>

using namespace chext_test;
using namespace sc_core;
using namespace sc_dt;

inline sc_bv<32> fp32_to_bv(float f) {
    static_assert(sizeof(f) == 4);
    std::uint32_t cast = *reinterpret_cast<std::uint32_t*>(&f);
    return { cast };
}

inline sc_bv<64> fp64_to_bv(double f) {
    static_assert(sizeof(f) == 8);
    std::uint64_t cast = *reinterpret_cast<std::uint64_t*>(&f);
    return { cast };
}

inline float bv_to_fp32(const sc_bv<32>& bv) {
    static_assert(sizeof(float) == 4);
    std::uint32_t bits = bv.to_uint();
    return *reinterpret_cast<float*>(&bits);
}

inline double bv_to_fp64(const sc_bv<64>& bv) {
    static_assert(sizeof(double) == 8);
    std::uint64_t bits = bv.to_uint64();
    return *reinterpret_cast<double*>(&bits);
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

    ElasticTop dut;

private:
    sc_clock clock;
    sc_signal<bool> reset;

    void entry() override {
        resetDut();
        constexpr float rel_tolerance_fp32 = 1e-5f;
        constexpr double rel_tolerance_fp64 = 1e-10;

        auto relative_error = [](double expected, double actual) -> double {
            return std::abs(expected - actual) / std::max(std::abs(expected), 1e-30);
        };

        constexpr std::size_t num_random_tests = 1000;
        std::size_t num_tests = 0;

        std::random_device rd;
        std::mt19937 gen(rd());
        std::uniform_real_distribution<double> dist_fp32(-1e5f, 1e5f);
        std::uniform_real_distribution<double> dist_fp64(-1e10, 1e10);

        std::vector<float> fp32_a, fp32_b, fp32_expected_add, fp32_expected_mul;
        std::vector<double> fp64_a, fp64_b, fp64_expected_add, fp64_expected_mul;

        // Generate test inputs and expected outputs

        for (std::size_t i = 0; i < num_random_tests; ++i) {
            float a_fp32 = dist_fp32(gen);
            float b_fp32 = dist_fp32(gen);
            fp32_a.push_back(a_fp32);
            fp32_b.push_back(b_fp32);
            fp32_expected_add.push_back(a_fp32 + b_fp32);
            fp32_expected_mul.push_back(a_fp32 * b_fp32);

            double a_fp64 = dist_fp64(gen);
            double b_fp64 = dist_fp64(gen);
            fp64_a.push_back(a_fp64);
            fp64_b.push_back(b_fp64);
            fp64_expected_add.push_back(a_fp64 + b_fp64);
            fp64_expected_mul.push_back(a_fp64 * b_fp64);

            num_tests++;
        }

        std::vector<float> special_fp32 = {
            0.0f, -0.0f, 1.0f, -1.0f,
            std::numeric_limits<float>::max(),
            -std::numeric_limits<float>::max(),
            std::numeric_limits<float>::min(),
            -std::numeric_limits<float>::min()
        };

        std::vector<double> special_fp64 = {
            0.0, -0.0, 1.0f, -1.0f,
            std::numeric_limits<double>::max(),
            -std::numeric_limits<double>::max(),
            std::numeric_limits<double>::min(),
            -std::numeric_limits<double>::min()
        };

        for (float a : special_fp32) {
            for (float b : special_fp32) {
                fp32_a.push_back(a);
                fp32_b.push_back(b);
                fp32_expected_add.push_back(a + b);
                fp32_expected_mul.push_back(a * b);

                num_tests++;
            }
        }

        for (double a : special_fp64) {
            for (double b : special_fp64) {
                fp64_a.push_back(a);
                fp64_b.push_back(b);
                fp64_expected_add.push_back(a + b);
                fp64_expected_mul.push_back(a * b);

                // do not increment num_tests here
            }
        }

        sc_join j;

        // Spawn block for sending FP32 inputs
        SC_SPAWN_TO(j) {
            for (std::size_t i = 0; i < num_tests; ++i) {
                dut.fp32_inA.send(fp32_to_bv(fp32_a[i]));
            }
        };

        SC_SPAWN_TO(j) {
            for (std::size_t i = 0; i < num_tests; ++i) {
                dut.fp32_inB.send(fp32_to_bv(fp32_b[i]));
            }
        };

        // Spawn block for sending FP64 inputs
        SC_SPAWN_TO(j) {
            for (std::size_t i = 0; i < num_tests; ++i) {
                dut.fp64_inA.send(fp64_to_bv(fp64_a[i]));
            }
        };

        SC_SPAWN_TO(j) {
            for (std::size_t i = 0; i < num_tests; ++i) {
                dut.fp64_inB.send(fp64_to_bv(fp64_b[i]));
            }
        };

        // Spawn block for checking FP32 additions
        SC_SPAWN_TO(j) {
            for (std::size_t i = 0; i < num_tests; ++i) {
                double output_add = bv_to_fp32(dut.fp32_addOut.receive());
                double expected_add = fp32_expected_add[i];
                if (auto err = relative_error(expected_add, output_add); err > rel_tolerance_fp32) {
                    fmt::print(
                        "Mismatch in fp32 addition! A: {}, B: {}, Expected: {}, Got: {}, Rel Error: {}\n",
                        fp32_a[i], fp32_b[i], expected_add, output_add, err
                    );
                    throw 0;
                }
            }
        };

        // Spawn block for checking FP32 multiplications
        SC_SPAWN_TO(j) {
            for (std::size_t i = 0; i < num_tests; ++i) {
                double output_mul = bv_to_fp32(dut.fp32_multiplyOut.receive());
                double expected_mul = fp32_expected_mul[i];
                if (auto err = relative_error(expected_mul, output_mul); err > rel_tolerance_fp32) {
                    fmt::print(
                        "Mismatch in fp32 multiplication! A: {}, B: {}, Expected: {}, Got: {}, Rel Error: {}\n",
                        fp32_a[i], fp32_b[i], expected_mul, output_mul, err
                    );
                    throw 0;
                }
            }
        };

        // Spawn block for checking FP64 additions
        SC_SPAWN_TO(j) {
            for (std::size_t i = 0; i < num_tests; ++i) {
                double output_add = bv_to_fp64(dut.fp64_addOut.receive());
                double expected_add = fp64_expected_add[i];
                if (auto err = relative_error(expected_add, output_add); err > rel_tolerance_fp64) {
                    fmt::print(
                        "Mismatch in fp64 addition! A: {}, B: {}, Expected: {}, Got: {}, Rel Error: {}\n",
                        fp64_a[i], fp64_b[i], expected_add, output_add, err
                    );
                    throw 0;
                }
            }
        };

        // Spawn block for checking FP64 multiplications
        SC_SPAWN_TO(j) {
            for (std::size_t i = 0; i < num_tests; ++i) {
                double output_mul = bv_to_fp64(dut.fp64_multiplyOut.receive());
                double expected_mul = fp64_expected_mul[i];
                if (auto err = relative_error(expected_mul, output_mul); err > rel_tolerance_fp64) {
                    fmt::print(
                        "Mismatch in fp64 multiplication! A: {}, B: {}, Expected: {}, Got: {}, Rel Error: {}\n",
                        fp64_a[i], fp64_b[i], expected_mul, output_mul, err
                    );
                    throw 0;
                }
            }
        };

        j.wait();

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
    trace_file->open(fmt::format("{}.vcd", "ElasticTop").c_str());

    tb.start();

    trace_file->close();

    return 0;
}

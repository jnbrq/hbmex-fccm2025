#ifndef CHEXT_TEST_TESTBENCH_HPP_INCLUDED
#define CHEXT_TEST_TESTBENCH_HPP_INCLUDED

#include <fmt/core.h>
#include <systemc>

namespace chext_test {

#define CHEXT_TEST_EXPECT(x) TestBenchBase::__expect((x), __FILE__, __LINE__, #x)
#define CHEXT_TEST_EXPECT_EQ(a, b) TestBenchBase::__expect_eq((a), (b), __FILE__, __LINE__, #a, #b)
#define CHEXT_TEST_EXPECT_NE(a, b) TestBenchBase::__expect_ne((a), (b), __FILE__, __LINE__, #a, #b)
#define CHEXT_TEST_EXPECT_LT(a, b) TestBenchBase::__expect_lt((a), (b), __FILE__, __LINE__, #a, #b)
#define CHEXT_TEST_EXPECT_LE(a, b) TestBenchBase::__expect_le((a), (b), __FILE__, __LINE__, #a, #b)
#define CHEXT_TEST_EXPECT_GT(a, b) TestBenchBase::__expect_gt((a), (b), __FILE__, __LINE__, #a, #b)
#define CHEXT_TEST_EXPECT_GE(a, b) TestBenchBase::__expect_ge((a), (b), __FILE__, __LINE__, #a, #b)
#define CHEXT_TEST_EXPECT_EQ(a, b) TestBenchBase::__expect_eq((a), (b), __FILE__, __LINE__, #a, #b)

#define CHEXT_TEST_ASSERT(x) TestBenchBase::__assert_((x), __FILE__, __LINE__, #x)
#define CHEXT_TEST_ASSERT_EQ(a, b) TestBenchBase::__assert_eq((a), (b), __FILE__, __LINE__, #a, #b)
#define CHEXT_TEST_ASSERT_NE(a, b) TestBenchBase::__assert_ne((a), (b), __FILE__, __LINE__, #a, #b)
#define CHEXT_TEST_ASSERT_LT(a, b) TestBenchBase::__assert_lt((a), (b), __FILE__, __LINE__, #a, #b)
#define CHEXT_TEST_ASSERT_LE(a, b) TestBenchBase::__assert_le((a), (b), __FILE__, __LINE__, #a, #b)
#define CHEXT_TEST_ASSERT_GT(a, b) TestBenchBase::__assert_gt((a), (b), __FILE__, __LINE__, #a, #b)
#define CHEXT_TEST_ASSERT_GE(a, b) TestBenchBase::__assert_ge((a), (b), __FILE__, __LINE__, #a, #b)
#define CHEXT_TEST_ASSERT_EQ(a, b) TestBenchBase::__assert_eq((a), (b), __FILE__, __LINE__, #a, #b)

#if !defined(CHEXT_TEST_NO_SHORT_MACROS)

#    define EXPECT_(x) CHEXT_TEST_EXPECT(x)
#    define EXPECT_EQ(a, b) CHEXT_TEST_EXPECT_EQ(a, b)
#    define EXPECT_NE(a, b) CHEXT_TEST_EXPECT_NE(a, b)
#    define EXPECT_LT(a, b) CHEXT_TEST_EXPECT_LT(a, b)
#    define EXPECT_LE(a, b) CHEXT_TEST_EXPECT_LE(a, b)
#    define EXPECT_GT(a, b) CHEXT_TEST_EXPECT_GT(a, b)
#    define EXPECT_GE(a, b) CHEXT_TEST_EXPECT_GE(a, b)
#    define EXPECT_EQ(a, b) CHEXT_TEST_EXPECT_EQ(a, b)

#    define ASSERT_(x) CHEXT_TEST_ASSERT(x)
#    define ASSERT_EQ(a, b) CHEXT_TEST_ASSERT_EQ(a, b)
#    define ASSERT_NE(a, b) CHEXT_TEST_ASSERT_NE(a, b)
#    define ASSERT_LT(a, b) CHEXT_TEST_ASSERT_LT(a, b)
#    define ASSERT_LE(a, b) CHEXT_TEST_ASSERT_LE(a, b)
#    define ASSERT_GT(a, b) CHEXT_TEST_ASSERT_GT(a, b)
#    define ASSERT_GE(a, b) CHEXT_TEST_ASSERT_GE(a, b)
#    define ASSERT_EQ(a, b) CHEXT_TEST_ASSERT_EQ(a, b)

#endif

class TestBenchBase : public sc_core::sc_module {
public:
    TestBenchBase(sc_core::sc_module_name const& name = "tb")
        : sc_module { name } {
        SC_THREAD(entry);
    }

    void start(sc_core::sc_time const& duration = sc_core::sc_time(50, sc_core::SC_NS)) {
        while (!stopped_) {
            sc_start(duration);
        }
    }

    virtual ~TestBenchBase() = default;

protected:
    void finish() {
        stop();
    }

    void __expect(bool expr, char const* file = nullptr, int line = -1, char const* msg = nullptr) {
        if (expr)
            return;

        fmt::print(
            "[ {} ] EXPECT Fail: {} is FALSE (t = {}) ({}:{})\n",
            this->name(),
            msg,
            sc_core::sc_time_stamp().to_string(),
            file, line
        );
    }

    void __expect_not(bool expr, char const* file = nullptr, int line = -1, char const* msg = nullptr) {
        if (!expr)
            return;

        fmt::print(
            "[ {} ] EXPECT_NOT Fail: {} is TRUE (t = {}) ({}:{})\n",
            this->name(),
            msg,
            sc_core::sc_time_stamp().to_string(),
            file, line
        );
    }

#define EXPECT_BINARY_OP(param1, param2, param3, param4)                                                \
    template<typename T1, typename T2>                                                                  \
    void __expect_##param1(                                                                             \
        T1 const& a,                                                                                    \
        T2 const& b,                                                                                    \
        char const* file = nullptr,                                                                     \
        int line = -1,                                                                                  \
        char const* a_str = nullptr,                                                                    \
        char const* b_str = nullptr                                                                     \
    ) {                                                                                                 \
        if (a param3 b)                                                                                 \
            return;                                                                                     \
                                                                                                        \
        fmt::print(                                                                                     \
            "[ {} ] EXPECT_" #param2 " Fail: {} " #param4 " {} ({} " #param4 " {}) (t = {}) ({}:{})\n", \
            this->name(),                                                                               \
            a_str, b_str,                                                                               \
            a, b,                                                                                       \
            sc_core::sc_time_stamp().to_string(),                                                       \
            file, line                                                                                  \
        );                                                                                              \
    }

    EXPECT_BINARY_OP(eq, EQ, ==, !=)
    EXPECT_BINARY_OP(ne, NE, !=, ==)
    EXPECT_BINARY_OP(lt, LT, <, >=)
    EXPECT_BINARY_OP(le, LE, <=, >)
    EXPECT_BINARY_OP(gt, GT, >, <=)
    EXPECT_BINARY_OP(ge, GE, >=, <)

#undef EXPECT_BINARY_OP

    void __assert_(bool expr, char const* file = nullptr, int line = -1, char const* msg = nullptr) {
        if (expr)
            return;

        fmt::print(
            "[ {} ] ASSERT Fail: {} is FALSE (t = {}) ({}:{})\n",
            this->name(),
            msg,
            sc_core::sc_time_stamp().to_string(),
            file, line
        );

        stop();
    }

    void __assert_not(bool expr, char const* file = nullptr, int line = -1, char const* msg = nullptr) {
        if (!expr)
            return;

        fmt::print(
            "[ {} ] ASSERT_NOT Fail: {} is TRUE (t = {}) ({}:{})\n",
            this->name(),
            msg,
            sc_core::sc_time_stamp().to_string(),
            file, line
        );

        stop();
    }

#define ASSERT_BINARY_OP(param1, param2, param3, param4)                                                \
    template<typename T1, typename T2>                                                                  \
    void __assert_##param1(                                                                             \
        T1 const& a,                                                                                    \
        T2 const& b,                                                                                    \
        char const* file = nullptr,                                                                     \
        int line = -1,                                                                                  \
        char const* a_str = nullptr,                                                                    \
        char const* b_str = nullptr                                                                     \
    ) {                                                                                                 \
        if (a param3 b)                                                                                 \
            return;                                                                                     \
                                                                                                        \
        fmt::print(                                                                                     \
            "[ {} ] ASSERT_" #param2 " Fail: {} " #param4 " {} ({} " #param4 " {}) (t = {}) ({}:{})\n", \
            this->name(),                                                                               \
            a_str, b_str,                                                                               \
            a, b,                                                                                       \
            sc_core::sc_time_stamp().to_string(),                                                       \
            file, line                                                                                  \
        );                                                                                              \
        stop();                                                                                         \
    }

    ASSERT_BINARY_OP(eq, EQ, ==, !=)
    ASSERT_BINARY_OP(ne, NE, !=, ==)
    ASSERT_BINARY_OP(lt, LT, <, >=)
    ASSERT_BINARY_OP(le, LE, <=, >)
    ASSERT_BINARY_OP(gt, GT, >, <=)
    ASSERT_BINARY_OP(ge, GE, >=, <)

#undef ASSERT_BINARY_OP

    virtual void entry() = 0;

private:
    bool stopped_ = false;

    void stop() {
        sc_core::sc_stop();
        stopped_ = true;
    }
};

} // namespace chext_test

#endif /* CHEXT_TEST_TESTBENCH_HPP_INCLUDED */

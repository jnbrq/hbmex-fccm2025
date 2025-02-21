#include <chext_test/chext_test.hpp>

using namespace sc_core;
using namespace sc_dt;

template<int W>
struct fmt::formatter<sc_bv<W>> : ostream_formatter {};

template<>
struct fmt::formatter<sc_bv_base> : ostream_formatter {};

template<int W>
struct fmt::formatter<sc_uint<W>> : ostream_formatter {};

template<>
struct fmt::formatter<sc_uint_base> : ostream_formatter {};

struct TestBench1 : chext_test::TestBenchBase {
    TestBench1()
        : TestBenchBase { "TestBench1" } {
    }

protected:
    void entry() override {
        using chext_test::util::scDump;
        using chext_test::util::ScDumpOptions;

        fmt::print("hello world!\n");
        wait(50, SC_NS);
        fmt::print("bye!\n");

        int x = 98;
        int y = 9;
        EXPECT_EQ(x, y);

        EXPECT_LT(x, y);

        chext_test::amba::axi4::full::Packets::Address ar1, ar2;
        ar1.addr = sc_bv<20>(0x10000);
        ar2.addr = sc_bv<20>(0x20000);

        sc_bv_base num1 { sc_bv<16>(0x1400) };
        sc_bv_base num2 { 32 };

        num2 = 0x1400;

        fmt::print("lengths of ar1 and ar2: {}, {}\n", ar1.addr.length(), ar2.addr.length());
        fmt::print("num1 = {}, num2 = {}, lengths: {}, {}\n", scDump(num1), scDump(num2), num1.length(), num2.length());

        num2 = 0xFFFF'FFFF;
        fmt::print("num2 = {}\n", scDump(num2, { .numrep = SC_HEX, .hasPrefix = true, .groupWidth = 4 }));

        num1 = 0xffff'1234;
        num2 = sc_bv<8>(0x99);
        fmt::print("num1 = {}, num2 = {}, lengths: {}, {}\n", num1, num2, num1.length(), num2.length());

        // lesson learned: sc_bv_base retains its original length that it was constructed with

        EXPECT_EQ(ar1, ar2);

        sc_bv<8> a(89);
        sc_bv<9> b(100);
        EXPECT_EQ(a, b);

        sc_bv_base xx(a);
        sc_bv_base yy(b);

        EXPECT_EQ(xx, yy);
        EXPECT_NE(xx, yy);
        // EXPECT_LE(xx, yy);

        sc_uint_base xxx(a);
        sc_uint_base yyy(b);

        EXPECT_EQ(xxx, yyy);
        EXPECT_NE(xxx, yyy);
        EXPECT_LE(xxx, yyy);
        EXPECT_GT(xxx, yyy);

        wait(10000, SC_NS);

        fmt::print("{}\n", sc_time_stamp().to_string());

        chext_test::amba::axi4::lite::Packets::Address arLite1 {
            .addr = sc_bv<12>(0x800)
        };

        chext_test::amba::axi4::lite::Packets::Address arLite2 {
            .addr = sc_bv<12>(0xA00)
        };

        chext_test::amba::axi4::lite::Packets::Address arLite3 {
            .addr = sc_bv<12>(0x800)
        };

        fmt::print("arLite1 = {}, arLite2 = {}\n", arLite1, arLite2);
        fmt::print("arLite1 == arLite2 = {}\n", arLite1 == arLite2);
        fmt::print("arLite1 == arLite3 = {}\n", arLite1 == arLite3);

        chext_test::amba::axi4::full::Packets::ReadData readData {
            .id = sc_bv<4>(0xA),
            .data = sc_bv<32>(0xDEAD'BEEF),
            .resp = 3,
            .last = true,
            .user = sc_bv<8>(0xAB)
        };

        fmt::print("readData = {}\n", readData);

        chext_test::amba::axi4::full::Packets::WriteData writeData {
            .data = sc_bv<32>(0xDEAD'BEEF),
            .strb = sc_bv<4>(0b1000),
            .last = true,
            .user = sc_bv<8>(0xAB)
        };

        fmt::print("writeData = {}\n", writeData);

        chext_test::amba::axi4::full::Packets::WriteResponse writeResponse {
            .id = sc_bv<4>(0xA),
            .resp = 2,
            .user = sc_bv<8>(0xAB)
        };

        fmt::print("writeResponse = {}\n", writeResponse);

        chext_test::amba::axi4::lite::Packets::ReadData readDataLite {
            .data = sc_bv<32>(0xDEAD'BEEF),
            .resp = 3
        };

        fmt::print("readDataLite = {}\n", readDataLite);

        chext_test::amba::axi4::lite::Packets::WriteData writeDataLite {
            .data = sc_bv<32>(0xDEAD'BEEF),
            .strb = sc_bv<4>(0b1000)
        };

        fmt::print("writeDataLite = {}\n", writeDataLite);

        chext_test::amba::axi4::lite::Packets::WriteResponse writeResponseLite {
            .resp = 2
        };

        fmt::print("writeResponseLite = {}\n", writeResponseLite);

        finish();
    }
};

int sc_main(int argc, char** argv) {
    TestBench1 tb;
    tb.start();
    return 0;
}

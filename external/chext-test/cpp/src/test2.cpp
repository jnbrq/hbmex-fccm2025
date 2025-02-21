#include <systemc>

#include <chrono>
#include <compare>
#include <iostream>
#include <sstream>
#include <tuple>

#include <fmt/chrono.h>
#include <fmt/core.h>

#include <jqr/comp_eq.hpp>
#include <jqr/core.hpp>
#include <jqr/dump.hpp>
#include <jqr/hash.hpp>

namespace o = jqr::opts;

struct Student {
    std::string name, surname;
    float gpa;
    std::chrono::system_clock::time_point date;

    JQR_DECL(
        Student,
        JQR_MEMBER(name, o::dump_fmt { "'{}'" }, o::dump_name { false }),
        JQR_MEMBER(surname, o::dump_fmt { "'{}'" }, o::dump_name { false }),
        JQR_MEMBER(gpa, o::dump_fmt { "{:1.2f}" }),
        JQR_MEMBER(date, o::dump_fmt { "'{:%F %T}'" })
    );
    JQR_TO_STRING;
};

struct Test {
    int a;
    int b;

    struct Nested {
        int x, y;

        JQR_DECL(Nested, JQR_MEMBER(x), JQR_MEMBER(y))
    } n;

    JQR_DECL(
        Test,
        JQR_MEMBER(a, o::dump_fmt { "0d{:05d}" }),
        JQR_MEMBER(b, o::dump_fmt { "0b{:b}" }),
        JQR_MEMBER(n, o::dump_class { false })
    )

    JQR_TO_STRING
};

template<typename T>
struct Log {
    int t;
    T obj;

    JQR_DECL(
        Log,
        JQR_MEMBER(t),
        JQR_MEMBER(obj)
    )

    JQR_OPTIONS(o::dump_paren { false })
    JQR_TO_STRING
};

struct Struct1 {
    int a, b, c;

    JQR_DECL(
        Struct1,
        JQR_MEMBER(a, o::comp_eq { false }),
        JQR_MEMBER(b),
        JQR_MEMBER(c)
    )

    JQR_COMP_EQ
};

// must be in global scope
JQR_DEFINE_STD_HASH(Struct1)

struct Struct2 {
    int a, b, c;

    JQR_DECL(
        Struct2,
        JQR_MEMBER(a),
        JQR_MEMBER(b),
        JQR_MEMBER(c, o::hash { false })
    )
};

struct VeryBareStruct {
    int (*x)(void*);
    const char* y;
};

struct Struct3 {
    VeryBareStruct x;

    JQR_DECL(
        Struct3,
        JQR_MEMBER(x)
    )

    JQR_COMP_EQ
};

struct Struct4 {
    VeryBareStruct x;

    JQR_DECL(
        Struct4,
        JQR_MEMBER(x, o::comp_eq { false })
    )

    JQR_COMP_EQ
};

#include <unordered_map>

int sc_main(int, char**) {
    Student s {
        .name = "Canberk",
        .surname = "Sönmez",
        .gpa = 4.0,
        .date = std::chrono::system_clock::now()
    };
    fmt::print("s = {}\n", s);

    int y;
    static Test t;
    constexpr auto x = jqr::members_of(t);

    Test t2 { 4, 5 };
    std::cout << t2.to_string() << std::endl;

    fmt::print("Is JQR? {}\n", jqr::is_jqr_v<Test>);
    fmt::print("Is JQR? {}\n", jqr::is_jqr_v<int>);

    fmt::print("Test object is: {}\n", Log<Test> { 5, t2 });

    fmt::print("object hash: {}\n", jqr::hash(std::string("canberk")));

    Struct1 s1 { 10, 20, 30 };
    Struct2 s2 { 10, 20, 30 };

    fmt::print("object hash: s1={}, s2={}\n", jqr::hash(s1), jqr::hash(s2));

    std::unordered_map<Struct1, std::string> map;

    Struct1 s1_a { 10, 20, 30 }, s1_b { 20, 20, 30 }, s1_c { 10, 25, 30 };
    auto result1 = s1_a == s1_b;
    auto result2 = s1_a == s1_c;
    fmt::print("s1_a = {}, s1_b = {}, equals = {}\n", s1_a, s1_b, result1);
    fmt::print("s1_a = {}, s1_c = {}, equals = {}\n", s1_a, s1_c, result2);

    Struct3 s3_a, s3_b;
    auto result3 = s3_a == s3_b;
    fmt::print("s3_a = {}, s3_b = {}, equals = {}\n", s3_a, s3_b, result3);

    Struct4 s4_a, s4_b;
    auto result4 = s4_a == s4_b;
    fmt::print("s4_a = {}, s4_b = {}, equals = {}\n", s4_a, s4_b, result4);

    return 0;
}

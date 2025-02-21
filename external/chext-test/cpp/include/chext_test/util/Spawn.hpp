#ifndef CHEXT_TEST_UTIL_SPAWNJOIN_HPP_INCLUDED
#define CHEXT_TEST_UTIL_SPAWNJOIN_HPP_INCLUDED

#include <sysc/kernel/sc_spawn.h>
#include <sysc/kernel/sc_join.h>

namespace chext_test::util::detail {

constexpr struct {
    template<typename T>
    auto operator+(T&& t) const {
        return ::sc_core::sc_spawn(std::forward<T>(t));
    }
} sc_spawn_helper;

struct sc_spawn_to_helper_t {
    ::sc_core::sc_join& j;

    template<typename T>
    void operator+(T&& t) const {
        auto handle = ::sc_core::sc_spawn(std::forward<T>(t));
        j.add_process(handle);
    }
};

} // namespace chext::util::detail

#define SC_SPAWN ::chext_test::util::detail::sc_spawn_helper + [&]
#define SC_SPAWN_TO(j) ::chext_test::util::detail::sc_spawn_to_helper_t { (j) } + [&]

#endif /* CHEXT_TEST_UTIL_SPAWNJOIN_HPP_INCLUDED */

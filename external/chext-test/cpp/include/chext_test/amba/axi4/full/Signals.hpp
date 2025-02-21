#ifndef CHEXT_TEST_AMBA_AXI4_FULL_SIGNALS_HPP_INCLUDED
#define CHEXT_TEST_AMBA_AXI4_FULL_SIGNALS_HPP_INCLUDED

#include <chext_test/amba/axi4/full/Packets.hpp>
#include <fmt/core.h>
#include <systemc>

namespace chext_test::amba::axi4::full {

namespace detail {

using namespace sc_core;
using namespace sc_dt;

template<unsigned WIDTH>
struct bv_bool_helper {
    using type = sc_bv<WIDTH>;

    template<sc_writer_policy WP>
    static auto peek(sc_signal<type, WP> const& lock) {
        return lock.read().to_uint();
    }
};

template<>
struct bv_bool_helper<1> {
    using type = bool;

    template<sc_writer_policy WP>
    static auto peek(sc_signal<type, WP> const& lock) {
        return lock.read();
    }
};

template<unsigned WIDTH>
using bv_bool_t = typename bv_bool_helper<WIDTH>::type;

constexpr unsigned notZeroOr(unsigned x, unsigned y) {
    return x > 0 ? x : y;
}

template<
    unsigned ID_WIDTH,
    unsigned ADDR_WIDTH,
    unsigned DATA_WIDTH,
    unsigned ARUSER_WIDTH = 0,
    unsigned RUSER_WIDTH = 0,
    unsigned AWUSER_WIDTH = 0,
    unsigned WUSER_WIDTH = 0,
    unsigned BUSER_WIDTH = 0,
    bool AXI3_COMPAT = false>
struct Signals {
    static constexpr unsigned wId = ID_WIDTH;
    static constexpr unsigned wAddr = ADDR_WIDTH;
    static constexpr unsigned wData = DATA_WIDTH;
    static constexpr unsigned wUserAR = ARUSER_WIDTH;
    static constexpr unsigned wUserR = RUSER_WIDTH;
    static constexpr unsigned wUserAW = AWUSER_WIDTH;
    static constexpr unsigned wUserW = WUSER_WIDTH;
    static constexpr unsigned wUserB = BUSER_WIDTH;

    static constexpr bool axi3Compat = AXI3_COMPAT;
    static constexpr unsigned wLen = axi3Compat ? 4 : 8;
    static constexpr unsigned wLock = axi3Compat ? 2 : 1;

    static constexpr unsigned wStrb = wData >> 3;

    struct ReadAddress {
        using value_type = Packets::ReadAddress;

        sc_signal<sc_bv<notZeroOr(wId, 32)>, SC_MANY_WRITERS> id;
        sc_signal<sc_bv<wAddr>, SC_MANY_WRITERS> addr;
        sc_signal<sc_bv<wLen>, SC_MANY_WRITERS> len;
        sc_signal<sc_bv<3>, SC_MANY_WRITERS> size;
        sc_signal<sc_bv<2>, SC_MANY_WRITERS> burst;
        sc_signal<bv_bool_t<wLock>, SC_MANY_WRITERS> lock;
        sc_signal<sc_bv<4>, SC_MANY_WRITERS> cache;
        sc_signal<sc_bv<3>, SC_MANY_WRITERS> prot;
        sc_signal<sc_bv<4>, SC_MANY_WRITERS> qos;
        sc_signal<sc_bv<4>, SC_MANY_WRITERS> region;
        sc_signal<sc_bv<notZeroOr(wUserAR, 32)>, SC_MANY_WRITERS> user;

        ReadAddress(const char* name)
            : id(fmt::format("{}_id", name).c_str())
            , addr(fmt::format("{}_addr", name).c_str())
            , len(fmt::format("{}_len", name).c_str())
            , size(fmt::format("{}_size", name).c_str())
            , burst(fmt::format("{}_burst", name).c_str())
            , lock(fmt::format("{}_lock", name).c_str())
            , cache(fmt::format("{}_cache", name).c_str())
            , prot(fmt::format("{}_prot", name).c_str())
            , qos(fmt::format("{}_qos", name).c_str())
            , region(fmt::format("{}_region", name).c_str())
            , user(fmt::format("{}_user", name).c_str()) {}

        void writeFrom(value_type const& packet) {
            id.write(packet.id);
            addr.write(packet.addr);
            len.write(packet.len);
            size.write(packet.size);
            burst.write(packet.burst);
            lock.write(packet.lock);
            cache.write(packet.cache);
            prot.write(packet.prot);
            qos.write(packet.qos);
            region.write(packet.region);
            user.write(packet.user);
        }

        void readTo(value_type& packet) const {
            packet.~value_type();

            new (&packet) value_type {
                .id = id.read(),
                .addr = addr.read(),
                .len = len.read().to_uint(),
                .size = size.read().to_uint(),
                .burst = burst.read().to_uint(),
                .lock = bv_bool_helper<wLock>::peek(lock),
                .cache = cache.read().to_uint(),
                .prot = prot.read().to_uint(),
                .qos = qos.read().to_uint(),
                .region = region.read().to_uint(),
                .user = user.read()
            };
        }
    };

    struct ReadData {
        using value_type = Packets::ReadData;

        sc_signal<sc_bv<notZeroOr(wId, 32)>, SC_MANY_WRITERS> id;
        sc_signal<sc_bv<wData>, SC_MANY_WRITERS> data;
        sc_signal<sc_bv<2>, SC_MANY_WRITERS> resp;
        sc_signal<bool, SC_MANY_WRITERS> last;
        sc_signal<sc_bv<notZeroOr(wUserR, 32)>, SC_MANY_WRITERS> user;

        ReadData(const char* name)
            : id(fmt::format("{}_id", name).c_str())
            , data(fmt::format("{}_data", name).c_str())
            , resp(fmt::format("{}_resp", name).c_str())
            , last(fmt::format("{}_last", name).c_str())
            , user(fmt::format("{}_user", name).c_str()) {}

        void writeFrom(value_type const& packet) {
            id.write(packet.id);
            data.write(packet.data);
            resp.write(packet.resp);
            last.write(packet.last);
            user.write(packet.user);
        }

        void readTo(value_type& packet) const {
            packet.~value_type();

            new (&packet) value_type {
                .id = id.read(),
                .data = data.read(),
                .resp = resp.read().to_uint(),
                .last = last.read(),
                .user = user.read()
            };
        }
    };

    struct WriteAddress {
        using value_type = Packets::WriteAddress;

        sc_signal<sc_bv<notZeroOr(wId, 32)>, SC_MANY_WRITERS> id;
        sc_signal<sc_bv<wAddr>, SC_MANY_WRITERS> addr;
        sc_signal<sc_bv<wLen>, SC_MANY_WRITERS> len;
        sc_signal<sc_bv<3>, SC_MANY_WRITERS> size;
        sc_signal<sc_bv<2>, SC_MANY_WRITERS> burst;
        sc_signal<bv_bool_t<wLock>, SC_MANY_WRITERS> lock;
        sc_signal<sc_bv<4>, SC_MANY_WRITERS> cache;
        sc_signal<sc_bv<3>, SC_MANY_WRITERS> prot;
        sc_signal<sc_bv<4>, SC_MANY_WRITERS> qos;
        sc_signal<sc_bv<4>, SC_MANY_WRITERS> region;
        sc_signal<sc_bv<notZeroOr(wUserAW, 32)>, SC_MANY_WRITERS> user;

        WriteAddress(const char* name)
            : id(fmt::format("{}_id", name).c_str())
            , addr(fmt::format("{}_addr", name).c_str())
            , len(fmt::format("{}_len", name).c_str())
            , size(fmt::format("{}_size", name).c_str())
            , burst(fmt::format("{}_burst", name).c_str())
            , lock(fmt::format("{}_lock", name).c_str())
            , cache(fmt::format("{}_cache", name).c_str())
            , prot(fmt::format("{}_prot", name).c_str())
            , qos(fmt::format("{}_qos", name).c_str())
            , region(fmt::format("{}_region", name).c_str())
            , user(fmt::format("{}_user", name).c_str()) {}

        void writeFrom(value_type const& packet) {
            id.write(packet.id);
            addr.write(packet.addr);
            len.write(packet.len);
            size.write(packet.size);
            burst.write(packet.burst);
            lock.write(packet.lock);
            cache.write(packet.cache);
            prot.write(packet.prot);
            qos.write(packet.qos);
            region.write(packet.region);
            user.write(packet.user);
        }

        void readTo(value_type& packet) const {
            packet.~value_type();

            new (&packet) value_type {
                .id = id.read(),
                .addr = addr.read(),
                .len = len.read().to_uint(),
                .size = size.read().to_uint(),
                .burst = burst.read().to_uint(),
                .lock = bv_bool_helper<wLock>::peek(lock),
                .cache = cache.read().to_uint(),
                .prot = prot.read().to_uint(),
                .qos = qos.read().to_uint(),
                .region = region.read().to_uint(),
                .user = user.read()
            };
        }
    };

    struct WriteData {
        using value_type = Packets::WriteData;

        sc_signal<sc_bv<wData>, SC_MANY_WRITERS> data;
        sc_signal<sc_bv<wStrb>, SC_MANY_WRITERS> strb;
        sc_signal<bool, SC_MANY_WRITERS> last;
        sc_signal<sc_bv<notZeroOr(wUserW, 32)>, SC_MANY_WRITERS> user;

        WriteData(const char* name)
            : data(fmt::format("{}_data", name).c_str())
            , strb(fmt::format("{}_strb", name).c_str())
            , last(fmt::format("{}_last", name).c_str())
            , user(fmt::format("{}_user", name).c_str()) {}

        void writeFrom(value_type const& packet) {
            data.write(packet.data);
            strb.write(packet.strb);
            last.write(packet.last);
            user.write(packet.user);
        }

        void readTo(value_type& packet) const {
            packet.~value_type();

            new (&packet) value_type {
                .data = data.read(),
                .strb = strb.read(),
                .last = last.read(),
                .user = user.read()
            };
        }
    };

    struct WriteResponse {
        using value_type = Packets::WriteResponse;

        sc_signal<sc_bv<notZeroOr(wId, 32)>, SC_MANY_WRITERS> id;
        sc_signal<sc_bv<2>, SC_MANY_WRITERS> resp;
        sc_signal<sc_bv<notZeroOr(wUserB, 32)>, SC_MANY_WRITERS> user;

        WriteResponse(const char* name)
            : id(fmt::format("{}_id", name).c_str())
            , resp(fmt::format("{}_resp", name).c_str())
            , user(fmt::format("{}_user", name).c_str()) {}

        void writeFrom(value_type const& packet) {
            id.write(packet.id);
            resp.write(packet.resp);
            user.write(packet.user);
        }

        void readTo(value_type& packet) const {
            packet.~value_type();

            new (&packet) value_type {
                .id = id.read(),
                .resp = resp.read().to_uint(),
                .user = user.read()
            };
        }
    };
};

} // namespace detail

using detail::Signals;

} // namespace chext_test::amba::axi4::full

#endif /* CHEXT_TEST_AMBA_AXI4_FULL_SIGNALS_HPP_INCLUDED */

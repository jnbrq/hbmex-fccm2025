#ifndef CHEXT_TEST_AMBA_AXI4_LITE_HAL_HPP_INCLUDED
#define CHEXT_TEST_AMBA_AXI4_LITE_HAL_HPP_INCLUDED

#include <cassert>

#include <chext_test/amba/axi4/lite/Driver.hpp>
#include <chext_test/util/Spawn.hpp>
#include <hal/hal.hpp>

#warning "This file should be properly tested!"

namespace chext_test::amba::axi4::lite {

/**
 * @brief Wraps a `SlaveBase` and returns a `hal::Memory`.
 *
 * @param slave
 * @return std::unique_ptr<hal::Memory>
 */
inline std::shared_ptr<hal::Memory> wrapSlave(SlaveBase& slave) {
    struct Memory : hal::Memory {
        explicit Memory(axi4::lite::SlaveBase& slave)
            : slave_(slave)
            , cfg_ { slave.config() } {

            assert(cfg_.wData == 32 || cfg_.wData == 64);
        }

        void write(hal::addr_t dest_addr, uint8_t const* src, hal::size_t size) override {
            assert(false);
        }

        void read(uint8_t* dest, hal::addr_t src_addr, hal::size_t size) override {
            assert(false);
        }

        void writeReg32(hal::addr_t addr, uint32_t value) override {
            if (cfg_.wData == 32) {
                writeImpl(addr & ~((hal::addr_t)0x3), sc_dt::sc_bv<32>(value), 0xF);
            } else {
                auto result = readReg64(addr);

                if ((addr >> 2) & 1) {
                    writeImpl(addr & ~((hal::addr_t)0x7), sc_dt::sc_bv<64>(((uint64_t)value) << 32), 0xF0);
                } else {
                    writeImpl(addr & ~((hal::addr_t)0x7), sc_dt::sc_bv<64>((uint64_t)value), 0x0F);
                }
            }
        }

        void writeReg64(hal::addr_t addr, uint64_t value) override {
            if (cfg_.wData == 64) {
                writeImpl(addr & ~((hal::addr_t)0x7), sc_dt::sc_bv<64>(value), 0xFF);
            } else {
                std::uint32_t low = value;
                std::uint32_t high = value >> 32;

                writeReg32((addr & ~((hal::addr_t)0x3)), low);
                writeReg32((addr & ~((hal::addr_t)0x3)), high);
            }
        }

        uint32_t readReg32(hal::addr_t addr) override {
            if (cfg_.wData == 32) {
                return readImpl(addr & ~((hal::addr_t)0x3)).to_uint64();
            } else {
                auto result = readReg64(addr);

                if ((addr >> 2) & 1) {
                    return result >> 32;
                } else {
                    return result;
                }
            }
        }

        uint64_t readReg64(hal::addr_t addr) override {
            if (cfg_.wData == 32) {
                std::uint64_t low = readReg32((addr & ~((hal::addr_t)0x3)));
                std::uint64_t high = readReg32((addr & ~((hal::addr_t)0x3)) + 4);

                return (high << 32) | low;
            } else {
                return readImpl(addr & ~((hal::addr_t)0x7)).to_uint64();
            }
        }

    private:
        axi4::lite::SlaveBase& slave_;
        axi4::lite::Config const& cfg_;

        sc_dt::sc_bv_base readImpl(hal::addr_t addr) {
            sc_core::sc_join j;
            sc_dt::sc_bv_base result;

            SC_SPAWN_TO(j) {
                slave_.sendAR({ .addr = sc_dt::sc_bv<64>(addr), .prot = 0 });
            };

            SC_SPAWN_TO(j) {
                new (&result) sc_dt::sc_bv_base(slave_.receiveR().data);
            };

            j.wait();

            return result;
        }

        void writeImpl(hal::addr_t addr, sc_dt::sc_bv_base const& data, std::uint8_t strb) {
            sc_core::sc_join j;

            SC_SPAWN_TO(j) {
                slave_.sendAW({ .addr = sc_dt::sc_bv<64>(addr) });
            };

            SC_SPAWN_TO(j) {
                slave_.sendW({ .data = data, .strb = sc_dt::sc_bv<8>(strb) });
            };

            SC_SPAWN_TO(j) {
                slave_.receiveB();
            };

            j.wait();
        }
    };

    return std::make_shared<Memory>(slave);
}

} // namespace chext_test::amba::axi4::lite

#endif // CHEXT_TEST_AMBA_AXI4_LITE_HAL_HPP_INCLUDED

#ifndef CHEXT_TEST_AMBA_AXI4_FULL_HAL_HPP_INCLUDED
#define CHEXT_TEST_AMBA_AXI4_FULL_HAL_HPP_INCLUDED

#include <chext_test/amba/axi4/full/Driver.hpp>
#include <chext_test/amba/axi4/full/Transaction.hpp>
#include <hal/hal.hpp>

namespace chext_test::amba::axi4::full {

/**
 * @brief Wraps a `SlaveBase` and returns a `hal::Memory`.
 *
 * @param slave
 * @return std::unique_ptr<hal::Memory>
 */
inline std::shared_ptr<hal::Memory> wrapSlave(SlaveBase& slave) {
    struct Memory : hal::Memory {
        explicit Memory(axi4::full::SlaveBase& slave)
            : slave_(slave) {}

        void write(hal::addr_t dest_addr, uint8_t const* src, hal::size_t size) override {
            chext_test::amba::axi4::full::write(slave_, dest_addr, size, src);
        }

        void read(uint8_t* dest, hal::addr_t src_addr, hal::size_t size) override {
            chext_test::amba::axi4::full::read(slave_, src_addr, size, dest);
        }

        void writeReg32(hal::addr_t addr, uint32_t value) override {
            uint8_t data[4];
            std::memcpy(data, &value, sizeof(value));
            write(addr, data, sizeof(value));
        }

        void writeReg64(hal::addr_t addr, uint64_t value) override {
            uint8_t data[8];
            std::memcpy(data, &value, sizeof(value));
            write(addr, data, sizeof(value));
        }

        uint32_t readReg32(hal::addr_t addr) override {
            uint8_t data[4];
            read(data, addr, sizeof(data));
            uint32_t value;
            std::memcpy(&value, data, sizeof(value));
            return value;
        }

        uint64_t readReg64(hal::addr_t addr) override {
            uint8_t data[8];
            read(data, addr, sizeof(data));
            uint64_t value;
            std::memcpy(&value, data, sizeof(value));
            return value;
        }

    private:
        axi4::full::SlaveBase& slave_;
    };

    return std::make_shared<Memory>(slave);
}

} // namespace chext_test::amba::axi4::full

#endif // CHEXT_TEST_AMBA_AXI4_FULL_HAL_HPP_INCLUDED

#include <hal/d4e.hpp>
#include <hal/hal.hpp>

#include <chrono>
#include <thread>

namespace d4e {

struct Memory : hal::Memory {
    Memory(d4e_device* device)
        : device_ { device } {
    }

    void write(hal::addr_t dest_addr, hal::uint8_t const* src, hal::size_t size) override {
        d4e_dma_h2d(device_, dest_addr, src, size);
    }

    void read(uint8_t* dest, hal::addr_t src_addr, hal::size_t size) override {
        d4e_dma_d2h(device_, dest, src_addr, size);
    }

    void writeReg32(hal::addr_t addr, hal::uint32_t value) override {
        d4e_reg_write32(device_, addr, value);
    }

    void writeReg64(hal::addr_t addr, hal::uint64_t value) override {
        d4e_reg_write64(device_, addr, value);
    }

    uint32_t readReg32(hal::addr_t addr) override {
        return d4e_reg_read32(device_, addr);
    }

    uint64_t readReg64(hal::addr_t addr) override {
        return d4e_reg_read64(device_, addr);
    }

    ~Memory() = default;

private:
    d4e_device* device_;
};

struct Sleep : hal::Sleep {
    void sleep(uint64_t ns) override {
        std::this_thread::sleep_for(std::chrono::nanoseconds(ns));
    }

    ~Sleep() = default;
};

std::shared_ptr<hal::Sleep> sleep() {
    static auto sleepImpl = std::make_shared<Sleep>();
    return sleepImpl;
}

std::shared_ptr<hal::Memory> wrapDevice(d4e_device* dev) {
    return std::make_shared<Memory>(dev);
}

} // namespace d4e

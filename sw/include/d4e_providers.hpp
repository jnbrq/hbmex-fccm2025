#ifndef D4E_PROVIDERS_HPP_INCLUDED
#define D4E_PROVIDERS_HPP_INCLUDED

#include <d4e/interface.h>
#include <chrono>
#include <thread>

#include "Providers.hpp"

struct d4e_memory_provider : providers::Memory {
    d4e_memory_provider(d4e_device* device)
        : device_ { device } {
    }

    void copyToDevice(uint64_t dest_addr, uint8_t const* src, uint32_t size) override {
        d4e_dma_h2d(device_, dest_addr, src, size);
    }

    void copyFromDevice(uint8_t* dest, uint64_t src_addr, uint32_t size) override {
        d4e_dma_d2h(device_, dest, src_addr, size);
    }

    void writeReg32(uint32_t addr, uint32_t value) override {
        d4e_reg_write32(device_, addr, value);
    }

    void writeReg64(uint32_t addr, uint64_t value) override {
        d4e_reg_write64(device_, addr, value);
    }

    uint32_t readReg32(uint32_t addr) override {
        return d4e_reg_read32(device_, addr);
    }

    uint64_t readReg64(uint64_t addr) override {
        return d4e_reg_read64(device_, addr);
    }

    ~d4e_memory_provider() = default;

private:
    d4e_device* device_;
};

struct sleep_provider : providers::Sleep {
    void sleep(uint64_t ns) override {
        std::this_thread::sleep_for(std::chrono::nanoseconds(ns));
    }

    ~sleep_provider() = default;
};

#endif // D4E_PROVIDERS_HPP_INCLUDED

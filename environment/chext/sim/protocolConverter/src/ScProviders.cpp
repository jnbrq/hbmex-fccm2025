#include <systemc>

#include <ScProviders.hpp>
#include <sctlm/tlm_lib/drivers/memory.hpp>

namespace sc_providers {

using namespace sc_core;
using namespace sc_dt;

using tlm::tlm_target_socket;

struct _ScMemory : providers::Memory {
    _ScMemory(const sc_module_name& name, tlm_target_socket<>& target)
        : driver_ { name } {
        driver_.socket(target);
    }

    void copyToDevice(uint64_t dest_addr, uint8_t const* src, uint32_t size) override {
        driver_.write(dest_addr, size, src);
    }

    void copyFromDevice(uint8_t* dest, uint64_t src_addr, uint32_t size) override {
        driver_.read(src_addr, size, dest);
    }

    void writeReg32(uint64_t addr, uint32_t value) override {
        driver_.write32(addr, value);
    }

    void writeReg64(uint64_t addr, uint64_t value) override {
        driver_.write64(addr, value);
    }

    uint32_t readReg32(uint64_t addr) override {
        return driver_.read32(addr);
    }

    uint64_t readReg64(uint64_t addr) override {
        return driver_.read64(addr);
    }

private:
    sctlm::tlm_lib::drivers::memory_interface driver_;
};

struct _ScSleep : providers::Sleep {
    void sleep(uint64_t ns) override {
        wait(ns, SC_NS);
    }
};

std::shared_ptr<providers::Memory> wrapTlmTargetSocket(
    tlm::tlm_target_socket<>& target,
    const sc_module_name& name
) {
    return std::static_pointer_cast<providers::Memory>(
        std::make_shared<_ScMemory>(name, target)
    );
}

std::shared_ptr<providers::Sleep> scSleep { new _ScSleep };

} // namespace sc_providers

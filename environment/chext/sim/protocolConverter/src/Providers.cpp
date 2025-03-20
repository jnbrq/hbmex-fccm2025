#include <Providers.hpp>
#include <cassert>

namespace providers {

struct OffsetMemory : Memory {
    OffsetMemory(std::shared_ptr<Memory> mem, int64_t offset)
        : mem_ { mem }
        , offset_ { offset } {
        assert(mem != nullptr);
    }

    void copyToDevice(uint64_t dest_addr, uint8_t const* src, uint32_t size) override {
        mem_->copyToDevice(dest_addr + offset_, src, size);
    }

    void copyFromDevice(uint8_t* dest, uint64_t src_addr, uint32_t size) override {
        mem_->copyFromDevice(dest, src_addr + offset_, size);
    }

    void writeReg32(uint64_t addr, uint32_t value) {
        mem_->writeReg32(addr + offset_, value);
    }

    void writeReg64(uint64_t addr, uint64_t value) {
        mem_->writeReg64(addr + offset_, value);
    }

    uint32_t readReg32(uint64_t addr) {
        return mem_->readReg32(addr + offset_);
    }

    uint64_t readReg64(uint64_t addr) {
        return mem_->readReg64(addr + offset_);
    }

private:
    std::shared_ptr<Memory> mem_;
    int64_t offset_;
};

std::shared_ptr<Memory> Memory::offset(int64_t offset) {
    return std::make_shared<OffsetMemory>(shared_from_this(), offset);
}

} // namespace providers

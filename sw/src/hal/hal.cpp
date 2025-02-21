#include <assert.h>
#include <hal/hal.hpp>

namespace hal {

struct OffsetMemory : Memory {
    OffsetMemory(std::shared_ptr<Memory> mem, offset_t offset)
        : mem_ { mem }
        , offset_ { offset } {
        assert(mem != nullptr);
    }

    void write(addr_t dest_addr, uint8_t const* src, size_t size) override {
        mem_->write(dest_addr + offset_, src, size);
    }

    void read(uint8_t* dest, addr_t src_addr, size_t size) override {
        mem_->read(dest, src_addr + offset_, size);
    }

    void writeReg32(addr_t addr, uint32_t value) override {
        mem_->writeReg32(addr + offset_, value);
    }

    void writeReg64(addr_t addr, uint64_t value) override {
        mem_->writeReg64(addr + offset_, value);
    }

    uint32_t readReg32(addr_t addr) override {
        return mem_->readReg32(addr + offset_);
    }

    uint64_t readReg64(addr_t addr) override {
        return mem_->readReg64(addr + offset_);
    }

private:
    std::shared_ptr<Memory> mem_;
    offset_t offset_;
};

std::shared_ptr<Memory> Memory::offset(offset_t offset) {
    return std::make_shared<OffsetMemory>(this->shared_from_this(), offset);
}

} // namespace hal

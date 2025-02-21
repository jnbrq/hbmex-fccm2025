#ifndef HAL_HAL_HPP_INCLUDED
#define HAL_HAL_HPP_INCLUDED

#include <cstdint>
#include <memory>

namespace hal {

using addr_t = std::uint64_t;
using size_t = std::uint64_t;
using offset_t = std::int64_t;

using std::uint8_t;
using std::uint32_t;
using std::uint64_t;

struct Memory : std::enable_shared_from_this<Memory> {
    virtual void write(addr_t dest_addr, uint8_t const* src, size_t size) = 0;
    virtual void read(uint8_t* dest, addr_t src_addr, size_t size) = 0;

    virtual void writeReg32(addr_t addr, uint32_t value) = 0;
    virtual void writeReg64(addr_t addr, uint64_t value) = 0;

    virtual uint32_t readReg32(addr_t addr) = 0;
    virtual uint64_t readReg64(addr_t addr) = 0;

    std::shared_ptr<Memory> offset(offset_t offset);

    virtual ~Memory() = default;
};

struct Sleep : std::enable_shared_from_this<Sleep> {
    virtual void sleep(uint64_t ns) = 0;
    virtual ~Sleep() = default;
};

} // namespace hal

#endif // HAL_HAL_HPP_INCLUDED

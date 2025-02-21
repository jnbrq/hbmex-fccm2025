#ifndef SPMV_ALLOCATOR_HPP_INCLUDED
#define SPMV_ALLOCATOR_HPP_INCLUDED

#include <hal/hal.hpp>

#include <cassert>
#include <memory>
#include <stdexcept>

namespace spmv {

enum AllocFlags : std::uint64_t {
    ALLOC__FIRST = 0x60,
    ALLOC_GENERIC = 0x60,
    ALLOC_VALUES_VECTOR,
    ALLOC_INDICES_VECTOR,
    ALLOC_LENGTHS_VECTOR,
    ALLOC_INPUT_VECTOR,
    ALLOC_OUTPUT_VECTOR,
    ALLOC__LAST,
};

struct Allocator : std::enable_shared_from_this<Allocator> {
    virtual hal::addr_t allocate(hal::size_t size, hal::size_t alignment, uint64_t flags = ALLOC_GENERIC) = 0;
    virtual void free(hal::addr_t addr, hal::size_t size, uint64_t flags = ALLOC_GENERIC) = 0;

    virtual ~Allocator() = default;
};

struct ArenaAllocator : Allocator {
    ArenaAllocator(hal::addr_t base, hal::size_t size) {
        init(base, size);
    }

    ArenaAllocator()
        : ArenaAllocator(0, 0) {
    }

    void init(hal::addr_t base, hal::size_t size) {
        begin_ = base;
        end_ = base + size;
        size_ = size;
        next_ = base;
        blocks_ = 0;
    }

    void reset() {
        init(begin_, size_);
    }

    hal::addr_t allocate(hal::size_t size, hal::size_t alignment, std::uint64_t flags = ALLOC_GENERIC) override {
        if ((alignment & (alignment - 1)) != 0)
            throw std::invalid_argument("Alignment must be a power of 2");

        auto aligned = (next_ + (alignment - 1)) & ~(alignment - 1);

        if (aligned > end_ || aligned + size >= end_ || aligned + size < aligned)
            throw std::bad_alloc();

        next_ = aligned + size;
        blocks_++;
        return aligned;
    }

    void free(hal::addr_t addr, hal::size_t size, std::uint64_t flags = ALLOC_GENERIC) override {
        assert(blocks_ >= 1);
        blocks_--;

        if (blocks_ == 0) {
            reset();
        }
    }

    hal::addr_t begin() const noexcept {
        return begin_;
    }

    hal::addr_t end() const noexcept {
        return end_;
    }

    hal::addr_t size() const noexcept {
        return size_;
    }

    hal::addr_t next() const noexcept {
        return next_;
    }

    ~ArenaAllocator() = default;

private:
    hal::addr_t begin_, end_, size_;
    hal::addr_t next_;
    hal::size_t blocks_;
};

} // namespace spmv

#endif /* SPMV_ALLOCATOR_HPP_INCLUDED */

#ifndef SPMV_MANAGER_HPP_INCLUDED
#define SPMV_MANAGER_HPP_INCLUDED

#include <hal/hal.hpp>
#include <spmv/Defs.hpp>

#include <cassert>
#include <list>

namespace spmv {

struct Allocator;
struct Task;

/// @brief Handles transfer of data and matrices between the device and the host.
struct Manager {
    Manager(
        std::shared_ptr<hal::Memory> memory,
        std::shared_ptr<hal::Memory> control,
        std::shared_ptr<hal::Sleep> sleep,
        std::shared_ptr<Allocator> allocator
    );

    /// @brief Sets the active stripe number.
    /// @param stripeIndex
    void setStripe(unsigned stripeIndex);

    std::shared_ptr<Task> createTask(
        std::string const& name,
        CompressedSparseMatrix const& csr,
        DenseMatrix const& m,
        bool verbose = false
    );

    void enqueueTask(std::shared_ptr<Task> task);

    std::shared_ptr<Task> waitOneTask();

    hal::uint64_t getAlignment() const noexcept {
        return alignment_;
    }

    void setAlignment(hal::uint64_t alignment) noexcept {
        alignment_ = alignment;
    }

    friend struct Task;

private:
    std::shared_ptr<hal::Memory> memory_;
    std::shared_ptr<hal::Memory> control_;
    std::shared_ptr<hal::Sleep> sleep_;
    std::shared_ptr<Allocator> allocator_;

    std::list<std::shared_ptr<Task>> taskQueue_;

    hal::uint64_t alignment_ { 4096 };

    void emptyOldResults_();
};

} // namespace spmv

#endif /* SPMV_MANAGER_HPP_INCLUDED */

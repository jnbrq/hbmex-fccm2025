#ifndef SPMV_TASK_HPP_INCLUDED
#define SPMV_TASK_HPP_INCLUDED

#include <hal/hal.hpp>
#include <spmv/Defs.hpp>

namespace spmv {

struct Manager;

struct TaskParameters {
    hal::addr_t ptrValues;
    hal::addr_t ptrColumnIndices;
    hal::addr_t ptrRowLengths;
    hal::addr_t ptrInputVector;
    hal::addr_t ptrOutputVector;

    hal::size_t numValues;
    hal::size_t numRows;

    hal::size_t szValues;
    hal::size_t szColumnIndices;
    hal::size_t szRowLengths;

    hal::size_t szInput;
    hal::size_t szOutput;
};

struct Task {
    Task(Manager& manager, std::string const& name, TaskParameters const& parameters)
        : manager_ { manager }
        , name_ { name }
        , parameters_ { parameters } {}

    Manager& manager() noexcept {
        return manager_;
    }

    Manager const& manager() const noexcept {
        return manager_;
    }

    TaskParameters const& parameters() const noexcept {
        return parameters_;
    }

    bool isComplete() const noexcept {
        return isComplete_;
    }

    std::uint64_t cycles() const noexcept {
        return cycles_;
    }

    DenseMatrix readOutput();

private:
    Manager& manager_;
    std::string const name_;
    TaskParameters const parameters_;

    bool isComplete_ { false };
    std::uint64_t cycles_ { 0 };

    void send();
    void receive();

    friend class Manager;
};

} // namespace spmv

#endif /* SPMV_TASK_HPP_INCLUDED */

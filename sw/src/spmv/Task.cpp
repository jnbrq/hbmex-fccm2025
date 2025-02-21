#include <spmv/Manager.hpp>
#include <spmv/Task.hpp>

namespace spmv {

void Task::send() {
    auto& control = manager_.control_;
    auto& sleep = manager_.sleep_;

    while (!control->readReg32(0x08)) {
        sleep->sleep(10000);
    }

    std::uint64_t buf[7];

    unsigned idx = 0;
    buf[idx++] = parameters_.numRows;
    buf[idx++] = parameters_.numValues;
    buf[idx++] = parameters_.ptrOutputVector;
    buf[idx++] = parameters_.ptrInputVector;
    buf[idx++] = parameters_.ptrRowLengths;
    buf[idx++] = parameters_.ptrColumnIndices;
    buf[idx++] = parameters_.ptrValues;

    unsigned dataBaseAddr = 3 << (10 - 2);

    for (unsigned i = 0; i < 7; ++i) {
        control->writeReg32(dataBaseAddr + (i * 8), buf[i]);
        control->writeReg32(dataBaseAddr + (i * 8) + 4, buf[i] >> 32);
    }

    control->writeReg32(0x0C, 1);
}

void Task::receive() {
    auto& control = manager_.control_;
    auto& sleep = manager_.sleep_;

    while (!control->readReg32(0x00)) {
        sleep->sleep(10000);
    }

    unsigned dataBaseAddr = 2 << (10 - 2);

    std::uint64_t lo = control->readReg32(dataBaseAddr);
    std::uint64_t hi = control->readReg32(dataBaseAddr + 4);
    cycles_ = lo | (hi << 32);

    control->writeReg32(0x04, 1);
}

DenseMatrix Task::readOutput() {
    auto& memory = manager_.memory_;

    // TODO is  *8 best done here?
    DenseMatrix m(parameters_.numRows * 8, 8);

    memory->read(
        (uint8_t*)m.data(),
        parameters_.ptrOutputVector,
        parameters_.szOutput
    );

    return m;
}

} // namespace spmv

#include <spmv/Allocator.hpp>
#include <spmv/Manager.hpp>
#include <spmv/Task.hpp>

namespace spmv {

struct ReportLog {
    ReportLog(std::string const& msg, bool verbose)
        : verbose_ { verbose } {
        if (verbose_)
            fmt::print("{}... ", msg);
    }

    ~ReportLog() {
        if (verbose_)
            fmt::print("[ DONE ]\n");
    }

private:
    bool const verbose_;
};

Manager::Manager(
    std::shared_ptr<hal::Memory> memory,
    std::shared_ptr<hal::Memory> control,
    std::shared_ptr<hal::Sleep> sleep,
    std::shared_ptr<Allocator> allocator
)
    : memory_ { memory }
    , control_ { control }
    , sleep_ { sleep }
    , allocator_ { allocator } {
#if 0
        , allocValues_ { ((hal::addr_t)8) << 28, ((hal::addr_t)2) << 28 }
        , allocColumnIndices_ { ((hal::addr_t)10) << 28, ((hal::addr_t)2) << 28 }
        , allocRowLengths_ { ((hal::addr_t)12) << 28, ((hal::addr_t)1) << 28 }
        , allocInputVector_ { ((hal::addr_t)0) << 28, ((hal::addr_t)8) << 28 }
        , allocOutputVector_ { ((hal::addr_t)13) << 28, ((hal::addr_t)3) << 28 } {
#endif
    emptyOldResults_();
}

void Manager::setStripe(unsigned stripeIndex) {
    control_->writeReg32(1 << 10, stripeIndex);
    control_->writeReg32(2 << 10, stripeIndex);
}

std::shared_ptr<Task> Manager::createTask(
    std::string const& name,
    CompressedSparseMatrix const& csr,
    DenseMatrix const& m,
    bool verbose
) {
    // numRows and numCols must be a multiple of 8
    assert((csr.numRows & 7) == 0);
    assert((csr.numCols & 7) == 0);
    assert((csr.numValues & 7) == 0);
    assert(m.numCols == 8);

    assert(csr.numRows > 0);
    assert(csr.numCols > 0);

    assert(m.numRows == csr.numCols);

    hal::size_t szValues = csr.numValues * sizeof(real_t);
    hal::size_t szColumnIndices = csr.numValues * sizeof(index_t);
    hal::size_t szRowLengths = csr.numRows * sizeof(index_t);

    hal::size_t szInput = m.numRows * m.numCols * sizeof(real_t);
    hal::size_t szOutput = csr.numRows * m.numCols * sizeof(real_t);

    hal::addr_t ptrValues = allocator_->allocate(szValues, alignment_, ALLOC_VALUES_VECTOR);
    hal::addr_t ptrColumnIndices = allocator_->allocate(szColumnIndices, alignment_, ALLOC_INDICES_VECTOR);
    hal::addr_t ptrRowLengths = allocator_->allocate(szRowLengths, alignment_, ALLOC_LENGTHS_VECTOR);
    hal::addr_t ptrInputVector = allocator_->allocate(szInput, alignment_, ALLOC_INPUT_VECTOR);
    hal::addr_t ptrOutputVector = allocator_->allocate(szOutput, alignment_, ALLOC_OUTPUT_VECTOR);

    hal::size_t numValues = csr.numValues / 8;
    hal::size_t numRows = csr.numRows / 8;

    auto parameters = TaskParameters {
        .ptrValues = ptrValues,
        .ptrColumnIndices = ptrColumnIndices,
        .ptrRowLengths = ptrRowLengths,
        .ptrInputVector = ptrInputVector,
        .ptrOutputVector = ptrOutputVector,
        .numValues = numValues,
        .numRows = numRows,
        .szValues = szValues,
        .szColumnIndices = szColumnIndices,
        .szRowLengths = szRowLengths,
        .szInput = szInput,
        .szOutput = szOutput
    };

    if (verbose)
        fmt::print(
            "TaskParameters:\n"
            "  ptrValues: 0x{:012x}, ptrColumnIndices: 0x{:012x}, ptrRowLengths: 0x{:012x},\n"
            "  ptrInputVector: 0x{:012x}, ptrOutputVector: 0x{:012x}\n"
            "  numValues: {}, numRows: {},\n"
            "  szValues: {}, szColumnIndices: {}, szRowLengths: {}, szInput: {}, szOutput: {}\n",
            parameters.ptrValues,
            parameters.ptrColumnIndices,
            parameters.ptrRowLengths,
            parameters.ptrInputVector,
            parameters.ptrOutputVector,
            parameters.numValues,
            parameters.numRows,
            parameters.szValues,
            parameters.szColumnIndices,
            parameters.szRowLengths,
            parameters.szInput,
            parameters.szOutput
        );

    {
        ReportLog log("writing the CSR matrix values", verbose);

        memory_->write(
            ptrValues,
            (const uint8_t*)csr.values.data(),
            szValues
        );
    }

    {
        ReportLog log("writing the CSR column indices", verbose);

        memory_->write(
            ptrColumnIndices,
            (const uint8_t*)csr.indices.data(),
            szColumnIndices
        );
    }

    {
        ReportLog log("writing the CSR row lengths", verbose);

        memory_->write(
            ptrRowLengths,
            (const uint8_t*)csr.lengths.data(),
            szRowLengths
        );
    }

    {
        ReportLog log("writing the input vector", verbose);

        memory_->write(
            ptrInputVector + 0x10'0000'0000ull,
            (const uint8_t*)m.data(),
            szInput
        );
    }

    return std::make_shared<Task>(*this, name, parameters);
}

void Manager::enqueueTask(std::shared_ptr<Task> task) {
    assert(&task->manager_ == this);

    taskQueue_.emplace_back(task);
    task->send();
}

std::shared_ptr<Task> Manager::waitOneTask() {
    if (taskQueue_.empty())
        return nullptr;

    auto task = taskQueue_.front();
    taskQueue_.pop_front();

    task->receive();

    return task;
}

void Manager::emptyOldResults_() {
    while (control_->readReg32(0x00)) {
        fmt::print("An old result is being discarded...\n");
        control_->writeReg32(0x04, 1);
        sleep_->sleep(100);
    }
}

} // namespace spmv

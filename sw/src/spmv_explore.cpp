#include <d4e/xil.h>
#include <hal/d4e.hpp>
#include <hal/hal.hpp>

#include <chrono>
#include <fstream>
#include <random>
#include <stdexcept>
#include <vector>

#include <cstdio>

#include <fmt/chrono.h>

#include <spmv/Allocator.hpp>
#include <spmv/Manager.hpp>
#include <spmv/Task.hpp>
#include <spmv/Utils.hpp>

struct TimedBlock {
    TimedBlock(std::string const& name)
        : name_ { name } {
        a = std::chrono::high_resolution_clock::now();
        fmt::print("Started: {} [t = {}]\n", name_, a);
    }

    ~TimedBlock() {
        auto b = std::chrono::high_resolution_clock::now();
        auto diff = b - a;
        fmt::print(
            "Complete: {} [t = {}, diff = {} = {}s]\n",
            name_,
            b,
            diff,
            std::chrono::duration<double>(diff).count()
        );
    }

private:
    std::string name_;
    std::chrono::high_resolution_clock::time_point a;
};

struct TimeKeeper {
    TimeKeeper() {}

    void enable() {
        enabled_ = true;
    }

    void disable() {
        enabled_ = false;
    }

    void start(std::string const& name) {
        if (used_)
            throw std::runtime_error("cannot use TimeKeeper before stopped!");

        name_ = name;
        a = std::chrono::high_resolution_clock::now();

        if (enabled_)
            fmt::print("Started: {} [t = {}]\n", name_, a);
    }

    void stop() {
        auto b = std::chrono::high_resolution_clock::now();
        auto diff = b - a;

        if (enabled_)
            fmt::print(
                "Complete: {} [t = {}, diff = {} = {}s]\n",
                name_,
                b,
                diff,
                std::chrono::duration<double>(diff).count()
            );
    }

private:
    bool enabled_ { true }, used_ { false };
    std::string name_;
    std::chrono::high_resolution_clock::time_point a;
};

struct MyAllocator : spmv::Allocator {
    MyAllocator() {
        reset();
    }

    hal::addr_t allocate(
        hal::size_t size,
        hal::size_t alignment,
        uint64_t flags = spmv::ALLOC_GENERIC
    ) override {
        switch (flags) {
        case spmv::ALLOC_INPUT_VECTOR:
            return allocInput_.allocate(size, alignment, 0);
        case spmv::ALLOC_VALUES_VECTOR:
            return allocValues_.allocate(size, alignment, 0);
        case spmv::ALLOC_INDICES_VECTOR:
            return allocIndices_.allocate(size, alignment, 0);
        case spmv::ALLOC_LENGTHS_VECTOR:
            return allocLengths_.allocate(size, alignment, 0);
        case spmv::ALLOC_OUTPUT_VECTOR:
            return allocOutput_.allocate(size, alignment, 0);
        default:
            throw std::runtime_error("Invalid allocation flag");
        }
    }

    void free(
        hal::addr_t addr,
        hal::size_t size,
        uint64_t flags = spmv::ALLOC_GENERIC
    ) override {
        switch (flags) {
        case spmv::ALLOC_INPUT_VECTOR:
            allocInput_.free(addr, size, 0);
            break;
        case spmv::ALLOC_VALUES_VECTOR:
            allocValues_.free(addr, size, 0);
            break;
        case spmv::ALLOC_INDICES_VECTOR:
            allocIndices_.free(addr, size, 0);
            break;
        case spmv::ALLOC_LENGTHS_VECTOR:
            allocLengths_.free(addr, size, 0);
            break;
        case spmv::ALLOC_OUTPUT_VECTOR:
            allocOutput_.free(addr, size, 0);
            break;
        default:
            throw std::runtime_error("Invalid free flag");
        }
    }

    void reset() {
        auto init_allocator =
            [this, addr = hal::addr_t { 0 }](spmv::ArenaAllocator& alloc, hal::size_t size) mutable {
                alloc.init(addr, size);
                addr += size;
            };

        init_allocator(allocInput_, 4096ull << 20);

        init_allocator(allocOutput_, 1024ull << 20);
        init_allocator(allocValues_, 1024ull << 20);
        init_allocator(allocIndices_, 1024ull << 20);
        init_allocator(allocLengths_, 1024ull << 20);
    }

private:
    spmv::ArenaAllocator allocInput_;

    spmv::ArenaAllocator allocOutput_;
    spmv::ArenaAllocator allocValues_;
    spmv::ArenaAllocator allocIndices_;
    spmv::ArenaAllocator allocLengths_;
};

void zeroOutHBM(std::shared_ptr<hal::Memory> memory) {
    std::vector<std::uint32_t> zeros(1 << 20);
    hal::size_t sz = zeros.size() * sizeof(std::uint32_t);

    fmt::print("zeroing the HBM...\n");
    hal::addr_t dest = 0;
    for (std::size_t i = 0; i < ((4ull << 30) / sz); ++i) {
        memory->write(dest, (hal::uint8_t const*)zeros.data(), sz);
        dest += sz;
    }
    fmt::print("done.\n");
}

struct Experiment {

    Experiment(d4e_device* dev)
        : memory { d4e::wrapDevice(dev) }
        , control { memory }
        , sleep { d4e::sleep() }
        , allocator { std::make_shared<MyAllocator>() }
        , manager {
            memory,
            control,
            sleep,
            allocator
        } {
    }

    void run() {
        entry();
    }

    ~Experiment() {
    }

private:
    std::shared_ptr<hal::Memory> memory;
    std::shared_ptr<hal::Memory> control;
    std::shared_ptr<hal::Sleep> sleep;
    std::shared_ptr<MyAllocator> allocator;

    spmv::Manager manager;

    void randomTest(
        linalg::size_t numRows,
        linalg::size_t numCols,
        linalg::size_t numValues,
        double tolerance = 1e-5
    ) {
        using spmv::Task;

        using spmv::CompressedSparseMatrix;
        using spmv::DenseMatrix;
        using spmv::SparseMatrix;

        using linalg::algos::copy;
        using linalg::algos::isSameRelative;
        using linalg::algos::product;

        TimeKeeper tk;

        // comment out to profile
        tk.disable();

        std::random_device rd;
        std::mt19937 gen(rd());

        std::uniform_int_distribution<linalg::index_t> rowDist(0, numRows - 1);
        std::uniform_int_distribution<linalg::index_t> colDist(0, numCols - 1);
        std::uniform_real_distribution<linalg::real_t> realDist(0.0, 1.0);

        SparseMatrix spm(numRows, numCols);
        DenseMatrix m(numCols, 8);

        tk.start("creating matrices");

        spm.clear();
        m.clear();

        while (spm.nonZeros() != numValues) {
            spm.set(rowDist(gen), colDist(gen), realDist(gen));
        }

        auto cspm = copy<CompressedSparseMatrix>(spm);
        tk.stop();

        tk.start("creating the task");
        auto task = manager.createTask("task", cspm, m, /* verbose = */ false);
        tk.stop();

        tk.start("calculating the expected matrix");
        auto mExpected = product<DenseMatrix>(cspm, m);
        tk.stop();

        manager.enqueueTask(task);

        tk.start("waiting to finish");
        manager.waitOneTask();
        tk.stop();

        auto totalCycles = task->cycles();

        tk.start("reading the output");
        auto mReceived = task->readOutput();
        tk.stop();

        auto sparsity = (1.0 - ((double)cspm.numValues) / ((((double)cspm.numRows) * ((double)cspm.numCols)))) * 100.0;
        auto cyclesPerValue = ((double)totalCycles) / cspm.numValues;

        fmt::print(
            "numRows = {}, numCols = {}, numValues = {}, sparsity = {}%, tolerance = {}, totalCycles = {}, cyclesPerValue = {}\n",
            cspm.numRows, cspm.numCols, cspm.numValues, sparsity, tolerance,
            totalCycles, cyclesPerValue
        );
    }

    void csrTest(std::string const& csrFile, double tolerance = 1e-5) {
        allocator->reset();

        using spmv::Task;

        using spmv::CompressedSparseMatrix;
        using spmv::DenseMatrix;
        using spmv::SparseMatrix;

        using linalg::algos::copy;
        using linalg::algos::isSameRelative;
        using linalg::algos::product;

        TimeKeeper tk;

        std::random_device rd;
        std::mt19937 gen(rd());
        std::uniform_real_distribution<float> realDist(-10.00f, 10.00f);
        // std::uniform_int_distribution<long> intDist(-(1l << 14), (1l << 14));

        tk.start(fmt::format("loading the CSR file: {}", csrFile));
        auto cspm = [&] {
            std::ifstream ifs(csrFile, std::ios::binary | std::ios::in);

            if (!ifs)
                throw std::runtime_error(fmt::format("could not open: {}", csrFile));

            ifs.seekg(0, std::ios::end);
            auto size = ifs.tellg();

            ifs.seekg(0, std::ios::beg);

            std::vector<char> buffer(size);
            ifs.read(buffer.data(), size);

            ifs.close();

            return linalg::exchange::binary::load<spmv::CompressedSparseMatrix>(
                (linalg::byte_t const*)buffer.data(), size
            );
        }();
        tk.stop();

        tk.start("Generating the random vector");
        DenseMatrix m(cspm.numCols, 8);

        for (linalg::index_t i = 0; i < m.numRows; ++i)
            for (linalg::index_t j = 0; j < m.numCols; ++j)
                m.set(i, j, realDist(gen));
        tk.stop();

        tk.start("Creating the task (write vectors)");
        auto task = manager.createTask(csrFile, cspm, m, false);
        tk.stop();

        tk.start("Calculating the expected result");
        auto mExpected = product<DenseMatrix>(cspm, m);
        tk.stop();

        manager.enqueueTask(task);

        tk.start("Waiting for completion");
        manager.waitOneTask();
        tk.stop();

        auto totalCycles = task->cycles();

        tk.start("Reading the output");
        auto mReceived = task->readOutput();
        tk.stop();

        tk.start("Checking the output");
        spmv::verifyAndReportMismatches(mExpected, mReceived, cspm, tolerance);
        tk.stop();

        auto sparsity = (1.0 - ((double)cspm.numValues) / ((((double)cspm.numRows) * ((double)cspm.numCols)))) * 100.0;
        auto cyclesPerValue = ((double)totalCycles) / cspm.numValues;

        fmt::print(
            "file = {}, numRows = {}, numCols = {}, numValues = {}, sparsity = {}%, tolerance = {}, totalCycles = {}, cyclesPerValue = {}\n",
            csrFile, cspm.numRows, cspm.numCols, cspm.numValues, sparsity, tolerance,
            totalCycles, cyclesPerValue
        );
    }

    void entry() {
        constexpr unsigned d = 16384;

        for (hal::uint32_t stripeIndex = 0; stripeIndex <= 3; ++stripeIndex) {
            fmt::print("stripe index = {}\n", stripeIndex);

            control->writeReg32(1 << 10, stripeIndex);
            control->writeReg32(2 << 10, stripeIndex);

// for generating the linear graphs
#if 0
            for (linalg::size_t i = 1; i <= 75; ++i) {
                randomTest(d, d, i * d);
            }
#endif

#if 1
            std::vector<std::string> files {
                "random_16384_16384_134217728.csr",
                "random_16384_16384_67108864.csr",
                "random_16384_16384_33554432.csr",
                "random_16384_16384_16777216.csr",
                "random_16384_16384_8388608.csr",
                "random_16384_16384_4194304.csr",
                "random_16384_16384_2097152.csr",
                "random_16384_16384_1048576.csr",
                "random_16384_16384_524288.csr",
                "random_16384_16384_262144.csr",
                "random_16384_16384_131072.csr",
                "random_16384_16384_65536.csr",
                "random_16384_16384_32768.csr",
                "random_16384_16384_16384.csr"
            };
#endif

#if 0
            // not much different between random and linear
            std::vector<std::string> files {
                "linear_16384_16384_134217728.csr",
                "linear_16384_16384_67108864.csr",
                "linear_16384_16384_33554432.csr",
                "linear_16384_16384_16777216.csr",
                "linear_16384_16384_8388608.csr",
                "linear_16384_16384_4194304.csr",
                "linear_16384_16384_2097152.csr",
                "linear_16384_16384_1048576.csr",
                "linear_16384_16384_524288.csr",
                "linear_16384_16384_262144.csr",
                "linear_16384_16384_131072.csr",
                "linear_16384_16384_65536.csr",
                "linear_16384_16384_32768.csr",
                "linear_16384_16384_16384.csr"
            };
#endif

            for (auto const& file : files)
                csrTest(fmt::format("workloads/spmv_explore/{}", file));

            allocator->reset();

            control->writeReg32(1 << 10, 0);
            control->writeReg32(2 << 10, 0);
        }
    }

    void testName(const char* name) {
        fmt::print("{:=^100}\n", fmt::format(" {} ", name));
    }
};

int main(int argc, char** argv) {
    // for immediate output
    std::setbuf(stdout, nullptr);

    struct d4e_xil_device xil_device;
    d4e_xil_device_open(&xil_device, "/dev/xdma0", 0, 0, (16ull << 20));

    {
        Experiment exp(&xil_device.device);
        exp.run();
    }

    d4e_close(&xil_device.device);
    return 0;
}

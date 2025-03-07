#include <d4e/xil.h>
#include <hal/d4e.hpp>
#include <hal/hal.hpp>

#include <fstream>
#include <random>
#include <stdexcept>
#include <vector>

#include <cstdio>

#include <linalg/linalg.hpp>

#include <spmv/Allocator.hpp>
#include <spmv/Manager.hpp>
#include <spmv/Task.hpp>
#include <spmv/Utils.hpp>

struct MyAllocator : spmv::Allocator {
    MyAllocator() {
        reset();
    }

    hal::addr_t allocate(
        hal::size_t size,
        hal::size_t alignment,
        uint64_t flags = spmv::ALLOC_GENERIC
    ) override {
        if (flags == spmv::ALLOC_INPUT_VECTOR)
            return allocInput_.allocate(size, alignment, 0);
        else
            return allocGeneric_.allocate(size, alignment, 0);
    }

    void free(
        hal::addr_t addr,
        hal::size_t size,
        uint64_t flags = spmv::ALLOC_GENERIC
    ) override {
        if (flags == spmv::ALLOC_INPUT_VECTOR)
            return allocInput_.free(addr, size, 0);
        else
            return allocGeneric_.free(addr, size, 0);
    }

    void reset() {
        auto init_allocator =
            [this, addr = hal::addr_t { 0 }](spmv::ArenaAllocator& alloc, hal::size_t size) mutable {
                alloc.init(addr, size);
                addr += size;
            };

        init_allocator(allocInput_, ((hal::addr_t)8) << 29);
        init_allocator(allocGeneric_, ((hal::addr_t)8) << 29);
    }

private:
    spmv::ArenaAllocator allocInput_;
    spmv::ArenaAllocator allocGeneric_;
};

void zeroOutHBM(std::shared_ptr<hal::Memory> memory) {
    std::vector<std::uint32_t> zeros(1 << 20, 0xCAFE'DEAD);
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

    void
    run() {
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

    void csrTest(std::string const& csrFile, double tolerance = 1e-5) {
        allocator->reset();

        using spmv::Task;

        using spmv::CompressedSparseMatrix;
        using spmv::DenseMatrix;
        using spmv::SparseMatrix;

        using linalg::algos::copy;
        using linalg::algos::isSameRelative;
        using linalg::algos::product;

        std::random_device rd;
        std::mt19937 gen(rd());
        std::uniform_real_distribution<float> realDist(-10.00f, 10.00f);
        // std::uniform_int_distribution<long> intDist(-(1l << 14), (1l << 14));

        fmt::print("loading... ");
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
        fmt::print("[DONE]\n");

        DenseMatrix m(cspm.numCols, 8);

        for (linalg::index_t i = 0; i < m.numRows; ++i)
            for (linalg::index_t j = 0; j < m.numCols; ++j)
                m.set(i, j, realDist(gen));
        // m.set(i, j, 1.0);
        // m.set(i, j, float(intDist(gen)) / float(1l << 14));

        auto task = manager.createTask(csrFile, cspm, m, true);

        auto mExpected = product<DenseMatrix>(cspm, m);

        manager.enqueueTask(task);

        fmt::print("waiting... ");
        manager.waitOneTask();
        fmt::print("[ DONE ]\n");

        auto totalCycles = task->cycles();

        fmt::print("reading output... ");
        auto mReceived = task->readOutput();
        fmt::print("[ DONE ]\n");

        spmv::verifyAndReportMismatches(mExpected, mReceived, cspm, tolerance);

        auto sparsity = (1.0 - ((double)cspm.numValues) / ((((double)cspm.numRows) * ((double)cspm.numCols)))) * 100.0;
        auto cyclesPerValue = ((double)totalCycles) / cspm.numValues;

        fmt::print(
            "file = {}, numRows = {}, numCols = {}, numValues = {}, sparsity = {}%, tolerance = {}, totalCycles = {}, cyclesPerValue = {}\n",
            csrFile, cspm.numRows, cspm.numCols, cspm.numValues, sparsity, tolerance,
            totalCycles, cyclesPerValue
        );

        // sleep->sleep(1e9);
    }

    void entry() {
        zeroOutHBM(memory);

#if 0
        sleep->sleep(10e9);

        manager.setStripe(3);
        csrTest("../workloads/ljournal-2008.csr", 1e-3);

        manager.setStripe(0);
#endif

        for (hal::uint32_t stripeIndex = 0; stripeIndex <= 3; ++stripeIndex) {
            fmt::print("stripe index = {}\n", stripeIndex);

            manager.setStripe(stripeIndex);

            double tolerance = 1e-2;
            unsigned runCount = 5;

            std::vector<const char*> files {
                "amazon-2008.csr",
                "cit-Patents.csr",
                "com-Youtube.csr",
                "cont11_l.csr",
                "dblp-2010.csr",
                "eu-2005.csr",
                "flickr.csr",
                "in-2004.csr",
                "ljournal-2008.csr",
                "road_usa.csr",
                "webbase-1M.csr",
                "wikipedia-20061104.csr"
            };

            for (auto file : files) {
                for (unsigned i = 0; i < runCount; ++i)
                    csrTest(fmt::format("workloads/suite_sparse/{}", file), tolerance);
            }

            manager.setStripe(0);
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


#include <chrono>
#include <fstream>
#include <random>
#include <stdexcept>

#include <cstdio>

#include <fmt/chrono.h>

#include <spmv/Defs.hpp>

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

void generateCsrRandom(
    std::string const& fileName,
    linalg::size_t numRows,
    linalg::size_t numCols,
    linalg::size_t numValues
) {
    fmt::print("generateCsrRandom({}, {}, {}, {})\n", fileName, numRows, numCols, numValues);

    TimeKeeper tk;

    std::random_device rd;
    std::mt19937 gen(rd());

    std::uniform_int_distribution<linalg::index_t> rowDist(0, numRows - 1);
    std::uniform_int_distribution<linalg::index_t> colDist(0, numCols - 1);
    std::uniform_real_distribution<linalg::real_t> realDist(0.0, 1.0);

    spmv::SparseMatrix spm(numRows, numCols);
    spmv::DenseMatrix m(numCols, 8);

    tk.start("creating matrices");

    spm.clear();
    m.clear();

    while (spm.nonZeros() != numValues) {
        spm.set(rowDist(gen), colDist(gen), realDist(gen));
    }

    auto cspm = linalg::algos::copy<spmv::CompressedSparseMatrix>(spm);
    tk.stop();

    tk.start("writing file");
    linalg::byte_t* data;
    linalg::size_t size;

    linalg::exchange::binary::save(cspm, data, size);

    std::ofstream ofs(fileName, std::ios::binary | std::ios::out);

    if (!ofs)
        fmt::print("could not open the output file: {}\n", fileName);

    ofs.write((char*)data, size);
    ofs.flush();
    fmt::print("written.\n");

    ofs.close();

    delete[] data;
    tk.stop();
}

void generateCsrLinear(
    std::string const& fileName,
    linalg::size_t numRows,
    linalg::size_t numCols,
    linalg::size_t numValuesPerRow
) {
    fmt::print("generateCsrLinear({}, {}, {}, {})\n", fileName, numRows, numCols, numValuesPerRow);

    TimeKeeper tk;

    std::random_device rd;
    std::mt19937 gen(rd());

    std::uniform_int_distribution<linalg::index_t> rowDist(0, numRows - 1);
    std::uniform_int_distribution<linalg::index_t> colDist(0, numCols - 1);
    std::uniform_real_distribution<linalg::real_t> realDist(0.0, 1.0);

    spmv::SparseMatrix spm(numRows, numCols);
    spmv::DenseMatrix m(numCols, 8);

    tk.start("creating matrices");

    spm.clear();
    m.clear();

    for (linalg::index_t rowIndex = 0; rowIndex < numRows; ++rowIndex) {
        for (linalg::index_t i = 0; i < numValuesPerRow; ++i) {
            spm.set(rowIndex, (rowIndex * numValuesPerRow + i) % numCols, realDist(gen));
        }
    }

    auto cspm = linalg::algos::copy<spmv::CompressedSparseMatrix>(spm);
    tk.stop();

    tk.start("writing file");
    linalg::byte_t* data;
    linalg::size_t size;

    linalg::exchange::binary::save(cspm, data, size);

    std::ofstream ofs(fileName, std::ios::binary | std::ios::out);

    if (!ofs)
        fmt::print("could not open the output file: {}\n", fileName);

    ofs.write((char*)data, size);
    ofs.flush();
    fmt::print("written.\n");

    ofs.close();

    delete[] data;
    tk.stop();
}

int main(int argc, char** argv) {
    // for immediate output
    std::setbuf(stdout, nullptr);

    linalg::size_t numRows = 16384, numCols = 16384;

    for (linalg::size_t i = 0; i <= 13; ++i) {
        linalg::size_t numValues = (1ull << i) * numRows;
        auto name = fmt::format("random_{}_{}_{}.csr", numRows, numCols, numValues);
        generateCsrRandom(name, numRows, numCols, numValues);
    }

#if 0
    for (linalg::size_t i = 0; i <= 13; ++i) {
        linalg::size_t numValuesPerRow = (1ull << i);
        linalg::size_t numValues = numValuesPerRow * numRows;
        auto name = fmt::format("linear_{}_{}_{}.csr", numRows, numCols, numValues);
        generateCsrLinear(name, numRows, numCols, numValuesPerRow);
    }
#endif

    return 0;
}

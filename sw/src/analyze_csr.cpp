#include <fmt/core.h>
#include <linalg/linalg.hpp>
#include <spmv/Defs.hpp>

#include <chrono>
#include <fstream>
#include <random>

#include <fmt/chrono.h>

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

int main(int argc, char** argv) {
    if (argc != 2) {
        fmt::print("Usage: analyze_csr input.csr\n");
        return -1;
    }

    TimeKeeper tk;

    std::string csrFile = argv[1];

    auto cspm = [&] {
        tk.start("loading the file");

        std::ifstream ifs(csrFile, std::ios::binary | std::ios::in);

        if (!ifs)
            throw std::runtime_error(fmt::format("could not open: {}", csrFile));

        ifs.seekg(0, std::ios::end);
        auto size = ifs.tellg();

        ifs.seekg(0, std::ios::beg);

        std::vector<char> buffer(size);
        ifs.read(buffer.data(), size);

        ifs.close();

        tk.stop();

        return linalg::exchange::binary::load<spmv::CompressedSparseMatrix>(
            (linalg::byte_t const*)buffer.data(), size
        );
    }();

    fmt::print(
        "Matrix info: numRows = {}, numCols = {}, numValues = {}\n",
        cspm.numRows, cspm.numCols, cspm.numValues
    );

    fmt::print("Row-by-row accesses:\n");

    for (linalg::index_t rowIndex = 0; rowIndex < cspm.numRows; ++rowIndex) {
        fmt::print("[{:10d}] = ", rowIndex);

        for (linalg::index_t colIndexIndex = cspm.offsets[rowIndex]; colIndexIndex < cspm.offsets[rowIndex + 1]; ++colIndexIndex) {
            linalg::index_t colIndex = cspm.indices[colIndexIndex];
            linalg::real_t value = cspm.values[colIndexIndex];

            fmt::print("[{:10d}] * {:5.3f} + ", colIndex, value);
        }

        fmt::print("\n");
    }

    return 0;
}

#include <fmt/core.h>
#include <linalg/linalg.hpp>
#include <spmv/Defs.hpp>

#include <fstream>
#include <random>

#define ALIGN_TO_POW2(expr, n) \
    (((expr) + ((std::uint64_t(1) << n) - 1)) >> n) << n

int main(int argc, char** argv) {
    if (argc != 3) {
        fmt::print("Usage: mm2csr input.mtx output.csr\n");
        return -1;
    }

    std::string inputFile = argv[1];
    std::string outputFile = argv[2];

    std::ifstream ifs(inputFile, std::ios::in);

    if (!ifs)
        fmt::print("could not open the input file: {}\n", inputFile);

    linalg::exchange::matrix_market::InputStream mmis(ifs);

    fmt::print("input file: {}\n", inputFile);
    fmt::print("output file: {}\n", outputFile);

    mmis.parseMetadata();
    fmt::print("parsed the header.\n");
    fmt::print("{}\n", mmis.typeCode().toString());
    fmt::print("{}\n", mmis.dimensions().toString());
    // fmt::print("\n");
    // fmt::print("comments:\n{}\n", mmis.comments());

    auto numRows = ALIGN_TO_POW2(mmis.dimensions().numRows, 3);
    auto numCols = ALIGN_TO_POW2(mmis.dimensions().numCols, 3);

    fmt::print("(after alignment) numRows: {}, numCols: {}\n", numRows, numCols);

    spmv::SparseMatrix spm(numRows, numCols);

    mmis.loadSparseMatrix(spm);
    fmt::print("parsed the matrix.\n");

    // numValues is not what we have in the header for symmetric matrices
    auto numValues = ALIGN_TO_POW2(spm.nonZeros(), 3);
    fmt::print("(after alignment) numValues: {}\n", numValues);

    // append explicit zeros to satisfy the alignment requirement
    {
        std::random_device rd;
        std::mt19937 gen(0xCAFE'BABE);

        std::uniform_int_distribution<linalg::index_t> rowDist(0, numRows - 1);
        std::uniform_int_distribution<linalg::index_t> colDist(0, numCols - 1);

        while (spm.nonZeros() != numValues) {
            spm.setIfImplicitZero(rowDist(gen), colDist(gen), 0);
        }
    }

    ifs.close();

    auto cspm = linalg::algos::copy<spmv::CompressedSparseMatrix>(spm);

    linalg::byte_t* data;
    linalg::size_t size;

    linalg::exchange::binary::save(cspm, data, size);

    std::ofstream ofs(outputFile, std::ios::binary | std::ios::out);

    if (!ofs)
        fmt::print("could not open the output file: {}\n", outputFile);

    ofs.write((char*)data, size);
    ofs.flush();
    fmt::print("written.\n");

    ofs.close();

    delete[] data;

    fmt::print("DONE.\n");

    return 0;
}

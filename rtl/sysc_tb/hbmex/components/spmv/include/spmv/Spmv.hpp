#ifndef SPMV_HPP_INCLUDED
#define SPMV_HPP_INCLUDED

#include <systemc>

#include <spmv/linalg.hpp>

#include <boost/endian.hpp>
#include <hal/hal.hpp>

namespace spmv {

namespace detail {

template<typename T1, typename T2>
void copy(T1* dest, T2 const* src, std::size_t n) {
    for (std::size_t i = 0; i < n; i++) {
        dest[i] = src[i];
    }
}

struct Task {
    std::uint64_t ptrValues;
    std::uint64_t ptrColumnIndices;
    std::uint64_t ptrRowLengths;
    std::uint64_t ptrInputVector;
    std::uint64_t ptrOutputVector;

    std::uint64_t numValues;
    std::uint64_t numRows;

    static constexpr std::size_t Width = 7 * 64;

    sc_dt::sc_bv<Width> to_bv() const {
        sc_dt::sc_bv<Width> result;

        // TODO: maybe automate this?
        result.range(447, 384) = sc_dt::sc_bv<64>(ptrValues);
        result.range(383, 320) = sc_dt::sc_bv<64>(ptrColumnIndices);
        result.range(319, 256) = sc_dt::sc_bv<64>(ptrRowLengths);
        result.range(255, 192) = sc_dt::sc_bv<64>(ptrInputVector);
        result.range(191, 128) = sc_dt::sc_bv<64>(ptrOutputVector);
        result.range(127, 64) = sc_dt::sc_bv<64>(numValues);
        result.range(63, 0) = sc_dt::sc_bv<64>(numRows);

        return result;
    }

    static Task from_bv(sc_dt::sc_bv_base const& bv) {
        assert(bv.length() == Width);

        return {
            bv.range(447, 384).to_uint64(),
            bv.range(383, 320).to_uint64(),
            bv.range(319, 256).to_uint64(),
            bv.range(255, 192).to_uint64(),
            bv.range(191, 128).to_uint64(),
            bv.range(127, 64).to_uint64(),
            bv.range(63, 0).to_uint64()
        };
    }
};

/// @brief Handles transfer of data and matrices between the device and the host.
struct Manager {

    Manager(std::shared_ptr<hal::Memory> memory)
        : memory_ { memory } {}

    /// @brief Writes a compressed sparse matrix to device memory.
    /// @param mcsr
    /// @param addrValues Incremented after the write is complete.
    /// @param addrColumnIndices Incremented after the write is complete.
    /// @param addrRowLengths Incremented after the write is complete.
    void
    writeCompressedSparseMatrix(
        linalg::CompressedSparseMatrix<linalg::real_t, linalg::RowMajor> const& mcsr,
        hal::addr_t& addrValues,
        hal::addr_t& addrColumnIndices,
        hal::addr_t& addrRowLengths
    ) const {
        // all the addresses must be 32-byte aligned, which is the
        // length of the HBM
        // HARDCODED
        assert((addrValues & 31) == 0);
        assert((addrColumnIndices & 31) == 0);
        assert((addrRowLengths & 31) == 0);

        // numRows and numCols must be a multiple of 8
        assert((mcsr.numRows & 7) == 0);
        assert((mcsr.numCols & 7) == 0);
        assert((mcsr.numValues & 7) == 0);

        assert(mcsr.numRows > 0);
        assert(mcsr.numCols > 0);

        using namespace boost::endian;

        std::vector<little_float32_at> vValues_la(mcsr.numValues);
        std::vector<little_uint32_at> vColumnIndices_la(mcsr.numValues);
        std::vector<little_uint32_at> vRowLengths_la(mcsr.numRows);

        copy(vValues_la.data(), mcsr.values.data(), mcsr.numValues);
        copy(vColumnIndices_la.data(), mcsr.indices.data(), mcsr.numValues);
        copy(vRowLengths_la.data(), mcsr.lengths.data(), mcsr.numRows);

        hal::size_t szValues = mcsr.numValues * sizeof(linalg::real_t);
        memory_->write(
            addrValues,
            (const uint8_t*)vValues_la.data(),
            szValues
        );
        addrValues += szValues;

        hal::size_t szColumnIndices = mcsr.numValues * sizeof(linalg::index_t);
        memory_->write(
            addrColumnIndices,
            (const uint8_t*)vColumnIndices_la.data(),
            szColumnIndices
        );
        addrColumnIndices += szColumnIndices;

        hal::size_t szRowLengths = mcsr.numRows * sizeof(linalg::index_t);
        memory_->write(
            addrRowLengths,
            (const uint8_t*)vRowLengths_la.data(),
            szRowLengths
        );
        addrRowLengths += szRowLengths;
    }

    /// @brief Writes a batch vector to device memory.
    /// @param m
    /// @param addr Incremented after the write is complete.
    void
    writeBatchVector(
        linalg::DenseMatrix<linalg::real_t, linalg::RowMajor> const& m,
        hal::addr_t& addr
    ) {
        // HARDCODED
        assert(m.numCols == 8);

        // HARDCODED
        assert((m.numRows & 7) == 0);
        assert(m.numRows > 0);

        // HARDCODED
        assert((addr & 31) == 0);

        using namespace boost::endian;

        std::vector<little_float32_at> buf(m.numRows * m.numCols);
        copy(buf.data(), m.data(), m.numRows * m.numCols);

        hal::size_t sz = m.numRows * m.numCols * sizeof(linalg::real_t);
        memory_->write(
            addr,
            (const uint8_t*)buf.data(),
            sz
        );
        addr += sz;
    }

    /// @brief
    /// @param numRows
    /// @param addr Incremented after the read is complete.
    /// @return
    linalg::DenseMatrix<linalg::real_t, linalg::RowMajor>
    readBatchVector(
        linalg::size_t numRows,
        hal::addr_t& addr
    ) {
        // HARDCODED
        assert((numRows & 7) == 0);
        assert(numRows > 0);

        // HARDCODED
        assert((addr & 31) == 0);

        using namespace boost::endian;

        std::vector<little_float32_at> buf(numRows * 8);

        hal::size_t sz = numRows * 8 * sizeof(linalg::real_t);
        memory_->read(
            (uint8_t*)buf.data(),
            addr,
            sz
        );
        addr += sz;

        linalg::DenseMatrix<linalg::real_t, linalg::RowMajor> m(numRows, 8);

        copy(m.data(), buf.data(), m.numRows * m.numCols);

        return m;
    }

private:
    std::shared_ptr<hal::Memory> memory_;
};

} // namespace detail

using detail::Manager;
using detail::Task;

} // namespace spmv

#endif // SPMV_HPP_INCLUDED

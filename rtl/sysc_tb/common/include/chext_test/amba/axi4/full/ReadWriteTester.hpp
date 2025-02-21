#ifndef CHEXT_TEST_AMBA_AXI4_FULL_READWRITETESTER_HPP_INCLUDED
#define CHEXT_TEST_AMBA_AXI4_FULL_READWRITETESTER_HPP_INCLUDED

#include <chrono>
#include <random>

#include <chext_test/amba/axi4/full/Transaction.hpp>
#include <chext_test/chext_test.hpp>


// TODO Maybe we should move this one to a different file
namespace chext_test::buffer_utils {

namespace detail {

static std::mt19937 mt(879821);
static std::uniform_int_distribution<> dist(0, 1024);

} // namespace detail

template<typename BufferT>
void reset(BufferT& buffer) {
    using value_type = std::remove_reference_t<decltype(*std::begin(buffer))>;

    for (auto it = std::begin(buffer); it != std::end(buffer); ++it)
        *it = ((value_type)0);
}

template<typename BufferT>
void linearInit(BufferT& buffer) {
    using value_type = std::remove_reference_t<decltype(*std::begin(buffer))>;

    value_type idx = (value_type)0;
    for (auto it = std::begin(buffer); it != std::end(buffer); ++it)
        *it = (idx++);
}

template<typename BufferT>
void randomInit(BufferT& buffer) {
    using value_type = std::remove_reference_t<decltype(*std::begin(buffer))>;

    for (auto it = std::begin(buffer); it != std::end(buffer); ++it)
        *it = ((value_type)detail::dist(detail::mt));
}

} // namespace chext_test::buffer_utils

namespace chext_test::amba::axi4::full {

struct ReadWriteTester : virtual TestBenchBase {
protected:
    /**
     * @brief Tests the specified AXI4 interfaces using different types of bursts.
     *
     * This function performs read and write operations on the provided AXI4 slave interfaces
     * with normal, narrow, unaligned, and narrow-unaligned bursts. It writes data to the `writeSlave`
     * interface and reads it back from the `readSlave` interface, verifying that the written and read
     * data match. Two types of data patterns are tested: linear and random.
     *
     * @param writeSlave Reference to the AXI4 write slave interface.
     * @param readSlave Reference to the AXI4 read slave interface.
     * @param addr Starting address for the read/write operations.
     * @param numBytes Number of bytes to write and read during each burst.
     */
    void readWriteTest(
        axi4::full::SlaveBase& writeSlave,
        axi4::full::SlaveBase& readSlave,
        uint64_t addr,
        uint64_t numBytes
    ) {
        using axi4::full::read;
        using axi4::full::write;

        std::vector<uint8_t> rdBuffer(numBytes), wrBuffer(numBytes);

        for (uint64_t offset = 0; offset < 128; ++offset) {
            for (int size = -1; size <= 2; ++size) {
                buffer_utils::linearInit(wrBuffer);
                write(writeSlave, addr + offset, numBytes, wrBuffer.data(), size, false);
                read(readSlave, addr + offset, numBytes, rdBuffer.data(), size, false);
                ASSERT_(rdBuffer == wrBuffer);
            }
        }

        for (uint64_t offset = 0; offset < 128; ++offset) {
            for (int size = -1; size < 2; ++size) {
                buffer_utils::randomInit(wrBuffer);
                write(writeSlave, addr + offset, numBytes, wrBuffer.data(), size, false);
                read(readSlave, addr + offset, numBytes, rdBuffer.data(), size, false);
                ASSERT_(rdBuffer == wrBuffer);
            }
        }
    }
};

} // namespace chext_test::amba::axi4::full

#endif /* CHEXT_TEST_AMBA_AXI4_FULL_READWRITETESTER_HPP_INCLUDED */

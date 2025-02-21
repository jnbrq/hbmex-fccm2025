#ifndef CHEXT_TEST_AMBA_AXI4_FULL_TRANSACTION_HPP_INCLUDED
#define CHEXT_TEST_AMBA_AXI4_FULL_TRANSACTION_HPP_INCLUDED

#include <chext_test/amba/axi4/full/Driver.hpp>
#include <chext_test/util/Spawn.hpp>
#include <chext_test/util/Util.hpp>

#include <systemc>

namespace chext_test::amba::axi4::full {

struct Beat {
    /// @brief index of the beat within the transaction
    uint32_t index;

    /// @brief the memory address of the first meaningful byte in the transaction
    uint64_t addr;

    /// @brief if the beat is last
    bool last;

    /// @brief lower byte index of the meaningful bus data
    uint32_t lowerByteIndex;

    /// @brief upper byte index of the meaningful bus data
    uint32_t upperByteIndex;

    /// @brief number of meaningful bytes in the beat
    uint32_t size;

    /// @brief write strobe corresponding to the beat
    uint64_t strb;

    JQR_DECL(
        Beat,
        JQR_MEMBER(index),
        JQR_MEMBER(addr, jqr::opts::dump_fmt { "{:#018x}" }),
        JQR_MEMBER(last, jqr::opts::dump_fmt { "{:#03b}" }),
        JQR_MEMBER(lowerByteIndex),
        JQR_MEMBER(upperByteIndex),
        JQR_MEMBER(size, jqr::opts::dump_fmt { "{:#04x}" }),
        JQR_MEMBER(strb, jqr::opts::dump_fmt { "{:#066b}" })
    )

    JQR_TO_STRING
};

struct Transaction {
    Transaction(uint16_t wData, bool axi3Compat = false)
        : wData_ { wData }
        , axi3Compat_ { axi3Compat } {
        assert(wData <= 512);
    }

    void reset(uint64_t addr, uint8_t len, uint8_t size, uint8_t burst) {
        assert(burst == 0 || burst == 1 || burst == 2);

        if (axi3Compat_) {
            assert(len < 16 && "in axi3 mode, len < 16!");
        }

        if (burst == 2 /* WRAP */) {
            assert(len == 0 || len == 1 || len == 3 || len == 7 || len == 15);
            uint8_t log2numBeats = log2(len + 1);

            // the total size of the transfer should be aligned
            uint64_t transferSize = ((uint64_t)1) << size;
            assert((addr & (transferSize - 1)) == 0 && "for wrap burst, it must be aligned to the transfer size!");
        }

        firstAddr_ = addr;
        addr_ = addr >> size;
        len_ = len;
        size_ = size;
        burst_ = burst;

        beatIndex_ = 0;
    }

    bool nextBeat(Beat& beat) {
        if (beatIndex_ > len_)
            return false;

        beat.~Beat();

        uint64_t busMask = (wData_ / 8) - 1;

        if (beatIndex_ == 0 || burst_ == 0) {
            uint64_t addr = firstAddr_;

            uint32_t lowerByteIndex = addr & busMask;
            uint32_t upperByteIndex = (((1 + (addr >> size_)) << size_) - 1) & busMask;
            uint32_t size = (upperByteIndex - lowerByteIndex) + 1;
            uint64_t strb = ((((uint64_t)1) << size) - 1) << lowerByteIndex;

            new (&beat) Beat {
                .index = beatIndex_,
                .addr = addr,
                .last = (beatIndex_ == len_),
                .lowerByteIndex = lowerByteIndex,
                .upperByteIndex = upperByteIndex,
                .size = size,
                .strb = strb
            };
        } else {
            uint64_t addr = addr_ << size_;

            uint32_t lowerByteIndex = addr & busMask;
            uint32_t upperByteIndex = (((1 + (addr >> size_)) << size_) - 1) & busMask;
            uint32_t size = (upperByteIndex - lowerByteIndex) + 1;
            uint64_t strb = ((((uint64_t)1) << size) - 1) << lowerByteIndex;

            new (&beat) Beat {
                .index = beatIndex_,
                .addr = addr,
                .last = (beatIndex_ == len_),
                .lowerByteIndex = lowerByteIndex,
                .upperByteIndex = upperByteIndex,
                .size = size,
                .strb = strb
            };
        }

        if (burst_ == 0 /* FIXED */) {
            // do nothing
        } else if (burst_ == 1 /* INCR */) {
            addr_++;
        } else /* WRAP */ {
            uint64_t mask = len_;
            addr_ = ((addr_ + 1) & mask) | ((addr_) & ~mask);
        }

        beatIndex_++;

        return true;
    }

private:
    uint16_t wData_;
    bool axi3Compat_;

    unsigned beatIndex_;

    uint64_t firstAddr_;
    uint64_t addr_;

    uint8_t len_;
    uint8_t size_;
    uint8_t burst_;
};

namespace detail {

inline void prepareWriteData(sc_dt::sc_bv_base& out, uint8_t const* in, uint8_t lowerByteIndex, uint8_t upperByteIndex) {
    // can be further improved
    uint8_t buffer[128] = { 0 };

    for (unsigned i = lowerByteIndex; i <= upperByteIndex; ++i)
        buffer[i] = *(in++);

    for (unsigned wordIndex = 0; wordIndex < out.size(); ++wordIndex) {
        static_assert(sizeof(sc_dt::sc_digit) == 4);

        // clang-format off
        out.set_word(
            wordIndex,
            (((sc_dt::sc_digit)buffer[wordIndex * 4]) << 0) |
            (((sc_dt::sc_digit)buffer[wordIndex * 4 + 1]) << 8) |
            (((sc_dt::sc_digit)buffer[wordIndex * 4 + 2]) << 16) |
            (((sc_dt::sc_digit)buffer[wordIndex * 4 + 3]) << 24)
        );
        // clang-format on
    }
}

inline void prepareWriteStrobe(sc_dt::sc_bv_base& out, uint8_t lowerByteIndex, uint8_t upperByteIndex) {
    for (unsigned bitIndex = 0; bitIndex < out.length(); ++bitIndex) {
        out.set_bit(bitIndex, bitIndex >= lowerByteIndex && bitIndex <= upperByteIndex);
    }
}

inline void prepareReadData(sc_dt::sc_bv_base const& in, uint8_t* out, uint8_t lowerByteIndex, uint8_t upperByteIndex) {
    // can be further improved
    uint8_t buffer[128] = { 0 };

    for (unsigned wordIndex = 0; wordIndex < in.size(); ++wordIndex) {
        static_assert(sizeof(sc_dt::sc_digit) == 4);

        auto word = in.get_word(wordIndex);

        // clang-format off
        buffer[wordIndex * 4] = (word >> 0) & 0xFF;
        buffer[wordIndex * 4 + 1] = (word >> 8) & 0xFF;
        buffer[wordIndex * 4 + 2] = (word >> 16) & 0xFF;
        buffer[wordIndex * 4 + 3] = (word >> 24) & 0xFF;
        // clang-format on
    }

    for (unsigned i = lowerByteIndex; i <= upperByteIndex; ++i)
        *(out++) = buffer[i];
}

} // namespace detail

inline void simpleWrite(
    axi4::full::SlaveBase& target,
    uint64_t& addr,
    uint64_t& numBytes,
    uint8_t const*& data,
    int size = -1,
    bool log = false
) {
    auto const& cfg = target.config();
    unsigned maxSize = log2(cfg.wData / 8u);
    size = (size >= 0 && size <= maxSize) ? size : maxSize;

    uint64_t mask = (((uint64_t)1) << size) - 1;
    uint64_t alignedAddr = addr & ~mask;
    uint64_t alignedNumBytes = numBytes + addr - alignedAddr;

    uint64_t numBeats = alignedNumBytes >> size;
    if (alignedNumBytes & mask)
        numBeats++;

    uint8_t len = numBeats - 1;
    len = MIN(len, cfg.axi3Compat ? 15 : 255);

    Transaction transaction(cfg.wData, cfg.axi3Compat);
    transaction.reset(addr, len, size, 1);

    // TODO: do this without spawning new threads all the time!
    sc_core::sc_join j;

    SC_SPAWN_TO(j) {
        axi4::full::Packets::WriteAddress aw {
            .id = util::bv_from(0, cfg.wId),
            .addr = util::bv_from(addr, cfg.wAddr),
            .len = (uint8_t)len,
            .size = (uint8_t)size,
            .burst = 1
        };

        target.sendAW(aw);
        if (log)
            fmt::print("simpleWrite: [t = {}] sent: {}\n", sc_core::sc_time_stamp().to_string(), aw);
    };

    SC_SPAWN_TO(j) {
        sc_dt::sc_bv_base bvData((int)cfg.wData);
        sc_dt::sc_bv_base bvStrb((int)cfg.wStrb);

        Beat b;

        while (transaction.nextBeat(b)) {
            uint32_t transferSize = MIN(b.size, numBytes);
            detail::prepareWriteData(bvData, data, b.lowerByteIndex, b.lowerByteIndex + transferSize - 1);
            detail::prepareWriteStrobe(bvStrb, b.lowerByteIndex, b.lowerByteIndex + transferSize - 1);

            axi4::full::Packets::WriteData w {
                .data = bvData,
                .strb = bvStrb,
                .last = b.last
            };

            target.sendW(w);
            if (log)
                fmt::print("simpleWrite: [t = {}] sent: {}\n", sc_core::sc_time_stamp().to_string(), w);

            addr += transferSize;
            data += transferSize;
            numBytes -= transferSize;
        }
    };

    SC_SPAWN_TO(j) {
        auto b = target.receiveB();

        if (log)
            fmt::print("simpleWrite: [t = {}] received: {}\n", sc_core::sc_time_stamp().to_string(), b);
    };

    j.wait();
}

inline void write(
    axi4::full::SlaveBase& target,
    uint64_t addr,
    uint64_t numBytes,
    unsigned char const* data,
    int size = -1,
    bool log = false
) {
    while (numBytes > 0) {
        simpleWrite(target, addr, numBytes, data, size, log);
        sc_core::wait(sc_core::SC_ZERO_TIME);
    }
}

inline void simpleRead(
    axi4::full::SlaveBase& target,
    uint64_t& addr,
    uint64_t& numBytes,
    uint8_t*& data,
    int size = -1,
    bool log = false
) {
    auto const& cfg = target.config();
    unsigned maxSize = log2(cfg.wData / 8u);
    size = (size >= 0 && size <= maxSize) ? size : maxSize;

    uint64_t mask = (((uint64_t)1) << size) - 1;
    uint64_t alignedAddr = addr & ~mask;
    uint64_t alignedNumBytes = numBytes + addr - alignedAddr;

    uint64_t numBeats = alignedNumBytes >> size;
    if (alignedNumBytes & mask)
        numBeats++;

    uint8_t len = numBeats - 1;

    len = MIN(len, cfg.axi3Compat ? 15 : 255);

    Transaction transaction(cfg.wData, cfg.axi3Compat);
    transaction.reset(addr, len, size, 1);

    // TODO: do this without spawning new threads all the time!
    sc_core::sc_join j;

    SC_SPAWN_TO(j) {
        axi4::full::Packets::ReadAddress ar {
            .id = util::bv_from(0, cfg.wId),
            .addr = util::bv_from(addr, cfg.wAddr),
            .len = (uint8_t)len,
            .size = (uint8_t)size,
            .burst = 1
        };

        target.sendAR(ar);
        if (log)
            fmt::print("simpleRead: [t = {}] sent: {}\n", sc_core::sc_time_stamp().to_string(), ar);
    };

    SC_SPAWN_TO(j) {
        sc_dt::sc_bv_base bvData((int)cfg.wData);

        Beat b;

        while (transaction.nextBeat(b)) {
            auto r = target.receiveR();
            if (log)
                fmt::print("simpleRead: [t = {}] received: {}\n", sc_core::sc_time_stamp().to_string(), r);

            uint32_t transferSize = MIN(b.size, numBytes);
            detail::prepareReadData(r.data, data, b.lowerByteIndex, b.lowerByteIndex + transferSize - 1);

            addr += transferSize;
            data += transferSize;
            numBytes -= transferSize;
        }
    };

    j.wait();
}

inline void read(
    axi4::full::SlaveBase& target,
    uint64_t addr,
    uint64_t numBytes,
    uint8_t* data,
    int size = -1,
    bool log = false
) {
    while (numBytes > 0) {
        simpleRead(target, addr, numBytes, data, size, log);
        sc_core::wait(sc_core::SC_ZERO_TIME);
    }
}

} // namespace chext_test::amba::axi4::full

#endif /* CHEXT_TEST_AMBA_AXI4_FULL_TRANSACTION_HPP_INCLUDED */

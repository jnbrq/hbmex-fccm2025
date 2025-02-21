#include <boost/endian.hpp>
#include <read_engine/ReadEngine.hpp>

#include <cstdlib>

#include <stdexcept>
#include <vector>

#define READENGINE_REG_WORKING 0x00000000ull
#define READENGINE_REG_COUNTER_LO 0x00000004ull
#define READENGINE_REG_COUNTER_HI 0x00000008ull
#define READENGINE_REG_DESC_INDEX 0x0000000cull
#define READENGINE_REG_DESC_COUNT 0x00000010ull
#define READENGINE_CMD_START 0x00000014ull

#define READENGINE_MULTI_REG_WORKING 0x00000000ull
#define READENGINE_MULTI_REG_COUNTER_LO 0x00000004ull
#define READENGINE_MULTI_REG_COUNTER_HI 0x00000008ull
#define READENGINE_MULTI_CMD_START 0x0000000cull

namespace read_engine {

void Desc::encode(std::uint8_t* dest) const noexcept {
    boost::endian::little_uint64_t buffer;

    buffer = //
        addr | //
        (((std::uint64_t)id) << 42) | //
        (((std::uint64_t)len) << 54) | //
        (((std::uint64_t)flags) << 62);

    std::memcpy(dest + 0, buffer.data(), 8);
}

Desc Desc::decode(const uint8_t* src) noexcept {
    boost::endian::little_uint64_t buffer;
    std::memcpy((void*)buffer.data(), src, 8);
    return {
        .addr = (uint64_t)((buffer) & ((1ull << 42) - 1)),
        .id = (uint16_t)((buffer >> 42) & ((1ull << 12) - 1)),
        .len = (uint8_t)((buffer >> 54) & ((1ull << 8) - 1)),
        .flags = (uint8_t)((buffer >> 62) & ((1ull << 2) - 1))
    };
}

ReadEngine::ReadEngine(
    Config const& cfg,
    std::shared_ptr<hal::Memory> mem_ctrl,
    std::shared_ptr<hal::Memory> mem_desc,
    std::shared_ptr<hal::Sleep> sleep
)
    : cfg_ { cfg }
    , mem_ctrl_ { mem_ctrl }
    , mem_desc_ { mem_desc }
    , sleep_ { sleep } {
}

void ReadEngine::copyDescRaw(uint8_t* data, uint32_t size, uint32_t offset, bool verify) {
    mem_desc_->write(offset, data, size);

    if (verify) {
        std::vector<uint8_t> buffer(size);
        mem_desc_->read(&buffer[0], offset, size);

        for (size_t i = 0; i < size; ++i)
            if (buffer[i] != data[i]) {
                throw std::runtime_error("descriptor corruption!");
            }
    }
}

void ReadEngine::copyDesc(Desc const* arr, uint32_t len, uint32_t offset, bool verify) {
    if (len > (1u << config().log2numDesc))
        throw std::logic_error("tried to copy more descriptors than available!");

    constexpr std::size_t DESC_SIZE = 8;

    std::vector<uint8_t> buf(len * DESC_SIZE);

    for (uint64_t idx = 0; idx < len; ++idx)
        arr[idx].encode(buf.data() + idx * DESC_SIZE);

    copyDescRaw(buf.data(), buf.size(), offset * DESC_SIZE, verify);
}

void ReadEngine::task(uint32_t idx, uint32_t len) {
    mem_ctrl_->writeReg32(READENGINE_REG_DESC_INDEX, idx);
    mem_ctrl_->writeReg32(READENGINE_REG_DESC_COUNT, len);
}

void ReadEngine::start() {
    mem_ctrl_->writeReg32(READENGINE_CMD_START, 1);
}

bool ReadEngine::isWorking() {
    return mem_ctrl_->readReg32(READENGINE_REG_WORKING) > 0;
}

uint64_t ReadEngine::cycles() {
    return mem_ctrl_->readReg64(READENGINE_REG_COUNTER_LO);
}

void ReadEngine::waitUntilComplete() {
    while (isWorking()) {
        sleep_->sleep(50);
    }
}

ReadEngineMulti::ReadEngineMulti(
    MultiConfig const& cfg,
    std::shared_ptr<hal::Memory> mem_ctrl,
    std::shared_ptr<hal::Memory> mem_desc,
    std::shared_ptr<hal::Sleep> sleep
)
    : cfg_ { cfg }
    , mem_ctrl_ { mem_ctrl }
    , mem_desc_ { mem_desc }
    , sleep_ { sleep } {

    for (unsigned i = 0; i < cfg.numEngines; ++i) {
        auto mem_ctrl = mem_ctrl_->offset(0x100 * (i + 1));
        auto mem_desc = mem_desc_->offset((8 << cfg.singleCfg.log2numDesc) * i);

        drivers_.emplace_back(
            cfg.singleCfg,
            mem_ctrl,
            mem_desc,
            sleep_
        );
    }
}

void ReadEngineMulti::start() {
    mem_ctrl_->writeReg32(READENGINE_MULTI_CMD_START, 1);
}

bool ReadEngineMulti::isWorking() {
    return mem_ctrl_->readReg32(READENGINE_MULTI_REG_WORKING);
}

uint64_t ReadEngineMulti::cycles() {
    return mem_ctrl_->readReg64(READENGINE_MULTI_REG_COUNTER_LO);
}

void ReadEngineMulti::waitUntilComplete() {
    while (isWorking()) {
        sleep_->sleep(50);
    }
}

} // namespace read_engine

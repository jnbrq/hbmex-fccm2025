#include "Sgdma.hpp"
#include "boost/endian.hpp"

#include <cstdlib>

#include <stdexcept>
#include <vector>

#define SGDMA_REG_WORKING 0x00000000ull
#define SGDMA_REG_COUNTER_LO 0x00000004ull
#define SGDMA_REG_COUNTER_HI 0x00000008ull
#define SGDMA_REG_MODE 0x0000000cull
#define SGDMA_REG_SGDMA_DISCARD_READ_DATA 0x00000010ull
#define SGDMA_REG_SGDMA_INDEX_LO 0x00000014ull
#define SGDMA_REG_SGDMA_INDEX_HI 0x00000018ull
#define SGDMA_REG_SGDMA_LENGTH_LO 0x0000001cull
#define SGDMA_REG_SGDMA_LENGTH_HI 0x00000020ull
#define SGDMA_REG_INIT_ADDR_LO 0x00000024ull
#define SGDMA_REG_INIT_ADDR_HI 0x00000028ull
#define SGDMA_REG_INIT_SIZE_LO 0x0000002cull
#define SGDMA_REG_INIT_SIZE_HI 0x00000030ull
#define SGDMA_REG_INIT_MAX_BURST_LEN 0x00000034ull
#define SGDMA_REG_INIT_INITIAL_0 0x00000038ull
#define SGDMA_REG_INIT_INITIAL_1 0x0000003cull
#define SGDMA_REG_INIT_INITIAL_2 0x00000040ull
#define SGDMA_REG_INIT_INITIAL_3 0x00000044ull
#define SGDMA_REG_INIT_DELTA_0 0x00000048ull
#define SGDMA_REG_INIT_DELTA_1 0x0000004cull
#define SGDMA_REG_INIT_DELTA_2 0x00000050ull
#define SGDMA_REG_INIT_DELTA_3 0x00000054ull
#define SGDMA_CMD_START 0x00000058ull

#define SGDMA_MULTI_REG_WORKING 0x00000000ull
#define SGDMA_MULTI_REG_COUNTER_LO 0x00000004ull
#define SGDMA_MULTI_REG_COUNTER_HI 0x00000008ull
#define SGDMA_MULTI_CMD_START 0x0000000cull

void SgdmaDesc::encode(std::uint8_t* dest) const noexcept {
    boost::endian::little_uint64_t buffer;
    buffer = //
        addr | //
        (((std::uint64_t)len) << 48) | //
        (((std::uint64_t)flags) << 58);
    std::memcpy(dest + 0, buffer.data(), 8);
}

SgdmaDesc SgdmaDesc::decode(const uint8_t* src) noexcept {
    boost::endian::little_uint64_t buffer;
    std::memcpy((void*)buffer.data(), src, 8);
    return {
        .addr = (uint16_t)((buffer) & ((1ull << 48) - 1)),
        .len = (uint16_t)((buffer >> 48) & ((1ull << 10) - 1)),
        .flags = (uint16_t)((buffer >> 58) & ((1ull << 6) - 1))
    };
}

Sgdma::Sgdma(
    SgdmaConfig const& cfg,
    std::shared_ptr<providers::Memory> mem_ctrl,
    std::shared_ptr<providers::Memory> mem_desc,
    std::shared_ptr<providers::Sleep> sleep
)
    : cfg_ { cfg }
    , mem_ctrl_ { mem_ctrl }
    , mem_desc_ { mem_desc }
    , sleep_ { sleep } {
}

void Sgdma::copyDescRaw(uint8_t* data, uint32_t size, uint32_t offset, bool verify) {
    mem_desc_->copyToDevice(offset, data, size);

    if (verify) {
        std::vector<uint8_t> buffer(size);
        mem_desc_->copyFromDevice(&buffer[0], offset, size);

        for (size_t i = 0; i < size; ++i)
            if (buffer[i] != data[i]) {
                throw std::runtime_error("descriptor corruption!");
            }
    }
}

void Sgdma::copyDesc(SgdmaDesc const* arr, uint32_t len, uint32_t offset, bool verify) {
    if (len > (1u << config().log2numDesc))
        throw std::logic_error("tried to copy more descriptors than available!");

    constexpr std::size_t DESC_SIZE = 8;

    std::vector<uint8_t> buf(len * DESC_SIZE);

    for (uint64_t idx = 0; idx < len; ++idx)
        arr[idx].encode(buf.data() + idx * DESC_SIZE);

    copyDescRaw(buf.data(), buf.size(), offset * DESC_SIZE, verify);
}

void Sgdma::sgdmaTask(uint32_t idx, uint32_t len, bool discardReadData) {
    mem_ctrl_->writeReg32(SGDMA_REG_MODE, 0);
    mem_ctrl_->writeReg32(SGDMA_REG_SGDMA_DISCARD_READ_DATA, discardReadData);
    mem_ctrl_->writeReg64(SGDMA_REG_SGDMA_INDEX_LO, idx);
    mem_ctrl_->writeReg64(SGDMA_REG_SGDMA_LENGTH_LO, len);
}

void Sgdma::constInitTask(
    uint64_t addr,
    uint64_t size,
    std::uint32_t* init_vec,
    unsigned maxBurst
) {
    throw std::logic_error("not implemented");
}

void Sgdma::zeroInitTask(
    uint64_t addr,
    uint64_t size,
    unsigned maxBurst
) {
    throw std::logic_error("not implemented");
}

void Sgdma::start() {
    mem_ctrl_->writeReg32(SGDMA_CMD_START, 1);
}

bool Sgdma::isWorking() {
    return mem_ctrl_->readReg32(SGDMA_REG_WORKING) > 0;
}

uint64_t Sgdma::cycles() {
    return mem_ctrl_->readReg64(SGDMA_REG_COUNTER_LO);
}

void Sgdma::waitUntilComplete() {
    while (isWorking()) {
        sleep_->sleep(50);
    }
}

SgdmaMulti::SgdmaMulti(
    SgdmaMultiConfig const& cfg,
    std::shared_ptr<providers::Memory> mem_ctrl,
    std::shared_ptr<providers::Memory> mem_desc,
    std::shared_ptr<providers::Sleep> sleep
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

void SgdmaMulti::start() {
    mem_ctrl_->writeReg32(SGDMA_MULTI_CMD_START, 1);
}

bool SgdmaMulti::isWorking() {
    return mem_ctrl_->readReg32(SGDMA_MULTI_REG_WORKING);
}

uint64_t SgdmaMulti::cycles() {
    return mem_ctrl_->readReg64(SGDMA_MULTI_REG_COUNTER_LO);
}

void SgdmaMulti::waitUntilComplete() {
    while (isWorking()) {
        sleep_->sleep(50);
    }
}

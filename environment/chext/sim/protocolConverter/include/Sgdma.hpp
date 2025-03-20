#ifndef SGDMA_HPP_INCLUDED
#define SGDMA_HPP_INCLUDED

#include "Providers.hpp"
#include <vector>

struct SgdmaDesc {
    uint64_t addr;
    uint16_t len;
    uint16_t flags;

    /** @param dest array of 8 bytes. */
    void encode(uint8_t* dest) const noexcept;

    /** @param src array of 8 bytes. */
    static SgdmaDesc decode(const uint8_t* src) noexcept;

    static inline SgdmaDesc genAR(uint64_t addr, uint16_t len) {
        return { addr, len, 0x1 };
    }

    static inline SgdmaDesc genAW(uint64_t addr, uint16_t len) {
        return { addr, len, 0x3 };
    }

    static inline SgdmaDesc wait(uint64_t cycles) {
        return { cycles, 0, 0x0 };
    }
};

struct SgdmaConfig {
    uint32_t log2numDesc;
};

struct Sgdma {
    Sgdma(
        SgdmaConfig const& cfg,
        std::shared_ptr<providers::Memory> mem_ctrl,
        std::shared_ptr<providers::Memory> mem_desc,
        std::shared_ptr<providers::Sleep> sleep
    );

    void copyDescRaw(uint8_t* data, uint32_t size, uint32_t offset, bool verify = false);
    void copyDesc(SgdmaDesc const* arr, uint32_t len, uint32_t offset = 0x0u, bool verify = false);
    void sgdmaTask(uint32_t idx, uint32_t len, bool discardReadData = false);

    /** @param init_vec an array of uint32_t of size 4. */
    void constInitTask(
        uint64_t addr,
        uint64_t size,
        uint32_t* init_vec,
        unsigned maxBurst = 32
    );

    void zeroInitTask(
        uint64_t addr,
        uint64_t size,
        unsigned maxBurst = 32
    );

    void start();
    bool isWorking();
    uint64_t cycles();

    providers::Memory& mem() noexcept { return *mem_; }

    void waitUntilComplete();

    SgdmaConfig const& config() const noexcept {
        return cfg_;
    }

private:
    SgdmaConfig cfg_;

    std::shared_ptr<providers::Memory> mem_ctrl_;
    std::shared_ptr<providers::Memory> mem_desc_;
    std::shared_ptr<providers::Memory> mem_;
    std::shared_ptr<providers::Sleep> sleep_;
};

struct SgdmaMultiConfig {
    uint32_t numEngines;
    SgdmaConfig singleCfg;
};

struct SgdmaMulti {
    SgdmaMulti(
        SgdmaMultiConfig const& cfg,
        std::shared_ptr<providers::Memory> mem_ctrl,
        std::shared_ptr<providers::Memory> mem_desc,
        std::shared_ptr<providers::Sleep> sleep
    );

    Sgdma& operator[](unsigned idx) {
        return drivers_.at(idx);
    }

    Sgdma const& operator[](unsigned idx) const {
        return drivers_.at(idx);
    }

    void start();
    bool isWorking();
    uint64_t cycles();

    void waitUntilComplete();

    SgdmaMultiConfig const& config() const noexcept {
        return cfg_;
    }

private:
    SgdmaMultiConfig cfg_;

    std::shared_ptr<providers::Memory> mem_ctrl_;
    std::shared_ptr<providers::Memory> mem_desc_;
    std::shared_ptr<providers::Sleep> sleep_;

    std::vector<Sgdma> drivers_;
};

#endif // SGDMA_HPP_INCLUDED

#ifndef READ_ENGINE_READENGINE_HPP_INCLUDED
#define READ_ENGINE_READENGINE_HPP_INCLUDED

#include <hal/hal.hpp>
#include <vector>

namespace read_engine {

struct Desc {
    uint64_t addr;
    uint16_t id;
    uint8_t len;
    uint8_t flags;

    /** @param dest array of 8 bytes. */
    void encode(uint8_t* dest) const noexcept;

    /** @param src array of 8 bytes. */
    static Desc decode(const uint8_t* src) noexcept;

    static inline Desc mkAddr(uint64_t addr, uint16_t id, uint8_t len) {
        return { addr, id, len, 0x1 };
    }

    static inline Desc mkWait(uint64_t cycles) {
        return { cycles, 0, 0, 0x0 };
    }
};

struct Config {
    uint32_t log2numDesc;
};

struct ReadEngine {
    ReadEngine(
        Config const& cfg,
        std::shared_ptr<hal::Memory> mem_ctrl,
        std::shared_ptr<hal::Memory> mem_desc,
        std::shared_ptr<hal::Sleep> sleep
    );

    void copyDescRaw(uint8_t* data, uint32_t size, uint32_t offset, bool verify = false);
    void copyDesc(Desc const* arr, uint32_t len, uint32_t offset = 0x0u, bool verify = false);
    void task(uint32_t idx, uint32_t len);

    void start();
    bool isWorking();
    uint64_t cycles();

    hal::Memory& mem() noexcept { return *mem_; }

    void waitUntilComplete();

    auto const& config() const noexcept {
        return cfg_;
    }

private:
    Config cfg_;

    std::shared_ptr<hal::Memory> mem_ctrl_;
    std::shared_ptr<hal::Memory> mem_desc_;
    std::shared_ptr<hal::Memory> mem_;
    std::shared_ptr<hal::Sleep> sleep_;
};

struct MultiConfig {
    uint32_t numEngines;
    Config singleCfg;
};

struct ReadEngineMulti {
    ReadEngineMulti(
        MultiConfig const& cfg,
        std::shared_ptr<hal::Memory> mem_ctrl,
        std::shared_ptr<hal::Memory> mem_desc,
        std::shared_ptr<hal::Sleep> sleep
    );

    ReadEngine& operator[](unsigned idx) {
        return drivers_.at(idx);
    }

    auto const& operator[](unsigned idx) const {
        return drivers_.at(idx);
    }

    void start();
    bool isWorking();
    uint64_t cycles();

    void waitUntilComplete();

    MultiConfig const& config() const noexcept {
        return cfg_;
    }

private:
    MultiConfig cfg_;

    std::shared_ptr<hal::Memory> mem_ctrl_;
    std::shared_ptr<hal::Memory> mem_desc_;
    std::shared_ptr<hal::Sleep> sleep_;

    std::vector<ReadEngine> drivers_;
};

} // namespace read_engine

#endif /* READ_ENGINE_READENGINE_HPP_INCLUDED */

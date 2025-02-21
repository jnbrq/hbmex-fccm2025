#include <d4e/xil.h>
#include <hal/d4e.hpp>
#include <hal/hal.hpp>

#include <read_engine/ReadEngine.hpp>

#include <fstream>
#include <random>
#include <sstream>
#include <stdexcept>
#include <vector>

#include <hbm_explore.hpp>

constexpr hal::addr_t READ_ENGINE_450MHZ_CTRL_BASE = 0x0'0000;
constexpr hal::addr_t READ_ENGINE_450MHZ_DESC_BASE = 0x0'8000;

constexpr hal::addr_t READ_ENGINE_300MHZ_CTRL_BASE = 0x1'0000;
constexpr hal::addr_t READ_ENGINE_300MHZ_DESC_BASE = 0x1'8000;

struct Experiment {
    Experiment(d4e_device* dev)
        : memory { d4e::wrapDevice(dev) }
        , sleep { d4e::sleep() }
        , readEngine450MHz(
              read_engine::Config { .log2numDesc = 12 },
              memory->offset(READ_ENGINE_450MHZ_CTRL_BASE),
              memory->offset(READ_ENGINE_450MHZ_DESC_BASE),
              sleep
          )
        , readEngine300MHz(
              read_engine::Config { .log2numDesc = 12 },
              memory->offset(READ_ENGINE_300MHZ_CTRL_BASE),
              memory->offset(READ_ENGINE_300MHZ_DESC_BASE),
              sleep
          ) {
    }

    void run() {
        readEngine = &readEngine300MHz;
        fmt::print("{:#^80}\n", "  Clock frequency is 300 MHz  ");
        runExperiments();

        readEngine = &readEngine450MHz;
        fmt::print("{:#^80}\n", "  Clock frequency is 450 MHz  ");
        runExperiments();
    }

    ~Experiment() {
    }

private:
    std::shared_ptr<hal::Memory> memory;
    std::shared_ptr<hal::Sleep> sleep;

    read_engine::ReadEngine readEngine450MHz, readEngine300MHz;
    read_engine::ReadEngine* readEngine;

    std::mt19937_64 gen { 877546 };

    void dataPoint(DataPointConfig const& cfg) {
        fmt::print("DataPoint({})\n", cfg.toString());

        // number of times this experiment is repeated
        constexpr unsigned numRepetitions = 1024;

        // number of descriptors used per repetition of the experiment
        constexpr unsigned numDescs = 4096;

        double sumCyclesPerBeat = 0;

        for (unsigned repetitionIndex = 0; repetitionIndex < numRepetitions; ++repetitionIndex) {
            unsigned idMask = ((1 << 6) - 1);

            std::vector<read_engine::Desc> descs;
            descs.reserve(numDescs);

            std::uniform_int_distribution<uint64_t> dist(0, ((1 << cfg.rndAddrBits) - 1));

            for (unsigned i = 0; i < numDescs; ++i) {
                // THIS IS THE LINE THAT CREATES AND TRANSFORMS THE ADDRESS
                uint64_t rnd = dist(gen);
                uint64_t addr = cfg.transform->transform(rnd);

                // fmt::print("addr[0x{:03x}]: 0x{:012x} -> 0x{:012x}\n", i, rnd, addr);

                uint16_t id;

                if (cfg.idMode == IdMode::ID_ZERO) {
                    id = 0;
                } else if (cfg.idMode == IdMode::ID_MASK_INDEX) {
                    id = (i & idMask);
                } else /* if (cfg.idMode == IdMode::ID_SHIFT_MASK_ADDR) */ {
                    id = ((addr >> cfg.idShift) & idMask);
                }

                descs.push_back(read_engine::Desc::mkAddr(addr, id, cfg.len));
            }

            readEngine->copyDesc(descs.data(), numDescs, 0, true);
            readEngine->task(0, numDescs);
            readEngine->start();
            readEngine->waitUntilComplete();

            auto cycles = readEngine->cycles();
            auto cyclesPerBeat = ((double)cycles) / (numDescs * (cfg.len + 1));
            sumCyclesPerBeat += cyclesPerBeat;

            // UNCOMMENT THE FOLLOWING LINE TO PRINT THE RESULT FOR EACH REPETITION
            // fmt::print("    RepetitionResult(repetitionIndex = {}, numCycles = {}, cyclesPerBeat = {})\n", repetitionIndex, cycles, cyclesPerBeat);
        }

        double avgCyclesPerBeat = sumCyclesPerBeat / numRepetitions;

        fmt::print("    DataPointResult(avgCyclesPerBeat = {})\n", avgCyclesPerBeat);
    }

    void runExperimentForLength(std::uint16_t len) {
        // NOTE: only valid for HBM2E 8H devices
        // NOTE: PCs are chosen by bits 32-29
        // NOTE: Bit 28 -> SID
        // NOTE: Bits 4-0 -> not used
        // NOTE: Bits 27-14 -> row address

        // 23 + 5 --> 256 MB
        std::uint16_t rndAddrBits = 23;

        // clang-format off
        auto shift = Transform::mkShiftLeft(5);
        auto transformPc1  = shift->then(Transform::mkGenericBE({ 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }));
        auto transformPc2  = shift->then(Transform::mkGenericBE({ 33, 32, 31, 30, 14, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 29, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }));
        auto transformPc4  = shift->then(Transform::mkGenericBE({ 33, 32, 31, 15, 14, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 30, 29, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }));
        auto transformPc8  = shift->then(Transform::mkGenericBE({ 33, 32, 16, 15, 14, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 31, 30, 29, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }));
        auto transformPc16 = shift->then(Transform::mkGenericBE({ 33, 17, 16, 15, 14, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 32, 31, 30, 29, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }));
        // clang-format on

        fmt::print("{:#^80}\n", fmt::format("  Length = {}  ", len));

        fmt::print("{:*^80}\n", "  single PC (512 MB)  ");
        dataPoint({ .idMode = IdMode::ID_ZERO, .idShift = 0, .len = len, .rndAddrBits = rndAddrBits, .transform = transformPc1 });
        dataPoint({ .idMode = IdMode::ID_MASK_INDEX, .idShift = 0, .len = len, .rndAddrBits = rndAddrBits, .transform = transformPc1 });
        dataPoint({ .idMode = IdMode::ID_SHIFT_MASK_ADDR, .idShift = 29, .len = len, .rndAddrBits = rndAddrBits, .transform = transformPc1 });

        fmt::print("{:*^80}\n", "  distribute among 2 PCs (1 GB)  ");
        dataPoint({ .idMode = IdMode::ID_ZERO, .idShift = 0, .len = len, .rndAddrBits = rndAddrBits, .transform = transformPc2 });
        dataPoint({ .idMode = IdMode::ID_MASK_INDEX, .idShift = 0, .len = len, .rndAddrBits = rndAddrBits, .transform = transformPc2 });
        dataPoint({ .idMode = IdMode::ID_SHIFT_MASK_ADDR, .idShift = 29, .len = len, .rndAddrBits = rndAddrBits, .transform = transformPc2 });

        fmt::print("{:*^80}\n", "  distribute among 4 PCs (2 GB)  ");
        dataPoint({ .idMode = IdMode::ID_ZERO, .idShift = 0, .len = len, .rndAddrBits = rndAddrBits, .transform = transformPc4 });
        dataPoint({ .idMode = IdMode::ID_MASK_INDEX, .idShift = 0, .len = len, .rndAddrBits = rndAddrBits, .transform = transformPc4 });
        dataPoint({ .idMode = IdMode::ID_SHIFT_MASK_ADDR, .idShift = 29, .len = len, .rndAddrBits = rndAddrBits, .transform = transformPc4 });

        fmt::print("{:*^80}\n", "  distribute among 8 PCs (4 GB)  ");
        dataPoint({ .idMode = IdMode::ID_ZERO, .idShift = 0, .len = len, .rndAddrBits = rndAddrBits, .transform = transformPc8 });
        dataPoint({ .idMode = IdMode::ID_MASK_INDEX, .idShift = 0, .len = len, .rndAddrBits = rndAddrBits, .transform = transformPc8 });
        dataPoint({ .idMode = IdMode::ID_SHIFT_MASK_ADDR, .idShift = 29, .len = len, .rndAddrBits = rndAddrBits, .transform = transformPc8 });

        fmt::print("{:*^80}\n", "  distribute among 16 PCs (8 GB)  ");
        dataPoint({ .idMode = IdMode::ID_ZERO, .idShift = 0, .len = len, .rndAddrBits = rndAddrBits, .transform = transformPc16 });
        dataPoint({ .idMode = IdMode::ID_MASK_INDEX, .idShift = 0, .len = len, .rndAddrBits = rndAddrBits, .transform = transformPc16 });
        dataPoint({ .idMode = IdMode::ID_SHIFT_MASK_ADDR, .idShift = 29, .len = len, .rndAddrBits = rndAddrBits, .transform = transformPc16 });
    }

    void runExperiments() {
        // 23 + 5 --> 256 MB
        std::uint16_t rndAddrBits = 23;

        runExperimentForLength(0);
        runExperimentForLength(1);
        runExperimentForLength(2);
        runExperimentForLength(3);
    }
};

int main(int argc, char** argv) {
    struct d4e_xil_device xil_device;
    d4e_xil_device_open(&xil_device, "/dev/xdma0", 0, 0, (16ull << 20));

    {
        Experiment exp(&xil_device.device);
        exp.run();
    }

    d4e_close(&xil_device.device);
    return 0;
}

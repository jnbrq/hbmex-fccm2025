#include <chext_test/util/hal.hpp>
#include <systemc>

namespace chext_test::util {

std::shared_ptr<hal::Sleep> halSleep = [] {
    struct Sleep : hal::Sleep {
        void sleep(hal::uint64_t ns) override {
            sc_core::wait(ns, sc_core::SC_NS);
        }

        virtual ~Sleep() = default;
    };

    return std::make_shared<Sleep>();
}();

} // namespace chext_test::util

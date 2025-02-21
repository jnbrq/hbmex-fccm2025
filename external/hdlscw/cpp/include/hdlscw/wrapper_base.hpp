#ifndef HDLSCW_WRAPPER_BASE_INCLUDED
#define HDLSCW_WRAPPER_BASE_INCLUDED

#if defined(VERILATED_TRACE_ENABLED)
#include <verilated_vcd_c.h>
#endif // defined(VERILATED_TRACE_ENABLED)

#include <systemc>
#include <string>
#include <unordered_map>
#include <type_traits>
#include <typeindex>

namespace hdlscw {

struct wrapper_base {
    virtual sc_core::sc_module* getThisModule() noexcept = 0;
    virtual sc_core::sc_module const* getThisModule() const noexcept = 0;

    virtual sc_core::sc_module* getVerilatedModule() noexcept = 0;
    virtual sc_core::sc_module const* getVerilatedModule() const noexcept = 0;

    #if defined(VERILATED_TRACE_ENABLED)
    virtual void traceVerilated(VerilatedVcdC* tfp, int levels, int options = 0) {  }
    #endif // defined(VERILATED_TRACE_ENABLED)

    template <typename T>
    T const &get(const std::string &name) const
    {
        auto const &x = objects_.at(name);

        if (typeid(T) != x.type_index)
            throw std::runtime_error("not the expected type");

        return *((T const *)x.ptr);
    }

    template <typename T>
    T &get(const std::string &name)
    {
        auto &x = objects_.at(name);

        if (typeid(T) != x.type_index)
            throw std::runtime_error("not the expected type");

        return *((T *)x.ptr);
    }

    virtual ~wrapper_base() = default;

protected:
    /** @note Non-owning. */
    template <typename T>
    void set(const std::string &name, T &t)
    {
        if (objects_.count(name) != 0)
            throw std::runtime_error("an object with the given name already registered!");

        objects_[name] = {(void *)&t, typeid(T)};
    }

private:
    struct PointerTypeId
    {
        void *ptr;
        std::type_index type_index{typeid(void)};
    };

    std::unordered_map<std::string, PointerTypeId> objects_;
}; /* struct wrapper_base */

} /* namespace hdlscw */

#endif // HDLSCW_WRAPPER_BASE_INCLUDED

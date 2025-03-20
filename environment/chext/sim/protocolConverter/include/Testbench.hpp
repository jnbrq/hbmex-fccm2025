#ifndef TESTBENCH_HPP_INCLUDED
#define TESTBENCH_HPP_INCLUDED

#include <functional>

#include <hdlscw/wrapper_base.hpp>
#include <systemc>

#include "Providers.hpp"
#include "Sgdma.hpp"

using ModulePtr = std::shared_ptr<hdlscw::wrapper_base>;
using ModuleGen = std::function<ModulePtr(sc_core::sc_module_name const&)>;

template<typename T>
ModuleGen moduleGenFor() {
    return [](sc_core::sc_module_name const& moduleName) -> ModulePtr {
        return ModulePtr(new T(moduleName));
    };
}

class Testbench : sc_core::sc_module {
public:
    SC_HAS_PROCESS(Testbench);

    Testbench(ModuleGen moduleGen);

    bool isDone();

    ~Testbench();

    ModulePtr dut;

private:
    sc_core::sc_clock clock;
    sc_core::sc_signal<bool> reset;

    std::shared_ptr<providers::Memory> S_AXI_MEM;
    std::shared_ptr<providers::Memory> S_AXIL_CTRL;
    std::shared_ptr<providers::Memory> S_AXI_DESC;
    std::unique_ptr<SgdmaMulti> sgdmaMulti_;
    bool isDone_ { false };

    void thread();
};

#endif /* TESTBENCH_HPP_INCLUDED */

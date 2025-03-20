#if !defined(__SCMYMODULE_HPP_INCLUDED__)
#define __SCMYMODULE_HPP_INCLUDED__

#include <VmyModule.h>

#include <systemc>
#include <tlm>

#include <hdlscw/wrapper_base.hpp>

/* BEGIN: chext_test includes for 'amba/axi4' */
#include <chext_test/amba/axi4/full/Driver.hpp>
#include <chext_test/amba/axi4/lite/Driver.hpp>
/* END: chext_test includes for 'amba/axi4' */

/* BEGIN: chext_test includes for 'elastic' */
#include <chext_test/elastic/Driver.hpp>
#include <chext_test/elastic/DataLast.hpp>
#include <Packet.hpp>
/* END: chext_test includes for 'elastic' */

/** @brief ScmyModule */
class ScmyModule final :
    public sc_core::sc_module,
    public hdlscw::wrapper_base {
public:

    explicit ScmyModule(sc_core::sc_module_name const& moduleName = "");

    SC_HAS_PROCESS(ScmyModule);

    /* BEGIN: clock ports (decl) */
    sc_core::sc_in_clk clock;
    /* END: clock ports (decl) */

    /* BEGIN: reset ports (decl) */
    sc_core::sc_in<bool> reset;
    /* END: reset ports (decl) */

    /* BEGIN: interrupt ports (decl) */
    sc_core::sc_out<bool> irq;
    /* END: interrupt ports (decl) */

    /* BEGIN: data ports (decl) */
    /* END: data ports (decl) */

    sc_core::sc_module* getThisModule() noexcept override {
        return this;
    }

    sc_core::sc_module const* getThisModule() const noexcept override {
        return this;
    }

    sc_core::sc_module* getVerilatedModule() noexcept override {
        return &verilatedModule_;
    }

    sc_core::sc_module const* getVerilatedModule() const noexcept override {
        return &verilatedModule_;
    }

    #if defined(VERILATED_TRACE_ENABLED)
    void traceVerilated(VerilatedVcdC* tfp, int levels, int options = 0) override {
        return verilatedModule_.trace(tfp, levels, options);
    }
    #endif

    /* BEGIN: chext_test public for 'amba/axi4' */
    chext_test::amba::axi4::lite::Slave<20,32> s_axil_management;
    chext_test::amba::axi4::full::Master<4,32,256,32,32,32,32,32,false> m_axi;
    /* END: chext_test public for 'amba/axi4' */

    /* BEGIN: chext_test public for 'elastic' */
    chext_test::elastic::Source<sc_dt::sc_bv<32>> source1;
    chext_test::elastic::Source<chext_test::elastic::DataLastSignals<64>> source2;
    chext_test::elastic::Source<PacketSignals<128>> source3;
    /* END: chext_test public for 'elastic' */

    virtual ~ScmyModule();

private:

    VmyModule verilatedModule_;

    /* BEGIN: inverted reset signals */
    sc_core::sc_signal<bool> reset_INVERTED_;
    /* END: inverted reset signals */

    void generateInvertedResetPorts();

protected:

}; /* class ScmyModule */

#endif /* !defined(__SCMYMODULE_HPP_INCLUDED__) */

#ifndef SCPROVIDERS_HPP_INCLUDED
#define SCPROVIDERS_HPP_INCLUDED

#include "Providers.hpp"
#include <systemc>
#include <tlm>

namespace sc_providers {

/** Wraps the TLM socket. */
std::shared_ptr<providers::Memory> wrapTlmTargetSocket(
    tlm::tlm_target_socket<>& target,
    const sc_core::sc_module_name& name = "unnamedMemoryDriver"
);

/** SystemC sleep wrapper for FlexiMem HAL. */
extern std::shared_ptr<providers::Sleep> scSleep;

} // namespace sc_providers

#endif /* SCPROVIDERS_HPP_INCLUDED */

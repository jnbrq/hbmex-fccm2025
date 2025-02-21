cmake_minimum_required(VERSION 3.15)
cmake_policy(SET CMP0144 OLD)

project(protocolConverter)

# NOTE: This is a quick hack, remove later
add_compile_definitions(SC_DISABLE_API_VERSION_CHECK)

find_package(SystemCLanguage REQUIRED)
find_package(fmt REQUIRED)
find_package(verilator REQUIRED)
find_package(hdlscw REQUIRED)

# TODO: maybe sctlm should automatically include all of above
find_package(sctlm REQUIRED)

add_executable(
    protocolConverter
    src/main.cpp
    src/Testbench.cpp
    src/Providers.cpp
    src/ScProviders.cpp
    src/Sgdma.cpp
)
target_include_directories(protocolConverter PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_link_libraries(protocolConverter sctlm::sctlm)
target_compile_definitions(protocolConverter PRIVATE VERILATED_TRACE_ENABLED)

verilate(
    protocolConverter
    SYSTEMC
    SOURCES hdl/ProtocolConverterTest1.sv
    VERILATOR_ARGS --trace
)

hdlscw(
    TARGET protocolConverter
    HDLINFO hdl/ProtocolConverterTest1.hdlinfo.json
    ARGS -i sctlm
)

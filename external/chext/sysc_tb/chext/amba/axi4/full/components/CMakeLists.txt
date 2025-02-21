generate_tb(
    TARGET_NAME AddressGenerator
    HDL_MODULES AddressGeneratorTestTop1_1
)

generate_tb(
    TARGET_NAME AddressStrobeGenerator
    HDL_MODULES AddressStrobeGeneratorTestTop1_1
)

generate_tb(
    TARGET_NAME Downscale
    HDL_MODULES DownscaleTestTop1_1 DownscaleTestTop1_2
)

generate_tb(
    TARGET_NAME Upscale
    HDL_MODULES
        UpscaleTestTop1_1
        UpscaleTestTop1_2
)

generate_tb(
    TARGET_NAME IdSerialize
    HDL_MODULES IdSerializeTestTop1_1
)

generate_tb(
    TARGET_NAME IdParallelize
    HDL_MODULES
        IdParallelizeTestTop2_1
        IdParallelizeTestTop2_2
        IdParallelizeTestTop2_3
        IdParallelizeTestTop2_4
        IdParallelizeTestTop2_5
        IdParallelizeTestTop2_6
)

generate_tb(
    TARGET_NAME Unburst
    HDL_MODULES UnburstTestTop1_1
)

generate_tb(
    TARGET_NAME Transaction
    HDL_MODULES
        UpscaleTestTop1_1
        DownscaleTestTop1_1
)

find_package(sctlm REQUIRED)
add_executable(SctlmTest src/SctlmTest.cpp)

target_link_libraries(
    SctlmTest
    PUBLIC
    SystemC::systemc
    fmt::fmt
    chext_test::chext_test
    sctlm::sctlm
)

verilate(
    SctlmTest
    SYSTEMC
    SOURCES hdl/SctlmTest.sv
    VERILATOR_ARGS --trace
)

hdlscw(
    TARGET SctlmTest
    HDLINFO hdl/SctlmTest.hdlinfo.json
    ARGS -i sctlm
)

target_compile_definitions(SctlmTest PUBLIC SCTLM_DEBUG)

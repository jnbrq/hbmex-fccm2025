generate_tb(
    TARGET_NAME ReadEngineTop1
    HDL_MODULES
        ReadEngineTop1_1
    CPP_SOURCES
        ReadEngineTop1.tb.cpp
        read_engine/ReadEngine.cpp
)

generate_tb(
    TARGET_NAME ReadEngineMultiTop1
    HDL_MODULES
        ReadEngineMultiTop1_1
    CPP_SOURCES
        ReadEngineMultiTop1.tb.cpp
        read_engine/ReadEngine.cpp
)

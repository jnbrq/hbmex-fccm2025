generate_tb(
    TARGET_NAME ReadEngineSim1
    HDL_MODULES ReadEngineSim1
    CPP_SOURCES
        ReadEngineSim1.tb.cpp
        read_engine/ReadEngine.cpp
)

generate_tb(
    TARGET_NAME ReadEngineMultiSim1
    HDL_MODULES ReadEngineMultiSim1
    CPP_SOURCES
        ReadEngineMultiSim1.tb.cpp
        read_engine/ReadEngine.cpp
)

generate_tb(
    TARGET_NAME ReadStreamTop1
    HDL_MODULES
        ReadStreamTop1_1
    CPP_SOURCES
        ReadStreamTop1.tb.cpp
)

generate_tb(
    TARGET_NAME ReadStreamTop2
    HDL_MODULES
        ReadStreamTop2_1
    CPP_SOURCES
        ReadStreamTop2.tb.cpp
)

generate_tb(
    TARGET_NAME WriteStream1
    HDL_MODULES
        WriteStreamTop1_1
    CPP_SOURCES
        WriteStreamTop1.tb.cpp
)

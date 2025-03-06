generate_tb(
    TARGET_NAME RowReduceSingleTop1
    HDL_MODULES
        RowReduceSingleTop1_1
    CPP_SOURCES
        RowReduceSingleTop1.tb.cpp
)

generate_tb(
    TARGET_NAME RowReduceTop1
    HDL_MODULES
        RowReduceTop1_1
    CPP_SOURCES
        RowReduceTop1.tb.cpp
)

generate_tb(
    TARGET_NAME SpmvTop1
    HDL_MODULES
        SpmvTop1_1
    CPP_SOURCES
        SpmvTop1.tb.cpp
)

generate_tb(
    TARGET_NAME SpmvTop2
    HDL_MODULES
        SpmvTop2_1
    CPP_SOURCES
        SpmvTop2.tb.cpp
)

add_executable(test.linalg src/linalg.test.cpp)
target_link_libraries(test.linalg fmt::fmt)
target_include_directories(test.linalg PUBLIC include/)

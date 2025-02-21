generate_tb(
    TARGET_NAME RowReduceSingleTop
    HDL_MODULES
        RowReduceSingleTop
    CPP_SOURCES
        RowReduceSingleTop.tb.cpp
)

generate_tb(
    TARGET_NAME RowReduceTop
    HDL_MODULES
        RowReduceTop
    CPP_SOURCES
        RowReduceTop.tb.cpp
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

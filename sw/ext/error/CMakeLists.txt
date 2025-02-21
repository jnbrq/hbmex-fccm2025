add_library(svm::error INTERFACE IMPORTED GLOBAL)

target_sources(
    svm::error
    INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/common.c
)

target_include_directories(
    svm::error
    INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

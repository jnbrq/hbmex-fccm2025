add_library(svm::util INTERFACE IMPORTED GLOBAL)

target_sources(
    svm::util
    INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/cqueue.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/lfsr.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/mem.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/ptable.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/vector.c
)

target_include_directories(
    svm::util
    INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(svm::util INTERFACE svm::error)

file(GLOB test_files test/test.*.c)

foreach (f ${test_files})
    get_filename_component(basename ${f} NAME_WLE)
    add_executable("${basename}" ${f})
    target_link_libraries("${basename}" PRIVATE svm::util)
endforeach()

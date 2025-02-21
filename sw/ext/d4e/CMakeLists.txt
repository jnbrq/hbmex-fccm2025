add_library(svm::d4e INTERFACE IMPORTED GLOBAL)

target_sources(
    svm::d4e
    INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/interface.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/xil.c
)

target_include_directories(
    svm::d4e
    INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(svm::d4e INTERFACE svm::util svm::com9n)

file(GLOB test_files test/test.*.c)

foreach (f ${test_files})
    get_filename_component(basename ${f} NAME_WLE)
    add_executable("${basename}" ${f})
    target_link_libraries("${basename}" PRIVATE svm::d4e)
endforeach()

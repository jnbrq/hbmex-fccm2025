add_library(svm::com9n INTERFACE IMPORTED GLOBAL)

target_sources(
    svm::com9n
    INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/d4e.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/efd.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/util.c
)

target_include_directories(
    svm::com9n
    INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(svm::com9n INTERFACE svm::util svm::d4e)

file(GLOB test_files test/test.*.c)

foreach (f ${test_files})
    get_filename_component(basename ${f} NAME_WLE)
    add_executable("${basename}" ${f})
    target_link_libraries("${basename}" PRIVATE svm::com9n)
endforeach()

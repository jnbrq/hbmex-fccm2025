cmake_minimum_required(VERSION 3.11)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 20)

include_directories(include/)

project(c_project C CXX)

include(FetchContent)

FetchContent_Declare(
  fmt
  GIT_REPOSITORY https://github.com/fmtlib/fmt
  GIT_TAG        e69e5f977d458f2650bb346dadf2ad30c5320281) # 10.2.1
FetchContent_MakeAvailable(fmt)

add_subdirectory(ext/error/)
add_subdirectory(ext/util/)
add_subdirectory(ext/com9n/)
add_subdirectory(ext/d4e/)

add_library(hbmex::hal INTERFACE IMPORTED GLOBAL)
target_sources(
  hbmex::hal
  INTERFACE
  ${CMAKE_CURRENT_SOURCE_DIR}/src/hal/hal.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/src/hal/d4e.cpp
)
target_link_libraries(hbmex::hal INTERFACE svm::d4e fmt::fmt)

add_library(hbmex::spmv INTERFACE IMPORTED GLOBAL)
target_sources(
  hbmex::spmv
  INTERFACE
  ${CMAKE_CURRENT_SOURCE_DIR}/src/spmv/Manager.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/src/spmv/Task.cpp
)
target_link_libraries(hbmex::spmv INTERFACE hbmex::hal)

add_library(hbmex::read_engine INTERFACE IMPORTED GLOBAL)
target_sources(
  hbmex::read_engine
  INTERFACE
  ${CMAKE_CURRENT_SOURCE_DIR}/src/read_engine/ReadEngine.cpp
)
target_link_libraries(hbmex::read_engine INTERFACE hbmex::hal)

add_executable(spmv_explore_generate src/spmv_explore_generate.cpp)
target_link_libraries(spmv_explore_generate PRIVATE fmt::fmt)

add_executable(spmv_explore src/spmv_explore.cpp src/hal/hal.cpp src/hal/d4e.cpp)
target_link_libraries(spmv_explore PRIVATE hbmex::spmv)

add_executable(mm2csr src/mm2csr.cpp)
target_link_libraries(mm2csr PRIVATE hbmex::spmv)

add_executable(analyze_csr src/analyze_csr.cpp)
target_link_libraries(analyze_csr PRIVATE hbmex::spmv)

add_executable(hbm_explore src/hbm_explore.cpp src/hal/hal.cpp src/hal/d4e.cpp)
target_link_libraries(hbm_explore PRIVATE hbmex::read_engine)

add_executable(hbm_explore2 src/hbm_explore2.cpp src/hal/hal.cpp src/hal/d4e.cpp)
target_link_libraries(hbm_explore2 PRIVATE hbmex::read_engine)

add_executable(hbm_explore3 src/hbm_explore3.cpp src/hal/hal.cpp src/hal/d4e.cpp)
target_link_libraries(hbm_explore3 PRIVATE hbmex::read_engine)

add_executable(suite_sparse src/suite_sparse.cpp src/hal/hal.cpp src/hal/d4e.cpp)
target_link_libraries(suite_sparse PRIVATE hbmex::spmv)

add_executable(linalg_test src/linalg_test.cpp)
target_link_libraries(linalg_test PRIVATE hbmex::spmv)

# add_executable(spmv_test src/spmv/Manager.cpp src/spmv/Task.cpp)
# target_link_libraries(spmv_test PRIVATE hbmex::spmv)

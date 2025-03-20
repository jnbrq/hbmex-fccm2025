cmake_minimum_required(VERSION 3.15)

project(hdlscw)

configure_file(
   ${CMAKE_CURRENT_SOURCE_DIR}/hdlscw-config.cmake.in
   ${CMAKE_CURRENT_BINARY_DIR}/hdlscw-config.cmake @ONLY
)

install(
    DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/include"
    DESTINATION "${CMAKE_INSTALL_PREFIX}"
)

install(
    FILES ${CMAKE_CURRENT_BINARY_DIR}/hdlscw-config.cmake
    DESTINATION lib/hdlscw
)

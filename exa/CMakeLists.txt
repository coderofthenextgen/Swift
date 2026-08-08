cmake_minimum_required(VERSION 3.20)
project(exa VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_BUILD_TYPE Release)

include(FetchContent)

FetchContent_Declare(
    glm
    GIT_REPOSITORY https://github.com/g-truc/glm.git
    GIT_TAG 1.0.1
)

FetchContent_MakeAvailable(glm)

find_package(PkgConfig REQUIRED)
pkg_check_modules(SPDLOG REQUIRED spdlog)

add_executable(exa
    src/main.cpp
    src/process.cpp
    src/roblox.cpp
)

target_include_directories(exa PRIVATE
    src
    ${SPDLOG_INCLUDE_DIRS}
)

target_link_directories(exa PRIVATE
    /opt/homebrew/lib
    ${SPDLOG_LIBRARY_DIRS}
)

target_link_libraries(exa PRIVATE
    ${SPDLOG_LIBRARIES}
    glm::glm
)

target_compile_options(exa PRIVATE
    ${SPDLOG_CFLAGS_OTHER}
)

if(APPLE)
    target_link_libraries(exa PRIVATE "-framework Carbon" "-framework CoreGraphics")
endif()

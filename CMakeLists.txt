cmake_minimum_required(VERSION 3.13)
project(MacroDSL)
set(CMAKE_CXX_STANDARD 14) # c++14

find_package(SDL2 REQUIRED)
find_package(GLEW REQUIRED)

file(GLOB_RECURSE SOURCE_FILES src/*.cpp)

add_executable(MacroDSL ${SOURCE_FILES})
target_link_libraries(MacroDSL SDL2::SDL2) # target based style
target_link_libraries(MacroDSL GLEW::GLEW)

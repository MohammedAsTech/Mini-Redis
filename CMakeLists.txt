cmake_minimum_required(VERSION 3.10)

project(MiniRedis)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_executable(MiniRedis
        src/main.cpp
        include/Database.h
        src/Database.cpp
        src/Parser.cpp
        include/Parser.h
        include/Command.h
        src/CommandSons.cpp
)

target_include_directories(MiniRedis PRIVATE
        ${PROJECT_SOURCE_DIR}/include
)

if(MSVC)
    target_compile_options(MiniRedis PRIVATE /W4)
else()
    target_compile_options(MiniRedis PRIVATE -Wall -Wextra -Wpedantic)
endif()
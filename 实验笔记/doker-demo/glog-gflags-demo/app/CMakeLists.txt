cmake_minimum_required(VERSION 3.16)
project(glog_gflags_demo LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 找 glog 和 gflags
# 注意: apt 安装和源码安装（/usr/local）都会提供 cmake 配置文件，所以两种方式都能找到
find_package(glog REQUIRED)
find_package(gflags REQUIRED)

add_executable(demo main.cc)

# glog::glog 是 glog 导出的 CMake target，gflags 是 gflags 导出的 target
# （这样写比手动 -lglog -lgflags 更规范：会自动带上头文件路径和依赖库）
target_link_libraries(demo PRIVATE glog::glog gflags)

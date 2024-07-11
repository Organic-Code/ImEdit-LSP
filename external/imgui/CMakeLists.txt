#
# Copyright (c) 2024 Maxime Pinard
#
# Distributed under the MIT license
# See accompanying file LICENSE or copy at
# https://opensource.org/licenses/MIT
#

# Fix for CMake pre 3.20 behaviour, see CMP0118
set_source_files_properties(${global_generated_files_list} PROPERTIES GENERATED ON)

# Download imgui
FetchContent_Populate(
  imgui
  SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/_deps/imgui-src"
  BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/_deps/imgui-build"
  SUBBUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/_deps/imgui-subbuild"
  GIT_REPOSITORY "https://github.com/ocornut/imgui"
  GIT_TAG "v1.90.8"
  GIT_SHALLOW ON
  GIT_PROGRESS ON
)

find_package(SDL2 REQUIRED)

# Declare imgui
add_library(imgui STATIC)
add_library(imgui::imgui ALIAS imgui)

# Add sources
file(
  GLOB sources
  "${imgui_SOURCE_DIR}/*.cpp"
  "${imgui_SOURCE_DIR}/*.h"
  "${imgui_SOURCE_DIR}/misc/cpp/*.cpp"
  "${imgui_SOURCE_DIR}/misc/cpp/*.h"
  "${CMAKE_CURRENT_LIST_DIR}/imgui-app/*.cpp"
  "${CMAKE_CURRENT_LIST_DIR}/imgui-app/*.h"
)
target_sources(imgui PRIVATE ${sources})

# Add includes
target_include_directories(
  imgui SYSTEM PUBLIC
  "${imgui_SOURCE_DIR}"
  "${imgui_SOURCE_DIR}/misc/cpp/"
  "${imgui_SOURCE_DIR}/backends"
  "${SDL2_INCLUDE_DIRS}"
  "${CMAKE_CURRENT_LIST_DIR}/imgui-app"
  )

target_link_libraries(
  imgui PUBLIC ${SDL2_LIBRARIES}
)

# Add definitions
target_compile_definitions(
  imgui PUBLIC
  IMGUI_DISABLE_OBSOLETE_FUNCTIONS
  IMGUI_DEFINE_MATH_OPERATORS
  IMGUI_APP_SDL2_GL3
)

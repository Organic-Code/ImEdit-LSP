set_source_files_properties(${global_generated_files_list} PROPERTIES GENERATED ON)

# Download imedit
FetchContent_Populate(
        imedit
        SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/_deps/imedit-src"
        BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/_deps/imedit-build"
        SUBBUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/_deps/imedit-subbuild"
        GIT_REPOSITORY "https://github.com/Organic-Code/ImEdit"
        GIT_TAG "master"
        GIT_PROGRESS ON
        GIT_SHALLOW ON
)

# Declare imgui
add_library(imedit STATIC)
add_library(imedit::imedit ALIAS imedit)

# Add sources
file(
        GLOB sources
        "${imedit_SOURCE_DIR}/imedit/*.cpp"
        "${imedit_SOURCE_DIR}/imedit/*.h"
)
target_sources(imedit PRIVATE ${sources})

# Add includes
target_include_directories(
        imedit PUBLIC
        "${imedit_SOURCE_DIR}"
)

# Add dependencies
target_link_libraries(
        imedit PUBLIC
        imgui::imgui
)

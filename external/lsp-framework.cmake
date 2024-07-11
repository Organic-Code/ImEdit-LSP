set_source_files_properties(${global_generated_files_list} PROPERTIES GENERATED ON)

if(TARGET lsp)
    return()
endif()

message(CHECK_START "external: configuring lsp-framework")
list(APPEND CMAKE_MESSAGE_INDENT "  ")

FetchContent_Populate(
        lsp_framework
        SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/_deps/lsp-framework-src"
        BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/_deps/lsp-framework-build"
        SUBBUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/_deps/lsp-framework-subbuild"
        GIT_REPOSITORY "https://github.com/leon-bckl/lsp-framework"
        GIT_TAG "b7ff25ebf547a01ba3a2fdc5ae73432c9a2adbee"
        GIT_PROGRESS ON
        PATCH_COMMAND git apply "${CMAKE_CURRENT_LIST_DIR}/lsp-framework/patch.diff"
        UPDATE_DISCONNECTED ON
)
add_subdirectory(${lsp_framework_SOURCE_DIR})

list(POP_BACK CMAKE_MESSAGE_INDENT)
message(CHECK_PASS "done")

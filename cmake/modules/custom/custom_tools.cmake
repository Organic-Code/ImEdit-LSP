#
# Copyright (c) 2024 Maxime Pinard
#
# Distributed under the MIT license
# See accompanying file LICENSE or copy at
# https://opensource.org/licenses/MIT
#
cmake_minimum_required(VERSION 3.25)

include_guard()

# Dependencies
enable_language(C)
enable_language(CXX)
include(CheckCSourceCompiles)
include(CheckCXXSourceCompiles)
include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)

macro(custom_build_type_init_base_flags_from __build_type __base_build_type)
    string(TOUPPER ${__build_type} __build_type)
    string(TOUPPER ${__base_build_type} __base_build_type)

    set(CMAKE_C_FLAGS_${__build_type}
      "${CMAKE_C_FLAGS_${__base_build_type}}"
      CACHE STRING "Flags used by the C compiler for ${__build_type} build type"
      FORCE
    )
    set(CMAKE_CXX_FLAGS_${__build_type}
      "${CMAKE_CXX_FLAGS_${__base_build_type}}"
      CACHE STRING "Flags used by the CXX compiler for ${__build_type} build type"
      FORCE
    )
    set(CMAKE_EXE_LINKER_FLAGS_${__build_type}
      "${CMAKE_EXE_LINKER_FLAGS_${__base_build_type}}"
      CACHE STRING "Linker flags to be used to create executables for ${__build_type} build type."
      FORCE
    )
    set(CMAKE_SHARED_LINKER_FLAGS_${__build_type}
      "${CMAKE_SHARED_LINKER_FLAGS_${__base_build_type}}"
      CACHE STRING "Linker lags to be used to create shared libraries for ${__build_type} build type."
      FORCE
    )
    mark_as_advanced(
      CMAKE_C_FLAGS_${__build_type}
      CMAKE_CXX_FLAGS_${__build_type}
      CMAKE_EXE_LINKER_FLAGS_${__build_type}
      CMAKE_SHARED_LINKER_FLAGS_${__build_type}
    )
endmacro()

macro(custom_build_type_add_base_flags __build_type)
    string(TOUPPER ${__build_type} __build_type)

    set(NEW_CMAKE_C_FLAGS_${__build_type} "${CMAKE_C_FLAGS_${__build_type}}")
    set(NEW_CMAKE_CXX_FLAGS_${__build_type} "${CMAKE_CXX_FLAGS_${__build_type}}")
    set(NEW_CMAKE_EXE_LINKER_FLAGS_${__build_type} "${CMAKE_EXE_LINKER_FLAGS_${__build_type}}")
    set(NEW_CMAKE_SHARED_LINKER_FLAGS_${__build_type} "${CMAKE_SHARED_LINKER_FLAGS_${__build_type}}")
    foreach(flag ${ARGN})
        set(NEW_CMAKE_C_FLAGS_${__build_type} "${NEW_CMAKE_C_FLAGS_${__build_type}} ${flag}")
        set(NEW_CMAKE_CXX_FLAGS_${__build_type} "${NEW_CMAKE_CXX_FLAGS_${__build_type}} ${flag}")
        set(NEW_CMAKE_EXE_LINKER_FLAGS_${__build_type} "${NEW_CMAKE_EXE_LINKER_FLAGS_${__build_type}} ${flag}")
        set(NEW_CMAKE_SHARED_LINKER_FLAGS_${__build_type} "${NEW_CMAKE_SHARED_LINKER_FLAGS_${__build_type}} ${flag}")
    endforeach()

    set(CMAKE_C_FLAGS_${__build_type}
      "${NEW_CMAKE_C_FLAGS_${__build_type}}"
      CACHE STRING "Flags used by the C compiler for ${__build_type} build type"
      FORCE
    )
    set(CMAKE_CXX_FLAGS_${__build_type}
      "${NEW_CMAKE_CXX_FLAGS_${__build_type}}"
      CACHE STRING "Flags used by the CXX compiler for ${__build_type} build type"
      FORCE
    )
    set(CMAKE_EXE_LINKER_FLAGS_${__build_type}
      "${NEW_CMAKE_EXE_LINKER_FLAGS_${__build_type}}"
      CACHE STRING "Linker flags to be used to create executables for ${__build_type} build type."
      FORCE
    )
    set(CMAKE_SHARED_LINKER_FLAGS_${__build_type}
      "${NEW_CMAKE_SHARED_LINKER_FLAGS_${__build_type}}"
      CACHE STRING "Linker lags to be used to create shared libraries for Asan build type."
      FORCE
    )
endmacro()

function(custom_check_cxx_compiler_flag flag var)
    # get check variable name from flag
    set(check ${flag})
    string(REPLACE "-" "_" check ${check})
    string(REPLACE "=" "_" check ${check})
    string(REPLACE " " "_" check ${check})
    string(REPLACE "," "_" check ${check})
    string(REPLACE "/" "_" check ${check})
    string(REPLACE ":" "_" check ${check})
    string(REPLACE ";" "_" check ${check})
    string(REPLACE "!" "_" check ${check})

    # clang only rejects unknown warning flags if -Werror=unknown-warning-option is also specified.
    if(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
        check_cxx_compiler_flag(-Werror=unknown-warning-option _Werror_unknown_warning_option)
        if(_Werror_unknown_warning_option)
            list(APPEND CMAKE_REQUIRED_FLAGS "-Werror=unknown-warning-option")
        endif()
    endif()

    # check
    check_cxx_compiler_flag(${flag} ${check})

    # set result
    set(${var} ${${check}} PARENT_SCOPE)
endfunction()

function(custom_check_compiler_linker_flag flag var)
    # get check variable name from flag
    set(check ${flag})
    string(REPLACE "-" "_" check ${check})
    string(REPLACE "=" "_" check ${check})
    string(REPLACE " " "_" check ${check})
    string(REPLACE "," "_" check ${check})
    string(REPLACE "/" "_" check ${check})
    string(REPLACE ":" "_" check ${check})
    string(REPLACE ";" "_" check ${check})
    string(REPLACE "!" "_" check ${check})

    # clang only rejects unknown warning flags if -Werror=unknown-warning-option is also specified.
    if(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
        check_cxx_compiler_flag(-Werror=unknown-warning-option _Werror_unknown_warning_option)
        if(_Werror_unknown_warning_option)
            list(APPEND CMAKE_REQUIRED_FLAGS "-Werror=unknown-warning-option")
            list(APPEND CMAKE_REQUIRED_LINK_OPTIONS "-Werror=unknown-warning-option")
        endif()
    endif()

    # set flag for linker
    list(APPEND CMAKE_REQUIRED_FLAGS "${flag}")
    list(APPEND CMAKE_REQUIRED_LINK_OPTIONS "${flag}")

    # check
    check_cxx_compiler_flag(${flag} ${check})

    # set result
    set(${var} ${${check}} PARENT_SCOPE)
endfunction()

cmake_minimum_required(VERSION 3.16)
project(dasProfile C CXX)

if (NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

find_package(DAS REQUIRED)
find_package(Threads REQUIRED)
include(FetchContent)

# Resolve SDK root from <sdk>/lib/cmake/DAS.
get_filename_component(DAS_SDK_ROOT "${DAS_DIR}/../../.." ABSOLUTE)
message(STATUS "daslang SDK root: ${DAS_SDK_ROOT}")

set(PROFILE_MODULE_DIR "${DAS_SDK_ROOT}/modules/dasProfile")
set(PROFILE_EXAMPLES_DIR "${DAS_SDK_ROOT}/examples/profile")

set(LUA_VERSION "5.5.0")
set(LUA_URL "https://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz")
set(LUA_URL_HASH "SHA256=57ccc32bbbd005cab75bcc52444052535af691789dba2b9016d5c50640d68b3d")

FetchContent_Declare(lua_src
    URL "${LUA_URL}"
    URL_HASH "${LUA_URL_HASH}"
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)
FetchContent_GetProperties(lua_src)
if (NOT lua_src_POPULATED)
    FetchContent_Populate(lua_src)
endif()

set(LUA_SRC_DIR "${lua_src_SOURCE_DIR}/src")
set(LUA_CORE_SOURCES
    ${LUA_SRC_DIR}/lapi.c
    ${LUA_SRC_DIR}/lcode.c
    ${LUA_SRC_DIR}/lctype.c
    ${LUA_SRC_DIR}/ldebug.c
    ${LUA_SRC_DIR}/ldo.c
    ${LUA_SRC_DIR}/ldump.c
    ${LUA_SRC_DIR}/lfunc.c
    ${LUA_SRC_DIR}/lgc.c
    ${LUA_SRC_DIR}/llex.c
    ${LUA_SRC_DIR}/lmem.c
    ${LUA_SRC_DIR}/lobject.c
    ${LUA_SRC_DIR}/lopcodes.c
    ${LUA_SRC_DIR}/lparser.c
    ${LUA_SRC_DIR}/lstate.c
    ${LUA_SRC_DIR}/lstring.c
    ${LUA_SRC_DIR}/ltable.c
    ${LUA_SRC_DIR}/ltm.c
    ${LUA_SRC_DIR}/lundump.c
    ${LUA_SRC_DIR}/lvm.c
    ${LUA_SRC_DIR}/lzio.c
)
set(LUA_LIB_SOURCES
    ${LUA_SRC_DIR}/lauxlib.c
    ${LUA_SRC_DIR}/lbaselib.c
    ${LUA_SRC_DIR}/lcorolib.c
    ${LUA_SRC_DIR}/ldblib.c
    ${LUA_SRC_DIR}/liolib.c
    ${LUA_SRC_DIR}/lmathlib.c
    ${LUA_SRC_DIR}/loadlib.c
    ${LUA_SRC_DIR}/loslib.c
    ${LUA_SRC_DIR}/lstrlib.c
    ${LUA_SRC_DIR}/ltablib.c
    ${LUA_SRC_DIR}/lutf8lib.c
    ${LUA_SRC_DIR}/linit.c
)

add_library(profileLua STATIC
    ${LUA_CORE_SOURCES}
    ${LUA_LIB_SOURCES}
)
target_include_directories(profileLua PUBLIC ${LUA_SRC_DIR})
set_target_properties(profileLua PROPERTIES POSITION_INDEPENDENT_CODE ON)

set(PROFILE_LUA_LINK_LIBS "")
if (APPLE)
    target_compile_definitions(profileLua PUBLIC LUA_USE_MACOSX LUA_USE_READLINE)
    list(APPEND PROFILE_LUA_LINK_LIBS readline)
elseif (UNIX)
    target_compile_definitions(profileLua PUBLIC LUA_USE_LINUX)
    list(APPEND PROFILE_LUA_LINK_LIBS dl)
endif()
if (NOT WIN32)
    list(APPEND PROFILE_LUA_LINK_LIBS m)
endif()
if (PROFILE_LUA_LINK_LIBS)
    target_link_libraries(profileLua PUBLIC ${PROFILE_LUA_LINK_LIBS})
endif()

add_executable(profileLuaCli ${LUA_SRC_DIR}/lua.c)
target_include_directories(profileLuaCli PRIVATE ${LUA_SRC_DIR})
target_link_libraries(profileLuaCli PRIVATE profileLua)
set_target_properties(profileLuaCli PROPERTIES OUTPUT_NAME lua)
if (UNIX AND NOT APPLE)
    target_link_options(profileLuaCli PRIVATE "-Wl,-E")
endif()
add_custom_command(TARGET profileLuaCli POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${PROFILE_EXAMPLES_DIR}/tests/lua"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_FILE:profileLuaCli>"
        "${PROFILE_EXAMPLES_DIR}/tests/lua/$<TARGET_FILE_NAME:profileLuaCli>"
    COMMENT "Staging Lua interpreter into SDK examples/profile/tests/lua"
)

# Keep generated module files in one location for all generator configurations.
foreach(cfg DEBUG RELEASE RELWITHDEBINFO MINSIZEREL)
    string(TOUPPER "${cfg}" cfg_upper)
endforeach()

# testProfile dynamic module (loadable via .das_module descriptor).
add_library(testProfile MODULE
    ${CMAKE_CURRENT_SOURCE_DIR}/test_profile.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test_profile.h
)

target_compile_features(testProfile PRIVATE cxx_std_17)
target_compile_definitions(testProfile PRIVATE DAS_MOD_EXPORTS DAS_ENABLE_DLL=1 DAS_ENABLE_DYN_INCLUDES=1)
target_link_libraries(testProfile PRIVATE DAS::libDaScript Threads::Threads)
target_include_directories(testProfile PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

if (NOT MSVC)
    target_compile_options(testProfile PRIVATE -fno-rtti -fwrapv)
endif()

set_target_properties(testProfile PROPERTIES
    PREFIX ""
    SUFFIX ".shared_module"
    LIBRARY_OUTPUT_DIRECTORY "${PROFILE_MODULE_DIR}"
    RUNTIME_OUTPUT_DIRECTORY "${PROFILE_MODULE_DIR}"
)
foreach(cfg DEBUG RELEASE RELWITHDEBINFO MINSIZEREL)
    set_target_properties(testProfile PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY_${cfg} "${PROFILE_MODULE_DIR}"
        RUNTIME_OUTPUT_DIRECTORY_${cfg} "${PROFILE_MODULE_DIR}"
    )
endforeach()

set(PROFILE_DAS_MODULE_FILE "${CMAKE_CURRENT_BINARY_DIR}/.das_module")
file(WRITE "${PROFILE_DAS_MODULE_FILE}" "options gen2\nrequire daslib/fio\n\n[export]\ndef initialize(project_path : string) {\n    if (das_is_dll_build()) {\n        register_dynamic_module(\"{project_path}/testProfile.shared_module\", \"testProfile\")\n        register_dynamic_module(\"{project_path}/testProfileAot.shared_module\", \"testProfileAot\")\n    }\n}\n")

add_custom_target(sync_profile_descriptor ALL
    COMMAND ${CMAKE_COMMAND} -E make_directory "${PROFILE_MODULE_DIR}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${PROFILE_DAS_MODULE_FILE}" "${PROFILE_MODULE_DIR}/.das_module"
    COMMENT "Syncing testProfile module descriptor"
)

add_dependencies(sync_profile_descriptor testProfile)

set(PROFILE_SYNC_EXTRA_TEST_COMMAND "")
if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/extra_test")
    list(APPEND PROFILE_SYNC_EXTRA_TEST_COMMAND
        COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_CURRENT_SOURCE_DIR}/extra_test" "${PROFILE_EXAMPLES_DIR}/extra_test"
    )
endif()

# Mirror benchmark scripts/resources into <sdk>/examples/profile so
# existing get_das_root()+"/examples/profile/..." paths keep working.
add_custom_target(sync_profile_examples ALL
    COMMAND ${CMAKE_COMMAND} -E make_directory "${PROFILE_EXAMPLES_DIR}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/main.das" "${PROFILE_EXAMPLES_DIR}/main.das"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/config.das" "${PROFILE_EXAMPLES_DIR}/config.das"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/bytecode_test.das" "${PROFILE_EXAMPLES_DIR}/bytecode_test.das"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_CURRENT_SOURCE_DIR}/tests" "${PROFILE_EXAMPLES_DIR}/tests"
    ${PROFILE_SYNC_EXTRA_TEST_COMMAND}
    COMMENT "Syncing profile scripts to SDK examples/profile"
)

add_dependencies(sync_profile_examples testProfile sync_profile_descriptor profileLuaCli)

add_custom_target(run_profile
    COMMAND $<TARGET_FILE:DAS::daslang> "${PROFILE_EXAMPLES_DIR}/main.das"
    DEPENDS testProfile sync_profile_examples
    USES_TERMINAL
    COMMENT "Running dasProfile benchmark suite"
)

# ===== AOT companion module for tests/*.das =====
# Generates AOT C++ stubs for every tests/<file>.das via the SDK's aot.exe,
# bundles them into testProfileAot.shared_module. The .das_module descriptor
# loads testProfileAot alongside testProfile so AotListBase static initializers
# fire on dlopen — populating the global AOT registry before any test file
# is compiled with cop.aot=true.

# Drive AOT via `daslang utils/aot/main.das` rather than the standalone aot.exe:
# daslang auto-discovers `<sdk>/modules/*/.das_module`, so `require testProfile`
# resolves. aot.exe (built via standalone_aot) skips that scan.
set(AOT_TOOL_DAS "${DAS_SDK_ROOT}/utils/aot/main.das")
set(AOT_GEN_DIR "${CMAKE_CURRENT_BINARY_DIR}/_aot_generated")
file(MAKE_DIRECTORY "${AOT_GEN_DIR}")

file(GLOB PROFILE_TEST_DAS_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/tests/*.das")

set(AOT_MANIFEST "${CMAKE_CURRENT_BINARY_DIR}/aot_inputs.txt")
set(PROFILE_AOT_GENERATED_SRC "")
set(_aot_manifest_lines "")
foreach(_das ${PROFILE_TEST_DAS_SOURCES})
    get_filename_component(_name "${_das}" NAME_WE)
    set(_out "${AOT_GEN_DIR}/${_name}.aot.cpp")
    list(APPEND PROFILE_AOT_GENERATED_SRC "${_out}")
    list(APPEND _aot_manifest_lines "aot ${_das} ${_out}")
endforeach()
string(REPLACE ";" "\n" _aot_manifest_content "${_aot_manifest_lines}")
file(GENERATE OUTPUT "${AOT_MANIFEST}" CONTENT "${_aot_manifest_content}\n")

# Re-run AOT whenever a test source or the manifest itself changes.
# Depends on testProfile + sync_profile_descriptor so the dlopen of
# testProfile.shared_module succeeds during require resolution.
add_custom_command(
    OUTPUT ${PROFILE_AOT_GENERATED_SRC}
    COMMAND $<TARGET_FILE:DAS::daslang> "${AOT_TOOL_DAS}" --
            -in_file "${AOT_MANIFEST}" -force-overwrite
    DEPENDS testProfile sync_profile_descriptor ${PROFILE_TEST_DAS_SOURCES} "${AOT_MANIFEST}"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    COMMENT "AOT generating C++ stubs for tests/*.das"
    VERBATIM
)

add_library(testProfileAot MODULE
    ${CMAKE_CURRENT_SOURCE_DIR}/test_profile_aot_module.cpp
    ${PROFILE_AOT_GENERATED_SRC}
)

target_compile_features(testProfileAot PRIVATE cxx_std_17)
target_compile_definitions(testProfileAot PRIVATE DAS_MOD_EXPORTS DAS_ENABLE_DLL=1 DAS_ENABLE_DYN_INCLUDES=1)
target_link_libraries(testProfileAot PRIVATE DAS::libDaScriptDyn Threads::Threads)
target_include_directories(testProfileAot PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

# AOT cpps for tests that pull in `daslib/ast` (transitively via `daslib/unroll`)
# include `daScript/builtin/ast_gen.inc` — generated at daslang build time and
# not shipped with the SDK headers. If the user has the daslang source tree
# checked out, point at its include/ as a fallback so those AOT cpps compile.
if (NOT DAS_SOURCE_INCLUDE_DIR)
    set(DAS_SOURCE_INCLUDE_DIR "$ENV{HOME}/Work/daScript/include" CACHE PATH
        "Optional source-tree include path for build-time .inc files missing from SDK")
endif()
if (EXISTS "${DAS_SOURCE_INCLUDE_DIR}/daScript/builtin/ast_gen.inc")
    target_include_directories(testProfileAot PRIVATE "${DAS_SOURCE_INCLUDE_DIR}")
else()
    message(WARNING "Missing ast_gen.inc — AOT for tests requiring daslib/ast (e.g. nbodies) will fail. "
                    "Set -DDAS_SOURCE_INCLUDE_DIR=<path-to-daslang/include> or accept reduced AOT coverage.")
endif()

if (NOT MSVC)
    target_compile_options(testProfileAot PRIVATE -fno-rtti -fwrapv)
endif()

# The AOT-generated .cpp files include "test_profile.h" and reference
# testFibI/testFibR/... defined in testProfile.shared_module. Defer those
# resolutions to dlopen so we don't duplicate test_profile.cpp here.
if (APPLE)
    target_link_options(testProfileAot PRIVATE "-undefined" "dynamic_lookup")
endif()

set_target_properties(testProfileAot PROPERTIES
    PREFIX ""
    SUFFIX ".shared_module"
    LIBRARY_OUTPUT_DIRECTORY "${PROFILE_MODULE_DIR}"
    RUNTIME_OUTPUT_DIRECTORY "${PROFILE_MODULE_DIR}"
)
foreach(cfg DEBUG RELEASE RELWITHDEBINFO MINSIZEREL)
    set_target_properties(testProfileAot PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY_${cfg} "${PROFILE_MODULE_DIR}"
        RUNTIME_OUTPUT_DIRECTORY_${cfg} "${PROFILE_MODULE_DIR}"
    )
endforeach()

add_dependencies(testProfileAot testProfile sync_profile_descriptor)
add_dependencies(sync_profile_examples testProfileAot)

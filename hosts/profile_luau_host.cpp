#include "lua.h"
#include "lualib.h"
#include "luacode.h"
#include "Luau/Compiler.h"
#include "Luau/CodeGen.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iterator>
#include <string>

static int lua_AddOne(lua_State* L) {
    lua_pushinteger(L, luaL_checkinteger(L, 1) + 1);
    return 1;
}

int main(int argc, char** argv) {
    bool codegen = false;
    int optimizationLevel = 1;
    const char* path = nullptr;
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--codegen") == 0) {
            codegen = true;
        } else if (strncmp(argv[i], "-O", 2) == 0) {
            optimizationLevel = atoi(argv[i] + 2);
        } else {
            path = argv[i];
        }
    }
    if (!path) {
        fprintf(stderr, "usage: luau_host [-O<level>] [--codegen] file.luau\n");
        return 1;
    }
    if (codegen && !Luau::CodeGen::isSupported()) {
        fprintf(stderr, "native code generation is not supported on this platform\n");
        return 1;
    }
    std::ifstream in(path, std::ios::binary);
    if (!in) {
        fprintf(stderr, "Error opening %s\n", path);
        return 1;
    }
    std::string source((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());

    lua_State* GL = luaL_newstate();
    if (codegen) {
        Luau::CodeGen::create(GL);
    }
    luaL_openlibs(GL);
    lua_pushcfunction(GL, lua_AddOne, "AddOne");
    lua_setglobal(GL, "AddOne");
    luaL_sandbox(GL);

    lua_State* L = lua_newthread(GL);
    luaL_sandboxthread(L);

    Luau::CompileOptions options = {};
    options.optimizationLevel = optimizationLevel;
    options.debugLevel = 1;
    options.typeInfoLevel = 1;
    std::string bytecode = Luau::compile(source, options);
    std::string chunkname = std::string("@") + path;

    int status = LUA_ERRSYNTAX;
    if (luau_load(L, chunkname.c_str(), bytecode.data(), bytecode.size(), 0) == 0) {
        if (codegen) {
            Luau::CodeGen::CompilationOptions nativeOptions;
            Luau::CodeGen::compile(L, -1, nativeOptions);
        }
        status = lua_resume(L, nullptr, 0);
    }
    if (status != 0) {
        const char* error = lua_tostring(L, -1);
        fprintf(stderr, "%s\n%s\n", error ? error : "error", lua_debugtrace(L));
    }
    lua_close(GL);
    return status == 0 ? 0 : 1;
}

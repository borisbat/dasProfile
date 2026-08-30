#include <lua.h>
#include <lauxlib.h>

#if defined(_WIN32)
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
static double monotonic_seconds(void) {
    LARGE_INTEGER freq, now;
    QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&now);
    return (double)now.QuadPart / (double)freq.QuadPart;
}
#else
#include <time.h>
static double monotonic_seconds(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
}
#endif

static int l_addOne(lua_State *L) {
    lua_pushinteger(L, luaL_checkinteger(L, 1) + 1);
    return 1;
}

static int l_clock(lua_State *L) {
    lua_pushnumber(L, monotonic_seconds());
    return 1;
}

static const luaL_Reg profile_native_funcs[] = {
    {"addOne", l_addOne},
    {"clock", l_clock},
    {NULL, NULL}
};

int luaopen_profile_native(lua_State *L) {
    luaL_newlib(L, profile_native_funcs);
    return 1;
}

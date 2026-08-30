#include "quickjs-libc.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(_WIN32)
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#endif

static JSValue js_AddOne(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    int32_t n = 0;
    (void)this_val;
    (void)argc;
    if (JS_ToInt32(ctx, &n, argv[0]))
        return JS_EXCEPTION;
    return JS_NewInt32(ctx, n + 1);
}

#if defined(_WIN32)
static JSValue js_performance_now(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    LARGE_INTEGER freq, now;
    (void)this_val;
    (void)argc;
    (void)argv;
    QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&now);
    return JS_NewFloat64(ctx, (double)now.QuadPart * 1000.0 / (double)freq.QuadPart);
}
#endif

int main(int argc, char **argv) {
    JSRuntime *rt;
    JSContext *ctx;
    JSValue global, val;
    uint8_t *buf;
    size_t len;
    int ret = 0;

    if (argc < 2) {
        fprintf(stderr, "usage: qjs_host file.js\n");
        return 1;
    }
    rt = JS_NewRuntime();
    js_std_init_handlers(rt);
    ctx = JS_NewContext(rt);
    js_init_module_std(ctx, "std");
    js_init_module_os(ctx, "os");
    JS_SetModuleLoaderFunc2(rt, NULL, js_module_loader, js_module_check_attributes, NULL);
    js_std_add_helpers(ctx, argc - 1, argv + 1);

    global = JS_GetGlobalObject(ctx);
    JS_SetPropertyStr(ctx, global, "AddOne", JS_NewCFunction(ctx, js_AddOne, "AddOne", 1));
#if defined(_WIN32)
    {
        JSValue performance = JS_GetPropertyStr(ctx, global, "performance");
        JS_SetPropertyStr(ctx, performance, "now", JS_NewCFunction(ctx, js_performance_now, "now", 0));
        JS_FreeValue(ctx, performance);
    }
#endif
    JS_FreeValue(ctx, global);

    buf = js_load_file(ctx, &len, argv[1]);
    if (!buf) {
        perror(argv[1]);
        return 1;
    }
    val = JS_Eval(ctx, (const char *)buf, len, argv[1], JS_EVAL_TYPE_GLOBAL);
    js_free(ctx, buf);
    if (JS_IsException(val)) {
        js_std_dump_error(ctx);
        ret = 1;
    }
    JS_FreeValue(ctx, val);
    js_std_loop(ctx);

    js_std_free_handlers(rt);
    JS_FreeContext(ctx);
    JS_FreeRuntime(rt);
    return ret;
}

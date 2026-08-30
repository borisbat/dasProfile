#include <squirrel.h>
#include <sqstdaux.h>
#include <sqstdsystem.h>
#include <sqmodules.h>
#include <sqrat.h>

#include <cstdarg>
#include <cstdio>

static void printfunc(HSQUIRRELVM, const char* s, ...) {
    va_list vl;
    va_start(vl, s);
    vfprintf(stdout, s, vl);
    va_end(vl);
}

static void errorfunc(HSQUIRRELVM, const char* s, ...) {
    va_list vl;
    va_start(vl, s);
    vfprintf(stderr, s, vl);
    va_end(vl);
}

static SQInteger sq_AddOne(HSQUIRRELVM v) {
    SQInteger n = 0;
    sq_getinteger(v, 2, &n);
    sq_pushinteger(v, n + 1);
    return 1;
}

int main(int argc, char** argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: sq_host file.nut\n");
        return 1;
    }
    HSQUIRRELVM v = sq_open(1024);
    sq_setprintfunc(v, printfunc, errorfunc);
    sqstd_seterrorhandlers(v);
    bool ok = false;
    {
        DefSqModulesFileAccess fileAccess;
        SqModules moduleMgr(v, &fileAccess);
        moduleMgr.registerMathLib();
        moduleMgr.registerStringLib();
        moduleMgr.registerSystemLib();
        moduleMgr.registerIoStreamLib();
        moduleMgr.registerIoLib();
        moduleMgr.registerDateTimeLib();
        moduleMgr.registerDebugLib();
        sqstd_register_command_line_args(v, argc, argv);

        sq_pushroottable(v);
        sq_pushstring(v, "AddOne", -1);
        sq_newclosure(v, sq_AddOne, 0);
        sq_setparamscheck(v, 2, ".i");
        sq_newslot(v, -3, SQFalse);
        sq_pop(v, 1);

        Sqrat::Object exports;
        SqModules::string errMsg;
        ok = moduleMgr.requireModule(argv[1], true, SqModules::__main__, exports, errMsg);
        if (!ok) {
            fprintf(stderr, "Error [%s]\n", errMsg.c_str());
        }
    }
    sq_close(v);
    return ok ? 0 : 1;
}

options gen2
options _comment_hygiene = true
// options log=true, print_var_access=true, print_ref=true

require daslib/only_nttp

include ../config.das

[sideeffects, only_nttp]
def fibI(n : int) {
    var last = 1
    var cur = 0
    for (i in range(n)) {
        let tmp = cur
        cur += last
        last = tmp
    }
    return cur
}

[export, no_aot]
def main {
    var f1 = 0
    bench("fibonacci loop") <| $() {
        f1 = fibI(6511134)
    }
    assert(f1 == 1781508648)
    if (is_interp_time()) {
        run_files(TestFile(
            cppFile = "fib_loop.cpp",
            luauFile = "fib_loop.luau",
            luaFile = "fib_loop.lua",
            luaJitFile = "fib_loop.lua",
            nutFile = "fib_loop.nut",
            nutModifiedFile = "fib_loop.nut",
            asFile = "fib_loop.as",
            jsFile = "fib_loop.js",
            monoFile = "fib_loop.cs",
            dotNetFile = "fib_loop.cs",
            zigFile = "fib_loop.zig"))
    }
}

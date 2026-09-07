options gen2
options _comment_hygiene = true
// options log=true, print_var_access=true, print_ref=true

require daslib/only_nttp

include ../config.das

[sideeffects, only_nttp]
def fibR(n) {
    if (n < 2) {
        return n
    }
    return fibR(n - 1) + fibR(n - 2)
}

[export, no_aot]
def main {
    var f3 = 0
    bench("fibonacci recursive") <| $() {
        f3 = fibR(31)
    }
    assert(f3 == 1346269)
    if (is_interp_time()) {
        run_files(TestFile(
            cppFile = "fib_recursive.das",
            luauFile = "fib_recursive.luau",
            luaFile = "fib_recursive.lua",
            luaJitFile = "fib_recursive.lua",
            nutFile = "fib_recursive.nut",
            nutModifiedFile = "fib_recursive.nut",
            asFile = "fib_recursive.as",
            jsFile = "fib_recursive.js",
            monoFile = "fib_recursive.cs",
            dotNetFile = "fib_recursive.cs",
            zigFile = "fib_recursive.zig"))
    }
}



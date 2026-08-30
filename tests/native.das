options gen2
options _comment_hygiene = true
// options log=true, log_nodes=true, print_var_access=true, print_ref=true
// options logCpp=true
require testProfile
require daslib/only_nttp

include ../config.das

[sideeffects, only_nttp]
def testAdds() {
    var count = 0
    for (i in range(10000000)) {
        count = AddOne(count)
    }
    return count
}

[export, no_aot, no_jit]
def main {
    var count = 0
    profile(BENCH_RUNS, "native loop") <| $() {
        count = testAdds()
    }
    assert(10000000 == count)
    if (is_cpp_time()) {
        cpp_label()
        profile(BENCH_RUNS, "native loop") <| $() {
            count = testNativeLoop()
        }
        assert(10000000 == count)
        run_files(TestFile(
            native = true,
            luauFile = "native.luau",
            luaFile = "native.lua",
            luaJitFile = "native.lua",
            nutFile = "native.nut",
            nutModifiedFile = "native.nut",
            jsFile = "native.js",
            monoFile = "native.cs",
            dotNetFile = "native.cs"))
    }
}

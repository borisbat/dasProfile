options gen2
options _comment_hygiene = true
// options log=true, print_var_access=true, print_ref=true

require daslib/only_nttp

include ../config.das

let TOTAL_NUMBERS = 10000
let TOTAL_TIMES = 4

[sideeffects, only_nttp]
def f2i(nums) {
    var summ_q = 0.0
    for (i in 0..TOTAL_TIMES) {
        for (s in nums) {
            summ_q += float(s)
        }
    }
    return summ_q
}

def mk_float(i) {
    return float(i) + float(i) / float(TOTAL_NUMBERS)
}

[export, no_aot]
def main {
    var nums : array<string> <- [for (i in range(TOTAL_NUMBERS)); string(mk_float(i))]
    // reference summ
    var summ = 0.0
    for (j in 0..TOTAL_TIMES) {
        for (i in range(TOTAL_NUMBERS)) {
            summ += mk_float(i)
        }
    }
    var f1 = 0.0
    bench("string2float") <| $() {
        f1 = f2i(nums)
    }
    assert(f1 == summ)
    if (is_interp_time()) {
        run_files(TestFile(
            cppFile = "f2i.cpp",
            luauFile = "f2i.luau",
            luaFile = "f2i.lua",
            luaJitFile = "f2i.lua",
            nutFile = "f2i.nut",
            nutModifiedFile = "f2i.nut",
            // asFile = "f2i.as",
            jsFile = "f2i.js",
            monoFile = "f2i.cs", // this one - interpreter goes bonkers
            dotNetFile = "f2i.cs",
            zigFile = "f2i.zig"))
    }
}


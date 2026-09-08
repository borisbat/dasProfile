options gen2
options _comment_hygiene = true

include ../config.das

options solid_context

let N = 8

[hint(unsafe_range_check)]
def isplaceok(a : int[8]; n, c, cmn, cpn : int) {
    for (i in range(n)) {
        let ai = a[i]
        if (ai == c || ai == cmn + i || ai  == cpn - i) {
            return false
        }
    }
    return true
}

var solutions : int

[hint(unsafe_range_check)]
def addqueen(var a : int[8]; n : int) {
    for [unroll_full] (c in range(N)) {
        if (isplaceok(a, n, c, c - n, c + n)) {
            a[n] = c
            if (n == (N - 1)) {
                solutions++
            } else {
                addqueen(a, n + 1)
            }
        }
    }
}

def test() {
    solutions = 0
    var a : int[8]
    addqueen(a, 0)
    assert(solutions == 92)
}

[export, no_aot]
def main {
    bench("queen") <| $() {
        test()
    }
    if (is_interp_time()) {
        run_files(TestFile(
            cppFile = "queen.cpp",
            luauFile = "queen.luau",
            luaFile = "queen.lua",
            luaJitFile = "queen.lua",
            nutFile = "queen.nut",
            nutModifiedFile = "queen.nut",
            jsFile = "queen.js",
            monoFile = "queen.cs",
            dotNetFile = "queen.cs",
            zigFile = "queen.zig"))
    }
}


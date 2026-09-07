options gen2
options _comment_hygiene = true
// options log=true, log_nodes=true, print_var_access=true, print_ref=true
// options logCpp=true
options persistent_heap
require math

include ../config.das

def makeRandomSequence(var src : array<int>) {
    let n = 100000
    let seed = 1u
    resize(src, n)
    for (i in range(n)) {
        src[i] = int(uint_noise_1D(i, seed))
    }
}

def sort_table(var tab : array<int>) {
    sort(tab, $(a, b) => a > b)
}

def clone(var tab : array<int>; from : array<int>) {
    let len = length(from)
    resize(tab, len)
    if (len != 0) {
        unsafe {
            memcpy(addr(tab[0]), addr(from[0]), len * typeinfo sizeof(type<int>))
        }
    }
}

[export, no_aot]
def main {
    var tab : array<int>
    makeRandomSequence(tab)
    bench("sort") <| $() {
        var inscope tabb := tab
        sort_table(tabb)
    }
    if (is_interp_time()) {
        run_files(TestFile(
            cppFile = "table-sort.das",
            luaFile = "table-sort.lua",
            luaJitFile = "table-sort.lua",
            luauFile = "table-sort.luau",
            jsFile = "table-sort.js",
            monoFile = "table-sort.cs",
            dotNetFile = "table-sort.cs",
            zigFile = "table-sort.zig",
            nutFile = "table-sort.nut",
            nutModifiedFile = "table-sort.nut"
        ))
    }
}

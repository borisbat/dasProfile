options gen2
options _comment_hygiene = true
options rtti
options unsafe_table_lookup = false
require daslib/clargs
require daslib/strings_boost
require peg/peg
require daslib/fio
require daslib/rtti
require daslib/ast
require daslib/debugapi
require daslib/module_path
require llvm/daslib/llvm_boost
require ./log_filter.das

var LOG_TEST_COMPILATION_TIME = false
var ENABLE_AOT = true
var ENABLE_JIT = true
var ENABLE_INTERPRETER = true
var PROFILE_MODULES_REGISTERED = false


var failed = 0
var subprocess_failed = false   //! the --json re-invocation exited non-zero: its own lanes failed

//! the source tree the runner was started in, when it holds the suite; the runner's own file
//! resolves to the binary's directory when it is named by a relative path, which is not the tree
def profile_root {
    let local = getcwd()
    if (fexist("{local}/config.das") && fexist("{local}/main.das") && stat("{local}/tests").is_valid) {
        return local
    }
    return get_this_module_dir()
}

def profile_build_root {
    return path_join(profile_root(), "build")
}

def profile_module_root {
    return path_join(get_das_root(), "modules/dasProfile")
}

def register_profile_dynamic_module(module_name; file_name : string) {
    if (has_module(module_name)) return true

    let local_path = path_join(profile_build_root(), file_name)
    if (fexist(local_path)) {
        register_dynamic_module(local_path, module_name)
        return true
    }

    let staged_path = path_join(profile_module_root(), file_name)
    if (fexist(staged_path)) {
        register_dynamic_module(staged_path, module_name)
        return true
    }

    return false
}

def ensure_profile_modules_registered {
    if (PROFILE_MODULES_REGISTERED || !das_is_dll_build()) return
    let registered_profile = register_profile_dynamic_module("testProfile", "testProfile.shared_module")
    let registered_profile_aot = register_profile_dynamic_module("testProfileAot", "testProfileAot.shared_module")
    PROFILE_MODULES_REGISTERED = registered_profile || registered_profile_aot
}

[CommandLineArgs]
struct ProfileArgs {
    @clarg_doc = "Run /examples/profile/tests/<name>.das and exit"
    test : string

    @clarg_doc = "Generate JSON output"
    json : bool

    @clarg_doc = "Print the startup table (hello world in every language on the boards) and exit"
    startup : bool

    @clarg_doc = "Log compilation time"
    log : bool

    @clarg_doc = "Disable main tests"
    nomain : bool

    @clarg_name = "das-only"
    @clarg_doc = "Profile only the DAS lanes and C++ baseline; skip external runtimes"
    dasonly : bool

    @clarg_short = "?"
    @clarg_name = "show-help"
    @clarg_doc = "Show this help and exit"
    help : bool
}

// JIT lane: child process per test, run twice - mint the DLL cache, then measure warm.
// In the shared harness process a jitted benchmark reads 2-3x slow on asymmetric cores.
def run_jit_child(fileName : string) {
    let exe = get_command_line_arguments()[0]
    var cmd = "{exe} -jit {fileName}"
    if (get_platform_name() == "windows") {
        // daScript#2802: the DLL cache bakes absolute addresses; no cache on windows
        cmd = "{exe} -jit -jit-no-cache {fileName}"
    } else {
        unsafe {
            popen(cmd) $(f) {
                while (!feof(f)) {
                    fgets(f)
                }
            }
        }
    }
    unsafe {
        let exitCode = popen(cmd) $(f) {
            while (!feof(f)) {
                let st = (fgets(f)) |> trim()
                if (st |> starts_with("\"")) {
                    print("{st}\n")
                }
            }
        }
        if (exitCode != 0) {
            print("failed to run {fileName} under -jit: exit {exitCode}\n")
            failed ++
        }
    }
}

def compile_and_run(fileName : string; useAot : bool; useJit : bool) {
    let t0 = ref_time_ticks()
    var inscope access <- make_file_access("")
    ensure_profile_modules_registered()
    using() $(var mg : ModuleGroup) {
        using() $(var cop : CodeOfPolicies) {
            cop.threadlock_context = true
            if (useJit) {
                cop.jit_enabled = jit_enabled()
                if (jit_enabled()) {
                    access |> add_extra_module("just_in_time", "{get_das_root()}/daslib/just_in_time.das")
                }
            } elif (useAot) {
                cop.aot = true
                cop.fail_on_no_aot = true
            } else {
                cop.jit_enabled = false
                cop.aot = false
            }
            compile_file(fileName, access, unsafe(addr(mg)), cop) $(ok, program, issues) {
                if (!ok) {
                    print("failed to compile {fileName}\n{issues}\n")
                    failed ++
                    return
                }
                simulate(program) $(sok; context; serrors) {
                    if (!sok) {
                        print("failed to simulate {fileName}\n{serrors}\n")
                        failed ++
                        return
                    }
                    let dt = get_time_usec(t0)
                    let sec = double(dt) / 1000000.0lf
                    if (LOG_TEST_COMPILATION_TIME) {
                        print("compiled in {sec} sec\n")
                    }
                    try {
                        unsafe(invoke_in_context(context, "main"))
                    } recover {
                        let ctx = unsafe(reinterpret<Context?>(context))
                        print("failed to run {fileName}\n{ctx.exceptionAt}: {ctx.exception}\n")
                        failed ++
                    }
                }
            }
        }
    }
}


// Samples per lane, each its own context (the JIT lane its own process): a per-process
// effect - where the child wakes up, where its DLL lands - is part of the spread.
def samples_per_lane {
    let s = get_env_variable("DASPROFILE_SAMPLES")
    let n = empty(s) ? 0 : to_int(s)
    return n < 1 ? 5 : n
}

def test_single_file(fileName : string) {
    let samples = samples_per_lane()
    if (ENABLE_AOT) {
        for (_ in range(samples)) {
            print("\"DAS AOT\", ")
            compile_and_run(fileName, true, false)
        }
    }
    if (ENABLE_JIT && jit_enabled()) {
        for (_ in range(samples)) {
            print("\"DAS JIT\", ")
            run_jit_child(fileName)
        }
    }
    if (ENABLE_INTERPRETER) {
        for (_ in range(samples)) {
            print("\"DAS INTERPRETER\", ")
            compile_and_run(fileName, false, false)
        }
    }
    if (ENABLE_AOT || ENABLE_JIT || ENABLE_INTERPRETER) {
        print("\n\n")
    }
}

def run_dir(appDir : string) {
    dir(appDir) $(fileName) {
        if ((!fileName |> starts_with("_")) && fileName |> ends_with(".das")) {
            let appfile = "{appDir}/{fileName}"
            test_single_file(appfile)
        }
    }
}

def has_tests(appDir : string) {
    var found = false
    dir(appDir) $(fileName) {
        if ((!fileName |> starts_with("_")) && fileName |> ends_with(".das")) {
            found = true
        }
    }
    return found
}

def tests_dir {
    let local = path_join(profile_root(), "tests")
    return has_tests(local) ? local : "{get_das_root()}/examples/profile/tests"
}

def extract_cpu_value(line : string) {
    let p = line |> find(":")
    if (p == -1) return line |> trim()
    return (line |> slice(p + 1)) |> trim()
}

def first_nonempty_command_line(cmd : string) {
    var result = ""
    unsafe {
        popen(cmd) $(f) {
            while (!feof(f)) {
                let st = (fgets(f)) |> trim()
                if (!empty(st)) {
                    result = st
                    break
                }
            }
        }
    }
    return result
}

// Strip marketing noise from raw CPU brand strings — the "(R)"/"(TM)" marks and
// the " CPU @ 3.60GHz" / " 64-Core Processor" tails — so the README headings and
// the daslang.io cycler row stay readable. Trim once here; consumers see it clean.
def private collapse_spaces(s : string) {
    var out = s
    while (out |> find("  ") != -1) {
        out = out |> replace("  ", " ")
    }
    return out
}

def private strip_cpu_clock_suffix(s : string) : string {
    // Drop "<space>CPU @ X.YGHz" tail (and stray "GHz" units).
    let cpuAt = s |> find(" CPU @ ")
    if (cpuAt != -1) return s |> slice(0, cpuAt)
    return s
}

def private strip_core_count_suffix(s : string) : string {
    // Drop "<space>NN-Core Processor" / "<space>Processor" tail.
    let p = s |> find("-Core Processor")
    if (p != -1) {
        // walk back past the digit run + the leading space
        var cut = p
        peek_data(s) $(arr) {
            var i = p - 1
            while (i >= 0 && int(arr[i]) >= int(0x30) /* '0' */ && int(arr[i]) <= int(0x39) /* '9' */) {
                i --
            }
            if (i >= 0 && int(arr[i]) == int(0x20) /* space */) {
                cut = i
            }
        }
        if (cut != p) return s |> slice(0, cut)
    }
    if (s |> ends_with(" Processor")) return s |> slice(0, length(s) - length(" Processor"))
    return s
}

def private trim_cpu_marketing(raw : string) {
    var out = raw |> trim()
    out = out |> replace("(R)", "")
    out = out |> replace("(TM)", "")
    out = strip_cpu_clock_suffix(out)
    out = strip_core_count_suffix(out)
    out = collapse_spaces(out)
    return out |> trim()
}

def get_cpu_name {
    let platform = get_platform_name()
    if (platform == "darwin") {
        return trim_cpu_marketing(first_nonempty_command_line("sysctl -n machdep.cpu.brand_string 2>/dev/null"))
    } elif (platform == "linux") {
        var cpuName : string
        unsafe {
            popen("lscpu 2>/dev/null") $(f) {
                while (!feof(f)) {
                    let st = fgets(f)
                    if (st |> find("Model name:") != -1) {
                        cpuName = extract_cpu_value(st)
                        break
                    }
                }
            }
        }
        if (!empty(cpuName)) return trim_cpu_marketing(cpuName)
        unsafe {
            popen("cat /proc/cpuinfo 2>/dev/null") $(f) {
                while (!feof(f)) {
                    let st = fgets(f)
                    if (st |> find("model name") != -1) {
                        cpuName = extract_cpu_value(st)
                        break
                    }
                }
            }
        }
        return trim_cpu_marketing(cpuName)
    } elif (platform == "windows") {
        var cpuName : string
        unsafe {
            popen("wmic cpu get name") $(f) {
                var prevName = false
                while (!feof(f)) {
                    let st = fgets(f)
                    if (st |> find("Name") != -1) {
                        prevName = true
                    } elif (prevName) {
                        cpuName = st |> trim()
                        break
                    }
                }
            }
        }
        return trim_cpu_marketing(cpuName)
    }
    return platform
}

def profile_runtime_root {
    let local = profile_root()
    let staged = "{get_das_root()}/examples/profile"
    let local_lua = native_executable("{local}/tests/lua/lua")
    if (fexist(local_lua)) return local
    return staged
}

def native_executable(path_no_ext : string) {
    return get_platform_name() == "windows" ? "{path_no_ext}.exe" : path_no_ext
}

def dotnet_executable {
    let dotnet_path = "/usr/local/share/dotnet/dotnet"
    return get_platform_name() == "windows" ? "dotnet" : (stat(dotnet_path).is_valid ? dotnet_path : "dotnet")
}

def quickjs_executable(js_root : string) {
    return get_platform_name() == "windows" ? "qjs" : native_executable("{js_root}/qjs")
}

def first_nonempty_line(text : string) {
    for (line in text |> split("\n")) {
        let trimmed = line |> trim()
        if (!empty(trimmed)) return trimmed
    }
    return ""
}

def probe_tool_version(args : array<string>) {
    var output = ""
    let exit_code = run_and_capture(args, output)
    if (exit_code != 0 && empty(output)) return ""
    return first_nonempty_line(output)
}

def get_llvm_version {
    var major : uint
    var minor : uint
    var patch : uint
    LLVMGetVersion(unsafe(addr(major)), unsafe(addr(minor)), unsafe(addr(patch)))
    return "{int(major)}.{int(minor)}.{int(patch)}"
}

def read_build_info_value(key : string) {
    let info_path = "{profile_root()}/profile_build_info.txt"
    let local_build_info = path_join(profile_build_root(), "profile_build_info.txt")
    let staged_build_info = "{get_das_root()}/examples/profile/profile_build_info.txt"
    let selected_path = (
        fexist(info_path) ? info_path
        : (fexist(local_build_info) ? local_build_info
        : (fexist(staged_build_info) ? staged_build_info : "")))
    if (empty(selected_path)) return ""
    var result = ""
    unsafe {
        fopen(selected_path, "r") $(f) {
            while (!feof(f)) {
                let st = (fgets(f)) |> trim()
                if (empty(st)) continue
                let sep = st |> find("=")
                if (sep == -1) continue
                if (((st |> slice(0, sep)) |> trim()) == key) {
                    result = (st |> slice(sep + 1)) |> trim()
                    break
                }
            }
        }
    }
    return result
}

struct private VersionInfo {
    cpp_compiler : string
    daslang      : string
    llvm         : string
    lua          : string
    luajit       : string
    luau         : string
    mono         : string
    dotnet       : string
    quickjs      : string
    quirrel      : string
    zig          : string
}

def get_version_info {
    let root = profile_runtime_root()
    let lua_root = "{root}/tests/lua"
    let luau_root = "{root}/tests/luau"
    let js_root = "{root}/tests/js"
    let squirrel_root = "{root}/tests/squirrel"

    var luau_version = probe_tool_version([native_executable("{luau_root}/luau"), "--help"])
    if (empty(luau_version) || (luau_version |> starts_with("Usage:"))) {
        luau_version = read_build_info_value("luau_version")
    }

    var quickjs_version = probe_tool_version([quickjs_executable(js_root), "-h"])
    if (empty(quickjs_version)) {
        quickjs_version = read_build_info_value("quickjs_version")
    }

    return <- VersionInfo(
        cpp_compiler = read_build_info_value("cxx_compiler"),
        daslang = get_das_version(),
        llvm = get_llvm_version(),
        lua = probe_tool_version([native_executable("{lua_root}/lua"), "-v"]),
        luajit = probe_tool_version([native_executable("{lua_root}/luajit"), "-v"]),
        luau = luau_version,
        mono = probe_tool_version(["mono", "--version"]),
        dotnet = probe_tool_version([dotnet_executable(), "--version"]),
        quickjs = quickjs_version,
        quirrel = probe_tool_version([native_executable("{squirrel_root}/sq"), "-v"]),
        zig = probe_tool_version(["zig", "version"]))
}

struct ProfileEntry {
    language : string
    category : string
    time     : double
    count    : int
}

def parse_profile_entry(invocation : string; blk : block<(var res : ProfileEntry; errors : array<ParsingError>) : void>) {
    parse(invocation) {
        var profile_entry : ProfileEntry
        rule(WS, string_ as language, WS, ",", WS, string_ as category, WS, ",", WS, double_ as time, WS, ",", WS, double_ as count) <| $() {
            return <- ProfileEntry(language = language, category = category, time = time, count = int(count))
        }
    }
}

def parse_short_profile_entry(invocation : string; blk : block<(var res : ProfileEntry; errors : array<ParsingError>) : void>) {
    parse(invocation) {
        var profile_entry : ProfileEntry
        rule(WS, string_ as category, WS, ",", WS, double_ as time, WS, ",", WS, double_ as count) <| $() {
            return <- ProfileEntry(category = category, time = time, count = int(count))
        }
    }
}

def make_entries {
    // Forward the parent's daslang invocation (exe + flags like -jit + script path),
    // but drop the `--` separator and script-side args (anything after `--`).
    var parts : array<string>
    var hasJit = false
    var hasNoCache = false
    for (arg in get_command_line_arguments()) {
        if (arg == "--") break
        if (arg == "-jit") {
            hasJit = true
        }
        if (arg == "-jit-no-cache") {
            hasNoCache = true
        }
        let isAbsolute = starts_with(arg, "/") || starts_with(arg, "\\") || (arg |> slice(1, 2)) == ":"
        if (ends_with(arg, ".das") && !starts_with(arg, "-") && !isAbsolute) {
            parts |> push("{getcwd()}/{arg}")
        } else {
            parts |> push(arg)
        }
    }
    // Inject -jit-no-cache under -jit on Windows (workaround for daScript#2802):
    // the per-script JIT DLL cache bakes absolute target addresses into the
    // emitted code, so ASLR rebasing makes a cache-hit DLL crash when loaded back.
    if (hasJit && !hasNoCache && get_platform_name() == "windows") {
        parts |> push("-jit-no-cache")
    }
    if (empty(parts)) {
        print("Error: empty command line\n")
        var empty_result : array<ProfileEntry>
        return <- empty_result
    }
    let cmdLine = parts |> join(" ")
    var entries : array<ProfileEntry>
    var prevLanguage = ""
    unsafe {
        let exitCode = popen(cmdLine) $(f) {
            while (!feof(f)) {
                let st = (fgets(f)) |> trim()
                if (empty(st)) continue
                var parsed = false
                parse_profile_entry(st) $(res, errors) {
                    if (errors |> empty) {
                        prevLanguage = res.language
                        entries |> push(res)
                        parsed = true
                    }
                }
                if (!parsed) {
                    parse_short_profile_entry(st) $(res, errors) {
                        if (errors |> empty) {
                            res.language = prevLanguage
                            entries |> push(res)
                        }
                    }
                }
            }
        }
        if (exitCode != 0) {
            print("subprocess exited with code {exitCode}\n")
            subprocess_failed = true
        }
    }
    return <- entries
}

struct private ResultEntry {
    language : string
    time     : double   //! median of samples
    count    : int      //! reps per sample the budget chose
    samples  : array<double>
}

def private median_of(var values : array<double>) : double {
    sort(values)
    let n = length(values)
    return (n & 1) == 1 ? values[n / 2] : (values[n / 2 - 1] + values[n / 2]) * 0.5lf
}

//! one runtime's hello world: the median wall time of `count` launches after a warm one, and the
//! size of the artifact the lane runs where it built one (a das exe, the C++ and zig exes, a .NET
//! assembly, a Mono exe); a script lane carries no size
struct private StartupEntry {
    language : string
    time     : double
    count    : int
    samples  : array<double>
    size     : int64
}

def private startup_runs {
    let s = get_env_variable("DASPROFILE_STARTUP_RUNS")
    let n = empty(s) ? 0 : to_int(s)
    return n < 1 ? 10 : n
}

def private file_size(path : string) : int64 {
    let st = stat(path)
    return st.is_valid ? int64(st.size) : 0l
}

//! launches argv `count` times and returns the wall time of each, seconds
def private time_launches(argv : array<string>; count : int) : array<double> {
    var samples : array<double>
    samples |> reserve(count)
    for (i in range(count)) {
        var out : string
        let t0 = ref_time_ticks()
        let rc = run_and_capture(argv, out, 0.0)   //! no timeout: a timed wait polls the child on a 100 ms grain
        let dt = get_time_nsec(t0)
        if (rc != 0) {
            print("startup: {argv} exited with {rc}\n{out}\n")
            failed ++
            break
        }
        samples |> push(double(dt) / 1000000000.0lf)
    }
    return <- samples
}

def private startup_entry(language : string; argv : array<string>; count : int; size : int64) : StartupEntry {
    var warm : string
    run_and_capture(argv, warm, 0.0)   //! one launch before the timed ones: a fresh artifact's first start pays the loader's checks
    var samples <- time_launches(argv, count)
    var sorted := samples
    let median = empty(sorted) ? 0.0lf : median_of(sorted)
    return <- StartupEntry(language = language, time = median, count = length(samples), samples <- samples, size = size)
}

//! the startup table: hello world in every language on the boards, each launched the way its
//! lane's kernels are launched, so a row reads as "what a program in this lane pays before its
//! first line"; the das exe, the .NET assembly and the Mono exe are built into a temp directory
def private collect_startup() : table<string; array<StartupEntry>> {   // nolint:STYLE037,STYLE038 - one lane after another, the order is the boards' order
    var result : table<string; array<StartupEntry>>
    let exe = get_command_line_arguments()[0]
    let root = profile_root()
    let runtimeRoot = profile_runtime_root()
    var terr : string
    let tmp = create_temp_directory("dasprofile_startup", terr)
    if (empty(tmp)) {
        print("startup: create_temp_directory: {terr}\n")
        failed ++
        return <- result
    }
    let prevPath = get_env_variable("PATH")
    let sep = get_platform_name() == "windows" ? ";" : ":"
    set_env_variable("PATH", "{dir_name(exe)}{sep}{prevPath}")   //! the das exe links the runtime beside daslang
    let count = startup_runs()
    var lanes : array<StartupEntry>
    let helloDas = path_join(root, "tests/startup/hello.das")
    lanes |> emplace(startup_entry("DAS INTERPRETER", [exe, helloDas], count, 0l))
    var jitArgv <- [exe, "-jit", helloDas]
    if (get_platform_name() == "windows") {
        jitArgv |> push("-jit-no-cache")   //! daScript#2802: no DLL cache on windows, every JIT launch compiles
    }
    lanes |> emplace(startup_entry("DAS JIT", jitArgv, count, 0l))   //! the warm launch inside mints the DLL cache
    let exeOut = path_join(tmp, "hello")
    let exePath = "{exeOut}.exe"   //! daslang -exe appends .exe to -output on every platform
    var bout : string
    let brc = run_and_capture([exe, "-exe", "-output", exeOut, helloDas], bout, 600.0)
    if (brc != 0 || !stat(exePath).is_valid) {
        print("startup: -exe build of hello.das failed ({brc})\n{bout}\n")
        failed ++
    } else {
        lanes |> emplace(startup_entry("DAS EXE", [exePath], count, file_size(exePath)))
    }
    let cppHello = native_executable("{runtimeRoot}/tests/cpp/hello")
    if (stat(cppHello).is_valid) {
        lanes |> emplace(startup_entry("C++", [cppHello], count, file_size(cppHello)))
    }
    let zigOut = path_join(root, "tests/zig/.zig-out")
    let zigHello = native_executable(path_join(zigOut, "hello"))
    if (!stat(zigHello).is_valid) {
        var merr : string
        mkdir_rec(zigOut, merr)
        var zout : string
        run_and_capture(["zig", "build-exe", "-O", "ReleaseFast", "-femit-bin={zigHello}", path_join(root, "tests/zig/hello.zig")], zout, 600.0)
    }
    if (stat(zigHello).is_valid) {
        lanes |> emplace(startup_entry("ZIG", [zigHello], count, file_size(zigHello)))
    }
    let luau = native_executable("{runtimeRoot}/tests/luau/luau")
    let helloLuau = path_join(root, "tests/luau/hello.luau")
    if (stat(luau).is_valid) {
        lanes |> emplace(startup_entry("LUAU --codegen", [luau, "-O2", "--codegen", helloLuau], count, 0l))
        lanes |> emplace(startup_entry("LUAU", [luau, "-O2", helloLuau], count, 0l))
    }
    let lua = native_executable("{runtimeRoot}/tests/lua/lua")
    let helloLua = path_join(root, "tests/lua/hello.lua")
    if (stat(lua).is_valid) {
        lanes |> emplace(startup_entry("LUA", [lua, helloLua], count, 0l))
    }
    let luajit = native_executable("{runtimeRoot}/tests/lua/luajit")
    if (stat(luajit).is_valid) {
        lanes |> emplace(startup_entry("LUAJIT -joff", [luajit, "-O3", "-joff", helloLua], count, 0l))
        lanes |> emplace(startup_entry("LUAJIT", [luajit, "-O3", helloLua], count, 0l))
    }
    let sq = native_executable("{runtimeRoot}/tests/squirrel/sq")
    if (stat(sq).is_valid) {
        lanes |> emplace(startup_entry("QUIRREL", [sq, path_join(root, "tests/squirrel/hello.nut")], count, 0l))
    }
    let qjs = quickjs_executable("{runtimeRoot}/tests/js")
    if (stat(qjs).is_valid || get_platform_name() == "windows") {
        lanes |> emplace(startup_entry("QUICKJS", [qjs, path_join(root, "tests/js/hello.js")], count, 0l))
    }
    let helloCs = path_join(root, "tests/cs/hello.cs")
    let monoExe = path_join(tmp, "hello_mono.exe")
    var mout : string
    if (run_and_capture(["mcs", "-optimize+", helloCs, "-out:{monoExe}"], mout, 600.0) == 0 && stat(monoExe).is_valid) {
        lanes |> emplace(startup_entry("MONO --interpreter", ["mono", "--interpreter", monoExe], count, file_size(monoExe)))
        lanes |> emplace(startup_entry("MONO", ["mono", monoExe], count, file_size(monoExe)))
    } else {
        print("startup: mcs build of hello.cs failed\n{mout}\n")
    }
    let dotnet = dotnet_executable()
    let dotnetOut = path_join(tmp, "dotnet-hello")
    let dotnetDll = path_join(dotnetOut, "bench.dll")
    var dout : string
    let drc = run_and_capture([dotnet, "build", path_join(root, "tests/cs/dasprofile_bench.csproj"), "-c", "Release", "-nologo", "-clp:ErrorsOnly",
        "-p:UseSharedCompilation=false", "-p:BenchmarkSource={helloCs}", "-o", dotnetOut], dout, 600.0)
    if (drc == 0 && stat(dotnetDll).is_valid) {
        lanes |> emplace(startup_entry(".NET", [dotnet, dotnetDll], count, file_size(dotnetDll)))
    } else {
        print("startup: dotnet build of hello.cs failed ({drc})\n{dout}\n")
    }
    result["hello world"] <- lanes
    set_env_variable("PATH", prevPath)
    var rerr : string
    rmdir_rec(tmp, rerr)
    return <- result
}

def private print_startup(startup : table<string; array<StartupEntry>>) {
    for (category, lanes in keys(startup), values(startup)) {
        for (lane in lanes) {
            let size = lane.size > 0l ? " {lane.size} bytes" : ""
            print("\"{lane.language}\", \"{category}\", {lane.time:.6f}, {lane.count}{size}\n")
        }
    }
}

struct private Report {
    cpu       : string
    platform  : string  // "darwin" / "linux" / "windows" — drives per-platform sections in README and the daslang.io cycler
    timestamp : string
    versions  : VersionInfo
    @rename = "Interpreted"
    interpreted : table<string; array<ResultEntry>>
    @rename = "AOT or JIT"
    aot_or_jit  : table<string; array<ResultEntry>>
    @rename = "Startup"
    startup     : table<string; array<StartupEntry>>
}

def private collect(lang_set : table<string>; entries : array<ProfileEntry>) : table<string; array<ResultEntry>> {
    var result : table<string; array<ResultEntry>>
    for (e in entries) {
        if (!(lang_set |> key_exists(e.language))) {
            continue
        }
        var found = false
        for (r in result[e.category]) {
            if (r.language == e.language) {
                r.samples |> push(e.time)
                found = true
                break
            }
        }
        if (!found) {
            result[e.category] |> emplace <| ResultEntry(language = e.language, time = e.time, count = e.count, samples <- [e.time])
        }
    }
    for (rows in values(result)) {
        for (r in rows) {
            r.time = median_of(r.samples)
        }
    }
    return <- result
}

def print_environment_summary(cpu_name : string; version_info : VersionInfo) {
    print("Testing on {cpu_name} at {get_clock()}\n")
    print("  C++ compiler: {version_info.cpp_compiler}\n") if (!empty(version_info.cpp_compiler))
    print("  daslang: {version_info.daslang}\n") if (!empty(version_info.daslang))
    print("  LLVM: {version_info.llvm}\n") if (!empty(version_info.llvm))
    print("  Lua: {version_info.lua}\n") if (!empty(version_info.lua))
    print("  LuaJIT: {version_info.luajit}\n") if (!empty(version_info.luajit))
    print("  Luau: {version_info.luau}\n") if (!empty(version_info.luau))
    print("  Mono: {version_info.mono}\n") if (!empty(version_info.mono))
    print("  .NET: {version_info.dotnet}\n") if (!empty(version_info.dotnet))
    print("  QuickJS: {version_info.quickjs}\n") if (!empty(version_info.quickjs))
    print("  Quirrel: {version_info.quirrel}\n") if (!empty(version_info.quirrel))
    print("  Zig: {version_info.zig}\n") if (!empty(version_info.zig))
    print("\n")
}

//! the das lanes a record must carry on every test, per board; a lane the capture lost (an AOT
//! module that never loaded, a runner started without -jit, a child that died) is a failed
//! capture, never a record with a hole - the site renders whatever arrives and drops the rest
let private DAS_INTERPRETED_LANES <- ["DAS INTERPRETER"]
let private DAS_AOT_JIT_LANES <- ["DAS AOT", "DAS JIT"]
let private DAS_STARTUP_LANES <- ["DAS INTERPRETER", "DAS JIT", "DAS EXE"]

def private has_lane(rows : array<ResultEntry>; lane : string; samples : int) : bool {
    for (r in rows) {
        if (r.language == lane) {
            return length(r.samples) == samples
        }
    }
    return false
}

def private has_startup_lane(rows : array<StartupEntry>; lane : string) : bool {
    for (r in rows) {
        if (r.language == lane && r.count > 0) return true
    }
    return false
}

def private board_holes(board : string; rows_by_test : table<string; array<ResultEntry>>; lanes : array<string>; expected, samples : int) : array<string> {
    var holes : array<string>
    if (length(rows_by_test) != expected) {
        holes |> push("{board}: {length(rows_by_test)} tests on the board, {expected} test files in the suite")
    }
    for (test, rows in keys(rows_by_test), values(rows_by_test)) {
        for (lane in lanes) {
            if (!has_lane(rows, lane, samples)) {
                holes |> push("{board} / {test}: no {lane} cell with {samples} samples")
            }
        }
    }
    return <- holes
}

//! every test file of the suite must sit on both boards with every das lane at the sample
//! count the run was asked for, and the startup row must carry the three das launches;
//! the report names each hole and the capture fails on any
def private missing_das_lanes(report : Report) : array<string> {
    let samples = samples_per_lane()
    var expected = 0
    dir(tests_dir()) $(fileName) {
        if ((!fileName |> starts_with("_")) && fileName |> ends_with(".das")) {
            expected ++
        }
    }
    var holes <- board_holes("Interpreted", report.interpreted, DAS_INTERPRETED_LANES, expected, samples)
    holes |> push_from(board_holes("AOT or JIT", report.aot_or_jit, DAS_AOT_JIT_LANES, expected, samples))
    var startupSeen = false
    for (row, rows in keys(report.startup), values(report.startup)) {
        continue if (row != "hello world")
        startupSeen = true
        for (lane in DAS_STARTUP_LANES) {
            if (!has_startup_lane(rows, lane)) {
                holes |> push("Startup / hello world: no {lane} launches")
            }
        }
    }
    if (!startupSeen) {
        holes |> push("Startup: no hello world row")
    }
    return <- holes
}

//! the capture's exit code: 0 with the record written, 1 with the holes named and no record
def make_json_output(cpu_name : string; version_info : VersionInfo) : int {
    let entries <- make_entries()

    let interpreted_languages : table<string> <- {
        "DAS INTERPRETER",
        "MONO --interpreter",
        "LUAU",
        "LUA",
        "LUAJIT -joff",
        "QUIRREL",
        "QUIRREL typed",
        "QUICKJS"}

    let aot_jit_languages : table<string> <- {
        "DAS AOT",
        "DAS JIT",
        "C++",
        "MONO",
        ".NET",
        "LUAJIT",
        "LUAU --codegen",
        "ZIG"}

    let report = Report(
        cpu = cpu_name,
        platform = get_platform_name(),
        timestamp = "{get_clock()}",
        versions = version_info,
        interpreted <- collect(interpreted_languages, entries),
        aot_or_jit  <- collect(aot_jit_languages, entries),
        startup     <- collect_startup())

    let holes <- missing_das_lanes(report)
    if (!empty(holes) || failed != 0 || subprocess_failed) {
        print("CAPTURE FAILED: no record written\n")
        for (h in holes) {
            print("  {h}\n")
        }
        print("  runner failures: {failed}, subprocess exit non-zero: {subprocess_failed}\n") if (failed != 0 || subprocess_failed)
        return 1
    }
    // Platform-suffixed so captures from several machines coexist; the README
    // generator (update_readme_benchmarks.py) globs them for per-platform
    // sections, and daslang.io's playground cycler fetches them by suffix.
    let output_file = "profile_results_{get_platform_name()}.json"
    unsafe {
        fopen(output_file, "w") $(f) {
            fwrite(f, sprint_json(report, true))
        }
    }
    print("JSON output written to {output_file}\n")
    return 0
}

//! the process exit code: 1 on any lane failure, so a --json parent and a shell both see it
[export]
def main : int {
    install_log_filter()

    var parsed <- parse_args(type<ProfileArgs>)
    if (parsed |> is_err) {
        print("error: {parsed |> unwrap_err}\n\n")
        print_help(get_command_info(type<ProfileArgs>), "profile_tests")
        return 1
    }

    let args <- parsed |> move_unwrap
    if (args.help) {
        print_help(get_command_info(type<ProfileArgs>), "profile_tests")
        return 0
    }

    if (args.dasonly) {
        // Env var (not an argument) so the gate survives the --json re-invocation
        // and reaches the popen'd test contexts, which never see our command line.
        set_env_variable("DASPROFILE_DAS_ONLY", "1")
    }

    let cpuName = get_cpu_name()
    let versionInfo <- get_version_info()
    print_environment_summary(cpuName, versionInfo)
    let singleTest = args.test
    let mainTests = !args.nomain
    print("{get_command_line_arguments()}\n\n")

    if (args.json) {
        return make_json_output(cpuName, versionInfo)
    }
    if (args.startup) {
        print_startup(collect_startup())
        return failed != 0 ? 1 : 0
    }
    if (args.log) {
        LOG_TEST_COMPILATION_TIME = true
    }

    if (!empty(singleTest)) {
        let dir = tests_dir()
        test_single_file("{dir}/{singleTest}.das")
    } elif (mainTests) {
        run_dir(tests_dir())
    }
    if (failed != 0) {
        print("TOTAL FAILURES: {failed}\n")
        return 1
    }
    return 0
}



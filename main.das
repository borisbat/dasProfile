options gen2
options rtti
options unsafe_table_lookup = false
require daslib/clargs
require daslib/strings_boost
require peg/peg
require daslib/fio
require daslib/rtti
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

def profile_root {
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

    @clarg_doc = "Log compilation time"
    log : bool

    @clarg_doc = "Disable main tests"
    nomain : bool

    @clarg_short = "?"
    @clarg_name = "show-help"
    @clarg_doc = "Show this help and exit"
    help : bool
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
                        let ctx = unsafe(reinterpret<Context?> context)
                        print("failed to run {fileName}\n{ctx.exceptionAt}: {ctx.exception}\n")
                        failed ++
                    }
                }
            }
        }
    }
}


def test_single_file(fileName : string) {
    if (ENABLE_AOT) {
        print("\"DAS AOT\", ")
        compile_and_run(fileName, true, false)
    }
    if (ENABLE_JIT && jit_enabled()) {
        print("\"DAS JIT\", ")
        compile_and_run(fileName, false, true)
    }
    if (ENABLE_INTERPRETER) {
        print("\"DAS INTERPRETER\", ")
        compile_and_run(fileName, false, false)
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

def get_cpu_name {
    let platform = get_platform_name()
    if (platform == "darwin") {
        return first_nonempty_command_line("sysctl -n machdep.cpu.brand_string 2>/dev/null")
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
        if (!empty(cpuName)) return cpuName
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
        return cpuName
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
        return cpuName
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
        quirrel = probe_tool_version([native_executable("{squirrel_root}/sq"), "-v"]))
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
    for (arg in get_command_line_arguments()) {
        if (arg == "--") break
        if (ends_with(arg, ".das") && !starts_with(arg, "-") && !starts_with(arg, "/")) {
            parts |> push("{getcwd()}/{arg}")
        } else {
            parts |> push(arg)
        }
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
            print("Warning: subprocess exited with code {exitCode}\n")
        }
    }
    return <- entries
}

struct private ResultEntry {
    language : string
    time     : double
    count    : int
}

struct private Report {
    cpu       : string
    timestamp : string
    versions  : VersionInfo
    @rename = "Interpreted"
    interpreted : table<string; array<ResultEntry>>
    @rename = "AOT or JIT"
    aot_or_jit  : table<string; array<ResultEntry>>
}

def private collect(lang_set : table<string>; entries : array<ProfileEntry>) : table<string; array<ResultEntry>> {
    var result : table<string; array<ResultEntry>>
    for (e in entries) {
        if (lang_set |> key_exists(e.language)) {
            result[e.category] |> emplace(
                ResultEntry(language = e.language, time = e.time, count = e.count))
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
    print("\n")
}

def make_json_output(cpu_name : string; version_info : VersionInfo) {
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
        "LUAU --codegen"}

    let report = Report(
        cpu = cpu_name,
        timestamp = "{get_clock()}",
        versions = version_info,
        interpreted <- collect(interpreted_languages, entries),
        aot_or_jit  <- collect(aot_jit_languages, entries))

    let output_file = "profile_results.json"
    unsafe {
        fopen(output_file, "w") $(f) {
            fwrite(f, sprint_json(report, true))
        }
    }
    print("JSON output written to {output_file}\n")
}

[export]
def main {
    install_log_filter()

    var parsed <- parse_args(type<ProfileArgs>)
    if (parsed |> is_err) {
        print("error: {parsed |> unwrap_err}\n\n")
        print_help(get_command_info(type<ProfileArgs>), "profile_tests")
        return
    }

    let args <- parsed |> move_unwrap
    if (args.help) {
        print_help(get_command_info(type<ProfileArgs>), "profile_tests")
        return
    }

    let cpuName = get_cpu_name()
    let versionInfo <- get_version_info()
    print_environment_summary(cpuName, versionInfo)
    let singleTest = args.test
    let mainTests = !args.nomain
    print("{get_command_line_arguments()}\n\n")

    if (args.json) {
        make_json_output(cpuName, versionInfo)
        return
    }
    if (args.log) {
        LOG_TEST_COMPILATION_TIME = true
    }

    if (!empty(singleTest)) {
        let dir = tests_dir()
        test_single_file("{dir}/{singleTest}.das")
        return
    }
    if (mainTests) {
        run_dir(tests_dir())
    }
    if (failed != 0) {
        print("TOTAL FAILURES: {failed}\n")
    }
}



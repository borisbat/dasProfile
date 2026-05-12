options gen2
options rtti
options unsafe_table_lookup = false
require daslib/clargs
require daslib/strings_boost
require peg/peg
require daslib/fio
require daslib/rtti
require daslib/debugapi
require ./log_filter.das

var LOG_TEST_COMPILATION_TIME = false
var ENABLE_AOT = true
var ENABLE_JIT = true
var ENABLE_INTERPRETER = true


var failed = 0

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
    let local = "{getcwd()}/tests"
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

def make_json_output {
    let entries <- make_entries()

    let interpreted_languages : table<string> <- {
        "DAS INTERPRETER",
        "MONO --interpreter",
        "LUAU",
        "LUA",
        "LUAJIT -joff",
        "SQUIRREL3",
        "QUIRREL",
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
        cpu = get_cpu_name(),
        timestamp = "{get_clock()}",
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
    print("Testing on {cpuName} at {get_clock()}\n")
    let singleTest = args.test
    let mainTests = !args.nomain
    print("{get_command_line_arguments()}\n")

    if (args.json) {
        make_json_output()
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



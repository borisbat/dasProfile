options gen2
require daslib/clargs
require daslib/strings_boost
require peg/peg
require daslib/fio
require daslib/rtti
require daslib/debugapi
require math

options unsafe_table_lookup = false

var HTML_TEST_MODE = false

var LOG_TEST_COMPILATION_TIME = false
var ENABLE_AOT = true
var ENABLE_JIT = true
var ENABLE_INTERPRETER = true


var failed = 0

[CommandLineArgs]
struct ProfileArgs {
    @clarg_doc = "Run /examples/profile/tests/<name>.das and exit"
    test : string

    @clarg_doc = "Generate HTML output"
    html : bool

    @clarg_doc = "Log compilation time"
    log : bool

    @clarg_doc = "Disable main tests"
    nomain : bool

    @clarg_doc = "Reserved legacy flag (currently no-op)"
    hash : bool

    @clarg_short = "?"
    @clarg_name = "show-help"
    @clarg_doc = "Show this help and exit"
    help : bool
}

def compile_and_run(fileName : string; useAot : bool; useJit : bool) {
    var t0 = ref_time_ticks()
    var inscope access <- make_file_access("")
    using <| $(var mg : ModuleGroup) {
        using <| $(var cop : CodeOfPolicies) {
            cop.aot_module = true
            cop.threadlock_context = true
            if (useJit) {
                cop.jit_enabled = jit_enabled()
            } elif (useAot) {
                cop.aot = true
            } else {
                cop.jit_enabled = false
                cop.aot = false
            }
            compile_file(fileName, access, unsafe(addr(mg)), cop) <| $(ok, program, issues) {
                if (!ok) {
                    print("failed to compile {fileName}\n{issues}\n")
                    failed ++
                    return
                }
                simulate(program) <| $(sok; context; serrors) {// no aot for now
                    if (!sok) {
                        print("failed to simulate {fileName}\n{serrors}\n")
                        failed ++
                        return
                    }
                    var dt = get_time_usec(t0)
                    var sec = double(dt) / 1000000.0lf
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
    if (ENABLE_JIT) {
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
    var once = false
    dir(appDir) <| $(fileName) {
        if ((!fileName |> starts_with("_")) && fileName |> ends_with(".das")) {
            if (HTML_TEST_MODE && once) {
                return
            }
            once = true
            let appfile = "{appDir}/{fileName}"
            test_single_file(appfile)
        }
    }
}

def get_cpu_name {
    var cpuName = ""
    unsafe {
        popen("wmic cpu get name") <| $(f) {
            var prevName = false
            while (!feof(f)) {
                let st = fgets(f)
                if (st |> find("Name") != -1) {
                    prevName = true
                } elif (prevName) {
                    cpuName = st |> trim()
                    prevName = false
                }
            }
        }
    }
    return cpuName
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

def make_table(tablename : string; entries : array<ProfileEntry>; languages : table<string>) {
    var categories : table<string; tuple<min : double; max : double>>
    for (e in entries) {
        if (languages |> key_exists(e.language)) {
            if (categories |> key_exists(e.category)) {
                let (tmin, tmax) = categories[e.category]
                categories[e.category] = (min = min(e.time, tmin), max = max(e.time, tmax))
            } else {
                categories[e.category] = (min = e.time, max = e.time)
            }
        }
    }
    var slanguages <- [for (l in keys(languages)); l]
    slanguages |> sort
    var scategories <- [for (c in keys(categories)); c]
    scategories |> sort
    print("\n<h2>{tablename}</h2>\n")
    for (c in scategories) {
        var cattime : table<string; double>
        for (e in entries) {
            if (e.category == c) {
                cattime[e.language] = e.time
            }
        }
        print("<h3>{c}</h3>\n")
        print("<table class=\"chart\" style=\"width: 600px;\">\n")
        for (l in slanguages) {
            if (cattime |> key_exists(l)) {
                let time = cattime[l]
                let (tmin, tmax) = categories[c]
                let minfactor = time / tmin
                let maxfactor = time / tmax
                let ts = fmt(":.4f", float(time))
                let fs = fmt(":.2f", float(minfactor))
                let featured = int(minfactor * 100.0lf) == 100
                let tabclass = !featured ? "chart-bar" : "chart-bar featured"
                let space = maxfactor * 100.0lf// make it no less than 10%?
                print("<tr><th>{l}</th><td><div class=\"{tabclass}\" style=\"width: {space}%;\">{ts}&nbsp ({fs})</div></td></tr>\n")
            }
        }
        print("</table>\n")
    }
}

def make_entries(extra : string = "") {
    let exe = get_command_line_arguments()[0]
    let cmdLine = "{exe}{extra}"
    var entries : array<ProfileEntry>
    var prevLanguage = ""
    unsafe {
        var exitCode = popen(cmdLine) <| $(f) {
            while (!feof(f)) {
                let st = fgets(f)
                var parsed = false
                parse_profile_entry(st) <| $(res, errors) {
                    if (errors |> empty) {
                        prevLanguage = res.language
                        entries |> push(res)
                        parsed = true
                        print("{res}\n")
                    }
                }
                if (!parsed) {
                    parse_short_profile_entry(st) <| $(res, errors) {
                        if (errors |> empty) {
                            res.language = prevLanguage
                            entries |> push(res)
                            parsed = true
                            print("{res}\n")
                        }
                    }
                }
                if (!parsed) {
                    print("{st}")
                }
            }
        }
        if (exitCode != 0) {
            print("Error: {exitCode}\n")
        }
    }
    return <- entries
}

def make_html {
    var entries <- make_entries()
    print("\n<!DOCTYPE html><html>\n")
    print("<body>\n")
    print("<small>Tested on {get_cpu_name()} at {get_clock()}</small><br>\n")
    make_table("Interpreted", entries, {
        "DAS INTERPRETER",
        "MONO --interpreter",
        "LUAU",
        "LUA",
        "LUAJIT -joff",
        "SQUIRREL3",
        "QUIRREL",
        "QUICKJS"})
    make_table("AOT or JIT", entries, {
        "DAS AOT",
        "DAS JIT",
        "C++",
        "MONO",
        ".NET",
        "LUAJIT",
        "LUAU --codegen"})
    print("</body>\n")
    print("</html>\n\n")
}

[export]
def main {
    var parsed <- parse_args(type<ProfileArgs>)
    if (parsed |> is_err) {
        print("error: {parsed |> unwrap_err}\n\n")
        print_help(get_command_info(type<ProfileArgs>), "profile_tests")
        return
    }

    var args <- parsed |> move_unwrap
    if (args.help) {
        print_help(get_command_info(type<ProfileArgs>), "profile_tests")
        return
    }

    var cpuName = get_cpu_name()
    print("Testing on {cpuName} at {get_clock()}\n")
    let singleTest = args.test
    let mainTests = !args.nomain
    print("{get_command_line_arguments()}\n")

    if (args.html) {
        make_html()
        return
    }
    if (args.log) {
        LOG_TEST_COMPILATION_TIME = true
    }

    if (!empty(singleTest)) {
        let appfile = "{get_das_root()}/examples/profile/tests/{singleTest}.das"
        test_single_file(appfile)
        return
    }
    if (mainTests) {
        run_dir("{get_das_root()}/examples/profile/tests")
    }
    if (failed != 0) {
        print("TOTAL FAILURES: {failed}\n")
    }
}



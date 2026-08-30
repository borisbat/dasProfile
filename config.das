options gen2
options _comment_hygiene = true
require daslib/fio
require daslib/strings
require jobque

let TEST_JAVASCRIPT = true
let TEST_LUAU = true
let TEST_LUA = true
let TEST_LUA_JIT = true
let TEST_SQUIRREL = true
let TEST_CSHARP = true
let TEST_MONO_INTERPRETER = true
let BENCH_RUNS = 10

[init, no_jit, no_aot]
def pin_benchmark_thread {
    set_current_thread_affinity(get_current_processor(), true)
}

[no_jit, no_aot]
def native_executable(path_no_ext : string) {
    return get_platform_name() == "windows" ? "{path_no_ext}.exe" : path_no_ext
}

// Normalize forward slashes to backslashes on Windows: popen runs the command
// through cmd.exe, which parses `D:/foo/bar.exe` as a drive change plus a switch
// and fails with "filename, directory name, or volume label syntax is incorrect".
[no_jit, no_aot]
def to_native_path(p : string) {
    return get_platform_name() == "windows" ? (p |> replace("/", "\\")) : p
}

[no_jit, no_aot]
def shell_quote(path : string) {
    return "\"{to_native_path(path)}\""
}

[no_jit, no_aot]
def quickjs_executable(js_root : string) {
    // Windows stages qjs.exe into <runtime_root>/tests/js/ (CMakeLists.txt,
    // stageProfileQuickJs, when MinGW gcc + MSYS2 make are available); fall back
    // to PATH when the staged copy is absent (older builds or BYO installs).
    if (get_platform_name() == "windows") {
        let staged = "{js_root}/qjs.exe"
        return fexist(staged) ? staged : "qjs"
    }
    return native_executable("{js_root}/qjs")
}

[no_jit, no_aot]
def dotnet_executable() : string {
    let dotnetPath = "/usr/local/share/dotnet/dotnet"
    return get_platform_name() == "windows" ? "dotnet" : (stat(dotnetPath).is_valid ? dotnetPath : "dotnet")
}

[no_jit, no_aot]
def csharp_shared_library_name(base_name : string) {
    if (get_platform_name() == "windows") return "{base_name}.dll"
    if (get_platform_name() == "macos" || get_platform_name() == "darwin") return "lib{base_name}.dylib"
    return "lib{base_name}.so"
}

[no_jit, no_aot]
def cpp_label {
    print("\"C++\", ")
}

[no_jit, no_aot]
def is_cpp_time {
    return !jit_enabled() && !aot_enabled()
}

[no_jit, no_aot]
def profile_source_root() : string {
    let local = getcwd()
    if (fexist("{local}/config.das") && fexist("{local}/main.das") && stat("{local}/tests").is_valid) {
        return local
    }
    return "{get_das_root()}/examples/profile"
}

[no_jit, no_aot]
def profile_runtime_root() : string {
    let local = profile_source_root()
    let local_lua = native_executable("{local}/tests/lua/lua")
    if (fexist(local_lua)) {
        return local
    }
    return "{get_das_root()}/examples/profile"
}

struct TestFile {
    luaFile : string // lua
    luaJitFile : string // lua jit
    luauFile : string // luau
    nutFile : string // quirrel
    nutModifiedFile : string // quirrel modified
    asFile  : string // angel script
    jsFile  : string // javascript
    monoFile  : string // csharp mono
    dotNetFile  : string // csharp .net
    native : bool //! the row calls AddOne: luau and quirrel run through the profile hosts
}

let ENCODING = string([ 0xefu8, 0xbbu8, 0xbfu8])

// Windows popen ⇒ cmd /c. cmd strips the first and last quote whenever a command
// both starts and ends with `"`, which leaves our quoted-exe + quoted-script
// commands unbalanced mid-string; wrap once more so that strip is harmless.
[no_jit, no_aot]
def cmd_safe(s : string) {
    return get_platform_name() == "windows" ? "\"{s}\"" : s
}

[no_jit, no_aot]
def run_and_gun(lang, cmdLine : string) {
    unsafe {
        print("\"{lang}\", ")
        let exitCode = popen(cmd_safe(cmdLine)) <| $(f) {
            var skipping = true
            while (!feof(f)) {
                var st = fgets(f)
                if (skipping) {
                    if (st |> starts_with(ENCODING)) {// MONO outputs encoding, skipping
                        st = st |> slice(3)
                        skipping = false
                    }
                }
                print(st)
            }
        }
        if (exitCode != 0) {
            print("Error: {exitCode}\n")
        }
    }
}

[no_jit, no_aot]
def run_and_gun_silent(cmdLine : string) {
    unsafe {
        var problem = ""
        var exitCode = popen(cmd_safe(cmdLine)) <| $(f) {
            while (!feof(f)) {
                let st = fgets(f)
                problem = "{problem}\n{st}"
            }
        }
        if (exitCode != 0) {
            print("Error: {exitCode}\n{problem}\n")
            return
        }
    }
}

[no_jit, no_aot]
def run_files(tf : TestFile) {
    if (!empty(get_env_variable("DASPROFILE_DAS_ONLY"))) return
    let sourceRoot = profile_source_root()
    let runtimeRoot = profile_runtime_root()

    if (TEST_LUAU && !empty(tf.luauFile)) {
        let luauSourceRoot = "{sourceRoot}/tests/luau"
        let luauRuntimeRoot = "{runtimeRoot}/tests/luau"
        let luauRunner = tf.native ? "luau_host" : "luau"
        let luaCompiler = native_executable("{luauRuntimeRoot}/{luauRunner}")
        let luaScript = "{luauSourceRoot}/{tf.luauFile}"
        let cwd = getcwd()
        chdir(luauSourceRoot)
        run_and_gun("LUAU --codegen", "{shell_quote(luaCompiler)} -O2 --codegen {shell_quote(luaScript)}")
        run_and_gun("LUAU", "{shell_quote(luaCompiler)} -O2 {shell_quote(luaScript)}")
        chdir(cwd)
    }
    if (TEST_LUA && !empty(tf.luaFile)) {
        let luaSourceRoot = "{sourceRoot}/tests/lua"
        let luaRuntimeRoot = "{runtimeRoot}/tests/lua"
        let luaCompiler = native_executable("{luaRuntimeRoot}/lua")
        let luaScript = "{luaSourceRoot}/{tf.luaFile}"
        let cwd = getcwd()
        chdir(luaSourceRoot)
        run_and_gun("LUA", "{shell_quote(luaCompiler)} {shell_quote(luaScript)}")
        chdir(cwd)
    }
    if (TEST_LUA_JIT && !empty(tf.luaJitFile)) {
        let luaSourceRoot = "{sourceRoot}/tests/lua"
        let luaRuntimeRoot = "{runtimeRoot}/tests/lua"
        let luaJitCompiler = native_executable("{luaRuntimeRoot}/luajit")
        let luaJitScript = "{luaSourceRoot}/{tf.luaJitFile}"
        let cwd = getcwd()
        chdir(luaSourceRoot)
        run_and_gun("LUAJIT -joff", "{shell_quote(luaJitCompiler)} -O3 -joff {shell_quote(luaJitScript)}")
        run_and_gun("LUAJIT", "{shell_quote(luaJitCompiler)} -O3 {shell_quote(luaJitScript)}")
        chdir(cwd)
    }
    if (TEST_SQUIRREL && !empty(tf.nutModifiedFile)) {
        let squirrelSourceRoot = "{sourceRoot}/tests/squirrel"
        let squirrelRuntimeRoot = "{runtimeRoot}/tests/squirrel"
        let quirrelRunner = tf.native ? "sq_host" : "sq"
        let numModifiedCompiler = native_executable("{squirrelRuntimeRoot}/{quirrelRunner}")
        let quirrelScript = "{squirrelSourceRoot}/{tf.nutModifiedFile}"
        let cwd = getcwd()
        chdir(squirrelSourceRoot)
        run_and_gun("QUIRREL", "{shell_quote(numModifiedCompiler)} {shell_quote(quirrelScript)}")
        chdir(cwd)
    }
    if (TEST_JAVASCRIPT && !empty(tf.jsFile)) {
        let jsSourceRoot = "{sourceRoot}/tests/js"
        let jsRuntimeRoot = "{runtimeRoot}/tests/js"
        let jsHost = native_executable("{jsRuntimeRoot}/qjs_host")
        let jsCompiler = fexist(jsHost) ? jsHost : quickjs_executable(jsRuntimeRoot)
        let jsScript = "{jsSourceRoot}/{tf.jsFile}"
        let cwd = getcwd()
        chdir(jsSourceRoot)
        run_and_gun("QUICKJS", "{shell_quote(jsCompiler)} {shell_quote(jsScript)}")
        chdir(cwd)
    }
    if (TEST_CSHARP && !empty(tf.monoFile)) {
        let monoSourceRoot = "{sourceRoot}/tests/cs"
        let monoRuntimeRoot = "{runtimeRoot}/tests/cs"
        let monoCompiler = "mcs"
        let monoRunner = "mono"
        let monoLibrary = "{monoRuntimeRoot}/{csharp_shared_library_name("addOne")}"
        // DYLD/LD_LIBRARY_PATH are POSIX-only: cmd.exe can't parse the prefix
        // VAR=VAL syntax ("'DYLD_LIBRARY_PATH' is not recognized..."), and
        // Windows Mono finds native deps via PATH anyway.
        let monoLibraryEnv = (get_platform_name() == "windows"
            ? ""
            : "DYLD_LIBRARY_PATH={shell_quote(monoRuntimeRoot)} LD_LIBRARY_PATH={shell_quote(monoRuntimeRoot)} ")
        let monoSource = "{monoSourceRoot}/{tf.monoFile}"
        let cwd = getcwd()
        chdir(monoSourceRoot)
        run_and_gun_silent("{monoCompiler} -optimize+ {monoSource} -out:test.exe")
        if (TEST_MONO_INTERPRETER) {
            let monoInterpreterCommand = stat(monoLibrary).is_valid ? "{monoLibraryEnv}{monoRunner} --interpreter test.exe" : "{monoRunner} --interpreter test.exe"
            run_and_gun("MONO --interpreter", monoInterpreterCommand)
        }
        if (stat(monoLibrary).is_valid) {
            run_and_gun("MONO", "{monoLibraryEnv}{monoRunner} test.exe")
        } else {
            run_and_gun("MONO", "{monoRunner} test.exe")
        }
        chdir(cwd)
    }
    if (TEST_CSHARP && !empty(tf.dotNetFile)) {
        let cscSourceRoot = "{sourceRoot}/tests/cs"
        let cscRuntimeRoot = "{runtimeRoot}/tests/cs"
        let dotnetRunner = dotnet_executable()
        let dotnetProject = "{cscSourceRoot}/dasprofile_bench.csproj"
        let dotnetOutput = "{cscSourceRoot}/.dotnet-bench"
        let dotnetLibrary = "{cscRuntimeRoot}/{csharp_shared_library_name("addOne")}"
        // Same Windows-skip as Mono above: DYLD/LD env vars don't apply.
        let dotnetLibraryEnv = (get_platform_name() == "windows"
            ? ""
            : "DYLD_LIBRARY_PATH={shell_quote(dotnetOutput)}:{shell_quote(cscRuntimeRoot)} LD_LIBRARY_PATH={shell_quote(dotnetOutput)}:{shell_quote(cscRuntimeRoot)} ")
        let dotnetSource = "{cscSourceRoot}/{tf.dotNetFile}"
        let dotnetAssembly = "{dotnetOutput}/bench.dll"
        let cwd = getcwd()
        chdir(cscSourceRoot)
        run_and_gun_silent("{shell_quote(dotnetRunner)} build {shell_quote(dotnetProject)} -c Release -nologo -clp:ErrorsOnly -p:BenchmarkSource={shell_quote(dotnetSource)} -p:NativeLibrary={shell_quote(dotnetLibrary)} -o {shell_quote(dotnetOutput)}")
        set_env_variable("DOTNET_TC_CallCountingDelayMs", "0")
        run_and_gun(".NET", "{dotnetLibraryEnv}{shell_quote(dotnetRunner)} {shell_quote(dotnetAssembly)}")
        chdir(cwd)
    }
}

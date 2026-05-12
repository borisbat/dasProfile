options gen2
require daslib/fio
require daslib/strings

let TEST_JAVASCRIPT = true
let TEST_LUAU = true
let TEST_LUA = true
let TEST_LUA_JIT = true
let TEST_SQUIRREL = true
let TEST_CSHARP = true
let TEST_MONO_INTERPRETER = true
let BENCH_RUNS = 10

[no_jit, no_aot]
def native_executable(path_no_ext : string) {
    return get_platform_name() == "windows" ? "{path_no_ext}.exe" : path_no_ext
}

[no_jit, no_aot]
def shell_quote(path : string) {
    return "\"{path}\""
}

[no_jit, no_aot]
def quickjs_executable(js_root : string) {
    return get_platform_name() == "windows" ? "qjs" : native_executable("{js_root}/qjs")
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
}

let ENCODING = string([ 0xefu8, 0xbbu8, 0xbfu8])

[no_jit, no_aot]
def run_and_gun(lang, cmdLine : string) {
    unsafe {
        print("\"{lang}\", ")
        let exitCode = popen(cmdLine) <| $(f) {
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
        var exitCode = popen(cmdLine) <| $(f) {
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
    let sourceRoot = profile_source_root()
    let runtimeRoot = profile_runtime_root()

    if (TEST_LUAU && !empty(tf.luauFile)) {
        let luauSourceRoot = "{sourceRoot}/tests/luau"
        let luauRuntimeRoot = "{runtimeRoot}/tests/luau"
        let luaCompiler = native_executable("{luauRuntimeRoot}/luau")
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
        let numModifiedCompiler = native_executable("{squirrelRuntimeRoot}/sq")
        let quirrelScript = "{squirrelSourceRoot}/{tf.nutModifiedFile}"
        let cwd = getcwd()
        chdir(squirrelSourceRoot)
        run_and_gun("QUIRREL", "{shell_quote(numModifiedCompiler)} {shell_quote(quirrelScript)}")
        chdir(cwd)
    }
    if (TEST_JAVASCRIPT && !empty(tf.jsFile)) {
        let jsSourceRoot = "{sourceRoot}/tests/js"
        let jsRuntimeRoot = "{runtimeRoot}/tests/js"
        let jsCompiler = quickjs_executable(jsRuntimeRoot)
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
        let monoLibraryEnv = "DYLD_LIBRARY_PATH={shell_quote(monoRuntimeRoot)} LD_LIBRARY_PATH={shell_quote(monoRuntimeRoot)}"
        let monoSource = "{monoSourceRoot}/{tf.monoFile}"
        let cwd = getcwd()
        chdir(monoSourceRoot)
        run_and_gun_silent("{monoCompiler} -optimize+ {monoSource} -out:test.exe")
        if (TEST_MONO_INTERPRETER) {
            let monoInterpreterCommand = stat(monoLibrary).is_valid ? "{monoLibraryEnv} {monoRunner} --interpreter test.exe" : "{monoRunner} --interpreter test.exe"
            run_and_gun("MONO --interpreter", monoInterpreterCommand)
        }
        if (stat(monoLibrary).is_valid) {
            run_and_gun("MONO", "{monoLibraryEnv} {monoRunner} test.exe")
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
        let dotnetLibraryEnv = "DYLD_LIBRARY_PATH={shell_quote(dotnetOutput)}:{shell_quote(cscRuntimeRoot)} LD_LIBRARY_PATH={shell_quote(dotnetOutput)}:{shell_quote(cscRuntimeRoot)}"
        let dotnetSource = "{cscSourceRoot}/{tf.dotNetFile}"
        let dotnetAssembly = "{dotnetOutput}/bench.dll"
        let cwd = getcwd()
        chdir(cscSourceRoot)
        run_and_gun_silent("{shell_quote(dotnetRunner)} build {shell_quote(dotnetProject)} -c Release -nologo -clp:ErrorsOnly -p:BenchmarkSource={shell_quote(dotnetSource)} -p:NativeLibrary={shell_quote(dotnetLibrary)} -o {shell_quote(dotnetOutput)}")
        run_and_gun(".NET", "{dotnetLibraryEnv} {shell_quote(dotnetRunner)} {shell_quote(dotnetAssembly)}")
        chdir(cwd)
    }
}

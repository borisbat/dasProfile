options gen2
require daslib/fio
require daslib/strings

let TEST_JAVASCRIPT = false
let TEST_LUAU = true
let TEST_LUA = true
let TEST_LUA_JIT = true
let TEST_SQUIRREL = true
let TEST_CSHARP = false
let TEST_MONO_INTERPRETER = false

[no_jit, no_aot]
def native_executable(path_no_ext : string) {
    return get_platform_name() == "windows" ? "{path_no_ext}.exe" : path_no_ext
}

[no_jit, no_aot]
def shell_quote(path : string) {
    return "\"{path}\""
}

[no_jit, no_aot]
def cpp_label {
    print("\"C++\", ")
}

[no_jit, no_aot]
def is_cpp_time {
    return !jit_enabled() && !aot_enabled()
}

struct TestFile {
    luaFile : string // lua
    luaJitFile : string // lua jit
    luauFile : string // luau
    nutFile : string // squirrel legacy
    nutModifiedFile : string // quirrel
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
    if (TEST_LUAU && !empty(tf.luauFile)) {
        // lua
        let luaRoot = "{get_das_root()}/examples/profile/tests/luau"
        let luaCompiler = native_executable("{luaRoot}/luau")
        let luaScript = "{luaRoot}/{tf.luauFile}"
        let cwd = getcwd()
        chdir(luaRoot)
        run_and_gun("LUAU --codegen", "{shell_quote(luaCompiler)} -O2 --codegen {shell_quote(luaScript)}")
        run_and_gun("LUAU", "{shell_quote(luaCompiler)} -O2 {shell_quote(luaScript)}")
        chdir(cwd)
    }
    if (TEST_LUA && !empty(tf.luaFile)) {
        // lua
        let luaRoot = "{get_das_root()}/examples/profile/tests/lua"
        let luaCompiler = native_executable("{luaRoot}/lua")
        let luaScript = "{luaRoot}/{tf.luaFile}"
        let cwd = getcwd()
        chdir(luaRoot)
        run_and_gun("LUA", "{shell_quote(luaCompiler)} {shell_quote(luaScript)}")
        chdir(cwd)
    }
    if (TEST_LUA_JIT && !empty(tf.luaJitFile)) {
        // lua
        let luaRoot = "{get_das_root()}/examples/profile/tests/lua"
        let luaJitCompiler = native_executable("{luaRoot}/luajit")
        let luaJitScript = "{luaRoot}/{tf.luaJitFile}"
        let cwd = getcwd()
        chdir(luaRoot)
        run_and_gun("LUAJIT -joff", "{shell_quote(luaJitCompiler)} -O3 -joff {shell_quote(luaJitScript)}")
        run_and_gun("LUAJIT", "{shell_quote(luaJitCompiler)} -O3 {shell_quote(luaJitScript)}")
        chdir(cwd)
    }
    if (TEST_SQUIRREL && !empty(tf.nutModifiedFile)) {
        // quirrel
        let nutRoot = "{get_das_root()}/examples/profile/tests/squirrel"
        let numModifiedCompiler = native_executable("{nutRoot}/sq")
        let quirrelScript = "{nutRoot}/{tf.nutModifiedFile}"
        let cwd = getcwd()
        chdir(nutRoot)
        run_and_gun("QUIRREL", "{shell_quote(numModifiedCompiler)} {shell_quote(quirrelScript)}")
        chdir(cwd)
    }
    if (TEST_JAVASCRIPT && !empty(tf.jsFile)) {
        // javascript
        let jsRoot = "{get_das_root()}/examples/profile/tests/js"
        let jsCompiler = "{jsRoot}/qjs.exe"
        let cwd = getcwd()
        chdir(jsRoot)
        run_and_gun("QUICKJS", "{jsCompiler} {jsRoot}/{tf.jsFile}")
        chdir(cwd)
    }
    if (TEST_CSHARP && !empty(tf.monoFile)) {
        // csharp
        let monoRoot = "{get_das_root()}/examples/profile/tests/cs"
        let monoCompiler = "mcs"
        let monoRunner = "mono"
        let cwd = getcwd()
        chdir(monoRoot)
        run_and_gun_silent("{monoCompiler} -optimize+ {monoRoot}/{tf.monoFile} -out:test.exe")
        if (TEST_MONO_INTERPRETER) {
            run_and_gun("MONO --interpreter", "{monoRunner} --interpreter test.exe")
        }
        run_and_gun("MONO", "{monoRunner} test.exe")
    }
    if (TEST_CSHARP && !empty(tf.dotNetFile)) {
        let cscRoot = "{get_das_root()}/examples/profile/tests/cs"
        let cscCompiler = "csc"
        let cwd = getcwd()
        chdir(cscRoot)
        run_and_gun_silent("{cscCompiler} /optimize+ {cscRoot}/{tf.dotNetFile} /out:testdotnet.exe")
        run_and_gun(".NET", "testdotnet.exe")
        chdir(cwd)
    }
}

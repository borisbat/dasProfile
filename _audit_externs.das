options gen2
require daslib/fio
require daslib/strings_boost
require daslib/rtti
require daslib/ast
require daslib/debugapi
require daslib/module_path

// Compiles every tests/*.das and lists the C++ extern functions each calls
// (call-based builtins, i.e. SimNode_ExtFuncCall territory) — the candidate
// list for the NTTP opt-in audit. Scaffolding for the interop rework arc.

var CURRENT_EXTERNS : table<string; int>

def collect_call(fname : string) {
    CURRENT_EXTERNS[fname]++
}

class ExternCollector : AstVisitor {
    def override visitExprCall(var expr : ExprCall?) : ExpressionPtr {
        if (expr.func != null && expr.func.flags.builtIn && !expr.func.flags.interopFn) {
            let mod = expr.func._module != null ? string(expr.func._module.name) : ""
            collect_call("{mod}::{expr.func.name}")
        }
        return expr
    }
}

def register_test_module(module_name; file_name : string) {
    if (has_module(module_name)) return
    let staged = path_join("{get_das_root()}/modules/dasProfile", file_name)
    if (fexist(staged)) {
        register_dynamic_module(staged, module_name)
    }
}

def audit_file(fileName : string) {
    clear(CURRENT_EXTERNS)
    var inscope access <- make_file_access("")
    using() $(var mg : ModuleGroup) {
        using() $(var cop : CodeOfPolicies) {
            cop.aot = false
            cop.jit_enabled = false
            compile_file(fileName, access, unsafe(addr(mg)), cop) $(ok, program, issues) {
                if (!ok) {
                    print("AUDIT-FAIL {fileName}\n{issues}\n")
                    return
                }
                var astVisitor = new ExternCollector()
                make_visitor(*astVisitor) $(adapter) {
                    visit(program, adapter)
                }
                unsafe {
                    delete astVisitor
                }
            }
        }
    }
    print("=== {base_name(fileName)}\n")
    for (name, count in keys(CURRENT_EXTERNS), values(CURRENT_EXTERNS)) {
        print("  {name} x{count}\n")
    }
}

[export]
def main {
    register_test_module("testProfile", "testProfile.shared_module")
    let dirName = path_join(get_this_module_dir(), "tests")
    var files : array<string>
    dir(dirName) $(fileName) {
        if ((!fileName |> starts_with("_")) && fileName |> ends_with(".das")) {
            files |> push("{dirName}/{fileName}")
        }
    }
    sort(files)
    for (f in files) {
        audit_file(f)
    }
}

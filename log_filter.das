options gen2
require daslib/debugger
require daslib/strings_boost

// DebugAgent that swallows JIT cache-bookkeeping chatter from llvm_macro.das
// ("LLVM JIT: DLL cache miss/hit/...", "LLVM JIT: GC stale artifact ...").
// These fire once per per-script JIT codegen and clutter the benchmark output;
// the first one (for main.das's own codegen) is unavoidable since it runs
// before `def main` gets a chance to install this agent.

class LogFilterAgent : DapiDebugAgent {
    def override onLog(context : Context?; at : LineInfo const?; level : int; text : string#) : bool {
        // Suppress JIT codegen chatter (llvm_macro.das) and the linker's
        // "Library ... made - ok" success line from module_jit.cpp.
        return text |> starts_with("LLVM JIT:") || text |> starts_with("Library ")
    }
}

def private setup_log_filter(ctx : Context) {
    install_new_debug_agent(new LogFilterAgent(), "log_filter")
}

def install_log_filter {
    if (!has_debug_agent_context("log_filter")) {
        fork_debug_agent_context(@@setup_log_filter)
    }
}

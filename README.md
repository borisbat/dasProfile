# dasProfile

Performance benchmarks for [daslang](https://dascript.org/) (formerly daScript).

This repository contains cross-language benchmark suites comparing daslang against Lua, LuaJIT, Luau, JavaScript (QuickJS), Quirrel, C#, and Zig.

## Benchmark Snapshot

Per-platform captures. A cell is the median of five samples, each its own process; a sample runs the kernel as many times as fit a 0.5 s budget and reports the per-run time, and `±` is half the sample range as a share of the median. Lower is better. The fastest result in each row is in bold. `-` means no value for that runtime on that benchmark. The Startup table is hello world in every language on the boards: the wall time of one launch the way that lane's kernels are launched (median of ten after a warm one), and the size of the artifact the lane runs where it built one - a das exe links the daslang runtime library dynamically, a zig exe is static.

### macOS — Apple M1 Max

Platform information:

- Captured from `profile_results_darwin.json` on Fri Sep 11 00:01:04 2026
- Toolchain: AppleClang 21.0.0.21000101, daslang 0.6.4, LLVM 22.1.5
- Runtimes: Lua 5.5.1, LuaJIT 2.1.1787165859, Luau 0.736, Mono 6.14.1 (tarball Tue Apr 29 17:43:02 UTC 2025), .NET 10.0.300, QuickJS 2026-06-04, Quirrel 4.29.1, Zig 0.16.0

#### Interpreted

| Test | DAS interpreter | Luau | Lua | LuaJIT -joff | Quirrel | QuickJS | Mono --interpreter |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | **0.002767s** ±1% | 0.011987s ±0% | 0.067834s ±2% | 0.244176s ±1% | 0.022128s ±3% | 0.023701s ±1% | 0.010776s ±0% |
| dictionary | **0.014233s** ±5% | 0.021984s ±1% | 0.039337s ±3% | 0.020729s ±2% | 0.047297s ±1% | 0.048006s ±1% | 0.318009s ±1% |
| n-bodies | **0.009090s** ±1% | 0.034086s ±0% | 0.043739s ±5% | 0.032946s ±0% | 0.069506s ±1% | 0.079996s ±0% | 0.027390s ±1% |
| spectral norm | **0.026709s** ±1% | 0.035303s ±0% | 0.060447s ±1% | 0.067542s ±0% | 0.131830s ±1% | 0.160332s ±1% | 0.031073s ±0% |
| mandelbrot | **0.002043s** ±0% | 0.035444s ±1% | 0.068047s ±0% | 0.044197s ±1% | 0.006963s ±0% | 0.007705s ±0% | 0.009342s ±1% |
| exp loop | **0.007284s** ±0% | 0.009873s ±1% | 0.021893s ±4% | 0.015402s ±2% | 0.042143s ±0% | 0.038044s ±4% | 0.025181s ±0% |
| string2float | **0.000635s** ±1% | 0.000886s ±2% | 0.002587s ±1% | 0.006335s ±1% | 0.001935s ±6% | 0.004281s ±0% | 0.052367s ±1% |
| particles kinematics | **0.000865s** ±1% | 0.027189s ±0% | 0.045420s ±2% | 0.027237s ±0% | 0.024332s ±0% | 0.033201s ±2% | 0.023660s ±0% |
| queen | **0.000922s** ±1% | 0.002520s ±1% | 0.001410s ±0% | 0.002201s ±1% | 0.002335s ±1% | 0.003179s ±1% | 0.000965s ±1% |
| interop host calls | **0.002487s** ±2% | 0.014286s ±4% | 0.012280s ±1% | 0.035305s ±2% | 0.036778s ±0% | 0.021444s ±0% | 0.098504s ±0% |
| primes loop | **0.021568s** ±1% | 0.065199s ±0% | 0.074455s ±0% | 0.194953s ±1% | 0.142655s ±0% | 0.138851s ±1% | 0.056606s ±0% |
| tree | 0.029241s ±0% | 0.030185s ±1% | 0.035031s ±2% | 0.032071s ±2% | 0.082917s ±0% | 0.059043s ±1% | **0.019358s** ±1% |
| sort | **0.015246s** ±0% | 0.047676s ±1% | 0.057780s ±2% | 0.058509s ±3% | 0.124674s ±0% | 0.043307s ±0% | 0.056757s ±2% |
| fibonacci loop | 0.032327s ±0% | 0.086305s ±1% | 0.046654s ±1% | 0.077376s ±0% | 0.057581s ±0% | 0.148516s ±0% | **0.031468s** ±1% |
| float2string | **0.001217s** ±2% | 0.002143s ±1% | 0.015901s ±1% | 0.005937s ±1% | 0.006143s ±1% | 0.008626s ±0% | 0.072655s ±0% |
| fibonacci recursive | **0.043476s** ±1% | 0.076357s ±1% | 0.067991s ±3% | 0.053430s ±0% | 0.157544s ±1% | 0.083478s ±1% | 0.045036s ±0% |

#### AOT or JIT

| Test | DAS AOT | DAS JIT | C++ | Zig | Luau --codegen | LuaJIT | Mono | .NET |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | - | - | 0.000156s ±1% | **0.000151s** ±1% | 0.010555s ±1% | 0.014558s ±1% | 0.000982s ±1% | 0.000487s ±1% |
| dictionary | - | - | 0.024773s ±1% | 0.007132s ±2% | 0.019037s ±1% | **0.007100s** ±2% | 0.077718s ±0% | 0.043591s ±5% |
| n-bodies | - | - | 0.000919s ±0% | **0.000833s** ±1% | 0.012112s ±0% | 0.003334s ±1% | 0.005319s ±3% | 0.001772s ±1% |
| spectral norm | - | - | 0.001729s ±0% | **0.001695s** ±0% | 0.007039s ±1% | 0.002411s ±1% | 0.006652s ±0% | 0.001769s ±1% |
| mandelbrot | - | - | 0.000364s ±1% | **0.000340s** ±1% | 0.024114s ±1% | 0.008166s ±1% | 0.001868s ±1% | 0.000380s ±0% |
| exp loop | - | - | **0.001681s** ±0% | 0.001702s ±1% | 0.005056s ±0% | 0.002373s ±1% | 0.006781s ±0% | 0.002573s ±0% |
| string2float | - | - | 0.000630s ±0% | **0.000531s** ±1% | 0.000767s ±0% | 0.005713s ±0% | 0.004572s ±1% | 0.001412s ±2% |
| particles kinematics | - | - | 0.000364s ±0% | **0.000284s** ±0% | 0.011502s ±0% | 0.004393s ±1% | 0.004599s ±0% | 0.000311s ±0% |
| queen | - | - | **0.000036s** ±53% | 0.000054s ±4% | 0.000763s ±1% | 0.000184s ±2% | 0.000181s ±0% | 0.000079s ±6% |
| interop host calls | - | - | **0.000931s** ±0% | 0.000936s ±1% | 0.012227s ±0% | 0.000931s ±0% | 0.007758s ±1% | 0.001241s ±0% |
| primes loop | - | - | 0.006837s ±1% | **0.006812s** ±0% | 0.038100s ±0% | 0.016365s ±0% | 0.025356s ±0% | 0.008216s ±1% |
| tree | - | - | 0.002522s ±1% | **0.002512s** ±0% | 0.019258s ±1% | 0.012277s ±255% | 0.003610s ±0% | 0.003961s ±1% |
| sort | - | - | **0.004364s** ±0% | 0.005517s ±1% | 0.043317s ±1% | 0.048935s ±2% | 0.009781s ±2% | 0.005438s ±3% |
| fibonacci loop | - | - | 0.002025s ±1% | **0.002020s** ±0% | 0.022963s ±1% | 0.010104s ±0% | 0.002053s ±1% | 0.005001s ±11% |
| float2string | - | - | 0.005869s ±0% | **0.001011s** ±1% | 0.002047s ±0% | 0.005525s ±0% | 0.016007s ±1% | 0.002583s ±1% |
| fibonacci recursive | - | - | 0.003917s ±1% | 0.004024s ±0% | 0.039070s ±1% | 0.006578s ±1% | 0.005762s ±0% | **0.003747s** ±1% |

#### Startup

| Runtime | hello world | artifact |
| --- | ---: | ---: |
| DAS interpreter | 0.020615s ±1% | - |
| DAS JIT | 0.097444s ±3% | - |
| DAS exe | 0.009566s ±70% | 50 KB |
| C++ | **0.003286s** ±3% | 33 KB |
| Zig | 0.003728s ±1% | 387 KB |
| Luau --codegen | 0.005253s ±3% | - |
| Luau | 0.005151s ±1% | - |
| Lua | 0.003678s ±2% | - |
| LuaJIT -joff | 0.003673s ±2% | - |
| LuaJIT | 0.003668s ±1% | - |
| Quirrel | 0.004328s ±1% | - |
| QuickJS | 0.004008s ±2% | - |
| Mono --interpreter | 0.022820s ±6% | 3 KB |
| Mono | 0.020474s ±6% | 3 KB |
| .NET | 0.027443s ±1% | 4 KB |

### Linux — AMD Ryzen 7 PRO 8700GE w/ Radeon 780M Graphics

Platform information:

- Captured from `profile_results_linux.json` on Fri Sep 11 09:02:54 2026
- Toolchain: Clang 19.1.7, daslang 0.6.4, LLVM 22.1.5
- Runtimes: Lua 5.5.1, LuaJIT 2.1.1787165859, Luau 0.736, Mono 6.8.0.105 (Debian 6.8.0.105+dfsg-3.3+deb12u1 Sat Jun 21 16:33:59 UTC 2025), .NET 10.0.400, QuickJS 2026-06-04, Quirrel 4.29.1, Zig 0.16.0

#### Interpreted

| Test | DAS interpreter | Luau | Lua | LuaJIT -joff | Quirrel | QuickJS | Mono --interpreter |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | **0.002694s** ±0% | 0.012381s ±1% | 0.070090s ±3% | 0.207169s ±2% | 0.018695s ±1% | 0.021311s ±1% | 0.018451s ±1% |
| dictionary | **0.011168s** ±0% | 0.019675s ±2% | 0.039444s ±6% | 0.011631s ±1% | 0.054499s ±1% | 0.046988s ±0% | 0.799419s ±3% |
| n-bodies | **0.009503s** ±1% | 0.028411s ±1% | 0.040852s ±2% | 0.025095s ±1% | 0.071128s ±0% | 0.084113s ±1% | 0.052686s ±5% |
| spectral norm | **0.024435s** ±0% | 0.033565s ±1% | 0.057872s ±2% | 0.037905s ±0% | 0.107619s ±4% | 0.090092s ±3% | 0.046952s ±4% |
| mandelbrot | **0.001776s** ±3% | 0.033205s ±1% | 0.056798s ±1% | 0.036282s ±1% | 0.005767s ±1% | 0.006382s ±4% | 0.013348s ±3% |
| exp loop | **0.006106s** ±5% | 0.011433s ±1% | 0.023723s ±1% | 0.010205s ±2% | 0.036395s ±0% | 0.030925s ±5% | 0.126975s ±8% |
| string2float | **0.000611s** ±0% | 0.001633s ±1% | 0.002774s ±2% | 0.003505s ±0% | 0.002371s ±1% | 0.003562s ±0% | 0.061779s ±0% |
| particles kinematics | **0.000951s** ±1% | 0.026874s ±0% | 0.042235s ±5% | 0.021589s ±1% | 0.025277s ±1% | 0.030316s ±5% | 0.038051s ±4% |
| queen | **0.000769s** ±0% | 0.001887s ±0% | 0.001476s ±3% | 0.000879s ±1% | 0.002006s ±1% | 0.002496s ±2% | 0.001445s ±7% |
| sort | **0.015338s** ±0% | 0.038738s ±0% | 0.045777s ±2% | 0.049946s ±2% | 0.115364s ±3% | 0.037298s ±0% | 0.126220s ±1% |
| interop host calls | **0.003533s** ±0% | 0.012164s ±0% | 0.015301s ±1% | 0.036431s ±2% | 0.038633s ±4% | 0.020783s ±2% | 0.089944s ±1% |
| primes loop | **0.026094s** ±0% | 0.150811s ±0% | 0.058904s ±0% | 0.044123s ±0% | 0.101451s ±1% | 0.112168s ±3% | 0.066150s ±12% |
| tree | 0.023778s ±1% | 0.024430s ±1% | 0.030903s ±6% | **0.018396s** ±4% | 0.069062s ±1% | 0.060946s ±1% | 0.020125s ±3% |
| fibonacci loop | **0.030659s** ±0% | 0.058255s ±1% | 0.053685s ±0% | 0.030686s ±1% | 0.043773s ±0% | 0.136534s ±1% | 0.062425s ±4% |
| float2string | **0.001317s** ±0% | 0.001781s ±0% | 0.013209s ±1% | 0.004587s ±1% | 0.005408s ±6% | 0.007704s ±2% | 0.110353s ±1% |
| fibonacci recursive | 0.047333s ±1% | 0.061662s ±1% | 0.048783s ±1% | **0.034877s** ±0% | 0.117003s ±4% | 0.084681s ±4% | 0.042031s ±2% |

#### AOT or JIT

| Test | DAS AOT | DAS JIT | C++ | Zig | Luau --codegen | LuaJIT | Mono | .NET |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | - | - | **0.000100s** ±0% | 0.000116s ±0% | 0.009691s ±1% | 0.014665s ±3% | 0.000898s ±1% | 0.000362s ±2% |
| dictionary | - | - | 0.028548s ±2% | **0.009435s** ±2% | 0.016360s ±3% | 0.010607s ±2% | 0.080326s ±1% | 0.049738s ±1% |
| n-bodies | - | - | 0.001191s ±0% | **0.000695s** ±0% | 0.011166s ±2% | 0.003422s ±1% | 0.004042s ±1% | 0.001487s ±0% |
| spectral norm | - | - | 0.001800s ±0% | **0.001794s** ±0% | 0.006032s ±0% | 0.001978s ±0% | 0.004636s ±0% | 0.001849s ±1% |
| mandelbrot | - | - | 0.000296s ±0% | **0.000214s** ±0% | 0.026146s ±1% | 0.007504s ±1% | 0.003681s ±0% | 0.000263s ±0% |
| exp loop | - | - | 0.004148s ±0% | **0.002355s** ±0% | 0.004289s ±0% | 0.003533s ±0% | 0.005918s ±0% | 0.003353s ±0% |
| string2float | - | - | 0.001476s ±1% | **0.000452s** ±0% | 0.001483s ±1% | 0.003100s ±0% | 0.004643s ±2% | 0.001238s ±2% |
| particles kinematics | - | - | 0.000253s ±3% | **0.000144s** ±1% | 0.014706s ±0% | 0.009059s ±5% | 0.006606s ±0% | 0.000397s ±0% |
| queen | - | - | 0.000030s ±1% | **0.000027s** ±1% | 0.000591s ±1% | 0.000201s ±0% | 0.000088s ±29% | 0.000033s ±3% |
| sort | - | - | **0.003391s** ±0% | 0.006357s ±0% | 0.035268s ±1% | 0.049393s ±2% | 0.010745s ±3% | 0.004396s ±21% |
| interop host calls | - | - | **0.000977s** ±0% | 0.000981s ±0% | 0.012146s ±0% | 0.001562s ±0% | 0.034331s ±0% | 0.001374s ±0% |
| primes loop | - | - | 0.012712s ±0% | 0.012713s ±0% | 0.026932s ±0% | **0.009733s** ±0% | 0.012776s ±0% | 0.012705s ±0% |
| tree | - | - | 0.002089s ±0% | **0.002029s** ±0% | 0.017921s ±1% | 0.013380s ±1% | 0.003056s ±2% | 0.002792s ±1% |
| fibonacci loop | - | - | **0.001265s** ±0% | 0.001265s ±0% | 0.027375s ±1% | 0.004304s ±0% | 0.003831s ±0% | 0.001313s ±0% |
| float2string | - | - | 0.005574s ±1% | **0.000843s** ±0% | 0.001631s ±1% | 0.004183s ±0% | 0.018557s ±0% | 0.002188s ±4% |
| fibonacci recursive | - | - | **0.002811s** ±0% | 0.002811s ±0% | 0.041293s ±3% | 0.005514s ±0% | 0.005707s ±0% | 0.002982s ±3% |

#### Startup

| Runtime | hello world | artifact |
| --- | ---: | ---: |
| DAS interpreter | 0.027587s ±1% | - |
| DAS JIT | 0.121155s ±1% | - |
| DAS exe | 0.010767s ±5% | 17 KB |
| C++ | 0.002394s ±17% | 16 KB |
| Zig | 0.002442s ±9% | 3.6 MB |
| Luau --codegen | 0.002893s ±15% | - |
| Luau | 0.002784s ±11% | - |
| Lua | 0.002408s ±11% | - |
| LuaJIT -joff | 0.002409s ±5% | - |
| LuaJIT | 0.002377s ±9% | - |
| Quirrel | 0.003025s ±11% | - |
| QuickJS | **0.002353s** ±4% | - |
| Mono --interpreter | 0.013015s ±4% | 3 KB |
| Mono | 0.011019s ±4% | 3 KB |
| .NET | 0.019758s ±2% | 4 KB |

## Capturing a record

One command, from the repository root, on an idle box:

```
cmake --build build --target run_profile
```

It runs `daslang -jit main.das -- --json`: the runner jitted, because the JIT lane is emitted
only then. The runner starts the child that runs the boards with `-ignore-manifest`, because
the AOT lane lives on the dlopen of `testProfileAot.shared_module`, which a descriptor manifest
would defer and nothing requires; the parent itself must stay without that flag, since it times
the startup launches and a parent that loaded every C++ module pays the fork of a fat address
space on each. The runner refuses `--json` without `-jit`, and on any das lane missing from any
test - or any lane failure - names the holes, writes no record and exits 1. `profile_results_<platform>.json`
lands beside this file; `update_readme_benchmarks.py` renders the tables above from it, and
daslang.io fetches it on deploy and fails the deploy on the same holes.

## Related

- [daslang](https://github.com/GaijinEntertainment/daScript) — the daslang compiler and runtime

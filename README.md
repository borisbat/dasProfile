# dasProfile

Performance benchmarks for [daslang](https://dascript.org/) (formerly daScript).

This repository contains cross-language benchmark suites comparing daslang against Lua, LuaJIT, Luau, JavaScript (QuickJS), Quirrel, C#, and Zig.

## Benchmark Snapshot

Per-platform captures. A cell is the median of five samples, each its own process; a sample runs the kernel as many times as fit a 0.5 s budget and reports the per-run time, and `±` is half the sample range as a share of the median. Lower is better. The fastest result in each row is in bold. `-` means no value for that runtime on that benchmark. The Startup table is hello world in every language on the boards: the wall time of one launch the way that lane's kernels are launched (median of ten after a warm one), and the size of the artifact the lane runs where it built one - a das exe links the daslang runtime library dynamically, a zig exe is static.

### macOS — Apple M1 Max

Platform information:

- Captured from `profile_results_darwin.json` on Fri Sep 11 15:51:31 2026
- Toolchain: AppleClang 21.0.0.21000101, daslang 0.6.4, LLVM 22.1.5
- Runtimes: Lua 5.5.1, LuaJIT 2.1.1787165859, Luau 0.736, Mono 6.14.1 (tarball Tue Apr 29 17:43:02 UTC 2025), .NET 10.0.300, QuickJS 2026-06-04, Quirrel 4.29.1, Zig 0.16.0

#### Interpreted

| Test | DAS interpreter | Luau | Lua | LuaJIT -joff | Quirrel | QuickJS | Mono --interpreter |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | **0.002773s** ±0% | 0.011973s ±1% | 0.067695s ±3% | 0.244565s ±1% | 0.022177s ±1% | 0.023779s ±1% | 0.010776s ±1% |
| dictionary | **0.014352s** ±5% | 0.022285s ±5% | 0.039973s ±5% | 0.020847s ±2% | 0.047185s ±1% | 0.048799s ±1% | 0.319260s ±2% |
| n-bodies | **0.009081s** ±0% | 0.034211s ±1% | 0.041771s ±1% | 0.032972s ±1% | 0.069381s ±0% | 0.080146s ±0% | 0.027403s ±1% |
| spectral norm | **0.026675s** ±1% | 0.035791s ±0% | 0.060682s ±0% | 0.067598s ±0% | 0.131664s ±1% | 0.159849s ±0% | 0.031081s ±0% |
| mandelbrot | **0.002097s** ±1% | 0.035572s ±0% | 0.067905s ±1% | 0.044250s ±0% | 0.006974s ±1% | 0.007712s ±1% | 0.009300s ±0% |
| exp loop | **0.007378s** ±0% | 0.009992s ±1% | 0.022165s ±6% | 0.015335s ±1% | 0.042101s ±0% | 0.038114s ±0% | 0.025187s ±1% |
| string2float | **0.000626s** ±1% | 0.000898s ±1% | 0.002531s ±1% | 0.006334s ±1% | 0.001955s ±5% | 0.004294s ±0% | 0.052489s ±1% |
| particles kinematics | **0.000858s** ±1% | 0.027591s ±1% | 0.045221s ±3% | 0.027225s ±1% | 0.024160s ±1% | 0.033033s ±2% | 0.023748s ±1% |
| queen | **0.000921s** ±1% | 0.002518s ±0% | 0.001412s ±0% | 0.002204s ±1% | 0.002328s ±0% | 0.003183s ±1% | 0.000964s ±0% |
| interop host calls | **0.002521s** ±1% | 0.013213s ±4% | 0.012249s ±2% | 0.035669s ±1% | 0.036889s ±1% | 0.021343s ±0% | 0.096818s ±0% |
| primes loop | **0.021872s** ±1% | 0.065235s ±0% | 0.074484s ±1% | 0.194620s ±1% | 0.142496s ±1% | 0.138991s ±0% | 0.056637s ±0% |
| tree | 0.028976s ±1% | 0.029962s ±1% | 0.034404s ±0% | 0.031993s ±1% | 0.082804s ±2% | 0.058944s ±1% | **0.019265s** ±0% |
| sort | **0.015177s** ±1% | 0.047236s ±2% | 0.056972s ±1% | 0.057101s ±3% | 0.125840s ±1% | 0.043518s ±0% | 0.057401s ±2% |
| fibonacci loop | 0.032751s ±1% | 0.086309s ±0% | 0.046461s ±1% | 0.077209s ±0% | 0.057830s ±1% | 0.148599s ±0% | **0.031476s** ±0% |
| float2string | **0.001214s** ±0% | 0.002172s ±1% | 0.015725s ±1% | 0.005929s ±0% | 0.006148s ±0% | 0.008626s ±0% | 0.072456s ±0% |
| fibonacci recursive | **0.043443s** ±1% | 0.076203s ±1% | 0.067993s ±46% | 0.053542s ±1% | 0.157739s ±1% | 0.083522s ±1% | 0.044946s ±1% |

#### AOT or JIT

| Test | DAS AOT | DAS JIT | C++ | Zig | Luau --codegen | LuaJIT | Mono | .NET |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | 0.000173s ±1% | **0.000143s** ±1% | 0.000156s ±1% | 0.000151s ±0% | 0.010573s ±2% | 0.014597s ±1% | 0.000979s ±1% | 0.000486s ±0% |
| dictionary | 0.009353s ±0% | 0.008175s ±3% | 0.024565s ±3% | 0.007092s ±1% | 0.018973s ±1% | **0.007027s** ±3% | 0.077971s ±5% | 0.039616s ±6% |
| n-bodies | 0.001339s ±21% | 0.000871s ±1% | 0.000920s ±1% | **0.000833s** ±0% | 0.012168s ±1% | 0.003328s ±0% | 0.005328s ±3% | 0.001773s ±0% |
| spectral norm | 0.001729s ±1% | **0.000622s** ±1% | 0.001732s ±0% | 0.001696s ±0% | 0.007045s ±1% | 0.002409s ±1% | 0.006654s ±0% | 0.001774s ±1% |
| mandelbrot | 0.000565s ±1% | 0.000463s ±1% | 0.000364s ±0% | **0.000340s** ±0% | 0.024142s ±0% | 0.008240s ±1% | 0.001868s ±0% | 0.000380s ±2% |
| exp loop | 0.003414s ±0% | **0.001652s** ±0% | 0.001712s ±0% | 0.001700s ±0% | 0.005127s ±1% | 0.002396s ±0% | 0.006801s ±1% | 0.002576s ±0% |
| string2float | 0.000547s ±1% | 0.000536s ±0% | 0.000630s ±1% | **0.000531s** ±1% | 0.000779s ±0% | 0.005711s ±1% | 0.004561s ±0% | 0.001415s ±1% |
| particles kinematics | 0.000334s ±0% | 0.000335s ±1% | 0.000364s ±0% | **0.000284s** ±1% | 0.011550s ±0% | 0.004399s ±0% | 0.004604s ±1% | 0.000312s ±1% |
| queen | 0.000096s ±1% | 0.000060s ±6% | **0.000040s** ±33% | 0.000054s ±29% | 0.000761s ±1% | 0.000186s ±1% | 0.000181s ±0% | 0.000076s ±10% |
| interop host calls | 0.001242s ±1% | **0.000641s** ±0% | 0.000932s ±0% | 0.000932s ±0% | 0.012212s ±1% | 0.000936s ±1% | 0.007763s ±0% | 0.001259s ±1% |
| primes loop | **0.006150s** ±0% | 0.006788s ±1% | 0.006813s ±0% | 0.006822s ±0% | 0.038186s ±0% | 0.016364s ±1% | 0.025372s ±0% | 0.008250s ±1% |
| tree | 0.002624s ±0% | **0.002467s** ±1% | 0.002520s ±1% | 0.002510s ±0% | 0.019193s ±1% | 0.012238s ±1% | 0.003610s ±1% | 0.003959s ±1% |
| sort | **0.002507s** ±0% | 0.004299s ±1% | 0.004372s ±0% | 0.005523s ±1% | 0.043398s ±1% | 0.048395s ±0% | 0.009810s ±1% | 0.005503s ±1% |
| fibonacci loop | 0.002022s ±1% | 0.002022s ±1% | 0.002022s ±0% | **0.002021s** ±0% | 0.022815s ±0% | 0.010110s ±1% | 0.002022s ±0% | 0.005005s ±1% |
| float2string | **0.000996s** ±1% | 0.001081s ±1% | 0.005865s ±0% | 0.001013s ±1% | 0.002042s ±0% | 0.005527s ±0% | 0.016021s ±1% | 0.002581s ±0% |
| fibonacci recursive | 0.003920s ±1% | 0.003923s ±1% | 0.003923s ±1% | 0.004027s ±1% | 0.039129s ±2% | 0.006584s ±0% | 0.005770s ±0% | **0.003538s** ±2% |

#### Startup

| Runtime | hello world | artifact |
| --- | ---: | ---: |
| DAS interpreter | 0.020257s ±1% | - |
| DAS JIT | 0.096991s ±0% | - |
| DAS exe | 0.009393s ±38% | 50 KB |
| C++ | **0.003208s** ±2% | 33 KB |
| Zig | 0.003668s ±2% | 387 KB |
| Luau --codegen | 0.005158s ±3% | - |
| Luau | 0.005099s ±2% | - |
| Lua | 0.003570s ±3% | - |
| LuaJIT -joff | 0.003566s ±2% | - |
| LuaJIT | 0.003596s ±1% | - |
| Quirrel | 0.004211s ±1% | - |
| QuickJS | 0.003941s ±3% | - |
| Mono --interpreter | 0.024229s ±1% | 3 KB |
| Mono | 0.020345s ±2% | 3 KB |
| .NET | 0.027569s ±5% | 4 KB |

### Linux — AMD Ryzen 7 PRO 8700GE w/ Radeon 780M Graphics

Platform information:

- Captured from `profile_results_linux.json` on Sat Sep 12 00:58:43 2026
- Toolchain: Clang 19.1.7, daslang 0.6.4, LLVM 22.1.5
- Runtimes: Lua 5.5.1, LuaJIT 2.1.1787165859, Luau 0.736, Mono 6.8.0.105 (Debian 6.8.0.105+dfsg-3.3+deb12u1 Sat Jun 21 16:33:59 UTC 2025), .NET 10.0.400, QuickJS 2026-06-04, Quirrel 4.29.1, Zig -

#### Interpreted

| Test | DAS interpreter | Luau | Lua | LuaJIT -joff | Quirrel | QuickJS | Mono --interpreter |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | **0.002704s** ±2% | 0.012424s ±3% | 0.069188s ±1% | 0.206859s ±2% | 0.018743s ±1% | 0.021329s ±2% | 0.018337s ±1% |
| dictionary | **0.011159s** ±1% | 0.020002s ±2% | 0.039274s ±1% | 0.011788s ±1% | 0.053221s ±1% | 0.047051s ±1% | 0.792170s ±1% |
| n-bodies | **0.009527s** ±0% | 0.028510s ±1% | 0.041960s ±2% | 0.025262s ±1% | 0.071521s ±1% | 0.082783s ±2% | 0.052414s ±3% |
| spectral norm | **0.024514s** ±0% | 0.033332s ±1% | 0.057586s ±1% | 0.037788s ±0% | 0.107332s ±6% | 0.090256s ±1% | 0.047591s ±4% |
| mandelbrot | **0.001781s** ±4% | 0.033381s ±8% | 0.056912s ±2% | 0.036618s ±1% | 0.005871s ±1% | 0.006367s ±3% | 0.013139s ±4% |
| exp loop | **0.006294s** ±6% | 0.011443s ±1% | 0.023740s ±1% | 0.010214s ±7% | 0.036820s ±2% | 0.030853s ±2% | 0.135355s ±12% |
| string2float | **0.000616s** ±0% | 0.001647s ±0% | 0.002786s ±2% | 0.003505s ±0% | 0.002354s ±1% | 0.003579s ±0% | 0.062070s ±1% |
| particles kinematics | **0.000933s** ±0% | 0.026668s ±1% | 0.039918s ±5% | 0.021564s ±0% | 0.025223s ±1% | 0.029946s ±1% | 0.037622s ±1% |
| queen | **0.000771s** ±1% | 0.001881s ±0% | 0.001507s ±3% | 0.000895s ±1% | 0.002002s ±1% | 0.002485s ±4% | 0.001421s ±5% |
| sort | **0.015372s** ±0% | 0.038777s ±1% | 0.045633s ±33% | 0.050480s ±3% | 0.113881s ±1% | 0.037440s ±1% | 0.127687s ±3% |
| interop host calls | **0.003547s** ±0% | 0.012173s ±0% | 0.015356s ±0% | 0.036156s ±2% | 0.038426s ±2% | 0.020742s ±1% | 0.090852s ±1% |
| primes loop | **0.026195s** ±0% | 0.150614s ±1% | 0.059168s ±0% | 0.044288s ±0% | 0.101850s ±5% | 0.106201s ±6% | 0.066330s ±10% |
| tree | 0.023586s ±1% | 0.024211s ±1% | 0.031357s ±4% | **0.018375s** ±0% | 0.069201s ±0% | 0.061785s ±1% | 0.020166s ±2% |
| fibonacci loop | **0.030752s** ±0% | 0.057874s ±1% | 0.053684s ±0% | 0.030820s ±0% | 0.043865s ±1% | 0.136592s ±0% | 0.062585s ±1% |
| float2string | **0.001221s** ±0% | 0.001774s ±1% | 0.013372s ±1% | 0.004574s ±0% | 0.005484s ±3% | 0.007704s ±0% | 0.109816s ±3% |
| fibonacci recursive | 0.047506s ±2% | 0.061880s ±2% | 0.048743s ±1% | **0.034779s** ±0% | 0.115210s ±0% | 0.084387s ±1% | 0.042032s ±0% |

#### AOT or JIT

| Test | DAS AOT | DAS JIT | C++ | Zig | Luau --codegen | LuaJIT | Mono | .NET |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | 0.000102s ±0% | **0.000097s** ±0% | 0.000100s ±0% | 0.000116s ±0% | 0.009755s ±10% | 0.014642s ±1% | 0.000894s ±0% | 0.000364s ±1% |
| dictionary | **0.006644s** ±1% | 0.007877s ±1% | 0.028487s ±2% | 0.009586s ±2% | 0.016361s ±3% | 0.010576s ±1% | 0.079748s ±1% | 0.049124s ±2% |
| n-bodies | 0.001220s ±0% | 0.000913s ±0% | 0.001200s ±0% | **0.000698s** ±0% | 0.011179s ±1% | 0.003381s ±1% | 0.004047s ±0% | 0.001489s ±0% |
| spectral norm | 0.001850s ±1% | 0.001923s ±1% | 0.001805s ±0% | **0.001796s** ±0% | 0.006016s ±1% | 0.001979s ±0% | 0.004657s ±0% | 0.001852s ±1% |
| mandelbrot | 0.000455s ±0% | 0.000260s ±0% | 0.000297s ±0% | **0.000215s** ±0% | 0.026163s ±1% | 0.007483s ±0% | 0.003688s ±0% | 0.000264s ±0% |
| exp loop | 0.002364s ±4% | 0.002355s ±0% | 0.004150s ±0% | **0.002354s** ±0% | 0.004295s ±0% | 0.003547s ±0% | 0.005916s ±0% | 0.003360s ±0% |
| string2float | **0.000435s** ±0% | 0.000442s ±1% | 0.001484s ±1% | 0.000452s ±0% | 0.001487s ±1% | 0.003102s ±0% | 0.004767s ±4% | 0.001242s ±1% |
| particles kinematics | 0.000257s ±1% | 0.000230s ±0% | 0.000252s ±2% | **0.000143s** ±1% | 0.014565s ±0% | 0.008881s ±5% | 0.006609s ±1% | 0.000395s ±0% |
| queen | 0.000054s ±13% | 0.000027s ±1% | 0.000030s ±0% | **0.000027s** ±1% | 0.000590s ±0% | 0.000201s ±0% | 0.000099s ±17% | 0.000033s ±3% |
| sort | **0.001855s** ±0% | 0.004464s ±0% | 0.003403s ±0% | 0.006391s ±0% | 0.035443s ±1% | 0.050176s ±3% | 0.010683s ±1% | 0.004308s ±22% |
| interop host calls | 0.001177s ±33% | **0.000797s** ±0% | 0.000981s ±0% | 0.000981s ±0% | 0.012127s ±0% | 0.001562s ±0% | 0.034218s ±1% | 0.001379s ±0% |
| primes loop | 0.010322s ±0% | 0.012756s ±0% | 0.012766s ±0% | 0.012768s ±0% | 0.026931s ±0% | **0.009765s** ±0% | 0.012774s ±0% | 0.012758s ±0% |
| tree | 0.002125s ±1% | 0.002040s ±0% | 0.002094s ±0% | **0.002032s** ±1% | 0.017982s ±1% | 0.013471s ±1% | 0.003021s ±2% | 0.002833s ±2% |
| fibonacci loop | 0.001271s ±0% | **0.001270s** ±0% | 0.001272s ±0% | 0.001271s ±0% | 0.027034s ±1% | 0.004325s ±0% | 0.003833s ±0% | 0.001317s ±0% |
| float2string | 0.000950s ±3% | 0.001055s ±12% | 0.005564s ±1% | **0.000842s** ±0% | 0.001641s ±1% | 0.004164s ±0% | 0.018515s ±1% | 0.002277s ±3% |
| fibonacci recursive | 0.003074s ±28% | 0.002810s ±0% | **0.002810s** ±0% | 0.002811s ±0% | 0.041178s ±0% | 0.005530s ±0% | 0.005709s ±0% | 0.002992s ±3% |

#### Startup

| Runtime | hello world | artifact |
| --- | ---: | ---: |
| DAS interpreter | 0.027758s ±2% | - |
| DAS JIT | 0.120371s ±1% | - |
| DAS exe | 0.011281s ±4% | 17 KB |
| C++ | 0.003224s ±13% | 16 KB |
| Zig | **0.002492s** ±16% | 3.6 MB |
| Luau --codegen | 0.003426s ±6% | - |
| Luau | 0.003576s ±3% | - |
| Lua | 0.002675s ±11% | - |
| LuaJIT -joff | 0.002724s ±12% | - |
| LuaJIT | 0.002798s ±12% | - |
| Quirrel | 0.003560s ±7% | - |
| QuickJS | 0.003059s ±9% | - |
| Mono --interpreter | 0.013349s ±3% | 3 KB |
| Mono | 0.011571s ±4% | 3 KB |
| .NET | 0.020200s ±2% | 4 KB |

## Related

- [daslang](https://github.com/GaijinEntertainment/daScript) — the daslang compiler and runtime

## Capturing a record

One command, from the repository root, on an idle box:

```
cmake --build build --target run_profile
```

It runs `daslang main.das -- --json`: the runner plain, neither `-jit` nor `-ignore-manifest`,
because it times the startup launches and pays its own address space on every fork - a jitted
parent maps LLVM and reads 5 ms slower on every lane. The boards need neither flag from it: the
JIT lane's children start under `-jit` themselves, and the runner starts the child that runs
the boards with `-ignore-manifest`, because the AOT lane lives on the dlopen of
`testProfileAot.shared_module`, which a descriptor manifest would defer and nothing requires.
The runner refuses `--json` from a jitted parent, and on any das lane missing from any test -
or any lane failure - names the holes, writes no record and exits 1.
`profile_results_<platform>.json` lands beside this file; `update_readme_benchmarks.py` renders
the tables above from it, and daslang.io fetches it on deploy and fails the deploy on the same
holes.

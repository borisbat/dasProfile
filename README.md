# dasProfile

Performance benchmarks for [daslang](https://dascript.org/) (formerly daScript).

This repository contains cross-language benchmark suites comparing daslang against Lua, LuaJIT, Luau, JavaScript (QuickJS), Quirrel, C#, and Zig.

## Benchmark Snapshot

Per-platform captures. A cell is the median of five samples, each its own process; a sample runs the kernel as many times as fit a 0.5 s budget and reports the per-run time, and `±` is half the sample range as a share of the median. Lower is better. The fastest result in each row is in bold. `-` means no value for that runtime on that benchmark. The Startup table is hello world in every language on the boards: the wall time of one launch the way that lane's kernels are launched (median of ten after a warm one), and the size of the artifact the lane runs where it built one - a das exe links the daslang runtime library dynamically, a zig exe is static.

### macOS — Apple M1 Max

Platform information:

- Captured from `profile_results_darwin.json` on Fri Sep 11 15:31:22 2026
- Toolchain: AppleClang 21.0.0.21000101, daslang 0.6.4, LLVM 22.1.5
- Runtimes: Lua 5.5.1, LuaJIT 2.1.1787165859, Luau 0.736, Mono 6.14.1 (tarball Tue Apr 29 17:43:02 UTC 2025), .NET 10.0.300, QuickJS 2026-06-04, Quirrel 4.29.1, Zig 0.16.0

#### Interpreted

| Test | DAS interpreter | Luau | Lua | LuaJIT -joff | Quirrel | QuickJS | Mono --interpreter |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | **0.002773s** ±1% | 0.012015s ±1% | 0.067726s ±2% | 0.244261s ±1% | 0.022381s ±3% | 0.023727s ±1% | 0.010765s ±1% |
| dictionary | **0.014386s** ±3% | 0.022165s ±3% | 0.039439s ±6% | 0.020829s ±2% | 0.047149s ±1% | 0.048040s ±1% | 0.319065s ±1% |
| n-bodies | **0.009601s** ±1% | 0.034173s ±0% | 0.041745s ±5% | 0.032860s ±0% | 0.069602s ±1% | 0.080062s ±1% | 0.027353s ±0% |
| spectral norm | **0.026721s** ±1% | 0.035673s ±1% | 0.060266s ±0% | 0.067563s ±0% | 0.131425s ±1% | 0.159816s ±1% | 0.031069s ±0% |
| mandelbrot | **0.002049s** ±1% | 0.035531s ±0% | 0.068178s ±1% | 0.044354s ±1% | 0.006966s ±0% | 0.007706s ±0% | 0.009295s ±0% |
| exp loop | **0.007353s** ±1% | 0.009898s ±1% | 0.022736s ±5% | 0.015289s ±1% | 0.042387s ±1% | 0.039859s ±3% | 0.025192s ±1% |
| string2float | **0.000629s** ±1% | 0.000885s ±0% | 0.002531s ±1% | 0.006339s ±1% | 0.001930s ±6% | 0.004298s ±1% | 0.052516s ±1% |
| particles kinematics | **0.000863s** ±1% | 0.027306s ±0% | 0.044254s ±3% | 0.027217s ±0% | 0.024630s ±1% | 0.033725s ±1% | 0.023694s ±1% |
| queen | **0.000909s** ±0% | 0.002513s ±0% | 0.001411s ±11% | 0.002202s ±0% | 0.002325s ±1% | 0.003176s ±1% | 0.000965s ±0% |
| interop host calls | **0.002484s** ±1% | 0.013266s ±1% | 0.012291s ±2% | 0.035504s ±1% | 0.036779s ±0% | 0.021299s ±0% | 0.096849s ±0% |
| primes loop | **0.021431s** ±1% | 0.065242s ±1% | 0.074386s ±0% | 0.194473s ±1% | 0.142412s ±2% | 0.138864s ±0% | 0.056606s ±0% |
| tree | 0.029062s ±1% | 0.029905s ±1% | 0.035242s ±6% | 0.032129s ±1% | 0.082929s ±1% | 0.058704s ±1% | **0.019301s** ±1% |
| sort | **0.015238s** ±0% | 0.047404s ±0% | 0.057286s ±1% | 0.057361s ±2% | 0.125349s ±1% | 0.043786s ±1% | 0.057259s ±1% |
| fibonacci loop | 0.032346s ±1% | 0.087100s ±1% | 0.046813s ±2% | 0.077386s ±2% | 0.057605s ±2% | 0.148600s ±1% | **0.031473s** ±1% |
| float2string | **0.001616s** ±1% | 0.002155s ±1% | 0.015716s ±0% | 0.005924s ±0% | 0.006157s ±0% | 0.008623s ±0% | 0.072430s ±0% |
| fibonacci recursive | **0.043404s** ±0% | 0.075987s ±0% | 0.067220s ±3% | 0.053445s ±0% | 0.156875s ±2% | 0.083314s ±1% | 0.045524s ±1% |

#### AOT or JIT

| Test | DAS AOT | DAS JIT | C++ | Zig | Luau --codegen | LuaJIT | Mono | .NET |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | 0.000173s ±1% | **0.000143s** ±1% | 0.000156s ±1% | 0.000151s ±0% | 0.010545s ±0% | 0.014580s ±1% | 0.000979s ±2% | 0.000486s ±1% |
| dictionary | 0.009425s ±1% | 0.008094s ±4% | 0.024490s ±4% | 0.007122s ±2% | 0.018893s ±1% | **0.007102s** ±3% | 0.077635s ±0% | 0.043603s ±5% |
| n-bodies | 0.001335s ±1% | 0.000871s ±1% | 0.000920s ±1% | **0.000833s** ±0% | 0.012117s ±0% | 0.003352s ±1% | 0.005315s ±0% | 0.001774s ±1% |
| spectral norm | 0.001728s ±0% | **0.000622s** ±1% | 0.001730s ±0% | 0.001695s ±0% | 0.007042s ±1% | 0.002409s ±1% | 0.006653s ±0% | 0.001770s ±1% |
| mandelbrot | 0.000565s ±0% | 0.000463s ±1% | 0.000364s ±0% | **0.000340s** ±0% | 0.024134s ±0% | 0.008186s ±1% | 0.001867s ±0% | 0.000380s ±1% |
| exp loop | 0.003414s ±1% | **0.001655s** ±0% | 0.001709s ±1% | 0.001699s ±0% | 0.005057s ±0% | 0.002396s ±1% | 0.006783s ±0% | 0.002576s ±1% |
| string2float | 0.000547s ±1% | 0.000534s ±1% | 0.000630s ±0% | **0.000531s** ±1% | 0.000767s ±0% | 0.005715s ±2% | 0.004574s ±0% | 0.001399s ±3% |
| particles kinematics | 0.000334s ±1% | 0.000334s ±0% | 0.000364s ±1% | **0.000284s** ±0% | 0.011533s ±0% | 0.004396s ±0% | 0.004601s ±0% | 0.000311s ±0% |
| queen | 0.000096s ±0% | 0.000061s ±25% | **0.000058s** ±22% | 0.000058s ±12% | 0.000761s ±1% | 0.000185s ±1% | 0.000181s ±1% | 0.000071s ±6% |
| interop host calls | 0.001242s ±0% | **0.000640s** ±0% | 0.000931s ±0% | 0.000938s ±1% | 0.012203s ±0% | 0.000932s ±0% | 0.007759s ±0% | 0.001242s ±0% |
| primes loop | **0.006149s** ±1% | 0.006788s ±0% | 0.006816s ±0% | 0.006883s ±1% | 0.038158s ±0% | 0.016326s ±0% | 0.025369s ±0% | 0.008237s ±1% |
| tree | 0.002618s ±1% | **0.002465s** ±1% | 0.002519s ±1% | 0.002514s ±1% | 0.019281s ±0% | 0.012213s ±1% | 0.003605s ±0% | 0.003976s ±1% |
| sort | **0.002512s** ±0% | 0.004306s ±0% | 0.004383s ±0% | 0.005514s ±0% | 0.043420s ±1% | 0.048354s ±1% | 0.009693s ±0% | 0.005498s ±1% |
| fibonacci loop | **0.002021s** ±1% | 0.002022s ±1% | 0.002023s ±2% | 0.002043s ±1% | 0.022814s ±1% | 0.010103s ±2% | 0.002043s ±1% | 0.005004s ±1% |
| float2string | **0.000982s** ±1% | 0.001074s ±1% | 0.005868s ±0% | 0.001002s ±0% | 0.002059s ±2% | 0.005513s ±0% | 0.016196s ±1% | 0.002582s ±0% |
| fibonacci recursive | 0.003916s ±1% | 0.003920s ±0% | 0.003921s ±1% | 0.004024s ±1% | 0.039908s ±2% | 0.006579s ±0% | 0.005763s ±0% | **0.003538s** ±3% |

#### Startup

| Runtime | hello world | artifact |
| --- | ---: | ---: |
| DAS interpreter | 0.025438s ±1% | - |
| DAS JIT | 0.102607s ±4% | - |
| DAS exe | 0.013781s ±35% | 50 KB |
| C++ | **0.008267s** ±2% | 33 KB |
| Zig | 0.008680s ±1% | 387 KB |
| Luau --codegen | 0.010154s ±3% | - |
| Luau | 0.010130s ±1% | - |
| Lua | 0.008628s ±6% | - |
| LuaJIT -joff | 0.008580s ±1% | - |
| LuaJIT | 0.008557s ±1% | - |
| Quirrel | 0.009271s ±2% | - |
| QuickJS | 0.008902s ±4% | - |
| Mono --interpreter | 0.031831s ±8% | 3 KB |
| Mono | 0.025460s ±1% | 3 KB |
| .NET | 0.031340s ±1% | 4 KB |

### Linux — AMD Ryzen 7 PRO 8700GE w/ Radeon 780M Graphics

Platform information:

- Captured from `profile_results_linux.json` on Sat Sep 12 00:31:18 2026
- Toolchain: Clang 19.1.7, daslang 0.6.4, LLVM 22.1.5
- Runtimes: Lua 5.5.1, LuaJIT 2.1.1787165859, Luau 0.736, Mono 6.8.0.105 (Debian 6.8.0.105+dfsg-3.3+deb12u1 Sat Jun 21 16:33:59 UTC 2025), .NET 10.0.400, QuickJS 2026-06-04, Quirrel 4.29.1, Zig -

#### Interpreted

| Test | DAS interpreter | Luau | Lua | LuaJIT -joff | Quirrel | QuickJS | Mono --interpreter |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | **0.002857s** ±1% | 0.012435s ±1% | 0.068848s ±1% | 0.207896s ±1% | 0.018659s ±1% | 0.021292s ±6% | 0.018408s ±2% |
| dictionary | **0.011140s** ±0% | 0.019993s ±2% | 0.039443s ±0% | 0.011706s ±2% | 0.053792s ±3% | 0.047423s ±1% | 0.799779s ±2% |
| n-bodies | **0.009514s** ±0% | 0.029498s ±4% | 0.042525s ±6% | 0.024987s ±1% | 0.071187s ±1% | 0.083562s ±2% | 0.052629s ±3% |
| spectral norm | **0.023400s** ±3% | 0.032819s ±4% | 0.057627s ±1% | 0.038056s ±0% | 0.107140s ±2% | 0.090818s ±2% | 0.048335s ±4% |
| mandelbrot | **0.001792s** ±6% | 0.033311s ±1% | 0.057141s ±1% | 0.036626s ±1% | 0.005796s ±4% | 0.006356s ±1% | 0.013417s ±1% |
| exp loop | **0.005989s** ±6% | 0.011443s ±0% | 0.023823s ±0% | 0.010234s ±2% | 0.036715s ±1% | 0.031428s ±6% | 0.125052s ±8% |
| string2float | **0.000620s** ±1% | 0.001648s ±0% | 0.002811s ±1% | 0.003521s ±0% | 0.002361s ±1% | 0.003579s ±0% | 0.062298s ±1% |
| particles kinematics | **0.000941s** ±1% | 0.026713s ±1% | 0.041470s ±5% | 0.021533s ±0% | 0.025219s ±2% | 0.029898s ±0% | 0.038691s ±3% |
| queen | **0.000778s** ±1% | 0.001886s ±0% | 0.001487s ±3% | 0.000900s ±0% | 0.002024s ±1% | 0.002488s ±1% | 0.001533s ±4% |
| sort | **0.015393s** ±0% | 0.038836s ±3% | 0.045843s ±1% | 0.050255s ±2% | 0.113145s ±1% | 0.037479s ±0% | 0.126500s ±4% |
| interop host calls | **0.003549s** ±0% | 0.012192s ±0% | 0.015397s ±1% | 0.036200s ±2% | 0.038558s ±38% | 0.020878s ±3% | 0.091536s ±2% |
| primes loop | **0.026224s** ±0% | 0.151400s ±0% | 0.059209s ±0% | 0.044280s ±0% | 0.101837s ±0% | 0.112544s ±8% | 0.066301s ±10% |
| tree | 0.023651s ±0% | 0.024547s ±2% | 0.029988s ±4% | **0.018419s** ±4% | 0.069457s ±1% | 0.061472s ±0% | 0.020439s ±3% |
| fibonacci loop | 0.030817s ±5% | 0.058347s ±1% | 0.053922s ±1% | **0.030750s** ±1% | 0.043959s ±0% | 0.137231s ±0% | 0.062910s ±3% |
| float2string | **0.001227s** ±3% | 0.001782s ±0% | 0.013285s ±3% | 0.004589s ±0% | 0.005448s ±0% | 0.007729s ±0% | 0.110765s ±2% |
| fibonacci recursive | 0.047871s ±1% | 0.062446s ±1% | 0.048911s ±0% | **0.034995s** ±0% | 0.116185s ±3% | 0.084649s ±21% | 0.042200s ±0% |

#### AOT or JIT

| Test | DAS AOT | DAS JIT | C++ | Zig | Luau --codegen | LuaJIT | Mono | .NET |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | 0.000102s ±0% | **0.000097s** ±0% | 0.000100s ±0% | 0.000117s ±0% | 0.009769s ±3% | 0.014392s ±2% | 0.000898s ±1% | 0.000374s ±3% |
| dictionary | **0.006665s** ±1% | 0.007980s ±1% | 0.028841s ±1% | 0.009463s ±2% | 0.016436s ±2% | 0.010663s ±2% | 0.079306s ±1% | 0.049186s ±6% |
| n-bodies | 0.001224s ±0% | 0.000914s ±0% | 0.001200s ±0% | **0.000699s** ±0% | 0.011188s ±3% | 0.003415s ±0% | 0.004045s ±0% | 0.001488s ±0% |
| spectral norm | 0.001850s ±1% | 0.001863s ±2% | 0.001810s ±1% | **0.001802s** ±0% | 0.006048s ±0% | 0.001978s ±0% | 0.004657s ±0% | 0.001842s ±0% |
| mandelbrot | 0.000457s ±0% | 0.000260s ±0% | 0.000296s ±0% | **0.000215s** ±0% | 0.025974s ±7% | 0.007504s ±1% | 0.003704s ±0% | 0.000264s ±0% |
| exp loop | 0.002366s ±0% | 0.002367s ±0% | 0.004153s ±0% | **0.002354s** ±0% | 0.004313s ±0% | 0.003549s ±0% | 0.005945s ±0% | 0.003370s ±0% |
| string2float | **0.000438s** ±1% | 0.000443s ±1% | 0.001485s ±0% | 0.000454s ±0% | 0.001496s ±1% | 0.003115s ±0% | 0.004677s ±1% | 0.001238s ±1% |
| particles kinematics | 0.000254s ±0% | 0.000231s ±0% | 0.000252s ±2% | **0.000145s** ±2% | 0.014533s ±0% | 0.008455s ±2% | 0.006600s ±0% | 0.000396s ±0% |
| queen | 0.000054s ±12% | **0.000027s** ±2% | 0.000030s ±1% | 0.000027s ±1% | 0.000590s ±1% | 0.000201s ±0% | 0.000088s ±34% | 0.000034s ±3% |
| sort | **0.001855s** ±0% | 0.004486s ±0% | 0.003404s ±0% | 0.006400s ±0% | 0.035400s ±1% | 0.049882s ±2% | 0.010774s ±1% | 0.004346s ±1% |
| interop host calls | 0.001180s ±33% | **0.000797s** ±0% | 0.000981s ±0% | 0.000981s ±0% | 0.012174s ±0% | 0.001569s ±0% | 0.034320s ±1% | 0.001380s ±0% |
| primes loop | 0.010343s ±0% | 0.012755s ±0% | 0.012764s ±0% | 0.012769s ±0% | 0.027043s ±0% | **0.009783s** ±0% | 0.012821s ±0% | 0.012775s ±0% |
| tree | 0.002091s ±0% | 0.002040s ±0% | 0.002093s ±0% | **0.002028s** ±0% | 0.017978s ±0% | 0.013434s ±1% | 0.003004s ±2% | 0.002796s ±1% |
| fibonacci loop | 0.001272s ±0% | 0.001272s ±0% | 0.001271s ±0% | **0.001271s** ±0% | 0.026981s ±1% | 0.004328s ±0% | 0.003833s ±0% | 0.001318s ±0% |
| float2string | 0.000952s ±4% | 0.001046s ±0% | 0.005595s ±0% | **0.000842s** ±0% | 0.001651s ±1% | 0.004178s ±0% | 0.018540s ±1% | 0.002196s ±2% |
| fibonacci recursive | 0.003087s ±27% | 0.002821s ±0% | 0.002821s ±0% | 0.002823s ±0% | 0.041123s ±2% | 0.005538s ±0% | 0.005731s ±0% | **0.002793s** ±4% |

#### Startup

| Runtime | hello world | artifact |
| --- | ---: | ---: |
| DAS interpreter | 0.030262s ±1% | - |
| DAS JIT | 0.122237s ±1% | - |
| DAS exe | 0.014048s ±4% | 17 KB |
| C++ | 0.005403s ±2% | 16 KB |
| Zig | **0.005042s** ±3% | 3.6 MB |
| Luau --codegen | 0.005826s ±6% | - |
| Luau | 0.005989s ±5% | - |
| Lua | 0.005082s ±6% | - |
| LuaJIT -joff | 0.005168s ±7% | - |
| LuaJIT | 0.005175s ±7% | - |
| Quirrel | 0.005858s ±6% | - |
| QuickJS | 0.005339s ±5% | - |
| Mono --interpreter | 0.016097s ±2% | 3 KB |
| Mono | 0.014234s ±2% | 3 KB |
| .NET | 0.022991s ±2% | 4 KB |

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

# dasProfile

Performance benchmarks for [daslang](https://dascript.org/) (formerly daScript).

This repository contains cross-language benchmark suites comparing daslang against Lua, LuaJIT, Luau, JavaScript (QuickJS), Quirrel, and C#.

## Benchmark Snapshot

Per-platform captures. Lower is better. The fastest result in each row is in bold. `-` means no value for that runtime on that benchmark.

### macOS — Apple M1 Max

Platform information:

- Captured from `profile_results_darwin.json` on Mon Aug 24 04:23:36 2026
- Toolchain: AppleClang 21.0.0.21000101, daslang 0.6.4, LLVM 22.1.5
- Runtimes: Lua 5.5.0, LuaJIT 2.1.1774896198, Luau 0.720, Mono 6.14.1 (tarball Tue Apr 29 17:43:02 UTC 2025), .NET 10.0.300, QuickJS 2025-09-13, Quirrel 4.20.0

#### Interpreted

| Test | DAS interpreter | Luau | Lua | LuaJIT -joff | Quirrel | QuickJS | Mono --interpreter |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | **0.088520s** | 0.375728s | 2.224072s | 0.253371s | 0.736345s | 0.928000s | 0.360820s |
| dictionary | **0.015346s** | 0.035719s | 0.053598s | 0.023007s | 0.074822s | 0.053000s | 0.354948s |
| n-bodies | **0.145181s** | 0.526935s | 0.683196s | 0.520397s | 1.093160s | 1.379000s | 0.432292s |
| spectral norm | **0.133007s** | 0.172225s | 0.312885s | 0.346714s | 0.659841s | 0.763000s | 0.160881s |
| native loop | **0.024800s** | - | - | - | - | - | 1.019868s |
| mandelbrot | **0.002039s** | 0.035791s | 0.077136s | 0.045929s | 0.006746s | 0.008000s | 0.009510s |
| exp loop | 0.009691s | **0.009619s** | 0.023254s | 0.015689s | 0.041328s | 0.037000s | 0.025938s |
| string2float | **0.016265s** | 0.022679s | 0.066204s | 0.164071s | 0.049809s | 0.125000s | 1.368532s |
| particles kinematics | **0.008510s** | 0.278972s | 0.436534s | 0.261112s | 0.254812s | 0.457000s | 0.244268s |
| queen | **0.000904s** | 0.002560s | 0.001446s | 0.002233s | 0.002381s | 0.003000s | 0.004897s |
| primes loop | **0.021740s** | 0.067061s | 0.076428s | 0.197245s | 0.150416s | 0.140000s | 0.058153s |
| sort | **0.015544s** | 0.041823s | 0.058396s | 0.055967s | 0.127205s | 0.043000s | 0.059335s |
| tree | 1.573471s | 1.746316s | 2.020678s | 1.859450s | 5.427960s | 9.976000s | **1.089033s** |
| fibonacci loop | **0.032298s** | 0.089567s | 0.047790s | 0.079696s | 0.063521s | 0.147000s | 0.032510s |
| float2string | **0.054154s** | 0.055475s | 0.417758s | 0.154445s | 0.167451s | 0.272000s | 1.885519s |
| fibonacci recursive | **0.043136s** | 0.078675s | 0.068694s | 0.055189s | 0.158539s | 0.108000s | 0.046331s |

#### AOT or JIT

| Test | DAS AOT | DAS JIT | C++ | Luau --codegen | LuaJIT | Mono | .NET |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | 0.006044s | **0.004381s** | 0.004976s | 0.332236s | 0.015384s | 0.032626s | 0.016494s |
| dictionary | 0.010834s | 0.008213s | 0.023741s | 0.024466s | **0.007986s** | 0.092023s | 0.035208s |
| n-bodies | 0.022058s | **0.013170s** | 0.024099s | 0.242705s | 0.052140s | 0.083842s | 0.027049s |
| spectral norm | 0.008624s | **0.003102s** | 0.008875s | 0.042218s | 0.012240s | 0.034274s | 0.009651s |
| native loop | 0.012397s | **0.006392s** | - | - | - | 0.080545s | 0.012768s |
| mandelbrot | 0.000566s | **0.000462s** | 0.000563s | 0.023783s | 0.005574s | 0.001899s | 0.000560s |
| exp loop | 0.003955s | **0.001626s** | 0.001729s | 0.005177s | 0.002407s | 0.006947s | 0.002592s |
| string2float | 0.013328s | **0.012951s** | 0.015955s | 0.019589s | 0.147690s | 0.118201s | 0.038627s |
| particles kinematics | 0.003328s | 0.003425s | **0.003272s** | 0.146696s | 0.044470s | 0.047529s | 0.005650s |
| queen | 0.000094s | **0.000040s** | 0.000042s | 0.000746s | 0.000199s | 0.000618s | 0.000731s |
| primes loop | **0.006138s** | 0.006728s | 0.006847s | 0.039414s | 0.016546s | 0.025704s | 0.008502s |
| sort | **0.002497s** | 0.004251s | 0.004348s | 0.036842s | 0.050098s | 0.010094s | 0.009006s |
| tree | 0.137791s | 0.136219s | **0.135164s** | 1.111824s | 0.740921s | 0.205640s | 0.225222s |
| fibonacci loop | **0.002017s** | **0.002017s** | 0.002079s | 0.023567s | 0.010315s | 0.002060s | 0.004418s |
| float2string | 0.045371s | **0.041331s** | 0.149963s | 0.052848s | 0.144027s | 0.412196s | 0.068169s |
| fibonacci recursive | **0.003910s** | 0.003937s | **0.003910s** | 0.036798s | 0.006668s | 0.005879s | 0.004517s |

### Windows — AMD Ryzen Threadripper 3990X

Platform information:

- Captured from `profile_results_windows.json` on Sun Aug 23 10:33:49 2026
- Toolchain: MSVC 19.51.36248.0, daslang 0.6.4, LLVM 22.1.5
- Runtimes: Lua -, LuaJIT 2.1.1774896198, Luau 0.720, Mono 6.12.0 (Visual Studio built mono), .NET 10.0.300, QuickJS 2025-09-13-2, Quirrel 4.20.0

#### Interpreted

| Test | DAS interpreter | Luau | Lua | LuaJIT -joff | Quirrel | QuickJS | Mono --interpreter |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | **0.125716s** | 0.689463s | 5.358000s | 0.274000s | 1.212000s | 1.760000s | 0.922089s |
| dictionary | **0.016731s** | 0.048607s | 0.070000s | 0.020000s | 0.096000s | 0.117000s | 1.389088s |
| n-bodies | **0.257026s** | 0.718266s | 1.342000s | 0.566000s | 2.167000s | 2.486000s | 1.170949s |
| mandelbrot | **0.003388s** | 0.056636s | 0.158000s | 0.059000s | 0.009000s | 0.012000s | 0.026202s |
| spectral norm | **0.186005s** | 0.238623s | 0.544000s | 0.291000s | 1.135000s | 1.212000s | 0.455888s |
| native loop | **0.041260s** | - | - | - | - | - | 1.868740s |
| exp loop | **0.015577s** | 0.019307s | 0.055000s | 0.019000s | 0.081000s | 0.102000s | 0.385876s |
| string2float | **0.030073s** | 0.129264s | 0.216000s | 0.128000s | 0.141000s | 0.229000s | 5.400243s |
| particles kinematics | **0.013997s** | 0.399296s | 1.594000s | 0.308000s | 1.034000s | 1.540000s | 0.669419s |
| queen | 0.001483s | 0.001605s | 0.002000s | **0.001000s** | 0.003000s | 0.005000s | 0.012880s |
| fibonacci loop | **0.034687s** | 0.060486s | 0.075000s | 0.045000s | 0.079000s | 0.263000s | 0.140542s |
| primes loop | **0.050933s** | 0.094500s | 0.088000s | 0.069000s | 0.236000s | 0.217000s | 0.158501s |
| sort | **0.019860s** | 0.057909s | 0.105000s | 0.073000s | 0.252000s | 0.072000s | 0.291007s |
| tree | 2.026014s | 1.788859s | 3.028000s | **1.531000s** | 8.654000s | 16.062000s | 1.939324s |
| float2string | 0.110610s | **0.077653s** | 0.777000s | 0.197000s | 0.310000s | 0.540000s | 5.606546s |
| fibonacci recursive | **0.032576s** | 0.086670s | 0.095000s | 0.061000s | 0.213000s | 0.211000s | 0.113692s |

#### AOT or JIT

| Test | DAS AOT | DAS JIT | C++ | Luau --codegen | LuaJIT | Mono | .NET |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | 0.009748s | 0.004396s | **0.004025s** | 0.549106s | 0.024000s | 0.046988s | 0.017283s |
| dictionary | 0.009965s | **0.009628s** | 0.040865s | 0.042399s | 0.014000s | 0.106316s | 0.067962s |
| n-bodies | 0.115406s | **0.024489s** | 0.033703s | 0.222957s | 0.082000s | 0.079346s | 0.040454s |
| mandelbrot | 0.000629s | 0.000441s | **0.000302s** | 0.040889s | 0.008000s | 0.004681s | 0.000605s |
| spectral norm | 0.012247s | 0.012153s | **0.011982s** | 0.055988s | 0.014000s | 0.027319s | 0.013291s |
| native loop | 0.012026s | **0.009663s** | - | - | - | 0.135522s | 0.077220s |
| exp loop | 0.006977s | **0.002984s** | 0.003263s | 0.007762s | 0.006000s | 0.011171s | 0.006345s |
| string2float | **0.023677s** | 0.023864s | 0.101710s | 0.117100s | 0.110000s | 0.167461s | 0.055313s |
| particles kinematics | **0.003030s** | 0.003619s | 0.003428s | 0.203969s | 0.188000s | 0.093309s | 0.007802s |
| queen | 0.000143s | 0.000106s | 0.000120s | 0.000762s | **0.000000s** | 0.000777s | 0.000959s |
| fibonacci loop | 0.001555s | **0.001544s** | 0.001561s | 0.030958s | 0.004000s | 0.002272s | 0.001957s |
| primes loop | 0.013211s | **0.003809s** | 0.037569s | 0.033763s | 0.014000s | 0.039134s | 0.039404s |
| sort | **0.003258s** | 0.005471s | 0.005408s | 0.054823s | 0.078000s | 0.011173s | 0.013657s |
| tree | 0.168591s | **0.153665s** | 0.175019s | 1.495365s | 1.079000s | 0.259549s | 0.220237s |
| float2string | 0.095155s | 0.094725s | 0.258462s | **0.070217s** | 0.174000s | 0.405035s | 0.093357s |
| fibonacci recursive | 0.006443s | **0.003768s** | 0.005263s | 0.061901s | 0.012000s | 0.009210s | 0.007482s |

## Native loop

The `native loop` row is a script calling a C function ten million times. Each runtime gets the call the way its users would write it:

| Runtime | Call | Source |
| --- | --- | --- |
| daslang | `AddOne`, bound with `addExternInline` | `test_profile.cpp` |
| C++ | `testNativeLoop`, the same `noinline` function called from C++ | `test_profile.cpp` |
| Lua | `profile_native.addOne`, a builtin library added to `linit.c` at configure time | `hosts/profile_lua_native.c` |
| LuaJIT | `ffi` call into `addOne.dll` / `libaddOne.so` | `tests/lua/native.lua` |
| Luau | `AddOne`, a global registered by `luau_host` (the CLI's file runner plus that one global) | `hosts/profile_luau_host.cpp` |
| Quirrel | `::AddOne`, registered by `sq_host` | `hosts/profile_sq_host.cpp` |
| QuickJS | `AddOne`, registered by `qjs_host` (built next to `qjs` by `hosts/quickjs_host.mk`; runs every QuickJS row, see Timers) | `hosts/profile_qjs_host.c` |
| Mono / .NET | `DllImport` of `addOne` | `tests/cs/native.cs` |

The Luau and Quirrel hosts run only the native row; every other row runs on the stock `luau` and `sq` binaries. `qjs_host` runs every QuickJS row.

## Timers

Every lane times with a sub-microsecond clock: `ref_time_ticks` (daslang), `Stopwatch` (C#), `os.clock` (Luau, high resolution on every platform), `performance.now()` (QuickJS - the MinGW build only has `gettimeofday` behind it, ticking every 0.3 ms, so on Windows `qjs_host` puts `QueryPerformanceCounter` behind it), `profile_native.clock` (Lua), `QueryPerformanceCounter` through `ffi` on Windows (LuaJIT). Quirrel's `clock()` is the CRT `clock()`, which advances once a millisecond on Windows until [quirrel#112](https://github.com/GaijinEntertainment/quirrel/pull/112) lands.

## Related

- [daslang](https://github.com/GaijinEntertainment/daScript) — the daslang compiler and runtime

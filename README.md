# dasProfile

Performance benchmarks for [daslang](https://dascript.org/) (formerly daScript).

This repository contains cross-language benchmark suites comparing daslang against Lua, LuaJIT, Luau, JavaScript (QuickJS), Quirrel, and C#.

## Benchmark Snapshot

Platform information:

- macOS on Apple M1 Max
- Captured from `profile_results.json` on Wed May 13 02:27:45 2026
- Toolchain: AppleClang 21.0.0.21000101, daslang 0.6.2, LLVM 22.1.5
- Runtimes: Lua 5.5.0, LuaJIT 2.1.1774896198, Luau 0.720, Mono 6.14.1 (tarball Tue Apr 29 17:43:02 UTC 2025), .NET 10.0.300, QuickJS 2025-09-13, Quirrel 4.20.0

Lower is better. The fastest result in each row is in bold. `-` means no value for that runtime on that benchmark.

### Interpreted

| Test | DAS interpreter | Luau | Lua | LuaJIT -joff | Quirrel | QuickJS | Mono --interpreter |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | **0.092694s** | 0.375514s | 2.219157s | 0.254910s | 0.736581s | 0.929000s | 0.359945s |
| dictionary | **0.019501s** | 0.033887s | 0.056969s | 0.023129s | 0.072739s | 0.053000s | 0.346503s |
| n-bodies | **0.155632s** | 0.526083s | 0.673379s | 0.517755s | 1.088980s | 1.378000s | 0.431229s |
| spectral norm | 0.182968s | 0.173266s | 0.312472s | 0.345040s | 0.657186s | 0.762000s | **0.159187s** |
| native loop | **0.025574s** | - | - | - | - | - | 1.024836s |
| mandelbrot | **0.002071s** | 0.035458s | 0.075769s | 0.045613s | 0.006820s | 0.008000s | 0.009544s |
| exp loop | 0.009753s | **0.009573s** | 0.023231s | 0.015827s | 0.041501s | 0.037000s | 0.025549s |
| string2float | **0.017439s** | 0.022654s | 0.067330s | 0.162124s | 0.049884s | 0.125000s | 1.365581s |
| particles kinematics | **0.008774s** | 0.275440s | 0.419066s | 0.261499s | 0.256935s | 0.458000s | 0.243845s |
| queen | **0.000935s** | 0.002558s | 0.001435s | 0.002251s | 0.002380s | 0.003000s | 0.004908s |
| primes loop | **0.022375s** | 0.067561s | 0.076955s | 0.201031s | 0.150567s | 0.140000s | 0.058360s |
| sort | **0.023568s** | 0.041513s | 0.058224s | 0.055987s | 0.127230s | 0.043000s | 0.058843s |
| tree | 1.661747s | 1.755597s | 2.025865s | 1.880567s | 5.271850s | 10.042000s | **1.084566s** |
| fibonacci loop | 0.033348s | 0.089427s | 0.047712s | 0.078617s | 0.063357s | 0.145000s | **0.032486s** |
| float2string | **0.053837s** | 0.054852s | 0.414679s | 0.154606s | 0.166803s | 0.272000s | 1.888956s |
| fibonacci recursive | **0.045908s** | 0.078326s | 0.068665s | 0.055565s | 0.158933s | 0.108000s | 0.046458s |

### AOT or JIT

| Test | DAS AOT | DAS JIT | C++ | Luau --codegen | LuaJIT | Mono | .NET |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | 0.006151s | **0.004480s** | 0.005061s | 0.333003s | 0.015595s | 0.032218s | 0.016053s |
| dictionary | 0.011667s | 0.011471s | 0.033336s | 0.025807s | **0.007609s** | 0.089849s | 0.036521s |
| n-bodies | 0.022452s | **0.013759s** | 0.024778s | 0.240852s | 0.051784s | 0.083267s | 0.027182s |
| spectral norm | 0.008831s | **0.003158s** | 0.009054s | 0.042284s | 0.012208s | 0.033698s | 0.009570s |
| native loop | 0.012765s | **0.006584s** | - | - | - | 0.080366s | 0.012807s |
| mandelbrot | 0.000577s | **0.000468s** | 0.000578s | 0.023760s | 0.005716s | 0.001898s | 0.000556s |
| exp loop | 0.004010s | **0.001583s** | 0.001709s | 0.005146s | 0.002368s | 0.006916s | 0.002591s |
| string2float | 0.014658s | **0.014494s** | 0.015883s | 0.019429s | 0.145709s | 0.118190s | 0.038697s |
| particles kinematics | 0.003396s | 0.003417s | **0.003376s** | 0.137624s | 0.050390s | 0.047589s | 0.005556s |
| queen | 0.000095s | 0.000054s | **0.000042s** | 0.000744s | 0.000217s | 0.000618s | 0.000699s |
| primes loop | **0.006296s** | 0.006875s | 0.007079s | 0.039515s | 0.016889s | 0.026252s | 0.008699s |
| sort | 0.004382s | 0.005490s | **0.004347s** | 0.036704s | 0.050057s | 0.009938s | 0.009020s |
| tree | 0.144122s | 0.158062s | **0.143808s** | 1.111482s | 0.730885s | 0.205152s | 0.224061s |
| fibonacci loop | 0.002018s | 0.002075s | **0.002017s** | 0.023451s | 0.010232s | 0.002056s | 0.004299s |
| float2string | 0.075989s | **0.046699s** | 0.152168s | 0.053023s | 0.144423s | 0.413133s | 0.068346s |
| fibonacci recursive | 0.003985s | **0.003626s** | 0.003984s | 0.036760s | 0.006678s | 0.005915s | 0.004551s |

## Related

- [daslang](https://github.com/GaijinEntertainment/daScript) — the daslang compiler and runtime

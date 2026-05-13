# dasProfile

Performance benchmarks for [daslang](https://dascript.org/) (formerly daScript).

This repository contains cross-language benchmark suites comparing daslang against Lua, LuaJIT, Luau, JavaScript (QuickJS), Quirrel, and C#.

## Benchmark Snapshot

Platform information:

- macOS on Apple M1 Max
- Captured from `profile_results.json` on Wed May 13 02:00:48 2026
- Toolchain: AppleClang 21.0.0.21000101, daslang 0.6.2, LLVM 22.1.5
- Runtimes: Lua 5.5.0, LuaJIT 2.1.1774896198, Luau 0.720, Mono 6.14.1 (tarball Tue Apr 29 17:43:02 UTC 2025), .NET 10.0.300, QuickJS 2025-09-13, Quirrel 4.20.0

Lower is better. The fastest result in each row is in bold. `-` means no value for that runtime on that benchmark.

### Interpreted

| Test | DAS interpreter | Luau | Lua | LuaJIT -joff | Quirrel | QuickJS | Mono --interpreter |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | **0.093044s** | 0.375649s | 2.221552s | 0.254255s | 0.737304s | 0.928000s | 0.359646s |
| dictionary | **0.017097s** | 0.034185s | 0.053710s | 0.022848s | 0.070157s | 0.054000s | 0.350049s |
| n-bodies | 0.155531s | 0.527262s | 0.674228s | 0.520503s | **0.109059s** | 1.387000s | 0.431170s |
| spectral norm | 0.183538s | 0.172946s | 0.313179s | 0.345418s | 0.660994s | 0.766000s | **0.160565s** |
| native loop | **0.025738s** | - | - | - | - | - | 1.023289s |
| mandelbrot | **0.002069s** | 0.035737s | 0.076888s | 0.045851s | 0.006848s | 0.008000s | 0.009580s |
| exp loop | 0.009823s | **0.009649s** | 0.022083s | 0.015731s | 0.041248s | 0.037000s | 0.025959s |
| string2float | **0.017390s** | 0.022757s | 0.065609s | 0.163696s | 0.166687s | 0.125000s | 1.369770s |
| particles kinematics | **0.008773s** | 0.277547s | 0.421807s | 0.260664s | 0.256429s | 0.456000s | 0.244278s |
| queen | **0.000935s** | 0.002554s | 0.001436s | 0.002228s | 0.002381s | 0.003000s | 0.004871s |
| primes loop | **0.022385s** | 0.067201s | 0.076930s | 0.197875s | 0.150816s | 0.140000s | 0.058670s |
| sort | **0.023545s** | 0.041524s | 0.058142s | 0.056749s | 0.127368s | 0.043000s | 0.058615s |
| tree | 1.660441s | 1.749676s | 2.034771s | 1.860792s | 5.445640s | 9.962000s | **1.089863s** |
| fibonacci loop | 0.033388s | 0.089350s | 0.047922s | 0.079709s | 0.063443s | 0.148000s | **0.032475s** |
| float2string | 0.053645s | 0.054740s | 0.413390s | 0.154451s | **0.049956s** | 0.272000s | 1.888065s |
| fibonacci recursive | **0.045650s** | 0.078462s | 0.068944s | 0.055534s | 0.159095s | 0.108000s | 0.046402s |

### AOT or JIT

| Test | DAS AOT | DAS JIT | C++ | Luau --codegen | LuaJIT | Mono | .NET |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | 0.006161s | **0.004484s** | 0.005090s | 0.331452s | 0.015638s | 0.032303s | 0.016256s |
| dictionary | 0.011146s | 0.011048s | 0.031762s | 0.028095s | **0.008192s** | 0.093185s | 0.038174s |
| n-bodies | 0.022467s | **0.013834s** | 0.024785s | 0.242297s | 0.051850s | 0.083733s | 0.027069s |
| spectral norm | 0.008942s | **0.003159s** | 0.009152s | 0.042301s | 0.012234s | 0.034394s | 0.009551s |
| native loop | 0.012804s | **0.006590s** | - | - | - | 0.080454s | 0.012766s |
| mandelbrot | 0.000589s | **0.000474s** | 0.000576s | 0.023928s | 0.005799s | 0.001864s | 0.000554s |
| exp loop | 0.004058s | **0.001584s** | 0.001710s | 0.005151s | 0.002398s | 0.006986s | 0.002590s |
| string2float | 0.014764s | **0.014496s** | 0.015804s | 0.019487s | 0.147916s | 0.118260s | 0.038657s |
| particles kinematics | 0.003394s | 0.003433s | **0.003369s** | 0.138068s | 0.049283s | 0.047264s | 0.005582s |
| queen | 0.000096s | 0.000053s | **0.000043s** | 0.000751s | 0.000201s | 0.000617s | 0.000734s |
| primes loop | **0.006205s** | 0.006900s | 0.007000s | 0.039131s | 0.016549s | 0.026034s | 0.008471s |
| sort | **0.004448s** | 0.005597s | 0.004453s | 0.036774s | 0.049979s | 0.009976s | 0.008930s |
| tree | 0.143697s | 0.157766s | **0.142813s** | 1.109295s | 0.724210s | 0.206414s | 0.224923s |
| fibonacci loop | **0.002055s** | 0.002079s | **0.002055s** | 0.023558s | 0.010350s | 0.002055s | 0.004396s |
| float2string | 0.076017s | **0.046535s** | 0.151872s | 0.052783s | 0.143574s | 0.412788s | 0.067936s |
| fibonacci recursive | 0.003987s | **0.003652s** | 0.003985s | 0.036824s | 0.006752s | 0.005832s | 0.004490s |

## Related

- [daslang](https://github.com/GaijinEntertainment/daScript) — the daslang compiler and runtime

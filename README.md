# dasProfile

Performance benchmarks for [daslang](https://dascript.org/) (formerly daScript).

This repository contains cross-language benchmark suites comparing daslang against Lua, LuaJIT, Luau, JavaScript (QuickJS), Quirrel, and C#.

## Benchmark Snapshot

Platform information:

- macOS on Apple M1 Max
- Captured from `profile_results.json` on Wed May 13 02:48:38 2026
- Toolchain: AppleClang 21.0.0.21000101, daslang 0.6.2, LLVM 22.1.5
- Runtimes: Lua 5.5.0, LuaJIT 2.1.1774896198, Luau 0.720, Mono 6.14.1 (tarball Tue Apr 29 17:43:02 UTC 2025), .NET 10.0.300, QuickJS 2025-09-13, Quirrel 4.20.0

Lower is better. The fastest result in each row is in bold. `-` means no value for that runtime on that benchmark.

### Interpreted

| Test | DAS interpreter | Luau | Lua | LuaJIT -joff | Quirrel | QuickJS | Mono --interpreter |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | **0.092860s** | 0.375728s | 2.224072s | 0.253371s | 0.736345s | 0.928000s | 0.360820s |
| dictionary | **0.016658s** | 0.035719s | 0.053598s | 0.023007s | 0.074822s | 0.053000s | 0.354948s |
| n-bodies | **0.155752s** | 0.526935s | 0.683196s | 0.520397s | 1.093160s | 1.379000s | 0.432292s |
| spectral norm | 0.183585s | 0.172225s | 0.312885s | 0.346714s | 0.659841s | 0.763000s | **0.160881s** |
| native loop | **0.025643s** | - | - | - | - | - | 1.019868s |
| mandelbrot | **0.002057s** | 0.035791s | 0.077136s | 0.045929s | 0.006746s | 0.008000s | 0.009510s |
| exp loop | 0.009897s | **0.009619s** | 0.023254s | 0.015689s | 0.041328s | 0.037000s | 0.025938s |
| string2float | **0.017470s** | 0.022679s | 0.066204s | 0.164071s | 0.049809s | 0.125000s | 1.368532s |
| particles kinematics | **0.008823s** | 0.278972s | 0.436534s | 0.261112s | 0.254812s | 0.457000s | 0.244268s |
| queen | **0.000935s** | 0.002560s | 0.001446s | 0.002233s | 0.002381s | 0.003000s | 0.004897s |
| primes loop | **0.022345s** | 0.067061s | 0.076428s | 0.197245s | 0.150416s | 0.140000s | 0.058153s |
| sort | **0.023536s** | 0.041823s | 0.058396s | 0.055967s | 0.127205s | 0.043000s | 0.059335s |
| tree | 1.659017s | 1.746316s | 2.020678s | 1.859450s | 5.427960s | 9.976000s | **1.089033s** |
| fibonacci loop | 0.033419s | 0.089567s | 0.047790s | 0.079696s | 0.063521s | 0.147000s | **0.032510s** |
| float2string | **0.053663s** | 0.055475s | 0.417758s | 0.154445s | 0.167451s | 0.272000s | 1.885519s |
| fibonacci recursive | **0.045765s** | 0.078675s | 0.068694s | 0.055189s | 0.158539s | 0.108000s | 0.046331s |

### AOT or JIT

| Test | DAS AOT | DAS JIT | C++ | Luau --codegen | LuaJIT | Mono | .NET |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | 0.006149s | **0.004512s** | 0.005108s | 0.332236s | 0.015384s | 0.032626s | 0.016494s |
| dictionary | 0.012154s | 0.011637s | 0.031887s | 0.024466s | **0.007986s** | 0.092023s | 0.035208s |
| n-bodies | 0.022459s | **0.013847s** | 0.024785s | 0.242705s | 0.052140s | 0.083842s | 0.027049s |
| spectral norm | 0.008844s | **0.003160s** | 0.009106s | 0.042218s | 0.012240s | 0.034274s | 0.009651s |
| native loop | 0.012605s | **0.006392s** | - | - | - | 0.080545s | 0.012768s |
| mandelbrot | 0.000564s | **0.000459s** | 0.000581s | 0.023783s | 0.005574s | 0.001899s | 0.000560s |
| exp loop | 0.004054s | **0.001583s** | 0.001711s | 0.005177s | 0.002407s | 0.006947s | 0.002592s |
| string2float | 0.014813s | **0.014481s** | 0.015896s | 0.019589s | 0.147690s | 0.118201s | 0.038627s |
| particles kinematics | 0.003401s | 0.003400s | **0.003360s** | 0.146696s | 0.044470s | 0.047529s | 0.005650s |
| queen | 0.000096s | 0.000055s | **0.000041s** | 0.000746s | 0.000199s | 0.000618s | 0.000731s |
| primes loop | **0.006289s** | 0.006960s | 0.007023s | 0.039414s | 0.016546s | 0.025704s | 0.008502s |
| sort | 0.004471s | 0.005609s | **0.004428s** | 0.036842s | 0.050098s | 0.010094s | 0.009006s |
| tree | 0.143418s | 0.157008s | **0.142762s** | 1.111824s | 0.740921s | 0.205640s | 0.225222s |
| fibonacci loop | **0.002055s** | 0.002062s | 0.002056s | 0.023567s | 0.010315s | 0.002060s | 0.004418s |
| float2string | 0.076211s | **0.046425s** | 0.152026s | 0.052848s | 0.144027s | 0.412196s | 0.068169s |
| fibonacci recursive | 0.004025s | **0.003625s** | 0.003988s | 0.036798s | 0.006668s | 0.005879s | 0.004517s |

## Related

- [daslang](https://github.com/GaijinEntertainment/daScript) — the daslang compiler and runtime

# dasProfile

Performance benchmarks for [daslang](https://dascript.org/) (formerly daScript).

This repository contains cross-language benchmark suites comparing daslang against Lua, LuaJIT, Luau, JavaScript (QuickJS), Quirrel, C#, and Zig.

## Benchmark Snapshot

Per-platform captures. A cell is the median of five samples, each its own process; a sample runs the kernel as many times as fit a 0.5 s budget and reports the per-run time, and `±` is half the sample range as a share of the median. Lower is better. The fastest result in each row is in bold. `-` means no value for that runtime on that benchmark. The Startup table is hello world in every language on the boards: the wall time of one launch the way that lane's kernels are launched (median of ten after a warm one), and the size of the artifact the lane runs where it built one - a das exe links the daslang runtime library dynamically, a zig exe is static.

### macOS — Apple M1 Max

Platform information:

- Captured from `profile_results_darwin.json` on Sun Sep 13 11:25:34 2026
- Toolchain: AppleClang 21.0.0.21000101, daslang 0.6.4, LLVM 22.1.5
- Runtimes: Lua 5.5.1, LuaJIT 2.1.1787165859, Luau 0.736, Mono 6.14.1 (tarball Tue Apr 29 17:43:02 UTC 2025), .NET 10.0.300, QuickJS 2026-06-04, Quirrel 4.29.1, Zig 0.16.0

#### Interpreted

| Test | DAS interpreter | Luau | Lua | LuaJIT -joff | Quirrel | QuickJS | Mono --interpreter |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | **0.002792s** ±1% | 0.012027s ±1% | 0.068824s ±1% | 0.244481s ±1% | 0.022684s ±3% | 0.023714s ±1% | 0.010786s ±1% |
| dictionary | **0.014329s** ±1% | 0.022576s ±2% | 0.041432s ±6% | 0.020956s ±2% | 0.047926s ±3% | 0.047980s ±0% | 0.320425s ±1% |
| n-bodies | **0.009184s** ±1% | 0.034255s ±0% | 0.041726s ±8% | 0.032954s ±0% | 0.069826s ±1% | 0.080258s ±0% | 0.027383s ±0% |
| spectral norm | **0.027048s** ±1% | 0.035754s ±1% | 0.060475s ±0% | 0.067626s ±0% | 0.131349s ±1% | 0.159958s ±0% | 0.031093s ±0% |
| mandelbrot | **0.002049s** ±0% | 0.035592s ±1% | 0.068065s ±2% | 0.044222s ±1% | 0.006969s ±0% | 0.007715s ±0% | 0.009275s ±1% |
| exp loop | **0.007419s** ±1% | 0.009995s ±1% | 0.021766s ±6% | 0.015341s ±1% | 0.042472s ±1% | 0.039527s ±1% | 0.025200s ±0% |
| string2float | **0.000634s** ±1% | 0.000887s ±1% | 0.002563s ±2% | 0.006340s ±1% | 0.001918s ±1% | 0.004289s ±0% | 0.052443s ±1% |
| particles kinematics | **0.000855s** ±1% | 0.027468s ±1% | 0.044332s ±3% | 0.027191s ±1% | 0.024278s ±0% | 0.033419s ±1% | 0.023706s ±2% |
| queen | **0.000933s** ±0% | 0.002520s ±1% | 0.001410s ±1% | 0.002201s ±0% | 0.002328s ±1% | 0.003178s ±0% | 0.000966s ±1% |
| interop host calls | **0.002487s** ±1% | 0.013214s ±4% | 0.012401s ±1% | 0.035628s ±1% | 0.036814s ±0% | 0.021081s ±0% | 0.096784s ±0% |
| primes loop | **0.022038s** ±1% | 0.065338s ±0% | 0.074484s ±0% | 0.194637s ±0% | 0.142570s ±0% | 0.139044s ±1% | 0.056667s ±1% |
| tree | 0.028922s ±0% | 0.030138s ±1% | 0.034692s ±4% | 0.032126s ±1% | 0.083084s ±0% | 0.059201s ±0% | **0.019380s** ±0% |
| sort | **0.015105s** ±0% | 0.047453s ±0% | 0.058141s ±1% | 0.058188s ±3% | 0.124800s ±0% | 0.043369s ±1% | 0.057334s ±2% |
| fibonacci loop | 0.032358s ±1% | 0.086431s ±0% | 0.046505s ±0% | 0.077280s ±0% | 0.057712s ±1% | 0.148741s ±1% | **0.031511s** ±1% |
| float2string | **0.001219s** ±1% | 0.002185s ±1% | 0.015712s ±1% | 0.005928s ±1% | 0.006153s ±0% | 0.008627s ±0% | 0.072626s ±1% |
| fibonacci recursive | **0.043298s** ±0% | 0.076156s ±2% | 0.067173s ±3% | 0.053478s ±0% | 0.156987s ±1% | 0.083642s ±1% | 0.045055s ±1% |

#### AOT or JIT

| Test | DAS AOT | DAS JIT | C++ | Zig | Luau --codegen | LuaJIT | Mono | .NET |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | 0.000173s ±0% | **0.000138s** ±1% | 0.000156s ±0% | 0.000151s ±0% | 0.010574s ±0% | 0.014607s ±0% | 0.000981s ±1% | 0.000489s ±2% |
| dictionary | 0.009309s ±3% | 0.008169s ±2% | 0.024960s ±5% | 0.007235s ±3% | 0.019496s ±1% | **0.007077s** ±1% | 0.078608s ±2% | 0.042451s ±5% |
| n-bodies | 0.001337s ±2% | 0.000871s ±1% | 0.000920s ±0% | **0.000834s** ±0% | 0.012127s ±0% | 0.003332s ±1% | 0.005321s ±0% | 0.001775s ±1% |
| spectral norm | 0.001732s ±0% | **0.000622s** ±0% | 0.001732s ±1% | 0.001696s ±0% | 0.007050s ±1% | 0.002417s ±1% | 0.006661s ±0% | 0.001796s ±1% |
| mandelbrot | 0.000565s ±0% | 0.000463s ±0% | 0.000364s ±0% | **0.000341s** ±1% | 0.024166s ±1% | 0.008191s ±1% | 0.001895s ±1% | 0.000381s ±0% |
| exp loop | 0.003419s ±0% | **0.001647s** ±1% | 0.001694s ±0% | 0.001692s ±2% | 0.005064s ±1% | 0.002374s ±1% | 0.006788s ±0% | 0.002564s ±1% |
| string2float | 0.000548s ±1% | 0.000538s ±0% | 0.000631s ±0% | **0.000532s** ±0% | 0.000768s ±0% | 0.005722s ±1% | 0.004565s ±1% | 0.001398s ±1% |
| particles kinematics | 0.000334s ±0% | 0.000335s ±0% | 0.000366s ±1% | **0.000285s** ±1% | 0.011606s ±1% | 0.004397s ±0% | 0.004604s ±1% | 0.000311s ±1% |
| queen | 0.000095s ±1% | 0.000036s ±23% | 0.000039s ±21% | **0.000034s** ±34% | 0.000761s ±0% | 0.000186s ±1% | 0.000181s ±1% | 0.000071s ±6% |
| interop host calls | 0.001242s ±1% | **0.000641s** ±1% | 0.000932s ±0% | 0.000935s ±1% | 0.012220s ±0% | 0.000932s ±1% | 0.007769s ±0% | 0.001243s ±0% |
| primes loop | **0.006194s** ±0% | 0.006792s ±1% | 0.006819s ±0% | 0.006818s ±0% | 0.038195s ±0% | 0.016344s ±0% | 0.025394s ±0% | 0.008234s ±1% |
| tree | 0.002613s ±1% | **0.002465s** ±1% | 0.002527s ±1% | 0.002512s ±1% | 0.019393s ±0% | 0.012235s ±6% | 0.003615s ±0% | 0.003979s ±0% |
| sort | **0.002496s** ±1% | 0.004343s ±1% | 0.004379s ±0% | 0.005607s ±1% | 0.043370s ±0% | 0.048355s ±1% | 0.009798s ±1% | 0.005488s ±3% |
| fibonacci loop | 0.002023s ±0% | 0.002024s ±1% | 0.002047s ±1% | 0.002023s ±0% | 0.022836s ±1% | 0.010114s ±0% | **0.002023s** ±0% | 0.005008s ±0% |
| float2string | **0.000992s** ±1% | 0.001069s ±1% | 0.005873s ±0% | 0.001011s ±1% | 0.002041s ±0% | 0.005536s ±0% | 0.016026s ±2% | 0.002585s ±0% |
| fibonacci recursive | 0.004172s ±1% | 0.003924s ±1% | 0.003923s ±1% | 0.004028s ±0% | 0.039559s ±2% | 0.006584s ±0% | 0.005772s ±0% | **0.003667s** ±2% |

#### Startup

| Runtime | hello world | artifact |
| --- | ---: | ---: |
| DAS interpreter | 0.018688s ±1% | - |
| DAS JIT | 0.088573s ±1% | - |
| DAS exe | 0.009618s ±63% | 50 KB |
| C++ | **0.003487s** ±5% | 33 KB |
| Zig | 0.003936s ±3% | 387 KB |
| Luau --codegen | 0.005425s ±3% | - |
| Luau | 0.005333s ±2% | - |
| Lua | 0.003882s ±9% | - |
| LuaJIT -joff | 0.003877s ±4% | - |
| LuaJIT | 0.003878s ±3% | - |
| Quirrel | 0.004493s ±1% | - |
| QuickJS | 0.004177s ±6% | - |
| Mono --interpreter | 0.024404s ±1% | 3 KB |
| Mono | 0.020672s ±4% | 3 KB |
| .NET | 0.026729s ±4% | 4 KB |

### Linux — AMD Ryzen 7 PRO 8700GE w/ Radeon 780M Graphics

Platform information:

- Captured from `profile_results_linux.json` on Sun Sep 13 19:38:21 2026
- Toolchain: Clang 19.1.7, daslang 0.6.4, LLVM 22.1.5
- Runtimes: Lua 5.5.1, LuaJIT 2.1.1787165859, Luau 0.736, Mono 6.8.0.105 (Debian 6.8.0.105+dfsg-3.3+deb12u1 Sat Jun 21 16:33:59 UTC 2025), .NET 10.0.400, QuickJS 2026-06-04, Quirrel 4.29.1, Zig 0.16.0

#### Interpreted

| Test | DAS interpreter | Luau | Lua | LuaJIT -joff | Quirrel | QuickJS | Mono --interpreter |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | **0.002510s** ±0% | 0.012423s ±0% | 0.068548s ±1% | 0.208152s ±3% | 0.018619s ±0% | 0.021312s ±1% | 0.018335s ±1% |
| dictionary | **0.011193s** ±25% | 0.019871s ±3% | 0.038771s ±0% | 0.011677s ±1% | 0.053417s ±0% | 0.047221s ±1% | 0.795195s ±2% |
| n-bodies | **0.009163s** ±2% | 0.028930s ±1% | 0.041577s ±4% | 0.025010s ±8% | 0.071261s ±0% | 0.082429s ±3% | 0.052171s ±5% |
| spectral norm | **0.023720s** ±1% | 0.032830s ±3% | 0.057832s ±2% | 0.037840s ±0% | 0.107082s ±9% | 0.091267s ±2% | 0.047752s ±4% |
| mandelbrot | **0.001791s** ±0% | 0.033439s ±1% | 0.056917s ±1% | 0.036648s ±2% | 0.005785s ±1% | 0.006346s ±1% | 0.013278s ±1% |
| exp loop | **0.006507s** ±10% | 0.011435s ±0% | 0.023746s ±3% | 0.010171s ±0% | 0.036572s ±0% | 0.031014s ±3% | 0.115838s ±11% |
| string2float | **0.000609s** ±1% | 0.001645s ±1% | 0.002789s ±1% | 0.003506s ±0% | 0.002354s ±1% | 0.003574s ±0% | 0.062370s ±1% |
| particles kinematics | **0.000950s** ±3% | 0.026647s ±0% | 0.039312s ±7% | 0.021500s ±0% | 0.025127s ±9% | 0.029979s ±0% | 0.038057s ±5% |
| queen | **0.000771s** ±2% | 0.001882s ±0% | 0.001483s ±3% | 0.000896s ±1% | 0.002017s ±1% | 0.002485s ±3% | 0.001459s ±4% |
| sort | **0.015450s** ±0% | 0.038680s ±0% | 0.045629s ±2% | 0.049885s ±3% | 0.112935s ±7% | 0.037570s ±0% | 0.128701s ±5% |
| interop host calls | **0.003740s** ±0% | 0.012167s ±0% | 0.015360s ±1% | 0.035712s ±2% | 0.038432s ±5% | 0.020744s ±1% | 0.092110s ±1% |
| primes loop | **0.026193s** ±0% | 0.151120s ±1% | 0.059061s ±1% | 0.044181s ±1% | 0.101679s ±1% | 0.112154s ±3% | 0.066296s ±18% |
| tree | 0.023617s ±1% | 0.024304s ±1% | 0.031137s ±7% | **0.018248s** ±1% | 0.069482s ±1% | 0.061180s ±0% | 0.020247s ±2% |
| fibonacci loop | **0.025913s** ±4% | 0.058040s ±1% | 0.053670s ±0% | 0.030923s ±1% | 0.043840s ±0% | 0.136506s ±0% | 0.062489s ±4% |
| float2string | **0.001222s** ±1% | 0.001780s ±0% | 0.013251s ±1% | 0.004558s ±1% | 0.005418s ±8% | 0.007688s ±1% | 0.110691s ±1% |
| fibonacci recursive | 0.048174s ±1% | 0.062497s ±1% | 0.048747s ±1% | **0.034842s** ±1% | 0.115255s ±4% | 0.088087s ±4% | 0.042388s ±38% |

#### AOT or JIT

| Test | DAS AOT | DAS JIT | C++ | Zig | Luau --codegen | LuaJIT | Mono | .NET |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| sha256 | 0.000102s ±1% | **0.000097s** ±0% | 0.000100s ±0% | 0.000116s ±3% | 0.009711s ±1% | 0.014532s ±1% | 0.000900s ±1% | 0.000369s ±3% |
| dictionary | **0.006535s** ±1% | 0.007957s ±2% | 0.028532s ±3% | 0.009451s ±2% | 0.016193s ±2% | 0.010711s ±3% | 0.080996s ±1% | 0.049417s ±0% |
| n-bodies | 0.001220s ±1% | 0.000913s ±0% | 0.001200s ±0% | **0.000698s** ±0% | 0.011198s ±0% | 0.003407s ±1% | 0.004049s ±0% | 0.001489s ±0% |
| spectral norm | 0.001831s ±2% | 0.001884s ±0% | 0.001802s ±0% | **0.001795s** ±0% | 0.006035s ±1% | 0.001979s ±0% | 0.004656s ±0% | 0.001853s ±1% |
| mandelbrot | 0.000455s ±0% | 0.000260s ±0% | 0.000297s ±0% | **0.000215s** ±0% | 0.026003s ±2% | 0.007487s ±1% | 0.003686s ±0% | 0.000264s ±0% |
| exp loop | 0.002365s ±4% | 0.002356s ±0% | 0.004158s ±0% | **0.002355s** ±0% | 0.004296s ±0% | 0.003547s ±0% | 0.005921s ±0% | 0.003363s ±0% |
| string2float | **0.000432s** ±1% | 0.000443s ±1% | 0.001480s ±1% | 0.000452s ±0% | 0.001483s ±1% | 0.003103s ±0% | 0.004739s ±1% | 0.001240s ±1% |
| particles kinematics | 0.000255s ±0% | 0.000231s ±0% | 0.000251s ±1% | **0.000144s** ±0% | 0.014606s ±0% | 0.009806s ±6% | 0.006597s ±0% | 0.000396s ±0% |
| queen | 0.000052s ±0% | **0.000027s** ±2% | 0.000030s ±1% | 0.000027s ±1% | 0.000590s ±4% | 0.000201s ±0% | 0.000088s ±20% | 0.000034s ±2% |
| sort | **0.001844s** ±0% | 0.004462s ±0% | 0.003398s ±0% | 0.006380s ±0% | 0.035917s ±2% | 0.050095s ±3% | 0.010698s ±1% | 0.004446s ±21% |
| interop host calls | 0.001177s ±0% | **0.000797s** ±0% | 0.000981s ±0% | 0.000981s ±0% | 0.012119s ±0% | 0.001563s ±0% | 0.034239s ±0% | 0.001379s ±0% |
| primes loop | 0.010364s ±0% | 0.012759s ±0% | 0.012769s ±0% | 0.012776s ±0% | 0.026936s ±0% | **0.009759s** ±0% | 0.012784s ±0% | 0.012756s ±0% |
| tree | 0.002088s ±0% | 0.002041s ±1% | 0.002091s ±0% | **0.002030s** ±0% | 0.017909s ±1% | 0.013494s ±1% | 0.003012s ±2% | 0.002804s ±1% |
| fibonacci loop | 0.001271s ±0% | **0.001269s** ±0% | 0.001272s ±0% | 0.001271s ±0% | 0.027063s ±1% | 0.004325s ±0% | 0.003833s ±0% | 0.001318s ±0% |
| float2string | 0.000951s ±1% | 0.001044s ±1% | 0.005569s ±3% | **0.000841s** ±0% | 0.001636s ±12% | 0.004168s ±0% | 0.018509s ±0% | 0.002177s ±1% |
| fibonacci recursive | 0.003073s ±0% | 0.002811s ±0% | 0.002811s ±0% | **0.002810s** ±0% | 0.041088s ±1% | 0.005552s ±0% | 0.005711s ±0% | 0.002992s ±3% |

#### Startup

| Runtime | hello world | artifact |
| --- | ---: | ---: |
| DAS interpreter | 0.026112s ±2% | - |
| DAS JIT | 0.113168s ±0% | - |
| DAS exe | 0.010580s ±4% | 17 KB |
| C++ | **0.002326s** ±6% | 16 KB |
| Zig | 0.002367s ±11% | 3.6 MB |
| Luau --codegen | 0.002637s ±15% | - |
| Luau | 0.002463s ±11% | - |
| Lua | 0.002366s ±7% | - |
| LuaJIT -joff | 0.002428s ±6% | - |
| LuaJIT | 0.002411s ±6% | - |
| Quirrel | 0.002744s ±14% | - |
| QuickJS | 0.002403s ±9% | - |
| Mono --interpreter | 0.012427s ±4% | 3 KB |
| Mono | 0.010765s ±3% | 3 KB |
| .NET | 0.019985s ±2% | 4 KB |

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

using System;
using System.Diagnostics;
using System.Timers;
using System.Collections.Generic;
using System.Numerics;

class HelloWorld {

    delegate void MyBlock();

    const int TOTAL_NUMBERS = 10000;
    const int TOTAL_TIMES = 100;

    static void profile ( int count, string category, MyBlock f ) {
        double minT = 1e+06;
        for ( int i = 0; i < count; i++ ) {
            Stopwatch stopwatch = Stopwatch.StartNew();
            f();
            stopwatch.Stop();
            double dt = stopwatch.Elapsed.TotalSeconds;
            minT = Math.Min(minT, dt);
        }
        Console.WriteLine($"\"{category}\", {minT}, {count}");
    }


    static float test_f2i(string[] nums)
    {
        float summ = 0.0f;
        for ( int i = 0; i != TOTAL_TIMES; ++i ) {
            foreach (var n in nums) {
                summ += float.Parse(n);
            }
        }
        return summ;
    }

    static float mk_float ( int i ) {
        return ((float)i) + ((float)i) / ((float)TOTAL_NUMBERS);
    }

    static string[] Init()
    {
        var nums = new string[TOTAL_NUMBERS];
        for ( int i = 0; i != TOTAL_NUMBERS; ++i ) {
            nums[i] = mk_float(i).ToString();
        }
        return nums;
    }

    public static bool IsRunningOnMono()
    {
        return Type.GetType("Mono.Runtime") != null;
    }

    static void Main() {
        var nums = Init();
        var count = 10;
        profile(count, "string2float", () => {
            test_f2i(nums);
        });
    }
}

using System;
using System.Diagnostics;
using System.Timers;
using System.Collections.Generic;
using System.Numerics;

class HelloWorld {

    delegate void MyBlock();

    const int TOTAL_NUMBERS = 10000;
    const int TOTAL_TIMES = 4;

    static void profile ( int count, string category, MyBlock f ) {
        long n = 1;
        double total = 0;
        while (true) {
            Stopwatch stopwatch = Stopwatch.StartNew();
            for ( long i = 0; i < n; i++ ) {
                f();
            }
            stopwatch.Stop();
            total = stopwatch.Elapsed.TotalSeconds;
            if (total >= 0.5 || n >= 1000000000L) break;
            double per = Math.Max(total / n, 1e-9);
            long next = (long)(0.5 / per * 1.2);
            next = Math.Min(next, 100L * n);
            next = Math.Max(next, n + 1);
            n = Math.Min(next, 1000000000L);
        }
        Console.WriteLine($"\"{category}\", {total / n}, {n}");
    }


    static int test_f2i(float[] nums)
    {
        int summ = 0;
        for ( int i = 0; i != TOTAL_TIMES; ++i ) {
            foreach (var n in nums) {
                summ += n.ToString().Length;
            }
        }
        return summ;
    }

    static float mk_float ( int i ) {
        return ((float)i) + ((float)i) / ((float)TOTAL_NUMBERS);
    }

    static float[] Init()
    {
        var nums = new float[TOTAL_NUMBERS];
        for ( int i = 0; i != TOTAL_NUMBERS; ++i ) {
            nums[i] = mk_float(i);
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
        profile(count, "float2string", () => {
            test_f2i(nums);
        });
    }
}

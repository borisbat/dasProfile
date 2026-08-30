using System;
using System.Diagnostics;
using System.Timers;
using System.Collections.Generic;

class HelloWorld {

    delegate void MyBlock();

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

    // Translated expLoop function
    public static double ExpLoop(int n)
    {
        double sum = 0.0;
        for (int i = 1; i <= n; i++)
        {
            sum += Math.Exp(1.0 / (1.0 + i));
        }
        return sum;
    }

    // Translated verifyExp function
    public static void VerifyExp(double f)
    {
        double t = 1e+06;
        double eps = 10.0;
        double q = Math.Abs(f - t);
        Debug.Assert(q < eps, "The result is outside the acceptable tolerance.");
    }

    static void Main() {
        profile(10, "exp loop", () => {
            double f4 = ExpLoop(1000000);
            VerifyExp(f4);
        });
    }
}

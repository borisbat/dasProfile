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

    public static int FibI(int n)
    {
        int last = 0;
        int cur = 1;
        n = n - 1; // Adjust because the loop starts with the second Fibonacci number
        while (n > 0)
        {
            n = n - 1;
            int tmp = cur;
            cur = last + cur;
            last = tmp;
        }
        return cur;
    }
    static void Main() {
        profile(10, "fibonacci loop", () => {
            int fi = FibI(6511134);
            Debug.Assert( fi==1781508648, "The result is incorrect.");
        });
    }
}


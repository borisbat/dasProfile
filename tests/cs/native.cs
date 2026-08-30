using System;
using System.Diagnostics;
using System.Timers;
using System.Collections.Generic;
using System.Runtime.InteropServices;

class HelloWorld {

    [DllImport ("addOne")]
    private static extern int AddOne ( int n );

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


    public static int testAdds()
    {
        int count = 0;
        for ( int i = 0; i < 1000000; i++ ) {
            count = AddOne(count);
        }
        return count;
    }

    static void Main() {
        profile(10, "native loop", () => {
            int count = testAdds();
            Debug.Assert(1000000==count);
        });
    }
}

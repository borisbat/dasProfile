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

    private static Random rng = new Random();

    static int [] makeRandomSequence(int n) {
        int [] src = new int[n];
        for (int i = 0; i < n; i++) {
            src[i] = rng.Next();
        }
        return src;
    }

    static void sortTable(int [] tab) {
        Array.Sort(tab, (a, b) => -a.CompareTo(b));
    }

    static void Main() {
        var tab = makeRandomSequence(100000);
        profile(10, "sort", () => {
            var tabb = (int[])tab.Clone();
            sortTable(tabb);
        });
    }
}

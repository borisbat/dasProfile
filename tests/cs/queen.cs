using System;
using System.Diagnostics;
using System.Timers;

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

    static int N = 8;

    // check whether position (n,c) is free from attacks
    static bool isplaceok ( int[] a, int n, int c ) {
        for ( int i = 0; i < n; i++ ) {
            if ( a[i] == c || a[i] - i == c - n || a[i] + i == c + n ) {
                return false;
            }
        }
        return true;
    }

    static int solutions = 0;

    static void addqueen ( int[] a, int n ) {
        if ( n == N ) {
            solutions++;
        } else {
            for ( int c = 0; c < N; c++ ) {
                if ( isplaceok(a, n, c) ) {
                    a[n] = c;
                    addqueen(a, n + 1);
                }
            }
        }
    }

    static void test () {
        solutions = 0;
        int[] a = new int[N];
        addqueen(a, 0);
    }

    static void Main() {
        profile(10, "queen", () => {
            test();
            Debug.Assert(solutions == 92, "The result is not correct.");
        });
    }
}

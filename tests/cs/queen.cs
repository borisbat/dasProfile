using System;
using System.Diagnostics;
using System.Timers;

class HelloWorld {

    delegate void MyBlock();

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

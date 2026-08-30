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

    // Check if a number is prime
    public static bool IsPrime(int n)
    {
        for (int i = 2; i < n; i++)
        {
            if (n % i == 0)
            {
                return false;
            }
        }
        return true;
    }

    // Count prime numbers up to n
    public static int Primes(int n)
    {
        int count = 0;
        for (int i = 2; i <= n; i++)
        {
            if (IsPrime(i))
            {
                count++;
            }
        }
        return count;
    }

    static void Main() {
        profile(10, "primes loop", () => {
            double f4 = Primes(14000);
            Debug.Assert(f4 == 1652, "The result is not correct.");
        });
    }
}

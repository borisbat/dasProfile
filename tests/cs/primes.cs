using System;
using System.Diagnostics;
using System.Timers;
using System.Collections.Generic;

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

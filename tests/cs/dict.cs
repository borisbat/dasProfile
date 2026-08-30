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

    public static void MakeRandomSequence(ref string[] src)
    {
        int n = 500000;
        uint mod = (uint)n;
        src = new string[n]; // Resizing the array in C#
        for (int i = 0; i < n; i++)
        {
            uint num = (271828183u ^ (uint)(i * 119)) % mod;
            src[i] = num.ToString();
        }
    }

    public static int Dict(string[] src)
    {
        var tab = new Dictionary<string, int>();
        int maxOcc = 1;
        foreach (var s in src)
        {
            if ( tab.TryGetValue(s, out int val) )
            {
                val ++;
                maxOcc = Math.Max(val, maxOcc);
            }
            else
            {
                tab[s] = 1;
            }

        }
        return maxOcc;
    }

    static void Main() {
        int occ = 0;
        profile(10, "dictionary", () => {
            string[] sequence = null;
            MakeRandomSequence(ref sequence);
            int maxOccurrence = Dict(sequence);
            occ += maxOccurrence;
        });
        Debug.Assert(occ>13);
    }
}

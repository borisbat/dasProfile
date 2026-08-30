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

    static int A(int i, int j) {
        return ((i + j) * (i + j + 1) / 2 + i + 1);
    }

    static double dot(double [] v, double [] u, int n) {
        int i;
        double sum = 0;
        for (i = 0; i < n; i++)
            sum += v[i] * u[i];
        return sum;
    }

    static void mult_Av(double [] v, double [] output, int n) {
        int i, j;
        double sum;
        for (i = 0; i < n; i++) {
            for (sum = j = 0; j < n; j++)
                sum += v[j] / A(i, j);
            output[i] = sum;
        }
    }

    static void mult_Atv(double [] v, double [] output, int n) {
        int i, j;
        double sum;
        for (i = 0; i < n; i++) {
            for (sum = j = 0; j < n; j++)
                sum += v[j] / A(j, i);
            output[i] = sum;
        }
    }

    static double [] tmp;
    static void mult_AtAv(double [] v, double [] output, int n) {
        mult_Av(v, tmp, n);
        mult_Atv(tmp, output, n);
    }

    static double testSnorm(int n) {
        double[] u = new double[n];
        double[] v = new double[n];
        tmp = new double[n];
        int i;
        for (i = 0; i < n; i++)
            u[i] = 1;
        for (i = 0; i < 2; i++) {
            mult_AtAv(u, v, n);
            mult_AtAv(v, u, n);
        }
        double result = Math.Sqrt(dot(u, v, n) / dot(v, v, n));
        tmp = null;
        u = null;
        v = null;
        return result;
    }


    static void Main() {
        profile(10, "spectral norm", () => {
            testSnorm(500);
        });
    }
}

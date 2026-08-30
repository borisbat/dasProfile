using System;
using System.Diagnostics;
using System.Timers;
using System.Collections.Generic;

public class HelloWorld {

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

    public class Node {
        public int X, Y;
        public Node Left, Right;

        public Node(int x, int y)
        {
            X = x;
            Y = y;
        }
    }

    private static Random rng = new Random();

    // Merge two subtrees
    private static Node Merge(Node lower, Node greater)
    {
        if (lower == null) return greater;
        if (greater == null) return lower;

        if (lower.Y < greater.Y)
        {
            lower.Right = Merge(lower.Right, greater);
            return lower;
        }
        else
        {
            greater.Left = Merge(lower, greater.Left);
            return greater;
        }
    }

    // Overloaded Merge to handle three subtrees
    private static Node Merge(Node lower, Node equal, Node greater) =>
        Merge(Merge(lower, equal), greater);

    // Split the tree
    private static void Split(Node orig, out Node lower, out Node greaterOrEqual, int value)
    {
        if (orig == null)
        {
            lower = null;
            greaterOrEqual = null;
        }
        else if (orig.X < value)
        {
            lower = orig;
            Split(orig.Right, out lower.Right, out greaterOrEqual, value);
        }
        else
        {
            greaterOrEqual = orig;
            Split(orig.Left, out lower, out greaterOrEqual.Left, value);
        }
    }

    // Overloaded Split to handle equal case
    private static void Split(Node orig, out Node lower, out Node equal, out Node greater, int value)
    {
        Node equalOrGreater;
        Split(orig, out lower, out equalOrGreater, value);
        Split(equalOrGreater, out equal, out greater, value + 1);
    }

    // Check if a value exists in the tree
    public static bool HasValue(ref Node mRoot, int x)
    {
        Node lower, equal, greater;
        Split(mRoot, out lower, out equal, out greater, x);
        bool result = equal != null;
        mRoot = Merge(lower, equal, greater);
        return result;
    }

    // Insert a value into the tree
    public static void Insert(ref Node mRoot, int x)
    {
        Node lower, equal, greater;
        Split(mRoot, out lower, out equal, out greater, x);
        if (equal == null) equal = new Node(x, rng.Next());
        mRoot = Merge(lower, equal, greater);
    }

    // Remove a value from the tree
    public static void Erase(ref Node mRoot, int x)
    {
        Node lower, equal, greater;
        Split(mRoot, out lower, out equal, out greater, x);
        mRoot = Merge(lower, greater);
        // In C#, garbage collection handles memory cleanup, so no manual delete is needed
    }

    static int MainTreeApp()
    {
        Node tree = null;
        int cur = 5;
        int res = 0;
        for (int i = 1; i < 20000; i++)
        {
            int a = i % 3;
            cur = (cur * 57 + 43) % 10007;
            if (a == 0)
            {
                Insert(ref tree, cur);
            }
            else if (a == 1)
            {
                Erase(ref tree, cur);
            }
            else if (a == 2)
            {
                res += HasValue(ref tree, cur) ? 1 : 0;
            }
        }
        return res;
    }

    static void Main() {
        profile(10, "tree", () => {
            var res = MainTreeApp();
            Debug.Assert(res != 1652, "The result is not correct.");
        });
    }
}

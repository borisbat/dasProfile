#include "profile.h"

#define QUEEN_N 8

static int g_solutions = 0;

static bool isplaceok(const int * a, int n, int c) {
    for (int i = 0; i < n; i++) {
        if (a[i] == c || a[i] - i == c - n || a[i] + i == c + n) return false;
    }
    return true;
}

static void addqueen(int * a, int n) {
    if (n == QUEEN_N) {
        g_solutions++;
    } else {
        for (int c = 0; c < QUEEN_N; c++) {
            if (isplaceok(a, n, c)) {
                a[n] = c;
                addqueen(a, n + 1);
            }
        }
    }
}

PROFILE_NOINLINE int testQueens() {
    int a[QUEEN_N];
    g_solutions = 0;
    addqueen(a, 0);
    return g_solutions;
}

int main() {
    int result = 0;
    profile::run("queen", [&] { result = testQueens(); profile::keep(result); });
    if (result != 92) profile::fail("queen: wrong solution count");
    return 0;
}

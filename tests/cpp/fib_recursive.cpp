#include "profile.h"

static volatile int depth = 31;

PROFILE_NOINLINE int fibR(int n) {
    if (n < 2) return n;
    return fibR(n - 1) + fibR(n - 2);
}

int main() {
    int result = 0;
    profile::run("fibonacci recursive", [&] { result = fibR(depth); profile::keep(result); });
    if (result != 1346269) profile::fail("fibonacci recursive: wrong result");
    return 0;
}

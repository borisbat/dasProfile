#include "profile.h"

static volatile int count = 6511134;

PROFILE_NOINLINE int fibI(int n) {
    int last = 1;
    int cur = 0;
    for (int i = 0; i < n; ++i) {
        int tmp = cur;
        cur = (int) ((unsigned) cur + (unsigned) last);
        last = tmp;
    }
    return cur;
}

int main() {
    int result = 0;
    profile::run("fibonacci loop", [&] { result = fibI(count); profile::keep(result); });
    if (result != 1781508648) profile::fail("fibonacci loop: wrong result");
    return 0;
}

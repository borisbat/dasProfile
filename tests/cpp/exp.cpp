#include "profile.h"
#include <cmath>

// every kernel takes its size through a volatile read, so the optimizer makes a real call per
// repetition instead of hoisting a pure call out of the harness loop
static volatile int count = 1000000;

PROFILE_NOINLINE float expLoop(int n) {
    float ret = 0;
    for (int i = 0; i < n; ++i) ret += expf(1.f / (1.f + i));
    return ret;
}

int main() {
    float result = 0;
    profile::run("exp loop", [&] { result = expLoop(count); profile::keep(result); });
    // f32 accumulation: past 2^20 every term rounds to 1.0, so the sum lands within a few ulps of 1e6
    if (fabsf(result - 1e6f) >= 16.f) profile::fail("exp loop: sum is off");
    return 0;
}

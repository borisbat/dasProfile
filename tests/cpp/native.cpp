#include "profile.h"

// AddOne lives in tests/cs/addOne/addOne.c, compiled as its own object without LTO:
// a real call across the C ABI on every iteration, as the other lanes' hosts make.
extern "C" int AddOne(int a);

static volatile int count = 1000000;

PROFILE_NOINLINE int testNativeLoop(int n) {
    int acc = 0;
    for (int i = 0; i < n; i++) acc = AddOne(acc);
    return acc;
}

int main() {
    int result = 0;
    profile::run("interop host calls", [&] { result = testNativeLoop(count); profile::keep(result); });
    if (result != 1000000) profile::fail("interop host calls: wrong count");
    return 0;
}

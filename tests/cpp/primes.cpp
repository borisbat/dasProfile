#include "profile.h"

static volatile int limit = 14000;

PROFILE_NOINLINE bool isprime(int n) {
    for (int i = 2; i != n; ++i) {
        if (n % i == 0) return false;
    }
    return true;
}

PROFILE_NOINLINE int primes(int n) {
    int count = 0;
    for (int i = 2; i != n + 1; ++i) {
        if (isprime(i)) ++count;
    }
    return count;
}

int main() {
    int result = 0;
    profile::run("primes loop", [&] { result = primes(limit); profile::keep(result); });
    if (result != 1652) profile::fail("primes loop: wrong count");
    return 0;
}

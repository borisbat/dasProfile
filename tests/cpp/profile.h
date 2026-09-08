// The harness every C++ test shares: the same budget loop as config.das's bench() and
// profile.lua - one call calibrates, each batch under the budget regrows the count from what
// it measured (1.2x the projection, at most 100x), and the batch that meets the budget is
// reported as `"category", seconds-per-run, runs` on stdout.
#pragma once
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>

#if defined(_MSC_VER)
#define PROFILE_NOINLINE __declspec(noinline)
#else
#define PROFILE_NOINLINE __attribute__((noinline))
#endif

namespace profile {

inline double now_seconds() {
    using clock = std::chrono::steady_clock;
    return std::chrono::duration<double>(clock::now().time_since_epoch()).count();
}

template <typename F>
void run(const char * category, F && f) {
    const double budget = 0.5;
    const int64_t max_reps = 1000000000;
    int64_t n = 1;
    double total = 0.0;
    for (;;) {
        const double t0 = now_seconds();
        for (int64_t i = 0; i < n; ++i) f();
        total = now_seconds() - t0;
        if (total >= budget || n >= max_reps) break;
        const double per = total / double(n) > 1e-9 ? total / double(n) : 1e-9;
        int64_t next = int64_t(budget / per * 1.2);
        if (next > 100 * n) next = 100 * n;
        if (next < n + 1) next = n + 1;
        n = next < max_reps ? next : max_reps;
    }
    printf("\"%s\", %.9f, %lld\n", category, total / double(n), (long long) n);
    fflush(stdout);
}

// a kernel's result lands in a volatile sink: without it, a pure kernel's result is dead until
// the last repetition and the optimizer deletes every call but that one, so the budget loop
// spins on nothing
template <typename T>
inline void keep(const T & value) {
    static volatile T sink;
    sink = value;
}

[[noreturn]] inline void fail(const char * message) {
    fprintf(stderr, "%s\n", message);
    exit(1);
}

}  // namespace profile

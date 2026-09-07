#include "profile.h"
#include <algorithm>
#include <cstring>
#include <vector>

// das's uint_noise_1D (dag_uint_noise.h): the same 100000 keys table-sort.das sorts
static uint32_t uint_noise1D(int position, uint32_t seed) {
    uint32_t mangled = (uint32_t) position;
    mangled *= 0x68E31DA4u;
    mangled += seed;
    mangled ^= (mangled >> 8);
    mangled += 0xB5297A4Du;
    mangled ^= (mangled << 8);
    mangled *= 0x1B56C4E9u;
    mangled ^= (mangled >> 8);
    return mangled;
}

PROFILE_NOINLINE void testTableSort(std::vector<int32_t> & tab) {
    std::sort(tab.begin(), tab.end(), [](int32_t a, int32_t b) { return a > b; });
}

int main() {
    const int n = 100000;
    std::vector<int32_t> src(n);
    for (int i = 0; i < n; i++) src[i] = (int32_t) uint_noise1D(i, 1u);
    std::vector<int32_t> work(n);
    profile::run("sort", [&] {
        memcpy(work.data(), src.data(), n * sizeof(int32_t));
        testTableSort(work);
    });
    for (int i = 1; i < n; i++) {
        if (work[i - 1] < work[i]) profile::fail("sort: not descending");
    }
    return 0;
}

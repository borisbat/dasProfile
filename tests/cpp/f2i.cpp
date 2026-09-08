#include "profile.h"
#include <cmath>
#include <cstring>
#include <string>
#include <vector>

static const int TOTAL_NUMBERS = 10000;
static volatile int times = 4;

static float mk_float(int i) { return float(i) + float(i) / float(TOTAL_NUMBERS); }

PROFILE_NOINLINE float test_f2i(const std::vector<std::string> & nums, int rounds) {
    float summ = 0.0f;
    for (int i = 0; i != rounds; ++i) {
        for (const auto & s : nums) summ += float(atof(s.c_str()));
    }
    return summ;
}

int main() {
    std::vector<std::string> nums(TOTAL_NUMBERS);
    char buf[64];
    for (int i = 0; i < TOTAL_NUMBERS; i++) {
        snprintf(buf, sizeof(buf), "%.9g", mk_float(i));
        nums[i] = buf;
    }
    float reference = 0.0f;
    for (int j = 0; j < 4; j++) {
        for (int i = 0; i < TOTAL_NUMBERS; i++) reference += mk_float(i);
    }
    float result = 0.0f;
    profile::run("string2float", [&] { result = test_f2i(nums, times); profile::keep(result); });
    if (result != reference) profile::fail("string2float: sum differs from the reference");
    return 0;
}

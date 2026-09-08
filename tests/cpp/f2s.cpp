#include "profile.h"
#include <cstring>
#include <vector>

static const int TOTAL_NUMBERS = 10000;
static volatile int times = 4;

static float mk_float(int i) { return float(i) + float(i) / float(TOTAL_NUMBERS); }

PROFILE_NOINLINE int32_t test_f2s(const std::vector<float> & nums, int rounds) {
    int32_t summ = 0;
    char buffer[128];
    for (int i = 0; i != rounds; ++i) {
        for (float f : nums) {
            snprintf(buffer, sizeof(buffer), "%f", f);
            summ += (int32_t) strlen(buffer);
        }
    }
    return summ;
}

int main() {
    std::vector<float> nums(TOTAL_NUMBERS);
    for (int i = 0; i < TOTAL_NUMBERS; i++) nums[i] = mk_float(i);
    int32_t result = 0;
    profile::run("float2string", [&] { result = test_f2s(nums, times); profile::keep(result); });
    return result > 0 ? 0 : 1;
}

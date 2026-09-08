#include "profile.h"
#include <cstring>
#include <string>
#include <unordered_map>
#include <vector>

// the keys as C strings and the FNV-1a hash the old module used, so the kernel is the one the
// C++ column always measured, not std::hash over std::string
struct dictKeyEqual {
    bool operator()(const char * lhs, const char * rhs) const { return lhs == rhs || strcmp(lhs, rhs) == 0; }
};
struct dictKeyHash {
    uint64_t operator()(const char * str) const {
        uint64_t h = 14695981039346656037ull;
        for (const unsigned char * p = (const unsigned char *) str; *p; ++p) h = (h ^ *p) * 1099511628211ull;
        return h;
    }
};

static std::vector<std::string> storage;
static std::vector<char *> keys;

static void makeRandomSequence() {
    const int n = 500000;
    storage.resize(n);
    keys.resize(n);
    for (int i = 0; i < n; i++) {
        unsigned num = (271828183u ^ (unsigned) (i * 119)) % (unsigned) n;
        storage[i] = std::to_string(num);
        keys[i] = storage[i].data();
    }
}

PROFILE_NOINLINE int testDict(const std::vector<char *> & src) {
    std::unordered_map<char *, int32_t, dictKeyHash, dictKeyEqual> tab;
    int maxOcc = 0;
    for (char * key : src) {
        int v = ++tab[key];
        if (v > maxOcc) maxOcc = v;
    }
    return maxOcc;
}

int main() {
    makeRandomSequence();
    int result = 0;
    profile::run("dictionary", [&] { result = testDict(keys); profile::keep(result); });
    return result > 0 ? 0 : 1;
}

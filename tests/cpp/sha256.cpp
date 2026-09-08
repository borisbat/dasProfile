#include "profile.h"
#include <cstring>

static const uint32_t sha256_k[64] = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

static inline uint32_t rotr32(uint32_t x, int n) { return (x >> n) | (x << (32 - n)); }

PROFILE_NOINLINE static void sha256_digest_block(const uint32_t * __restrict data, uint32_t * __restrict hash) {
    uint32_t digest[64];
    for (int j = 0; j < 16; ++j) digest[j] = data[j];
    for (int j = 16; j < 64; ++j) {
        uint32_t v0 = digest[j - 15];
        uint32_t s0 = rotr32(v0, 7) ^ rotr32(v0, 18) ^ (v0 >> 3);
        uint32_t v1 = digest[j - 2];
        uint32_t s1 = rotr32(v1, 17) ^ rotr32(v1, 19) ^ (v1 >> 10);
        digest[j] = digest[j - 16] + s0 + digest[j - 7] + s1;
    }
    uint32_t a = hash[0], b = hash[1], c = hash[2], d = hash[3];
    uint32_t e = hash[4], f = hash[5], g = hash[6], h = hash[7];
    for (int i = 0; i < 64; ++i) {
        uint32_t s0 = rotr32(a, 2) ^ rotr32(a, 13) ^ rotr32(a, 22);
        uint32_t maj = (a & b) ^ (a & c) ^ (b & c);
        uint32_t t2 = s0 + maj;
        uint32_t s1 = rotr32(e, 6) ^ rotr32(e, 11) ^ rotr32(e, 25);
        uint32_t ch = (e & f) ^ ((~e) & g);
        uint32_t t1 = h + s1 + ch + sha256_k[i] + digest[i];
        h = g; g = f; f = e; e = d + t1;
        d = c; c = b; b = a; a = t1 + t2;
    }
    hash[0] += a; hash[1] += b; hash[2] += c; hash[3] += d;
    hash[4] += e; hash[5] += f; hash[6] += g; hash[7] += h;
}

static void sha256(const uint8_t * msg, size_t len, char * out65) {
    static const uint32_t init[8] = { 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19 };
    uint32_t hash[8];
    memcpy(hash, init, sizeof(hash));
    const uint32_t * data = (const uint32_t *) msg;
    for (size_t i = 0; i < len / 64; ++i) sha256_digest_block(data + i * 16, hash);
    snprintf(out65, 65, "%08x%08x%08x%08x%08x%08x%08x%08x", hash[0], hash[1], hash[2], hash[3], hash[4], hash[5], hash[6], hash[7]);
}

static volatile int rounds = 32;

int main() {
    alignas(4) uint8_t input[1024];
    memset(input, '.', sizeof(input));
    char hex[65];
    profile::run("sha256", [&] { for (int i = 0; i < rounds; i++) sha256(input, sizeof(input), hex); });
    sha256(input, sizeof(input), hex);
    if (strcmp(hex, "8adcaee60bb05a9964a1df12d2f007adcb8f3fa20ff7d1ecfde0a2ac301ff412") != 0) profile::fail("sha256: wrong digest");
    return 0;
}

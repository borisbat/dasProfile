//-file:plus-string

function rrotate(value, bits) {
    return (((value >>> bits) | (value << (32 - bits))) & 0xffffffff);
}

let primes = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
];

let hexDigits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"];

function hex8(value) {
    local result = "";
    for (local shift = 28; shift >= 0; shift -= 4) {
        result += hexDigits[(value >>> shift) & 0xf];
    }
    return result;
}

function readInt32(buffer, index) {
    return (((buffer[index] << 24) | (buffer[index + 1] << 16) | (buffer[index + 2] << 8) | buffer[index + 3]) & 0xffffffff);
}

function digestBlock(msg, index, hash) {
    local digest = array(64, 0);
    for (local j = 0; j < 16; ++j) {
        digest[j] = readInt32(msg, index + j * 4);
    }
    for (local j = 16; j < 64; ++j) {
        local v0 = digest[j - 15];
        local s0 = (rrotate(v0, 7) ^ rrotate(v0, 18) ^ (v0 >>> 3)) & 0xffffffff;
        local v1 = digest[j - 2];
        local s1 = (rrotate(v1, 17) ^ rrotate(v1, 19) ^ (v1 >>> 10)) & 0xffffffff;
        digest[j] = (digest[j - 16] + s0 + digest[j - 7] + s1) & 0xffffffff;
    }

    local a = hash[0];
    local b = hash[1];
    local c = hash[2];
    local d = hash[3];
    local e = hash[4];
    local f = hash[5];
    local g = hash[6];
    local h = hash[7];

    for (local i = 0; i < 64; ++i) {
        local s0 = (rrotate(a, 2) ^ rrotate(a, 13) ^ rrotate(a, 22)) & 0xffffffff;
        local maj = ((a & b) ^ (a & c) ^ (b & c)) & 0xffffffff;
        local t2 = (s0 + maj) & 0xffffffff;
        local s1 = (rrotate(e, 6) ^ rrotate(e, 11) ^ rrotate(e, 25)) & 0xffffffff;
        local ch = ((e & f) ^ ((~e) & g)) & 0xffffffff;
        local t1 = (h + s1 + ch + primes[i] + digest[i]) & 0xffffffff;

        h = g;
        g = f;
        f = e;
        e = (d + t1) & 0xffffffff;
        d = c;
        c = b;
        b = a;
        a = (t1 + t2) & 0xffffffff;
    }

    hash[0] = (hash[0] + a) & 0xffffffff;
    hash[1] = (hash[1] + b) & 0xffffffff;
    hash[2] = (hash[2] + c) & 0xffffffff;
    hash[3] = (hash[3] + d) & 0xffffffff;
    hash[4] = (hash[4] + e) & 0xffffffff;
    hash[5] = (hash[5] + f) & 0xffffffff;
    hash[6] = (hash[6] + g) & 0xffffffff;
    hash[7] = (hash[7] + h) & 0xffffffff;
}

function sha256(msg) {
    local hash = [
        0x6a09e667,
        0xbb67ae85,
        0x3c6ef372,
        0xa54ff53a,
        0x510e527f,
        0x9b05688c,
        0x1f83d9ab,
        0x5be0cd19
    ];

    for (local i = 0; i < msg.len(); i += 64) {
        digestBlock(msg, i, hash);
    }

    local result = "";
    foreach (value in hash) {
        result += hex8(value & 0xffffffff);
    }
    return result;
}

local input = array(1024, 46);

local profile_it
local clock_func
try {
  profile_it = getroottable()["loadfile"]("profile.nut")()
  if (profile_it == null)
    throw "no loadfile"
} catch(e) profile_it = require("profile.nut")

try {
    clock_func = getroottable()["clock"]
} catch (e) {
    clock_func = require("datetime").clock
}

local res = "";
local start = clock_func();
print("\"sha256\", " + profile_it(10, function() {
    for (local i = 0; i < 1024; ++i) {
        res = sha256(input);
    }
}) + ", 10\n");
local elapsed = clock_func() - start;

assert(sha256(input) == "8adcaee60bb05a9964a1df12d2f007adcb8f3fa20ff7d1ecfde0a2ac301ff412");
print("\t" + (1.0 / (elapsed / 10.0)) + " mb/sec\n");
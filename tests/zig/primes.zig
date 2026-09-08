const std = @import("std");
const profile = @import("profile.zig");

var result: i32 = 0;
var limit: i32 = 14000;

noinline fn isprime(n: i32) bool {
    var i: i32 = 2;
    while (i < n) : (i += 1) {
        if (@rem(n, i) == 0) return false;
    }
    return true;
}

noinline fn primes(n: i32) i32 {
    var count: i32 = 0;
    var i: i32 = 2;
    while (i <= n) : (i += 1) {
        if (isprime(i)) count += 1;
    }
    return count;
}

fn run(_: void) void {
    result = primes(@as(*volatile i32, &limit).*);
    std.mem.doNotOptimizeAway(result);
}

pub fn main(init: std.process.Init) !void {
    try profile.profile(init, "primes loop", run, {});
    if (result != 1652) profile.fail("primes loop: wrong count");
}

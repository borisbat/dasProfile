const std = @import("std");
const profile = @import("profile.zig");

var result: f32 = 0;
var count: u32 = 1_000_000;

noinline fn expLoop(n: u32) f32 {
    var sum: f32 = 0;
    var i: u32 = 0;
    while (i < n) : (i += 1) {
        sum += @exp(1.0 / (1.0 + @as(f32, @floatFromInt(i))));
    }
    return sum;
}

fn run(_: void) void {
    result = expLoop(@as(*volatile u32, &count).*);
    std.mem.doNotOptimizeAway(result);
}

pub fn main(init: std.process.Init) !void {
    try profile.profile(init, "exp loop", run, {});
    // f32 accumulation: past 2^20 every term rounds to 1.0, so the sum lands within a few ulps of 1e6
    if (@abs(result - 1.0e6) >= 16.0) profile.fail("exp loop: sum is off");
}

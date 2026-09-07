const std = @import("std");
const profile = @import("profile.zig");

var result: i32 = 0;
var depth: i32 = 31;

noinline fn fibR(n: i32) i32 {
    if (n < 2) return n;
    return fibR(n - 1) + fibR(n - 2);
}

fn run(_: void) void {
    result = fibR(@as(*volatile i32, &depth).*);
    std.mem.doNotOptimizeAway(result);
}

pub fn main(init: std.process.Init) !void {
    try profile.profile(init.io, "fibonacci recursive", run, {});
    if (result != 1346269) profile.fail("fibonacci recursive: wrong result");
}

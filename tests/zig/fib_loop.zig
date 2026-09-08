const std = @import("std");
const profile = @import("profile.zig");

var result: i32 = 0;
var count: u32 = 6511134;

noinline fn fibI(n: u32) i32 {
    var last: i32 = 1;
    var cur: i32 = 0;
    var i: u32 = 0;
    while (i < n) : (i += 1) {
        const tmp = cur;
        cur +%= last;
        last = tmp;
    }
    return cur;
}

fn run(_: void) void {
    result = fibI(@as(*volatile u32, &count).*);
    std.mem.doNotOptimizeAway(result);
}

pub fn main(init: std.process.Init) !void {
    try profile.profile(init, "fibonacci loop", run, {});
    if (result != 1781508648) profile.fail("fibonacci loop: wrong result");
}

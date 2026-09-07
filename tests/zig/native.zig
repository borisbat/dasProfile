const std = @import("std");
const profile = @import("profile.zig");

// AddOne lives in tests/cs/addOne/addOne.c, compiled as its own object without LTO:
// a real call across the C ABI on every iteration, as the other lanes' hosts make.
extern fn AddOne(n: c_int) c_int;

var result: c_int = 0;
var count: u32 = 1_000_000;

noinline fn testAdds(n: u32) c_int {
    var acc: c_int = 0;
    var i: u32 = 0;
    while (i < n) : (i += 1) {
        acc = AddOne(acc);
    }
    return acc;
}

fn run(_: void) void {
    result = testAdds(@as(*volatile u32, &count).*);
    std.mem.doNotOptimizeAway(result);
}

pub fn main(init: std.process.Init) !void {
    try profile.profile(init, "interop host calls", run, {});
    if (result != 1_000_000) profile.fail("interop host calls: wrong count");
}

const std = @import("std");
const profile = @import("profile.zig");

const total_numbers = 10000;
const total_times = 4;
var nums: [total_numbers]f32 = undefined;
var result: usize = 0;
var times: u32 = total_times;

fn mkFloat(i: usize) f32 {
    const f: f32 = @floatFromInt(i);
    return f + f / @as(f32, total_numbers);
}

noinline fn f2s(rounds: u32) usize {
    var sum: usize = 0;
    var buf: [64]u8 = undefined;
    for (0..rounds) |_| {
        for (nums) |f| {
            const s = std.fmt.bufPrint(&buf, "{d}", .{f}) catch unreachable;
            sum += s.len;
        }
    }
    return sum;
}

fn run(_: void) void {
    result = f2s(@as(*volatile u32, &times).*);
    std.mem.doNotOptimizeAway(result);
}

pub fn main(init: std.process.Init) !void {
    for (0..total_numbers) |i| nums[i] = mkFloat(i);
    try profile.profile(init.io, "float2string", run, {});
}

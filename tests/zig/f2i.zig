const std = @import("std");
const profile = @import("profile.zig");

const total_numbers = 10000;
const total_times = 4;
var nums: [total_numbers][]const u8 = undefined;
var storage: [total_numbers][32]u8 = undefined;
var result: f32 = 0;
var times: u32 = total_times;

fn mkFloat(i: usize) f32 {
    const f: f32 = @floatFromInt(i);
    return f + f / @as(f32, total_numbers);
}

noinline fn f2i(rounds: u32) f32 {
    var sum: f32 = 0;
    for (0..rounds) |_| {
        for (nums) |s| {
            sum += std.fmt.parseFloat(f32, s) catch 0;
        }
    }
    return sum;
}

fn run(_: void) void {
    result = f2i(@as(*volatile u32, &times).*);
    std.mem.doNotOptimizeAway(result);
}

pub fn main(init: std.process.Init) !void {
    for (0..total_numbers) |i| {
        nums[i] = try std.fmt.bufPrint(&storage[i], "{d}", .{mkFloat(i)});
    }
    var reference: f32 = 0;
    for (0..total_times) |_| {
        for (0..total_numbers) |i| reference += mkFloat(i);
    }
    try profile.profile(init.io, "string2float", run, {});
    if (result != reference) profile.fail("string2float: sum differs from the reference");
}

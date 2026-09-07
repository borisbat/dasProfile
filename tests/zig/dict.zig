const std = @import("std");
const profile = @import("profile.zig");

const n = 500000;
var keys: [n][]const u8 = undefined;
var storage: [n][12]u8 = undefined;
var table: std.StringHashMapUnmanaged(i32) = .empty;
var gpa: std.mem.Allocator = undefined;
var result: i32 = 0;

fn makeRandomSequence() !void {
    for (0..n) |i| {
        const num: u32 = (271828183 ^ (@as(u32, @intCast(i)) *% 119)) % n;
        keys[i] = try std.fmt.bufPrint(&storage[i], "{d}", .{num});
    }
}

noinline fn dict() !i32 {
    table.clearRetainingCapacity();
    var maxOcc: i32 = 0;
    for (keys) |s| {
        const gop = try table.getOrPut(gpa, s);
        if (!gop.found_existing) gop.value_ptr.* = 0;
        gop.value_ptr.* += 1;
        maxOcc = @max(maxOcc, gop.value_ptr.*);
    }
    return maxOcc;
}

fn run(_: void) void {
    result = dict() catch profile.fail("dictionary: out of memory");
}

pub fn main(init: std.process.Init) !void {
    gpa = init.gpa;
    try makeRandomSequence();
    try profile.profile(init.io, "dictionary", run, {});
}

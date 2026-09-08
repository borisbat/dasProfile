const std = @import("std");
const profile = @import("profile.zig");

const n = 100000;
var src: [n]i32 = undefined;
var work: [n]i32 = undefined;

// das's uint_noise_1D (dag_uint_noise.h): the same 100000 keys table-sort.das sorts
fn uintNoise1D(position: i32, seed: u32) u32 {
    var mangled: u32 = @bitCast(position);
    mangled *%= 0x68E31DA4;
    mangled +%= seed;
    mangled ^= (mangled >> 8);
    mangled +%= 0xB5297A4D;
    mangled ^= (mangled << 8);
    mangled *%= 0x1B56C4E9;
    mangled ^= (mangled >> 8);
    return mangled;
}

fn greaterThan(_: void, a: i32, b: i32) bool {
    return a > b;
}

noinline fn sortTable(tab: []i32) void {
    std.sort.pdq(i32, tab, {}, greaterThan);
}

fn run(_: void) void {
    @memcpy(&work, &src);
    sortTable(&work);
}

pub fn main(init: std.process.Init) !void {
    for (0..n) |i| src[i] = @bitCast(uintNoise1D(@intCast(i), 1));
    try profile.profile(init, "sort", run, {});
    for (1..n) |i| {
        if (work[i - 1] < work[i]) profile.fail("sort: not descending");
    }
}

const std = @import("std");
const profile = @import("profile.zig");

const n = 500;
var tmp: [n]f64 = undefined;
var result: f64 = 0;
var rounds: u32 = 2;

inline fn a(i: usize, j: usize) f64 {
    return @floatFromInt((((i + j) * (i + j + 1)) >> 1) + i + 1);
}

fn dot(v: *const [n]f64, u: *const [n]f64) f64 {
    var sum: f64 = 0;
    for (v, u) |x, y| sum += x * y;
    return sum;
}

fn multAv(v: *const [n]f64, out: *[n]f64) void {
    for (0..n) |i| {
        var sum: f64 = 0;
        for (0..n) |j| sum += v[j] / a(i, j);
        out[i] = sum;
    }
}

fn multAtv(v: *const [n]f64, out: *[n]f64) void {
    for (0..n) |i| {
        var sum: f64 = 0;
        for (0..n) |j| sum += v[j] / a(j, i);
        out[i] = sum;
    }
}

fn multAtAv(v: *const [n]f64, out: *[n]f64) void {
    multAv(v, &tmp);
    multAtv(&tmp, out);
}

noinline fn test_(iterations: u32) f64 {
    var u: [n]f64 = undefined;
    var v: [n]f64 = undefined;
    for (&u) |*x| x.* = 1.0;
    for (0..iterations) |_| {
        multAtAv(&u, &v);
        multAtAv(&v, &u);
    }
    return @sqrt(dot(&u, &v) / dot(&v, &v));
}

fn run(_: void) void {
    result = test_(@as(*volatile u32, &rounds).*);
    std.mem.doNotOptimizeAway(result);
}

pub fn main(init: std.process.Init) !void {
    try profile.profile(init.io, "spectral norm", run, {});
    if (@abs(result - 1.274224153) >= 1e-5) profile.fail("spectral norm: wrong result");
}

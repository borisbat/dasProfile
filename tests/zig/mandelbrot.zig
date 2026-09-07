const std = @import("std");
const profile = @import("profile.zig");

var result: i32 = 0;
var grid: u32 = 64;

fn level(cx: f32, cy: f32) i32 {
    var l: i32 = 0;
    var zx = cx;
    var zy = cy;
    while (@sqrt(zx * zx + zy * zy) < 2.0 and l < 255) {
        const nx = zx * zx - zy * zy;
        const ny = zx * zy + zy * zx;
        zx = nx + cx;
        zy = ny + cy;
        l += 1;
    }
    return l - 1;
}

noinline fn test_(n: u32) i32 {
    const xmin: f32 = -2.0;
    const xmax: f32 = 2.0;
    const ymin: f32 = -2.0;
    const ymax: f32 = 2.0;
    const nf: f32 = @floatFromInt(n);
    const dx = (xmax - xmin) / nf;
    const dy = (ymax - ymin) / nf;
    var s: i32 = 0;
    var x = xmin;
    var i: u32 = 0;
    while (i < n) : (i += 1) {
        var y = ymin;
        var j: u32 = 0;
        while (j < n) : (j += 1) {
            s += level(x, y);
            y += dy;
        }
        x += dx;
    }
    return s;
}

fn run(_: void) void {
    result = test_(@as(*volatile u32, &grid).*);
    std.mem.doNotOptimizeAway(result);
}

pub fn main(init: std.process.Init) !void {
    try profile.profile(init.io, "mandelbrot", run, {});
}

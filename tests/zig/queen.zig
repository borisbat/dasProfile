const std = @import("std");
const profile = @import("profile.zig");

const n_queens = 8;
var solutions: i32 = 0;

fn isplaceok(a: *const [n_queens]i32, n: usize, c: i32) bool {
    for (0..n) |i| {
        const ai = a[i];
        const d: i32 = @intCast(n - i);
        if (ai == c or ai == c - d or ai == c + d) return false;
    }
    return true;
}

fn addqueen(a: *[n_queens]i32, n: usize) void {
    var c: i32 = 0;
    while (c < n_queens) : (c += 1) {
        if (isplaceok(a, n, c)) {
            a[n] = c;
            if (n == n_queens - 1) {
                solutions += 1;
            } else {
                addqueen(a, n + 1);
            }
        }
    }
}

fn run(_: void) void {
    solutions = 0;
    var a: [n_queens]i32 = undefined;
    addqueen(&a, 0);
    std.mem.doNotOptimizeAway(solutions);
}

pub fn main(init: std.process.Init) !void {
    try profile.profile(init, "queen", run, {});
    if (solutions != 92) profile.fail("queen: wrong solution count");
}

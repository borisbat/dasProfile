// The harness every zig test shares: the same budget loop as config.das's bench() and
// profile.lua - one call calibrates, each batch under the budget regrows the count from what
// it measured (1.2x the projection, at most 100x), and the batch that meets the budget is
// reported as `"category", seconds-per-run, runs` on stdout.
const std = @import("std");
const Io = std.Io;

pub const budget_s: f64 = 0.5;
pub const max_reps: i64 = 1_000_000_000;

fn nowNs(io: Io) f64 {
    const t = Io.Clock.Timestamp.now(io, .awake);
    return @floatFromInt(t.raw.nanoseconds);
}

pub fn profile(io: Io, category: []const u8, comptime f: anytype, ctx: anytype) !void {
    var n: i64 = 1;
    var total: f64 = 0;
    while (true) {
        const t0 = nowNs(io);
        var i: i64 = 0;
        while (i < n) : (i += 1) f(ctx);
        total = (nowNs(io) - t0) / 1e9;
        if (total >= budget_s or n >= max_reps) break;
        const per = @max(total / @as(f64, @floatFromInt(n)), 1e-9);
        var next: i64 = @intFromFloat(budget_s / per * 1.2);
        next = @min(next, 100 * n);
        next = @max(next, n + 1);
        n = @min(next, max_reps);
    }
    var buf: [256]u8 = undefined;
    var w: Io.File.Writer = .init(.stdout(), io, &buf);
    try w.interface.print("\"{s}\", {d:.9}, {d}\n", .{ category, total / @as(f64, @floatFromInt(n)), n });
    try w.interface.flush();
}

pub fn fail(msg: []const u8) noreturn {
    std.debug.print("{s}\n", .{msg});
    std.process.exit(1);
}

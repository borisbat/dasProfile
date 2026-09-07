const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    var buf: [64]u8 = undefined;
    var w: Io.File.Writer = .init(.stdout(), init.io, &buf);
    try w.interface.print("hello\n", .{});
    try w.interface.flush();
}

const std = @import("std");
const profile = @import("profile.zig");

const Vec3 = @Vector(4, f32); // a float3 in a 16-byte lane, as das and the C++ module keep it

const Object = struct {
    position: Vec3,
    velocity: Vec3,
};

const count = 50000;
var objects: [count]Object = undefined;

noinline fn simI(objs: []Object) void {
    for (objs) |*obj| {
        obj.position += obj.velocity;
    }
}

noinline fn sim2I(objs: []Object, times: u32) void {
    var i: u32 = 0;
    while (i < times) : (i += 1) simI(objs);
}

fn run(_: void) void {
    sim2I(&objects, 10);
}

pub fn main(init: std.process.Init) !void {
    for (&objects, 0..) |*obj, i| {
        const f: f32 = @floatFromInt(i);
        obj.position = .{ f, f + 1.0, f + 2.0, 0.0 };
        obj.velocity = .{ 1.0, 2.0, 3.0, 0.0 };
    }
    try profile.profile(init, "particles kinematics", run, {});
}

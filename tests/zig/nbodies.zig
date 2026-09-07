const std = @import("std");
const profile = @import("profile.zig");

const pi: f32 = 3.141592653589793;
const solar_mass: f32 = 4.0 * pi * pi;
const days_per_year: f32 = 365.24;

const Planet = struct { x: f32, y: f32, z: f32, pad: f32, vx: f32, vy: f32, vz: f32, mass: f32 };

const nbodies = 5;
var bodies = [nbodies]Planet{
    .{ .x = 0, .y = 0, .z = 0, .pad = 0, .vx = 0, .vy = 0, .vz = 0, .mass = solar_mass },
    .{ .x = 4.84143144246472090e+00, .y = -1.16032004402742839e+00, .z = -1.03622044471123109e-01, .pad = 0, .vx = 1.66007664274403694e-03 * days_per_year, .vy = 7.69901118419740425e-03 * days_per_year, .vz = -6.90460016972063023e-05 * days_per_year, .mass = 9.54791938424326609e-04 * solar_mass },
    .{ .x = 8.34336671824457987e+00, .y = 4.12479856412430479e+00, .z = -4.03523417114321381e-01, .pad = 0, .vx = -2.76742510726862411e-03 * days_per_year, .vy = 4.99852801234917238e-03 * days_per_year, .vz = 2.30417297573763929e-05 * days_per_year, .mass = 2.85885980666130812e-04 * solar_mass },
    .{ .x = 1.28943695621391310e+01, .y = -1.51111514016986312e+01, .z = -2.23307578892655734e-01, .pad = 0, .vx = 2.96460137564761618e-03 * days_per_year, .vy = 2.37847173959480950e-03 * days_per_year, .vz = -2.96589568540237556e-05 * days_per_year, .mass = 4.36624404335156298e-05 * solar_mass },
    .{ .x = 1.53796971148509165e+01, .y = -2.59193146099879641e+01, .z = 1.79258772950371181e-01, .pad = 0, .vx = 2.68067772490389322e-03 * days_per_year, .vy = 1.62824170038242295e-03 * days_per_year, .vz = -9.51592254519715870e-05 * days_per_year, .mass = 5.15138902046611451e-05 * solar_mass },
};

fn advance(bs: *[nbodies]Planet, dt: f32) void {
    for (0..nbodies) |i| {
        const b = &bs[i];
        for (i + 1..nbodies) |j| {
            const b2 = &bs[j];
            const dx = b.x - b2.x;
            const dy = b.y - b2.y;
            const dz = b.z - b2.z;
            const distanced = dx * dx + dy * dy + dz * dz;
            const distance = @sqrt(distanced);
            const mag = dt / (distanced * distance);
            b.vx -= dx * b2.mass * mag;
            b.vy -= dy * b2.mass * mag;
            b.vz -= dz * b2.mass * mag;
            b2.vx += dx * b.mass * mag;
            b2.vy += dy * b.mass * mag;
            b2.vz += dz * b.mass * mag;
        }
    }
    for (bs) |*b| {
        b.x += dt * b.vx;
        b.y += dt * b.vy;
        b.z += dt * b.vz;
    }
}

fn offsetMomentum(bs: *[nbodies]Planet) void {
    var px: f32 = 0;
    var py: f32 = 0;
    var pz: f32 = 0;
    for (bs) |b| {
        px += b.vx * b.mass;
        py += b.vy * b.mass;
        pz += b.vz * b.mass;
    }
    bs[0].vx = -px / solar_mass;
    bs[0].vy = -py / solar_mass;
    bs[0].vz = -pz / solar_mass;
}

noinline fn steps(count: u32) void {
    var i: u32 = 0;
    while (i < count) : (i += 1) advance(&bodies, 0.01);
}

fn run(_: void) void {
    steps(33000);
}

pub fn main(init: std.process.Init) !void {
    offsetMomentum(&bodies);
    try profile.profile(init, "n-bodies", run, {});
}

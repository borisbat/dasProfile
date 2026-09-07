const std = @import("std");
const profile = @import("profile.zig");

// a treap keyed on x with random priorities y, split/merge as tree.das and the C++ module do
const Node = struct {
    x: i32,
    y: i32,
    left: ?*Node = null,
    right: ?*Node = null,
};

var gpa: std.mem.Allocator = undefined;
var seed: [4]i32 = .{ 1, 1, 1, 1 };
var result: i32 = 0;

// daslib/random's random_big_int: a 4-lane LCG, two 15-bit halves joined
fn randomBigInt() i32 {
    inline for (0..4) |i| seed[i] = 214013 *% seed[i] +% 2531011;
    const lo = (seed[0] >> 16) & 0x7fff;
    const hi = (seed[1] >> 16) & 0x7fff;
    return lo + (hi << 15);
}

fn merge(lower: ?*Node, greater: ?*Node, out: *?*Node) void {
    if (lower == null) {
        out.* = greater;
    } else if (greater == null) {
        out.* = lower;
    } else if (lower.?.y < greater.?.y) {
        out.* = lower;
        merge(lower.?.right, greater, &lower.?.right);
    } else {
        out.* = greater;
        merge(lower, greater.?.left, &greater.?.left);
    }
}

fn split(orig: ?*Node, lower: *?*Node, greaterOrEqual: *?*Node, value: i32) void {
    if (orig == null) {
        lower.* = null;
        greaterOrEqual.* = null;
    } else if (orig.?.x < value) {
        lower.* = orig;
        split(orig.?.right, &orig.?.right, greaterOrEqual, value);
    } else {
        greaterOrEqual.* = orig;
        split(orig.?.left, lower, &orig.?.left, value);
    }
}

fn hasValue(root: *?*Node, x: i32) bool {
    var lower: ?*Node = null;
    var equal: ?*Node = null;
    var greater: ?*Node = null;
    var equalOrGreater: ?*Node = null;
    split(root.*, &lower, &equalOrGreater, x);
    split(equalOrGreater, &equal, &greater, x + 1);
    const res = equal != null;
    var t: ?*Node = null;
    merge(lower, equal, &t);
    merge(t, greater, root);
    return res;
}

fn insert(root: *?*Node, x: i32) void {
    var lower: ?*Node = null;
    var equal: ?*Node = null;
    var greater: ?*Node = null;
    var equalOrGreater: ?*Node = null;
    split(root.*, &lower, &equalOrGreater, x);
    split(equalOrGreater, &equal, &greater, x + 1);
    if (equal == null) {
        const node = gpa.create(Node) catch profile.fail("tree: out of memory");
        node.* = .{ .x = x, .y = randomBigInt() };
        equal = node;
    }
    var t: ?*Node = null;
    merge(lower, equal, &t);
    merge(t, greater, root);
}

fn erase(root: *?*Node, x: i32) void {
    var lower: ?*Node = null;
    var equal: ?*Node = null;
    var greater: ?*Node = null;
    var equalOrGreater: ?*Node = null;
    split(root.*, &lower, &equalOrGreater, x);
    split(equalOrGreater, &equal, &greater, x + 1);
    merge(lower, greater, root);
    if (equal) |node| gpa.destroy(node);
}

fn freeTree(node: ?*Node) void {
    if (node) |nd| {
        freeTree(nd.left);
        freeTree(nd.right);
        gpa.destroy(nd);
    }
}

noinline fn mainTreeNode() i32 {
    var tree: ?*Node = null;
    var cur: i32 = 5;
    var res: i32 = 0;
    var i: i32 = 1;
    while (i < 20000) : (i += 1) {
        const mode = @rem(i, 3);
        cur = @rem(cur * 57 + 43, 10007);
        if (mode == 0) {
            insert(&tree, cur);
        } else if (mode == 1) {
            erase(&tree, cur);
        } else if (hasValue(&tree, cur)) {
            res += 1;
        }
    }
    freeTree(tree);
    return res;
}

fn run(_: void) void {
    result = mainTreeNode();
}

pub fn main(init: std.process.Init) !void {
    gpa = init.gpa;
    try profile.profile(init, "tree", run, {});
}

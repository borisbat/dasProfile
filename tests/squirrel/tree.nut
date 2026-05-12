//-file:plus-string

let math = require("math")

math.srand(1)

function merge(lower, greater) {
    if (!lower) {
        return greater;
    }

    if (!greater) {
        return lower;
    }

    if (lower.y < greater.y) {
        lower.right = merge(lower.right, greater);
        return lower;
    } else {
        greater.left = merge(lower, greater.left);
        return greater;
    }
}

function split_binary(orig, value) {
    if (!orig) {
        return [null, null];
    }

    if (orig.x < value) {
        local splitPair = split_binary(orig.right, value);
        orig.right = splitPair[0];
        return [orig, splitPair[1]];
    } else {
        local splitPair = split_binary(orig.left, value);
        orig.left = splitPair[1];
        return [splitPair[0], orig];
    }
}

function merge3(lower, equal, greater) {
    return merge(merge(lower, equal), greater);
}

function split(orig, value) {
    local lowerEqualGreater = split_binary(orig, value);
    local equalGreater = split_binary(lowerEqualGreater[1], value + 1);
    return [lowerEqualGreater[0], equalGreater[0], equalGreater[1]];
}

function tree_has_value(tree, x) {
    local splitTree = split(tree.root, x);
    local res = splitTree[1] != null;
    tree.root = merge3(splitTree[0], splitTree[1], splitTree[2]);
    return res;
}

function tree_insert(tree, x) {
    local splitTree = split(tree.root, x);
    if (!splitTree[1]) {
        splitTree[1] = {
            x = x,
            y = math.rand(),
            left = null,
            right = null
        };
    }
    tree.root = merge3(splitTree[0], splitTree[1], splitTree[2]);
}

function tree_erase(tree, x) {
    local splitTree = split(tree.root, x);
    tree.root = merge(splitTree[0], splitTree[2]);
}

function testTree() {
    local tree = {
        root = null
    };
    local cur = 5;
    local res = 0;

    for (local i = 1; i < 1000000; ++i) {
        local a = i % 3;
        cur = (cur * 57 + 43) % 10007;
        if (a == 0) {
            tree_insert(tree, cur);
        } else if (a == 1) {
            tree_erase(tree, cur);
        } else if (a == 2) {
            if (tree_has_value(tree, cur)) {
                res += 1;
            }
        }
    }
    return res;
}

local profile_it
try {
  profile_it = getroottable()["loadfile"]("profile.nut")()
  if (profile_it == null)
    throw "no loadfile"
} catch(e) profile_it = require("profile.nut")

print("\"tree\", " + profile_it(10, testTree) + ", 10\n");
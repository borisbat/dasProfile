--Copyright and license: https://github.com/frol/completely-unscientific-benchmarks

local function merge(lower, greater)
    if not lower then
        return greater
    end

    if not greater then
        return lower
    end

    if lower.y < greater.y then
        lower.right = merge(lower.right, greater)
        return lower
    else
        greater.left = merge(lower, greater.left)
        return greater
    end
end

local function split_binary(orig, value)
    if not orig then
        return nil, nil
    end

    if orig.x < value then
        local origRight, origLeft = split_binary(orig.right, value)
        orig.right = origRight
        return orig, origLeft
    else
        local origRight, origLeft = split_binary(orig.left, value)
        orig.left = origLeft
        return origRight, orig
    end
end

local function merge3(lower, equal, greater)
    return merge(merge(lower, equal), greater)
end

local function split(orig, value)
    local lower, equalGreater = split_binary(orig, value)
    local equal, greater = split_binary(equalGreater, value + 1)
    return lower, equal, greater
end

local function tree_has_value(tree, x)
    local lower, equal, greater = split(tree.root, x)
    local res = equal ~= nil
    tree.root = merge3(lower, equal, greater)
    return res
end

local function tree_insert(tree, x)
    local lower, equal, greater = split(tree.root, x)
    if not equal then
        equal = {
            x = x,
            y = math.random(0, 2^30),
            left = nil,
            right = nil
        }
    end
    tree.root = merge3(lower, equal, greater)
end

local function tree_erase(tree, x)
    local lower, equal, greater = split(tree.root, x)
    tree.root = merge(lower, greater)
end

PROFILE_N = 1

function profile_it(profiles, fn)
  local n = 1
  local total
  while true do
    local start = os.clock()
    for i = 1, n do fn() end
    total = os.clock() - start
    if total >= 0.5 or n >= 1000000000 then break end
    local per = math.max(total / n, 1e-9)
    local nxt = math.floor(0.5 / per * 1.2)
    nxt = math.min(nxt, 100 * n)
    nxt = math.max(nxt, n + 1)
    n = math.min(nxt, 1000000000)
  end
  PROFILE_N = n
  return total / n
end

local function main()
    local tree = {
        root = nil
    }
    local cur = 5
    local res = 0

    for i = 1, 20000 do
        local a = i % 3
        cur = (cur * 57 + 43) % 10007
        if a == 0 then
            tree_insert(tree, cur)
        elseif a == 1 then
            tree_erase(tree, cur)
        elseif a == 2 then
            if tree_has_value(tree, cur) then
                res = res + 1
            end
        end
    end
    --print(res)
end

print(string.format("\"tree\", %.8f, %d", profile_it(10, function () main() end), PROFILE_N))

local function testAdds()
    local count = 0
    for i = 1, 1000000 do
        count = AddOne(count)
    end
    return count
end

function test()
    local count = testAdds()
    if count ~= 1000000 then print("failed\n", count) end
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

print(string.format("\"interop host calls\", %.8f, %d", profile_it(10, test), PROFILE_N))

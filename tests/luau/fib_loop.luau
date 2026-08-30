local function fibI(n:number)
    local last : number = 0
    local cur : number = 1
    n = n - 1
    while (n > 0)
    do
        n = n - 1
        local tmp : number = cur
        cur = last + cur
        last = tmp
    end
    return cur
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

print(string.format("\"fibonacci loop\", %.8f, %d", profile_it(10, function () fibI(6511134) end), PROFILE_N))


local function dict(tab, src)
  table.clear(tab)
  local max = 0
  for i,l in src do
    local tabL = (tab[l] or 0) + 1
    tab[l] = tabL
    max = math.max(max, tabL)
  end
  return max
end

local tab = {}
local src = {}
local n = 500000
local modn = n
for i = 0, n - 1 do
    --local num = math.random(1,modn) * 271828183
    local num = bit32.bxor(271828183, i*119)%modn
  table.insert(src, string.format("%d", num))
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

print(string.format("\"dictionary\", %.8f, %d", profile_it(10, function () dict(tab, src); end), PROFILE_N))

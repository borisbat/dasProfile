-- Public domain
--
function create_rng(seed)
  local Rm, Rj = {}, 1
  for i=1,17 do Rm[i] = 0 end
  for i=17,1,-1 do
    seed = (seed*9069) % (2^31)
    Rm[i] = seed
  end
  return function()
      local j, m = Rj, Rm
      local h = j - 5
      if h < 1 then h = h + 17 end
      local k = m[h] - m[j]
      if k < 0 then k = k + 2147483647 end
      m[j] = k
      if j < 17 then Rj = j + 1 else Rj = 1 end
      return k
  end
end

rand = create_rng(12345)

n = tonumber(arg and arg[1]) or 100000
t = {}
for i = 1,n do
	t[i] = rand()
end

function cmp(lhs, rhs)
    return lhs > rhs
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

print(string.format("\"sort\", %.8f, %d", profile_it(10, function () table.sort(table.clone(t), cmp) end), PROFILE_N))
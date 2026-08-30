	TOTAL_NUMBERS = 10000
	TOTAL_TIMES = 4

    function mk_float(i)
        return i + (i/TOTAL_NUMBERS)
    end

    function update(nums)
        local summ = 0
        for i = 1, TOTAL_TIMES do
            for i,num in ipairs(nums) do
                summ = summ + #(tostring(num))
            end
        end
        return summ
    end

  nums = {}
  for i = 1, TOTAL_NUMBERS do
    table.insert(nums, mk_float(i))
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

print(string.format("\"float2string\", %.8f, %d", profile_it(10, function () update(nums) end), PROFILE_N))


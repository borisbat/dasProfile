local function testAdds()
    local count = 0
    for i = 1, 10000000 do
        count = AddOne(count)
    end
    return count
end

function test()
    local count = testAdds()
    if count ~= 10000000 then print("failed\n", count) end
end

function profile_it(profiles, fn)
  local res
  for i = 1, profiles do
    local start = os.clock()
    fn()
    local measured = os.clock() - start
    if i == 1 or res > measured then res = measured end
  end
  return res
end

print(string.format("\"native loop\", %.8f, 10", profile_it(10, test)))

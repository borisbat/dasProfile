local addOne
if jit then
    local ffi = require("ffi")
    ffi.cdef[[
    int addOne(int);
    ]]
    local lib = ffi.load(jit.os == "Windows" and "addOne.dll"
        or (jit.os == "OSX" and "./libaddOne.dylib" or "./libaddOne.so"))
    addOne = lib.addOne
else
    addOne = profile_native.addOne
end

local function testAdds()
    local count = 0
    for i = 1, 10000000 do
        count = addOne(count)
    end
    return count
end

function test()
    local count = testAdds()
    if count ~= 10000000 then print("failed\n", count) end
end

loadfile("profile.lua")()

io.write(string.format("\"native loop\", %.8f, %d\n", profile_it(PROFILE_RUNS, test), PROFILE_RUNS))

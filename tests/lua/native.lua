local ffi = require("ffi")
ffi.cdef[[
int addOne(int);
]]

local addOne = ffi.load(jit.os == "Windows" and "addOne.dll"
    or (jit.os == "OSX" and "./libaddOne.dylib" or "./libaddOne.so"))

local function testAdds()
    local count = 0
    for i = 1, 10000000 do
        count = addOne.addOne(count)
    end
    return count
end

loadfile("profile.lua")()

io.write(string.format("\"native loop\", %.8f, %d\n", profile_it(PROFILE_RUNS, function () testAdds() end), PROFILE_RUNS))


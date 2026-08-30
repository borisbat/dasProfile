PROFILE_RUNS = 10

local clock = os.clock
if profile_native and profile_native.clock then
  clock = profile_native.clock
elseif jit and jit.os == "Windows" then
  local ffi = require("ffi")
  ffi.cdef[[
    int QueryPerformanceCounter(int64_t * count);
    int QueryPerformanceFrequency(int64_t * freq);
  ]]
  local freq = ffi.new("int64_t[1]")
  ffi.C.QueryPerformanceFrequency(freq)
  local scale = 1.0 / tonumber(freq[0])
  local count = ffi.new("int64_t[1]")
  clock = function()
    ffi.C.QueryPerformanceCounter(count)
    return tonumber(count[0]) * scale
  end
end

function profile_it(profiles, fn)
  local res
  for i = 1, profiles do
    local start = clock()
    fn()
    local measured = clock() - start
    if i == 1 or res > measured then res = measured end
  end
  return res
end

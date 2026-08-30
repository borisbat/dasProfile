//-file:plus-string
local clock_func
try {
  clock_func = getroottable()["clock"]
}
catch (e) {
  clock_func = require("datetime").clock
}

function profile_it(cnt, f) {
  local n = 1
  local total = 0.0
  while (true) {
    local start = clock_func()
    for (local i = 0; i < n; ++i) f()
    total = clock_func() - start
    if (total >= 0.5 || n >= 1000000000) break
    local per = total / n
    if (per < 1e-9) per = 1e-9
    local nxt = (0.5 / per * 1.2).tointeger()
    if (nxt > 100 * n) nxt = 100 * n
    if (nxt < n + 1) nxt = n + 1
    if (nxt > 1000000000) nxt = 1000000000
    n = nxt
  }
  ::PROFILE_N <- n
  return total / n
}

return profile_it
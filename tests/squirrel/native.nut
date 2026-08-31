function testAdds()
{
    local count = 0;
    for (local i = 0; i < 1000000; ++i)
        count = ::AddOne(count)
    return count
}

local profile_it
try {
  profile_it = getroottable()["loadfile"]("profile.nut")()
  if (profile_it == null)
    throw "no loadfile"
} catch(e) profile_it = require("profile.nut")

print("\"interop host calls\", " + profile_it(10, function() {testAdds()}) + ", " + ::PROFILE_N + "\n");

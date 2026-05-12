//-file:plus-string

function level(cx, cy) {
    local l = 0;
    local zx = cx;
    local zy = cy;
    while ((zx * zx + zy * zy) < 4.0 && l < 255) {
        local nextX = zx * zx - zy * zy + cx;
        local nextY = zx * zy + zy * zx + cy;
        zx = nextX;
        zy = nextY;
        ++l;
    }
    return l - 1;
}

function test() {
    local xmin = -2.0;
    local xmax = 2.0;
    local ymin = -2.0;
    local ymax = 2.0;
    local N = 64;
    local dx = (xmax - xmin) / N;
    local dy = (ymax - ymin) / N;
    local sum = 0;
    local x = xmin;
    for (local i = 0; i < N; ++i) {
        local y = ymin;
        for (local j = 0; j < N; ++j) {
            sum += level(x, y);
            y += dy;
        }
        x += dx;
    }
    return sum;
}

local profile_it
try {
  profile_it = getroottable()["loadfile"]("profile.nut")()
  if (profile_it == null)
    throw "no loadfile"
} catch(e) profile_it = require("profile.nut")

print("\"mandelbrot\", " + profile_it(20, test) + ", 20\n");
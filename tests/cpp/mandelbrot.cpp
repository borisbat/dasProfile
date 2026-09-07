#include "profile.h"
#include <cmath>

static volatile int grid = 64;

static int level(float cx, float cy) {
    int l = 0;
    float zx = cx, zy = cy;
    while (sqrtf(zx * zx + zy * zy) < 2.0f && l < 255) {
        float nx = zx * zx - zy * zy;
        float ny = zx * zy + zy * zx;
        zx = nx + cx;
        zy = ny + cy;
        l++;
    }
    return l - 1;
}

PROFILE_NOINLINE int test(int n) {
    const float xmin = -2.0f, xmax = 2.0f, ymin = -2.0f, ymax = 2.0f;
    const float dx = (xmax - xmin) / float(n);
    const float dy = (ymax - ymin) / float(n);
    int s = 0;
    float x = xmin;
    for (int i = 0; i < n; i++) {
        float y = ymin;
        for (int j = 0; j < n; j++) {
            s += level(x, y);
            y += dy;
        }
        x += dx;
    }
    return s;
}

int main() {
    int result = 0;
    profile::run("mandelbrot", [&] { result = test(grid); profile::keep(result); });
    return result == 0 ? 1 : 0;
}

#include "profile.h"
#include <cmath>

#define pi 3.141592653589793f
#define solar_mass (4 * pi * pi)
#define days_per_year 365.24f

struct planet { float x, y, z; float pad; float vx, vy, vz; float mass; };

static void advance(int nbodies, planet * __restrict bodies, float dt) {
    for (int i = 0; i < nbodies; i++) {
        planet * b = &bodies[i];
        for (int j = i + 1; j < nbodies; j++) {
            planet * b2 = &bodies[j];
            float dx = b->x - b2->x;
            float dy = b->y - b2->y;
            float dz = b->z - b2->z;
            float distanced = dx * dx + dy * dy + dz * dz;
            float distance = sqrtf(distanced);
            float mag = dt / (distanced * distance);
            b->vx -= dx * b2->mass * mag;
            b->vy -= dy * b2->mass * mag;
            b->vz -= dz * b2->mass * mag;
            b2->vx += dx * b->mass * mag;
            b2->vy += dy * b->mass * mag;
            b2->vz += dz * b->mass * mag;
        }
    }
    for (int i = 0; i < nbodies; i++) {
        planet * b = &bodies[i];
        b->x += dt * b->vx;
        b->y += dt * b->vy;
        b->z += dt * b->vz;
    }
}

static void offset_momentum(int nbodies, planet * bodies) {
    float px = 0.0f, py = 0.0f, pz = 0.0f;
    for (int i = 0; i < nbodies; i++) {
        px += bodies[i].vx * bodies[i].mass;
        py += bodies[i].vy * bodies[i].mass;
        pz += bodies[i].vz * bodies[i].mass;
    }
    bodies[0].vx = -px / solar_mass;
    bodies[0].vy = -py / solar_mass;
    bodies[0].vz = -pz / solar_mass;
}

#define NBODIES 5
static planet bodies[NBODIES] = {
    { 0, 0, 0, 0, 0, 0, 0, solar_mass },
    { 4.84143144246472090e+00f, -1.16032004402742839e+00f, -1.03622044471123109e-01f, 0.f,
      1.66007664274403694e-03f * days_per_year, 7.69901118419740425e-03f * days_per_year, -6.90460016972063023e-05f * days_per_year,
      9.54791938424326609e-04f * solar_mass },
    { 8.34336671824457987e+00f, 4.12479856412430479e+00f, -4.03523417114321381e-01f, 0.f,
      -2.76742510726862411e-03f * days_per_year, 4.99852801234917238e-03f * days_per_year, 2.30417297573763929e-05f * days_per_year,
      2.85885980666130812e-04f * solar_mass },
    { 1.28943695621391310e+01f, -1.51111514016986312e+01f, -2.23307578892655734e-01f, 0.f,
      2.96460137564761618e-03f * days_per_year, 2.37847173959480950e-03f * days_per_year, -2.96589568540237556e-05f * days_per_year,
      4.36624404335156298e-05f * solar_mass },
    { 1.53796971148509165e+01f, -2.59193146099879641e+01f, 1.79258772950371181e-01f, 0.f,
      2.68067772490389322e-03f * days_per_year, 1.62824170038242295e-03f * days_per_year, -9.51592254519715870e-05f * days_per_year,
      5.15138902046611451e-05f * solar_mass }
};

static volatile int steps = 33000;

PROFILE_NOINLINE void testNBodiesS(int n) {
    for (int i = 0; i != n; ++i) advance(NBODIES, bodies, 0.01f);
}

int main() {
    offset_momentum(NBODIES, bodies);
    profile::run("n-bodies", [&] { testNBodiesS(steps); });
    return 0;
}

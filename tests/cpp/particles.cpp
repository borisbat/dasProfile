#include "profile.h"
#include <vector>

// a float3 in a 16-byte lane, as das and the old module kept it
struct alignas(16) Vec3 { float x, y, z, w; };
struct Object { Vec3 position, velocity; };

static volatile int times = 10;

PROFILE_NOINLINE void particlesI(std::vector<Object> & objects, int count) {
    for (int i = 0; i != count; ++i) {
        for (auto & obj : objects) {
            obj.position.x += obj.velocity.x;
            obj.position.y += obj.velocity.y;
            obj.position.z += obj.velocity.z;
        }
    }
}

int main() {
    std::vector<Object> objects(50000);
    for (size_t i = 0; i < objects.size(); ++i) {
        float f = float(i);
        objects[i].position = { f, f + 1.f, f + 2.f, 0.f };
        objects[i].velocity = { 1.f, 2.f, 3.f, 0.f };
    }
    profile::run("particles kinematics", [&] { particlesI(objects, times); });
    return 0;
}

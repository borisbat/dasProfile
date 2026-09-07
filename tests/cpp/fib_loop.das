options gen2
options _comment_hygiene = true

require testProfile
include ../../config.das

[export]
def main {
    var f4 = 0
    bench("fibonacci loop") <| $() {
        f4 = testProfile::testFibI(6511134)
    }
    assert(f4 == 1781508648)
}

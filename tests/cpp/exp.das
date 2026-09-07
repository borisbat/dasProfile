options gen2
options _comment_hygiene = true

require testProfile
include ../../config.das

def verifyExp(f) {
    let t = 1e+06
    let eps = 10.
    let q = abs(f - t)
    assert(q < eps)
}

[export]
def main {
    var f4 = 0.
    bench("exp loop") <| $() {
        f4 = testProfile::testExpLoop(1000000)
    }
    verifyExp(f4)
}

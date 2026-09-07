options gen2
options _comment_hygiene = true

require testProfile
include ../../config.das

[export]
def main {
    var f5 = 0
    bench("fibonacci recursive") <| $() {
        f5 = testProfile::testFibR(31)
    }
    assert(f5 == 1346269)
}

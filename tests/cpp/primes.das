options gen2
options _comment_hygiene = true

require testProfile
include ../../config.das

[export]
def main {
    var f3 = 0
    bench("primes loop") <| $() {
        f3 = testProfile::testPrimes(14000)
    }
    assert(f3 == 1652)
}

options gen2
options _comment_hygiene = true

require testProfile
include ../../config.das

[export]
def main {
    let input <- [for (i in range(1024)); uint8('.')]
    bench("sha256") <| $() {
        for (i in range(32)) {
            testProfile::testSha256(input)
        }
    }
    verify(testProfile::testSha256(input) == "8adcaee60bb05a9964a1df12d2f007adcb8f3fa20ff7d1ecfde0a2ac301ff412")
}

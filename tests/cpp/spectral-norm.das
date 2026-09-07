options gen2
options _comment_hygiene = true

require testProfile
include ../../config.das

[export]
def main {
    bench("spectral norm") <| $() {
        testSnorm()
    }
}

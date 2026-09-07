options gen2
options _comment_hygiene = true

require testProfile
include ../../config.das

[export]
def main {
    testNBodiesInit()
    bench("n-bodies") <| $() {
        testNBodiesS(33000)
    }
}

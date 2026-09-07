options gen2
options _comment_hygiene = true

require testProfile
include ../../config.das

[export]
def main {
    var count = 0
    bench("interop host calls") <| $() {
        count = testNativeLoop()
    }
    assert(1000000 == count)
}

options gen2
options _comment_hygiene = true

require testProfile
include ../../config.das

[export]
def main {
    bench("queen") <| $() {
        let size = testQueens()
        assert(size == 92)
    }
}

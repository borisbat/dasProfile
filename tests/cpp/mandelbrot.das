options gen2
options _comment_hygiene = true

require testProfile
include ../../config.das

var S = 0

[export]
def main {
    bench("mandelbrot") <| $() {
        S += testMandelbrot()
    }
}

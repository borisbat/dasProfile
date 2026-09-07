options gen2
options _comment_hygiene = true

require testProfile
include ../../config.das

let TOTAL_NUMBERS = 10000
let TOTAL_TIMES = 4

def mk_float(i) {
    return float(i) + float(i) / float(TOTAL_NUMBERS)
}

[export]
def main {
    var nums : array<float> <- [for (i in range(TOTAL_NUMBERS)); mk_float(i)]
    var f4 = 0
    bench("float2string") <| $() {
        f4 = test_f2s(nums, TOTAL_NUMBERS, TOTAL_TIMES)
    }
}

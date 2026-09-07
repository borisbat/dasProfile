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
    var nums : array<string> <- [for (i in range(TOTAL_NUMBERS)); string(mk_float(i))]
    var summ = 0.0
    for (j in 0..TOTAL_TIMES) {
        for (i in range(TOTAL_NUMBERS)) {
            summ += mk_float(i)
        }
    }
    var f4 = 0.0
    bench("string2float") <| $() {
        f4 = test_f2i(nums, TOTAL_NUMBERS, TOTAL_TIMES)
    }
    assert(f4 == summ)
}

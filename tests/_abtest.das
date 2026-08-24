options gen2
require testProfile

include ../config.das

// Same-process A/B of the extern binding flavors: identical callees bound as
// member (indirect fn) vs NTTP-inline, interleaved so machine drift cancels.

[sideeffects]
def add_inline_loop {
    var count = 0
    for (i in range(10000000)) {
        count = AddOne(count)
    }
    return count
}

[sideeffects]
def add_member_loop {
    var count = 0
    for (i in range(10000000)) {
        count = AddOneMember(count)
    }
    return count
}

[sideeffects]
def parse_inline_loop(nums : array<string>) {
    var summ = 0.0
    for (j in range(100)) {
        for (s in nums) {
            summ += ParseFloatInline(s)
        }
    }
    return summ
}

[sideeffects]
def parse_member_loop(nums : array<string>) {
    var summ = 0.0
    for (j in range(100)) {
        for (s in nums) {
            summ += ParseFloatMember(s)
        }
    }
    return summ
}

[export, no_aot, no_jit]
def main {
    var nums : array<string> <- [for (i in range(10000)); "{float(i) + float(i) / 10000.0}"]
    var sink = 0
    var fsink = 0.0
    for (round in range(3)) {
        profile(1, "addone inline r{round}") <| $() {
            sink = add_inline_loop()
        }
        profile(1, "addone member r{round}") <| $() {
            sink = add_member_loop()
        }
        profile(1, "parse inline r{round}") <| $() {
            fsink = parse_inline_loop(nums)
        }
        profile(1, "parse member r{round}") <| $() {
            fsink = parse_member_loop(nums)
        }
    }
    assert(sink == 10000000)
    assert(fsink > 0.0)
}

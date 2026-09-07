options gen2
options _comment_hygiene = true

require testProfile
include ../../config.das

def makeRandomSequence(var src : array<string>) {
    let n = 500000
    let mod = uint(n)
    resize(src, n)
    for (i in range(n)) {
        let num = (271828183u ^ uint(i * 119)) % mod
        src[i] = "{num}"
    }
}

[export]
def main {
    var src : array<string>
    makeRandomSequence(src)
    bench("dictionary") <| $() {
        testProfile::testDict(src)
    }
}

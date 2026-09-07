options gen2
options _comment_hygiene = true

require testProfile
include ../../config.das

def makeRandomSequence(var src : array<int>) {
    let n = 100000
    let seed = 1u
    resize(src, n)
    for (i in range(n)) {
        src[i] = int(uint_noise_1D(i, seed))
    }
}

[export]
def main {
    var tab : array<int>
    makeRandomSequence(tab)
    bench("sort") <| $() {
        var inscope tabb := tab
        testTableSort(tabb)
    }
}

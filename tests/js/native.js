function testAdds() {
    let count = 0
    for (let i = 0; i < 10000000; ++i) {
        count = AddOne(count)
    }
    return count
}

function timeStamp() {
    return performance.now()
}

function profile(name, count, testFn) {
    let best = 100500
    let remaining = count
    while (remaining > 0) {
        const t0 = timeStamp()
        testFn()
        const t1 = timeStamp()
        best = Math.min(best, t1 - t0)
        remaining -= 1
    }
    print('"' + name + '", ' + (best / 1000.0) + ', ' + count)
}

function performance_tests() {
    profile("native loop", 10, function () {
        const count = testAdds()
        if (count !== 10000000) {
            throw new Error("native loop failed: " + count)
        }
    })
}

performance_tests()

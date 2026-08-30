function create_rng(seed) {
    const state = new Array(18).fill(0)
    let cursor = 1
    for (let index = 17; index >= 1; --index) {
        seed = (seed * 9069) % 2147483648
        state[index] = seed
    }
    return function () {
        const head = cursor
        let tail = head - 5
        if (tail < 1) {
            tail += 17
        }
        let value = state[tail] - state[head]
        if (value < 0) {
            value += 2147483647
        }
        state[head] = value
        cursor = head < 17 ? head + 1 : 1
        return value
    }
}

const rand = create_rng(12345)
const size = 100000
const values = []
for (let index = 0; index < size; ++index) {
    values.push(rand())
}

function cmp(lhs, rhs) {
    return rhs - lhs
}

function shallowCopy(array) {
    return array.slice()
}

function timeStamp() {
    return performance.now()
}

function profile(tname, cnt, testFn) {
    let n = 1
    let total = 0
    while (true) {
        const start = timeStamp()
        for (let i = 0; i < n; ++i) {
            testFn()
        }
        total = timeStamp() - start
        if (total >= 500.0 || n >= 1000000000) break
        const per = Math.max(total / n, 1e-6)
        let next = Math.floor(500.0 / per * 1.2)
        next = Math.min(next, 100 * n)
        next = Math.max(next, n + 1)
        n = Math.min(next, 1000000000)
    }
    print('"' + tname + '", ' + (total / 1000.0 / n) + ', ' + n)
}

function performance_tests() {
    profile("sort", 10, function () {
        shallowCopy(values).sort(cmp)
    })
    timeStamp()
}

performance_tests()
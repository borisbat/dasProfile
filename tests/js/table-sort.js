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
    return Date.now()
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
    profile("sort", 10, function () {
        shallowCopy(values).sort(cmp)
    })
    timeStamp()
}

performance_tests()
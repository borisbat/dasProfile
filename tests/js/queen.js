function isPlaceOk(board, row, column) {
    for (let index = 0; index < row; ++index) {
        const placedColumn = board[index]
        const placedRow = index + 1
        const currentRow = row + 1
        if (placedColumn === column) {
            return false
        }
        if (placedColumn - placedRow === column - currentRow) {
            return false
        }
        if (placedColumn + placedRow === column + currentRow) {
            return false
        }
    }
    return true
}

function addQueen(board, row, size) {
    if (row === size) {
        return 1
    }

    let solutions = 0
    for (let column = 1; column <= size; ++column) {
        if (isPlaceOk(board, row, column)) {
            board[row] = column
            solutions += addQueen(board, row + 1, size)
        }
    }
    return solutions
}

function testQueens() {
    return addQueen([], 0, 8)
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
    profile("queen", 10, function () {
        const size = testQueens()
        if (size !== 92) {
            throw new Error("queen failed: " + size)
        }
    })
    timeStamp()
}

performance_tests()
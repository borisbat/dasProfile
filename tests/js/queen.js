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
    profile("queen", 10, function () {
        const size = testQueens()
        if (size !== 92) {
            throw new Error("queen failed: " + size)
        }
    })
    timeStamp()
}

performance_tests()
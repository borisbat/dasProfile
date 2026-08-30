// fibonacii test

function fibI(n) {
	var last = 0
	var cur = 1
	n = n - 1
	while ( n>0 ) {
		n = n - 1
		var tmp = cur
		cur = last + cur
		last = tmp
	}
	return cur
}

// infrastructure

function timeStamp() {
	return performance.now();
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
	profile("fibonacci loop",10,function(){
		fibI(6511134);
	});
	timeStamp();
}

performance_tests();

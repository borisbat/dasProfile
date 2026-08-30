// primes test

function isprime(n) {
	var m = n - 1;
	for(var i=2; i!=m; ++i ) {
		if ( n % i ==0 ) {
			return false;
		}
	}
	return true;
}

function primes(n) {
	var count = 0;
	for ( var i=2; i!=n; ++i ) {
		if ( isprime(i) ) {
			count ++;
		}
	}
	return count;
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
	profile("primes loop",10,function(){
		primes(14000);
	});
	timeStamp();
}

performance_tests();

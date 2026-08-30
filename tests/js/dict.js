// dictionary test

function dict_makeSrc(){
	var src = [];
	var n = 500000;
	var modn = n;
	for (var i=0; i != n; ++i ) {
		var num = (271828183 ^ i*119) % modn;
		src.push('_' + num);
	}
	return src;
}

function dict(src) {
	var tab = {}
	var n = src.length;
	var max = 1
	for (var i=0; i != n; ++i ) {
		var l = src[n];
		if ( tab.hasOwnProperty(l) ) {
			max = Math.max(++tab[l],max);
		} else {
			tab[l] = 1;
		}
	}
	return max;
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
	{
		var src = dict_makeSrc();
		profile("dictionary",10,function(){
			dict(src);
		});
	}
	timeStamp();
}

performance_tests();

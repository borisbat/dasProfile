// particle test


let TOTAL_NUMBERS = 10000;

let TOTAL_TIMES = 4;

function mk_float(i) {
    return i + (i / TOTAL_NUMBERS);
}

function update(nums) {
    let summ = 0;
    for (let i = 1; i <= TOTAL_TIMES; i++) {
        for (let j = 0; j < nums.length; j++) {
            summ = summ + nums[j].toString().length;
        }
    }
    return summ;
}

function make_nums() {
    let nums = [];
    for (let i = 1; i <= TOTAL_NUMBERS; i++) {
        nums.push(mk_float(i));
    }
    return nums;
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
        let nums = make_nums();
		profile("float2string",10,function(){
			update(nums);
		});
	}
	timeStamp();
}

performance_tests();

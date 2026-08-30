// primes test

function Node(x) {
    this.x = x
    this.y = Math.random()
    this.left = null
    this.right = null
}


function merge(lower, greater) {
    if (lower === null) {
    	return greater
    }

    if (greater === null) {
    	return lower
    }

    if (lower.y < greater.y) {
        lower.right = merge(lower.right, greater)
        return lower
    } else {
        greater.left = merge(lower, greater.left)
        return greater
    }
}

function splitBinary(orig, value) {
    if (orig === null) {
    	return [null, null]
    }

    if (orig.x < value) {
        const splitPair = splitBinary(orig.right, value)
        orig.right = splitPair[0]
        return [orig, splitPair[1]]
    } else {
        const splitPair = splitBinary(orig.left, value)
        orig.left = splitPair[1]
        return [splitPair[0], orig]
    }
}

function merge3(lower, equal, greater) {
    return merge(merge(lower, equal), greater)
}


function SplitResult(lower, equal, greater) {
    this.lower = lower
    this.equal = equal
    this.greater = greater
}


function split(orig, value) {
    var lower_eqg = splitBinary(orig, value)
    var eq_greater = splitBinary(lower_eqg[1], value + 1)
    return new SplitResult(lower_eqg[0], eq_greater[0], eq_greater[1])
}


function Tree()
{
    this.root = null
}

Tree.prototype.has_value = function(x) {
    var splited = split(this.root, x)
    var res = splited.equal !== null
    this.root = merge3(splited.lower, splited.equal, splited.greater)
    return res
}

Tree.prototype.insert = function(x) {
    var splited = split(this.root, x)
    if (splited.equal === null) {
        splited.equal = new Node(x)
    }
    this.root = merge3(splited.lower, splited.equal, splited.greater)
}

Tree.prototype.erase = function(x) {
    var splited = split(this.root, x)
    this.root = merge(splited.lower, splited.greater)
}

function testTree() {
    var tree = new Tree()
    var cur = 5;
    var res = 0;

    for (var i = 1; i < 20000; ++i) {
        var a = i % 3;
        cur = (cur * 57 + 43) % 10007;
        if (a === 0) {
            tree.insert(cur);
        } else if (a === 1) {
            tree.erase(cur);
        } else if (a == 2) {
            res += tree.has_value(cur) ? 1 : 0;
        }
    }
	return res;
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
    profile("tree",10,function(){
		testTree();
	});
	timeStamp();
}

performance_tests();

function A(i,j) {
return 1/((i+j)*(i+j+1)/2+i+1);
}

function Au(u,v) {
for (var i=0; i<u.length; ++i) {
    var t = 0;
    for (var j=0; j<u.length; ++j)
    t += A(i,j) * u[j];
    v[i] = t;
}
}

function Atu(u,v) {
for (var i=0; i<u.length; ++i) {
    var t = 0;
    for (var j=0; j<u.length; ++j)
    t += A(j,i) * u[j];
    v[i] = t;
}
}

function AtAu(u,v,w) {
Au(u,w);
Atu(w,v);
}

function spectralnorm(n) {
var i, u=[], v=[], w=[], vv=0, vBv=0;
for (i=0; i<n; ++i) {
    u[i] = 1; v[i] = w[i] = 0;
}
for (i=0; i<2; ++i) {
    AtAu(u,v,w);
    AtAu(v,u,w);
}
for (i=0; i<n; ++i) {
    vBv += u[i]*v[i];
    vv  += v[i]*v[i];
}
return Math.sqrt(vBv/vv);
}

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
		profile("spectral norm",10,function(){
			spectralnorm(500);
		});
	}
	timeStamp();
}

performance_tests();
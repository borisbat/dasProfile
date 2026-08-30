function level(cx, cy) {
  let l = 0;
  let zx = cx;
  let zy = cy;
  while ((zx * zx + zy * zy) < 4.0 && l < 255) {
    const nextX = zx * zx - zy * zy + cx;
    const nextY = zx * zy + zy * zx + cy;
    zx = nextX;
    zy = nextY;
    l++;
  }
  return l - 1;
}

function test() {
  const xmin = -2.0;
  const xmax = 2.0;
  const ymin = -2.0;
  const ymax = 2.0;
  const N = 64;
  const dx = (xmax - xmin) / N;
  const dy = (ymax - ymin) / N;
  let sum = 0;
  let x = xmin;
  for (let i = 0; i < N; ++i) {
    let y = ymin;
    for (let j = 0; j < N; ++j) {
      sum += level(x, y);
      y += dy;
    }
    x += dx;
  }
  return sum;
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

profile('mandelbrot', 10, function () {
  test();
});
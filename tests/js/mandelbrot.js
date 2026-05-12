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
  return Date.now();
}

function profile(tname, cnt, testFn) {
  let t = 100500;
    let count = 10;
  while (count > 0) {
    const t0 = timeStamp();
    testFn();
    const t1 = timeStamp();
    const dt = t1 - t0;
    t = Math.min(dt, t);
    count--;
  }
  t /= 1000.0;
  print('"' + tname + '", ' + t + ', 10');
}

profile('mandelbrot', 10, function () {
  test();
});
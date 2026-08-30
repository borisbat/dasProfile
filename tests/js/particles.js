// particle test

function update_particle(p) {
	p.pos.x += p.vel.x;
	p.pos.y += p.vel.y;
	p.pos.z += p.vel.z;
}

function update_particles(particles) {
	var n = particles.length;
	for ( var i=0; i!=n; ++i ) {
		update_particle(particles[i]);
	}
}

function multi_update_particles(particles,count) {
	while ( count ) {
		update_particles(particles);
		count--;
	}
}

function update_particles_i(particles) {
	var n = particles.length;
	for ( var i=0; i!=n; ++i ) {
		var p = particles[i];
		p.pos.x += p.vel.x;
		p.pos.y += p.vel.y;
		p.pos.z += p.vel.z;
	}
}

function multi_update_particles_i(particles,count) {
	while ( count ) {
		update_particles_i(particles);
		count--;
	}
}

function make_particles() {
	var particles = []
	var n = 50000;
	for ( var i=0; i!=n; ++i ) {
		var p = {
			pos : {x : i + 0.1, y : i + 0.2, z : i + 0.3},
			vel : {x : 1.1, y : 2.1,  z : 3.1}
		};
		particles.push(p);
	}
	return particles;
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
        var particles = make_particles();
		profile("particles kinematics",10,function(){
			multi_update_particles_i(particles,10);
		});
	}
	timeStamp();
}

performance_tests();

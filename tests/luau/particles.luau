local function updateI(particles)
	for i,p in ipairs(particles) do
      p.pos.x=p.pos.x+p.vel.x
      p.pos.y=p.pos.y+p.vel.y
      p.pos.z=p.pos.z+p.vel.z
	end
end

local function update_several_timesI(particles, count)
  for i = 0, count  do
     updateI(particles)
  end
end


particles = {}
for i = 1, 50000 do
	table.insert(particles,
		{
			pos = {x = i + 0.1, y = i + 0.2, z = i + 0.3},
			vel = {x = 1.1, y = 2.1,  z = 3.1}
		})
end

PROFILE_N = 1

function profile_it(profiles, fn)
  local n = 1
  local total
  while true do
    local start = os.clock()
    for i = 1, n do fn() end
    total = os.clock() - start
    if total >= 0.5 or n >= 1000000000 then break end
    local per = math.max(total / n, 1e-9)
    local nxt = math.floor(0.5 / per * 1.2)
    nxt = math.min(nxt, 100 * n)
    nxt = math.max(nxt, n + 1)
    n = math.min(nxt, 1000000000)
  end
  PROFILE_N = n
  return total / n
end

print(string.format("\"particles kinematics\", %.8f, %d", profile_it(10, function () update_several_timesI(particles, 10) end), PROFILE_N))

local G = love.graphics

flash_shader = G.newShader([[
vec4 effect(vec4 col, sampler2D tex, vec2 tex_coords, vec2 screen_coords) {
	vec4 tc = texture2D(tex, tex_coords) * col;
	return tc + vec4(vec3(1, 1, 1) - tc.rgb, 0) * 0.5;
}]])

Game = Object:new {}
Game.health_img = G.newImage("media/health.png")
Game.health_quads = makeQuads(16, 8, 8)
Game.canvas = G.newCanvas()


function Game:init()
	self.stars = Stars()
	self.walls = Walls()
	self.player = Player()
end
function Game:playBack(demo)
	self:reset(demo.seed)
	self.record = demo.record
	self.is_demo = true
end
function Game:makeRG()
	return makeRandomGenerator(self.rand.int(0xffffff))
end
function Game:start(seed, input)
	self.input = input
	self:reset(seed)
end
function Game:reset(seed)
	self.seed = seed
	self.rand = makeRandomGenerator(self.seed)
	self.record = {}
	self.is_demo = false
	self.tick = 0
	self.outro = 0
	self.blend = 1
	self.action = false
	self.pause = false

	self.wall_rows = 0
	self.blockades = 0

	self.player:reset()
	self.stars:reset(self:makeRG())
	self.walls:reset(self:makeRG())

	Boom.list = {}
	Particle.list = {}
	Laser.list = {}
	Enemy.list = {}
	Bullet.list = {}
	Item.list = {}

	RingEnemy.counter = 0
	RocketEnemy.counter = 0

	self.saucer_delay = 0

	-- DEBUG
--	for i = 1, 720 do self.walls:generate() end
--	CannonEnemy(self:makeRG(), 0, 0, "left")
--	CannonEnemy(self:makeRG(), 50, -100, "up")
--	MoneyItem(0, 0)
--	SpeedItem(0, -100)
--	SpeedItem(0, -200)
--	BallItem(0, 100)
--	SaucerEnemy(self:makeRG(), 100, -150)
end
function Game:next_wall_row()
	self.wall_rows = self.wall_rows + 1
	if self.wall_rows % 50 == 0 then
		self.blockades = self.blockades + 1
	end
	if self.blockades > 0 then
		local data = self.walls.data
		local r = data[#data]

		local i = 1
		while r[i] > 0 do i = i + 1 end
		local j = i
		while r[j] == 0 do j = j + 1 end
		local k = j
		while (r[k] or 0) > 0 do k = k + 1 end
		if k == #r + 1
		and (r[i - 1] or 1) == 1 and (r[j] or 1) == 1 then
			self.blockades = self.blockades - 1
			local prev
			for ix, c in ipairs(r) do
				if c == 0 then
					r[ix] = -2
					local x, y = self.walls:getTilePosition(ix, #data)
					block = BlockadeEnemy(x, y, r, ix)
					if prev then
						block.neighbors[1] = prev
						prev.neighbors[2] = block
					end
					prev = block
				end
			end
		end
	end
end
function Game:update()
	-- DEBUG
--	love.timer.sleep(0.05)

	if Input:gotAnyPressed("back")
	or self.is_demo and	(Input:gotAnyPressed("start") or Input:gotAnyPressed("shoot")) then
		self.action = "BACK"
	end
	if not self.action and Input:gotAnyPressed("start") then
		self.pause = not self.pause
	end

	-- blend
	if not self.action then
		if self.blend > 0 then
			self.blend = self.blend - 0.1
		end
	else
		if self.blend < 1 then
			self.blend = self.blend + 0.1
		end
		if self.blend >= 1 then
			if self.action == "BACK" then
				state = menu
				bg_music:stop()
				menu:swapState("main")
			end
		end
	end

	-- pause
	if self.pause then return end


	self.tick = self.tick + 1

	-- input
	local input = {}
	if self.is_demo then
		local i = self.record[self.tick] or 5
		input.dx = i % 4 - 1
		input.dy = math.floor(i / 4) % 4 - 1
		input.shoot = math.floor(i / 16) > 0
		if not self.record[self.tick] then self.action = "BACK" end
	else
		input = self.input.state
		self.record[self.tick]	= (1 + input.dx)
								+ (1 + input.dy) * 4
								+ bool[input.shoot] * 16
	end



	-- update entities

	self.stars:update(self.walls.speed)
	self.walls:update()

	updateList(Particle.list)
	updateList(Boom.list)

	self.player:update(input)
	updateList(Enemy.list)
	updateList(Laser.list)
	updateList(Bullet.list)
	updateList(Item.list)



	-- TODO: spawn enemies
	if self.saucer_delay > 0 then self.saucer_delay = self.saucer_delay - 1 end
	if self.rand.float(-5, 1) > 0.99996^(self.tick/10 + 1000 + self.tick % 1000 * 3) then

		local data = self.walls.data
		local j = #data - 1
		local wall_spot = {}
		local spot = {}
		for i, c in ipairs(data[j]) do
			if c == 0 then
				table.insert(spot, i)
				if     data[j][i-1] == 1 then
					table.insert(wall_spot, { i, "left" })
				elseif data[j][i+1] == 1 then
					table.insert(wall_spot, { i, "right" })
				elseif data[j+1][i] == 1 then
					table.insert(wall_spot, { i, "up" })
				elseif data[j-1][i] == 1 then
					table.insert(wall_spot, { i, "down" })
				end
			end
		end


		local side_spot = {}
		for i = 9, #data - 4 do
			if	data[i    ][1] == 0
			and data[i + 1][1] == 0
			and data[i + 2][1] == 0 then
				table.insert(side_spot, { 1, i + 1, 0 })
			end
			if	data[i    ][26] == 0
			and data[i + 1][26] == 0
			and data[i + 2][26] == 0 then
				table.insert(side_spot, { 26, i + 1, math.pi })
			end

		end



		local r = self.rand.int(1, 8)
		if #spot > 0 and r <= 4 then
			local t = spot[self.rand.int(1, #spot)]
			data[j][t] = -1
			local x, y = self.walls:getTilePosition(t, #data - 1)
			if r == 1 then
				SquareEnemy(self:makeRG(), x, y)
			elseif r < 4 then
				RingEnemy(self:makeRG(), x, y)
			end
		end
		if #wall_spot > 0 and r >= 5 and r <= 6 then
			local t = wall_spot[self.rand.int(1, #wall_spot)]
			data[j][t[1]] = -1
			local x, y = self.walls:getTilePosition(t[1], #data - 1)
			if r == 5 then
				RocketEnemy(self:makeRG(), x, y, t[2])
			else
				CannonEnemy(self:makeRG(), x, y, t[2])
			end
		end

		-- twister
		if #side_spot > 0 and r == 7 and self.rand.int(0, 3) == 0 then
			local t = side_spot[self.rand.int(1, #side_spot)]
			for iy = t[2] - 9, t[2] + 9 do
				if data[iy] and data[iy][t[1]] == 0 then
					data[iy][t[1]] = -1
				end
			end
			local x, y = self.walls:getTilePosition(t[1], t[2])
			x = x + (bool[x > 0] - bool[x < 0]) * 16
			TwisterSpawn(self:makeRG(), x, y, t[3])
		end

		-- saucer
		if #spot > 0 and r == 8 and self.tick % 3 == 0 and self.saucer_delay <= 0 then
			self.saucer_delay = 3000 - self.tick * 0.02
			local t = spot[self.rand.int(1, #spot)]
			data[j][t] = -1
			local x, y = self.walls:getTilePosition(t, #data - 1)
			SaucerEnemy(self:makeRG(), x, y)
		end
	end


	-- game over
	if not self.player.alive then
		self.outro = self.outro + 1
		if self.outro > 250 then
			state = menu
			bg_music:stop()
			if self.is_demo then
				menu:swapState("main")
			else
				menu:gameOver(self)
			end
		end
	end
end
function Game:draw()
	G.scale(G.getWidth() / 800, G.getHeight() / 600)
	G.translate(400, 300)

if DEBUG then
	G.scale(0.25)
	G.translate(0, 650)
end


	G.setCanvas(Boom.canvas)
	G.clear()
	G.setColor(255, 255, 255)
	G.setBlendMode("add")
	drawList(Boom.list)
	G.setBlendMode("alpha")



	G.setCanvas(self.canvas)
	G.clear()

	self.stars:draw()
	for _, p in ipairs(Particle.list) do
		if p.layer == "back" then p:draw() end
	end
	drawList(Enemy.list)
	drawList(Bullet.list)
	drawList(Laser.list)
	self.player:draw()
	self.walls:draw()


	G.setCanvas()
	G.origin()
	Boom.shader:send("bump", Boom.canvas)
	G.setShader(Boom.shader)
	G.setColor(255, 255, 255)
	G.setBlendMode("replace")
	G.draw(self.canvas)
	G.setBlendMode("alpha")
	G.setShader()

	G.scale(G.getWidth() / 800, G.getHeight() / 600)
	G.translate(400, 300)

if DEBUG then
	G.scale(0.25)
	G.translate(0, 650)
	G.rectangle("line", -400, -300, 800, 600)
end

	for _, p in ipairs(Particle.list) do
		if p.layer == "front" then p:draw() end
	end
	drawList(Item.list)



	-- hud
	G.origin()
	G.scale(G.getWidth() / 800, G.getHeight() / 600)
	G.setColor(255, 255, 255)
	font:print(("%07d"):format(self.player.score), 800 - 6 * 4 * 7 - 8, 0)

	for i = 1, self.player.max_shield do
		local f = 1
		if i > self.player.shield
		or (self.player.shield == 1 and self.tick % 32 < 8) then
			f = 2
		end
		G.draw(self.health_img, self.health_quads[f],
			8 + (i - 1) * 32,
			4, 0, 4)
	end


	-- pause
	if self.pause then
		font:printCentered("PAUSE", 398, 300 - 20)
	end


	local blend = self.blend
	if not self.player.alive and self.outro > 200 then
		blend = math.max(blend, math.min(1, (self.outro - 200) / 50))
	end
	if blend > 0 then
		G.setColor(0, 0, 0, blend * 255)
		G.rectangle("fill", 0, 0, 800, 600)
	end
end

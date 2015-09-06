local G = love.graphics
local isDown = love.keyboard.isDown

flash_shader = G.newShader([[
vec4 effect(vec4 col, sampler2D tex, vec2 tex_coords, vec2 screen_coords) {
	vec4 tc = texture2D(tex, tex_coords) * col;
	return tc + vec4(max(max(tc.rgb, tc.gbr), tc.brg), 0);
}]])

Game = Object:new { seed = 7 }
Game.health_img = G.newImage("media/health.png")
Game.health_quads = makeQuads(16, 8, 8)
Game.canvas = G.newCanvas()

function Game:init(seed)
	self.stars = Stars()
	self.walls = Walls()
	self.player = Player()

	self:reset()
end
function Game:playBack(record)
	self:reset()
	self.record = record
	self.is_demo = true
end
function Game:makeRG()
	return makeRandomGenerator(self.rand.int(0xffffff))
end
function Game:reset()
	self.rand = makeRandomGenerator(self.seed)
	self.record = {}
	self.is_demo = false
	self.tick = 0
	self.outro = 0
	self.blend = 1
	self.action = false

	self.player:reset()
	self.stars:reset(self:makeRG())
	self.walls:reset(self:makeRG())

	Boom.list = {}
	Particle.list = {}
	Laser.list = {}
	Enemy.list = {}
	Bullet.list = {}

	-- TODO
--	for i = 1, 720 do self.walls:generate() end
--	CannonEnemy(self:makeRG(), 0, 0, "left")
--	CannonEnemy(self:makeRG(), 50, -100, "up")

end
function Game:update()
	self.tick = self.tick + 1

	local input = {}
	if self.is_demo then
		local i = self.record[self.tick] or 5
		input.dx = i % 4 - 1
		input.dy = math.floor(i / 4) % 4 - 1
		input.shoot = math.floor(i / 16) > 0
	else
		input.dx = bool[isDown("right")] - bool[isDown("left")]
		input.dy = bool[isDown("down")] - bool[isDown("up")]
		input.shoot = isDown("x")
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



	-- TODO: spawn enemies
	if self.rand.float(-5, 1) > 0.99996^(self.tick/20 + 1000 + self.tick % 1000 * 3) then

		local d = self.walls.data
		local j = #d - 1
		local w = {}
		local s = {}
		for i, c in ipairs(d[j]) do
			if c == 0 then
				s[#s+1] = i
				if     d[j][i-1] == 1 then
					w[#w+1] = { i, "left"}
				elseif d[j][i+1] == 1 then
					w[#w+1] = { i, "right"}
				elseif d[j+1][i] == 1 then
					w[#w+1] = { i, "up"}
				elseif d[j-1][i] == 1 then
					w[#w+1] = { i, "down"}
				end
			end
		end




		local r = self.rand.int(1, 6)
		if #s > 0 then
			local t = s[self.rand.int(1, #s)]
			d[j][t] = -1
			local x, y = self.walls:getTilePosition(t, #d - 1)
			if r == 1 then
				SquareEnemy(self:makeRG(), x, y)
			elseif r < 5 then
				RingEnemy(self:makeRG(), x, y)
			end
		end
		if #w > 0 and r >= 5 then
			local t = w[self.rand.int(1, #w)]
			d[j][t[1]] = -1
			local x, y = self.walls:getTilePosition(t[1], #d - 1)
			if r == 5 then
				RocketEnemy(self:makeRG(), x, y, t[2])
			else
				CannonEnemy(self:makeRG(), x, y, t[2])
			end
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
	if self.is_demo and not self.record[self.tick] then
		self.action = "BACK"
	end
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
end
function Game:keypressed(key, isrepeat)
	if key == "escape"
	or self.is_demo and (key == "return" or key == "space" or key == "x") then
		self.action = "BACK"
	end

	if self.is_demo and key == "p" then
		self.is_demo = false
	end


--	if key == "-" then
--		self.walls.speed = self.walls.speed - 1
--	elseif key == "+" then
--		self.walls.speed = self.walls.speed + 1
--	end


--	if key == "r" then
--		local d = self.walls.data
--		local j = #d - 1
--		local s = {}
--		for i, c in ipairs(d[j]) do
--			if c == 0 then
--				if d[j][i-1] == 1 then
--					s[#s+1] = { i, "left"}
--				elseif d[j][i+1] == 1 then
--					s[#s+1] = { i, "right"}
--				elseif d[j+1][i] == 1 then
--					s[#s+1] = { i, "up"}
--				elseif d[j-1][i] == 1 then
--					s[#s+1] = { i, "down"}
--				end
--			end
--		end
--		if #s > 0 then
--			local t = s[self.rand.int(1, #s)]
--			local x, y = self.walls:getTilePosition(t[1], #d - 1)
--			RocketEnemy(self:makeRG(), x, y, t[2])
--		end
--	end

end
function Game:draw()
	G.scale(G.getWidth() / 800, G.getHeight() / 600)
	G.translate(400, 300)

if DEBUG then
	G.scale(0.3)
	G.translate(0, 500)
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
	G.scale(0.3)
	G.translate(0, 500)
	G.rectangle("line", -400, -300, 800, 600)
end

	drawList(Particle.list)



	-- hud
	G.origin()
	G.scale(G.getWidth() / 800, G.getHeight() / 600)
	G.setColor(255, 255, 255)
	font:print(("%08d"):format(self.player.score), 796 - 6 * 32 - 4, 0, 4)

	for i = 1, 3 do
		local f = 1
		if i > self.player.shield
		or (self.player.shield == 1 and self.tick % 32 < 8) then
			f = 2
		end
		G.draw(self.health_img, self.health_quads[f],
			8 + (i - 1) * 32,
			4, 0, 4)
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

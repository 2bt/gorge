local G = love.graphics
local isDown = love.keyboard.isDown

Game = Object:new { seed = 7 }
Game.health_img = G.newImage("media/health.png")
Game.health_quads = makeQuads(16, 8, 8)

function Game:init(seed)
	self.stars = Stars()
	self.walls = Walls()
	self.player = Player()

	self:reset()
end
function Game:rewind()
	local r = self.record
	self:reset()
	self.record = r
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

	self.player:reset()
	self.stars:reset(self:makeRG())
	self.walls:reset(self:makeRG())

	Boom.list = {}
	Particle.list = {}
	Laser.list = {}
	Enemy.list = {}

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


	self.stars:update(self.walls.speed)
	self.walls:update()

	updateList(Particle.list)
	updateList(Boom.list)

	self.player:update(input)
	updateList(Enemy.list)
	updateList(Laser.list)



	if isDown("s") then
		local d = self.walls.data
		local r = d[#d - 1]
		local s = {}
		for i, c in ipairs(r) do
			if c == 0 then
				s[#s + 1] = i
			end
		end
		if #s > 0 then
			local x, y = self.walls:getTilePosition(s[self.rand.int(1, #s)], #d - 1)
			RingEnemy(self:makeRG(), x, y)
		end

--		makeExplosion(math.random(-100, 100), math.random(-100, 100))
	end


	if not self.player.alive then
		self.outro = self.outro + 1
		if self.outro > 250 then
			state = menu
			state:reset()
			self:rewind()
		end
	end


	-- replay
	if self.is_demo and not self.record[self.tick] then
		self:rewind()
	end

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



	G.setCanvas(canvas)
	G.clear()

	self.stars:draw()
	self.walls:draw()
	drawList(Laser.list)
	drawList(Enemy.list)
	self.player:draw()


	G.setCanvas()
	G.origin()
	Boom.shader:send("bump", Boom.canvas)
	G.setShader(Boom.shader)
	G.setColor(255, 255, 255)
	G.setBlendMode("replace")
	G.draw(canvas)
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


	local blend = 0
	if self.tick < 10 then
		blend = 1 - self.tick / 10
	elseif not self.player.alive and self.outro > 200 then
		blend = math.min(1, (self.outro - 200) / 50)
	end
	if blend > 0 then
		G.setColor(0, 0, 0, blend * 255)
		G.rectangle("fill", 0, 0, 800, 600)
	end
end

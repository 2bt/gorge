local G = love.graphics


Enemy = Object:new {
	list = {},
	alive = true,
	ang = 0,
	flash = 0,
	score = 0,
}
function Enemy:init(rand, x, y)
	table.insert(self.list, self)
	self.rand = rand
	self.trans_model = {}
	self.x = x
	self.y = y
	self.tick = 0
end
function Enemy:hit(damage)
	self.flash = 5
	self.shield = self.shield - damage
	if self.shield <= 0 then
		self.alive = false
		game.player.score = game.player.score + self.score
	end
end
function Enemy:update()
	if not self.alive then
		makeExplosion(self.x, self.y)
		return "kill"
	end
	if self.x > 440 or self.x < -440
	or self.y > 340 or self.y < -370 then
		return "kill"
	end

	if self.flash > 0 then self.flash = self.flash - 1 end
	self.tick = self.tick + 1

	self:subUpdate()
end
function Enemy:draw()
	if self.flash > 0 then G.setShader(flash_shader) end
	self:subDraw()
	if self.flash > 0 then G.setShader() end
end
function Enemy:subDraw()
	G.setColor(255, 255, 255)
	G.draw(self.img, self.quads[math.floor(self.tick / 4) % #self.quads + 1],
		self.x, self.y, 0, 4, 4, 8, 8)
--	G.polygon("line", self.trans_model)
end


--------------------------------------------------------------------------------


RingEnemy = Enemy:new {
	img = G.newImage("media/ring.png"),
	shield = 1,
	score = 100,
	model = {
		-8, 16,
		-12, 8,
		-12, -8,
		-8, -16,
		8, -16,
		12, -8,
		12, 8,
		8, 16,
	},
}
genQuads(RingEnemy, 16)
function RingEnemy:init(rand, x, y)
	self:super(rand, x, y)
	self:turnTo(0.2, math.pi - 0.2)
	self.delay = self.rand.int(200)
	transform(self)
end
function RingEnemy:turnTo(ang1, ang2)
	local ang = self.rand.float(ang1, ang2)
	self.vx = math.cos(ang) * 1.5
	self.vy = math.sin(ang) * 1.5
end
function RingEnemy:subUpdate()
	self.x = self.x + self.vx
	self.y = self.y + self.vy + game.walls.speed


	transform(self)
	local d, n, w = game.walls:checkCollision(self.trans_model)
	if d > 0 then
		self.x = self.x - n[1] * d
		self.y = self.y - n[2] * d
		self:turnTo(0, 2 * math.pi)
		transform(self)
	end
	self.delay = self.delay + self.rand.int(1, 4)
	if self.delay > 200 then
		self.delay = 0
		if self.rand.float(0, 1) < 0.6 then
			self:turnTo(0, math.pi)
		else
			self:turnTo(math.pi, 2 * math.pi)
		end
	end
end


SquareEnemy = Enemy:new {
	img = G.newImage("media/square.png"),
	shield = 3,
	score = 450,
	model = {
		-8, 16,
		-16, 8,
		-16, -8,
		-8, -16,
		8, -16,
		16, -8,
		16, 8,
		8, 16,
	},
	bounce_model = {
		-12, 24,
		-24, 12,
		-24, -12,
		-12, -24,
		12, -24,
		24, -12,
		24, 12,
		12, 24,
	},
}
genQuads(SquareEnemy, 16)
function SquareEnemy:init(rand, x, y)
	self:super(rand, x, y)
	self.tick = self.rand.int(1, 100)
	self.delay = self.rand.int(100)
	self.vx = self.rand.float(-4, 4)
	self.vy = 1
	self:normVel()
	transform(self)
end
function SquareEnemy:normVel()
	local f = 1.1 / (self.vx*self.vx + self.vy*self.vy) ^ 0.5
	self.vx = self.vx * f
	self.vy = self.vy * f
end
function SquareEnemy:subUpdate()
	self.x = self.x + self.vx
	self.y = self.y + self.vy + game.walls.speed

	local p = math.sin(self.tick * 0.1)

	self.x = self.x + self.vy * p
	self.y = self.y - self.vx * p

	transform(self, self.bounce_model)
	local d, n, w = game.walls:checkCollision(self.trans_model)
	if d > 0 then
		self.vx = self.vx - n[1] * 0.06
		self.vy = self.vy - n[2] * 0.06
	else
		self.vy = self.vy + 0.01
		self:normVel()
	end
	transform(self)
end

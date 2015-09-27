local G = love.graphics

SquareEnemy = Enemy:new {
	img = G.newImage("media/square.png"),
	shield = 2,
	score = 350,
	model = { 8, 16, 16, 8, 16, -8, 8, -16, -8, -16, -16, -8, -16, 8, -8, 16, },
	bounce_model = { 16, 32, 32, 16, 32, -16, 16, -32, -16, -32, -32, -16, -32, 16, -16, 32, },
}
genQuads(SquareEnemy)
function SquareEnemy:init(...)
	self:super(...)
	self.tick = self.rand.int(1, 100)
	self.delay = self.rand.int(30, 300)
	self.vx = self.rand.float(-4, 4)
	self.vy = 1
	self:normVel()
end
function SquareEnemy:die()
	makeEnergyItem(self.x, self.y, self.rand, 3)
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
		self.vy = self.vy + 0.008
		self:normVel()
	end
	transform(self)
	local d, n, w = game.walls:checkCollision(self.trans_model)
	if d > 0 then
		self.x = self.x - n[1] * d
		self.y = self.y - n[2] * d
		transform(self)
	end


	if not game.player.alive then return end

	if self.delay <= 10
	or not game.walls:checkSight(self.x, self.y, game.player.x, game.player.y) then
		self.delay = self.delay - 1
	end
	if self.delay <= 10 and self.delay % 10 == 0 then
		local dx = game.player.x - self.x
		local dy = game.player.y - self.y
		local ang = math.atan2(dx, dy) + self.rand.float(-0.2, 0.2)
		local s = self.rand.float(4, 4.2)
		RapidBullet(self.x, self.y, math.sin(ang) * s, math.cos(ang) * s)
		if self.delay == 0 then
			self.delay = self.rand.int(200, 300)
		end
	end
end
RapidBullet = Bullet:new {
	color = { 146, 255, 146 },
	model = { 2, 6, 2, -6, -2, -6, -2, 6, }
}
function RapidBullet:init(x, y, dx, dy)
	self:super(x, y, dx, dy)
	self.ang = math.atan2(dx, dy)
end
function RapidBullet:draw()
	G.setColor(unpack(self.color))
	G.polygon("fill", self.trans_model)
end

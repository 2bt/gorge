local G = love.graphics

RingEnemy = Enemy:new {
	img = G.newImage("media/ring.png"),
	shield = 1,
	score = 100,
	model = { 8, 16, 12, 8, 12, -8, 8, -16, -8, -16, -12, -8, -12, 8, -8, 16, },
	counter = 0
}
genQuads(RingEnemy)
function RingEnemy:init(...)
	self:super(...)
	self:turnTo(0.2, math.pi - 0.2)
	self.delay = self.rand.int(200)
end
function RingEnemy:die()
	RingEnemy.counter = RingEnemy.counter + 1
	if RingEnemy.counter % 25 == 0 then
		if not game.player.balls[1].alive
		or not game.player.balls[2].alive then
			BallItem(self.x, self.y)
		else
			HealthItem(self.x, self.y)
		end
	end
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

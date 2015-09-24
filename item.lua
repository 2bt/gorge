local G = love.graphics


Item = Object:new {
	model = { 12, 12, 12, -12, -12, -12, -12, 12, },
	bounce_model = { 16, 32, 32, 16, 32, -16, 16, -32, -16, -32, -32, -16, -32, 16, -16, 32, },
	list = {},
	size = 8,
	frame_length = 6,
}
function Item:init(x, y)
	table.insert(self.list, self)
	self.x = x
	self.y = y
	self.tick = 0
	self.trans_model = {}
end
function Item:collect(player)
	makeFastSparkleParticle(self.x, self.y)
	player.score = player.score + self.score
	if self.subCollect then
		self:subCollect(player)
	end
end
function Item:update()
	self.tick = self.tick + 1
	self.y = self.y + game.walls.speed + math.sin(self.tick * 0.1)
	self.x = self.x + math.cos(self.tick * 0.1)
	if self.y > 310 then return "kill" end

	transform(self, self.bounce_model)
	local d, n, w = game.walls:checkCollision(self.trans_model)
	if d > 0 then
		self.x = self.x - n[1] * 0.1
		self.y = self.y - n[2] * 0.1
	end
	transform(self)

	if game.player.alive then
		local d, n, w = polygonCollision(self.trans_model, game.player.trans_model)
		if d > 0 then
			self:collect(game.player)
			return "kill"
		end
	end
end
function Item:draw()
	G.setColor(255, 255, 255)
	G.draw(self.img, self.quads[math.floor(self.tick / self.frame_length) % #self.quads + 1],
		self.x, self.y, 0, 4, 4, self.size / 2, self.size / 2)
end




MoneyItem = Item:new {
	img = G.newImage("media/money_item.png"),
	size = 9,
	score = 10000,
}
genQuads(MoneyItem)


HealthItem = Item:new {
	img = G.newImage("media/health_item.png"),
	size = 9,
	score = 2500,
}
genQuads(HealthItem)
function HealthItem:subCollect(player)
	if player.shield < player.max_shield then
		player.shield = player.shield + 1
	end
end

BallItem = Item:new {
	img = G.newImage("media/ball_item.png"),
	score = 1000,
}
genQuads(BallItem)
function BallItem:subCollect(player)
	for _, ball in ipairs(player.balls) do
		if not ball.alive then ball:activate() end
	end
end



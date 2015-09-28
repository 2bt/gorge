local G = love.graphics


Item = Object:new {
	model = { 16, 16, 16, -16, -16, -16, -16, 16, },
	bounce_model = { 24, 48, 48, 24, 48, -24, 24, -48, -24, -48, -48, -24, -48, 24, -24, 48, },
	list = {},
	size = 8,
	frame_length = 6,
	layer = "front",
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
		self.x = self.x - n[1] * 0.3
		self.y = self.y - n[2] * 0.3
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
--	if self.trans_model[1] then G.polygon("line", self.trans_model) end
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


SpeedItem = Item:new {
	img = G.newImage("media/speed_item.png"),
	score = 1000,
	frame_length = 5,
}
genQuads(SpeedItem)
function SpeedItem:subCollect(player)
	player.speed_boost = player.speed_boost + 1
end


MoneyItem = Item:new {
	img = G.newImage("media/money_item.png"),
	size = 9,
	score = 10000,
}
genQuads(MoneyItem)



EnergyItem = Item:new {
	img = G.newImage("media/energy_item.png"),
	size = 8,
	score = 80,
	model = { 8, 8, 8, -8, -8, -8, -8, 8, },
	frame_length = 2,
	layer = "back",
}
genQuads(EnergyItem)
function EnergyItem:init(x, y, vx, vy)
	self:super(x, y)
	self.vx = vx
	self.vy = vy
	self.tick = math.random(1, #self.quads * self.frame_length)
end
function EnergyItem:update()
	self.tick = self.tick + 1
	self.y = self.y + game.walls.speed + self.vy
	self.x = self.x + self.vx

	self.vx = self.vx * 0.98
	self.vy = self.vy * 0.98

	if self.y > 310 then return "kill" end

	transform(self)
	local d, n, w = game.walls:checkCollision(self.trans_model)
	if d > 0 then
		self.x = self.x - n[1] * d
		self.y = self.y - n[2] * d

		local dot = (self.vx * n[1] + self.vy * n[2]) * 2
		self.vx = self.vx - dot * n[1]
		self.vy = self.vy - dot * n[2]
	end
	transform(self)

	local player = game.player
	if player.alive then
		local dx = player.x - self.x
		local dy = player.y - self.y
		local l = dx^2 + dy^2
		if l < 6000 then
			l = 1 / (l ^ 0.5)
			self.x = self.x + dx * l * 5
			self.y = self.y + dy * l * 5
		end


		local d, n, w = polygonCollision(self.trans_model, player.trans_model)
		if d > 0 then
			self:collect(game.player)
			return "kill"
		end
	end
end
function EnergyItem:collect(player)
	SparkleParticle(self.x, self.y)
	player.score = player.score + self.score
	if player.energy < player.max_energy then
		player.energy = player.energy + 1
	end
end
function makeEnergyItem(x, y, rand, count)
	for i = 1, count do
		local r = rand.float(0, math.pi * 2)
		local s = rand.float(1, 2.5)
		EnergyItem(x, y, math.sin(r) * s, math.cos(r) * s)
	end
end

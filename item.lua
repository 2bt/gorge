local G = love.graphics


Item = BatchDrawer(100, {
	model = { 12, 12, 12, -12, -12, -12, -12, 12, },
	bounce_model = { 24, 48, 48, 24, 48, -24, 24, -48, -24, -48, -48, -24, -48, 24, -24, 48, },
	size = 8,
	frame_length = 6,
	layer = "front",
})
initPolygonRadius(Item.model)
function Item:init(x, y)
	table.insert(self.list, self)
	self.x = x
	self.y = y
	self.tick = 0
	self.trans_model = {}
	sound.play("drop", self.x, self.y)
end
function Item:collect(player)
	sound.play("collect", self.x, self.y)
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
	if self.y > 330 then return "kill" end

	transform(self, self.bounce_model)
	local d, n, w = game.walls:checkCollision(self.trans_model)
	if d > 0 then
		self.x = self.x - n[1] * 0.3
		self.y = self.y - n[2] * 0.3
	end
	transform(self)


	local player = game.player
	if player.alive then
		local dx = player.x - self.x
		local dy = player.y - self.y
		local l = dx*dx + dy*dy
		if l < 3500 then
			l = 3 / (l ^ 0.5)
			self.x = self.x + dx * l
			self.y = self.y + dy * l
		end

		local d, n, w = polygonCollision(self.trans_model, player.trans_model)
		if d > 0 then
			self:collect(game.player)
			return "kill"
		end
	end

end
function Item:draw()
	self.quads.batch:add(self.quads[math.floor(self.tick / self.frame_length) % #self.quads + 1],
		self.x, self.y, 0, 4, 4, self.size / 2, self.size / 2)
end




BallItem = Item:New { score = 1000, }
BallItem:InitQuads("media/ball_item.png")
function BallItem:subCollect(player)
	for _, ball in ipairs(player.balls) do
		if not ball.alive then ball:activate() end
	end
end

HealthItem = Item:New {
	img = G.newImage("media/health_item.png"),
	size = 9,
	score = 2500,
}
HealthItem:InitQuads("media/health_item.png")
function HealthItem:subCollect(player)
	if player.shield < player.max_shield then
		player.shield = player.shield + 1
	end
end


SpeedItem = Item:New {
	score = 1000,
	frame_length = 5,
}
SpeedItem:InitQuads("media/speed_item.png")
function SpeedItem:subCollect(player)
	player.speed_boost = player.speed_boost + 1
end


MoneyItem = Item:New {
	size = 9,
	score = 10000,
}
MoneyItem:InitQuads("media/money_item.png")



EnergyItem = Item:New {
	size = 8,
	score = 80,
	model = { 8, 8, 8, -8, -8, -8, -8, 8, },
	frame_length = 2,
	layer = "back",
}
EnergyItem:InitQuads("media/energy_item.png")
initPolygonRadius(EnergyItem.model)
function EnergyItem:init(x, y, vx, vy)
	table.insert(self.list, self)
	self.x = x
	self.y = y
	self.tick = 0
	self.trans_model = {}
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

	if self.y > 330 then return "kill" end

	transform(self)
	local d, n, w = game.walls:checkCollision(self.trans_model)
	if d > 0 then
		self.x = self.x - n[1] * d
		self.y = self.y - n[2] * d
		transform(self)

		local dot = (self.vx * n[1] + self.vy * n[2]) * 2
		self.vx = self.vx - dot * n[1]
		self.vy = self.vy - dot * n[2]
	end

	local player = game.player
	if player.alive then
		local dx = player.x - self.x
		local dy = player.y - self.y
		local l = dx*dx + dy*dy
		if l < 6000 then
			l = 5 / (l ^ 0.5)
			self.x = self.x + dx * l
			self.y = self.y + dy * l
		end


		local d, n, w = polygonCollision(self.trans_model, player.trans_model)
		if d > 0 then
			self:collect(game.player)
			return "kill"
		end
	end
end
function EnergyItem:collect(player)
	sound.play("coin", self.x, self.y)
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

local G = love.graphics


Item = Object:new {
	model = { -12, 12, -12, -12, 12, -12, 12, 12 },
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
end
function Item:update()
	self.tick = self.tick + 1
	self.y = self.y + game.walls.speed
	if self.y > 310 then return "kill" end

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
--	G.polygon("line", self.trans_model)
end




HealthItem = Item:new {
	img = G.newImage("media/health_item.png"),
	size = 9,
}
genQuads(HealthItem)
function HealthItem:collect(player)
	player.score = player.score + 2000
	if player.shield < player.max_shield then
		player.shield = player.shield + 1
	end
end

BallItem = Item:new {
	img = G.newImage("media/ball_item.png"),
}
genQuads(BallItem)
function BallItem:collect(player)
	player.score = player.score + 1000
	for _, ball in ipairs(player.balls) do
		if not ball.alive then ball:activate() end
	end
end

local G = love.graphics

BlockadeEnemy = Enemy:New {
	size = 8,
	model = { 16, 12, 16, -12, -16, -12, -16, 12, },
	shield = 10,
	score = 2000,
}
BlockadeEnemy:InitQuads("media/blockade.png")
initPolygonRadius(BlockadeEnemy.model)
function BlockadeEnemy:init(rand, x, y, wall_row, index)
	self:super(rand, x, y - game.walls.speed) -- fix offset issue
	self.neighbors = {}
	self.index = index
	self.wall_row = wall_row
end
function BlockadeEnemy:die()
	self.wall_row[self.index] = 0

	local ttls = { 9, 10 }
	if not self.ttl then
		makeEnergyItem(self.x, self.y, self.rand, 5)
		ttls[2] = 5
	end

	for i, ttl in ipairs(ttls) do
		if self.neighbors[i] then
			self.neighbors[i].ttl = ttl
			self.neighbors[i].neighbors[3 - i] = nil
			self.neighbors[i] = nil
		end
	end
end
function BlockadeEnemy:subUpdate()
	self.y = self.y + game.walls.speed

	if self.ttl then
		self.ttl = self.ttl - 1
		if self.ttl <= 0 then
			self.alive = false
		end
	end

	transform(self)
end

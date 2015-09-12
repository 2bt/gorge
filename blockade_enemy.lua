local G = love.graphics

BlockadeEnemy = Enemy:new {
	size = 8,
	img = G.newImage("media/blockade.png"),
	model = { 16, 12, 16, -12, -16, -12, -16, 12, },
	shield = 10,
	score = 1000,
}
genQuads(BlockadeEnemy)
function BlockadeEnemy:init(x, y, wall_row, index)
	self:super(nil, x, y)
	self.neighbors = {}
	self.index = index
	self.wall_row = wall_row
end
function BlockadeEnemy:die()
	self.wall_row[self.index] = 0

	for i = 1, 2 do
		if self.neighbors[i] then
			self.neighbors[i].ttl = 10
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

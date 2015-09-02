local G = love.graphics

CannonEnemy = Enemy:new {
	shield = 1,
	score = 300,
	img = G.newImage("media/cannon.png"),
	model = { -16, 16, -16, 0, -8, -16, 8, -16, 16, 0, 16, 16 }
}
genQuads(CannonEnemy, 16)
function CannonEnemy:init(rand, x, y, wall)
	self:super(rand, x, y)
	self.nx = 0
	self.ny = 0
	if wall == "up"		then self.ny =1  end
	if wall == "down"	then self.ny =-1  end
	if wall == "left"	then self.nx =1  end
	if wall == "right"	then self.nx =-1  end
	self.ang = math.atan2(-self.nx, -self.ny)
	transform(self)
	self.cannon_ang = self.ang + self.rand.float(-1.3, 1.3)
	self.delay = self.rand.int(100, 150)
end
function CannonEnemy:subUpdate()
	self.y = self.y + game.walls.speed
	transform(self)
	if not game.player.alive then return end

	local dx = game.player.x - self.x
	local dy = game.player.y - self.y
	local ang = math.atan2(-dx, -dy)
	local diff = (self.ang - ang + 3 * math.pi) % (2 * math.pi) - math.pi

	if math.abs(diff) < 1.75 and self.delay < 50
	and not game.walls:checkSight(self.x, self.y, game.player.x, game.player.y) then

		local speed = 0.05
		local d = (self.cannon_ang - ang + math.pi * 3) % (2 * math.pi) - math.pi

		if     d >  speed then self.cannon_ang = self.cannon_ang - speed
		elseif d < -speed then self.cannon_ang = self.cannon_ang + speed
		else
			self.cannon_ang = self.cannon_ang - d
			if self.delay == 0 then
				self.delay = self.rand.int(150, 250)
				local l = (dx*dx + dy*dy) ^ 0.5
				dx = dx / l
				dy = dy / l
				Bullet(self.x + dx * 16, self.y + dy * 16, dx * 4, dy * 4)
			end
		end
	end
	if self.delay > 0 then
		self.delay = self.delay - 1
	end
end
function CannonEnemy:subDraw()
	G.setColor(255, 255, 255)
	G.draw(self.img, self.quads[2], self.x, self.y, -self.cannon_ang or 0, 4, 4, 8, 8)
	G.draw(self.img, self.quads[1], self.x, self.y, -self.ang or 0, 4, 4, 8, 8)
end

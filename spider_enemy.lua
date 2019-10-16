local G = love.graphics

SpiderEnemy = Enemy:New {
	size = 16,
	shield = 1,
	score = 550,
	model = { 5, 16, 16, 5, 16, -5, 5, -16, -5, -16, -16, -5, -16, 5, -5, 16, },
	frame_length = 7,
	speed = 0.8
}
SpiderEnemy:InitQuads("media/spider.png")
initPolygonRadius(SpiderEnemy.model)
function SpiderEnemy:init(rand, x, y, wall)
	self:super(rand, x, y)
	self.nx = 0
	self.ny = 0
	if wall == "up"		then self.ny =  1 end
	if wall == "down"	then self.ny = -1 end
	if wall == "left"	then self.nx =  1 end
	if wall == "right"	then self.nx = -1 end

	if wall == "left"		then self.dir = 1
	elseif wall == "right"	then self.dir = -1
	else
		self.dir = rand.int(0, 1) * 2 - 1
	end
	self.floating = false
	self.shoot = false
	self.delay = self.rand.int(200, 300)

	self.sprite_ang = math.atan2(-self.nx, -self.ny)
end
function SpiderEnemy:die()
	makeEnergyItem(self.x, self.y, self.rand, 3)
	game:trySpawnHeart(self.x, self.y, 2)
end
function SpiderEnemy:subUpdate()
	self.x = self.x
	self.y = self.y + game.walls.speed


	if self.floating then
		self.sprite_ang = self.sprite_ang + self.dir * 0.05
		transform(self)
		return
	end

	-- stick to wall
	self.x = self.x - self.nx
	self.y = self.y - self.ny

	transform(self)
	local d, n, w = game.walls:checkCollision(self.trans_model)
	if d > 0 then
		self.x = self.x - n[1] * d
		self.y = self.y - n[2] * d
		transform(self)
		self.nx = -n[1]
		self.ny = -n[2]
	else
		-- floating
		self.x = self.x + self.nx
		self.y = self.y + self.ny
		self.floating = true
		self.dir = self.rand.int(0, 1) * 2 - 1
		return
	end



	self.delay = self.delay - 1
	if self.delay > 0 then


		-- crawl
		self.x = self.x - self.ny * self.dir * self.speed
		self.y = self.y + self.nx * self.dir * self.speed

		transform(self)
		local d, n, w = game.walls:checkCollision(self.trans_model)
		if d > 0 then
			self.x = self.x - n[1] * d
			self.y = self.y - n[2] * d
			transform(self)

			self.nx = -n[1]
			self.ny = -n[2]

		end

		-- turn
		local dst_ang = math.atan2(-self.nx, -self.ny)
		local ad = (dst_ang - self.sprite_ang + math.pi * 3) % (math.pi * 2) - math.pi
		if ad > math.pi then ad = math.pi * 2 - ad end
		if ad < -math.pi then ad = math.pi * -2 + ad end
		self.sprite_ang = self.sprite_ang + math.max(-0.05, math.min(ad, 0.05))


		-- sight check
		if self.delay == 1 then
			if game.walls:checkSight(self.x, self.y, game.player.x, game.player.y) then
				self.delay = self.rand.int(0, 100)
			end
		end
	else
		if self.delay == 0 then
			self.shoot = true
			self.tick = 0

		end


		if self.delay < -28 * 3 then
			self.delay = self.rand.int(200, 300)
			self.dir = self.rand.int(0, 1) * 2 - 1
			self.shoot = false

		end

		-- shoot
		if self.tick >= 28 and self.tick % 8 == 0 then
			local l = (self.tick - 28) / 56
			if self.dir == -1 then l = 1 - l end
			local ang = l * math.pi - self.sprite_ang
			SpiderBullet(self.x, self.y, -math.cos(ang) * 3, -math.sin(ang) * 3)
			sound.play("spider", self.x, self.y)
		end

	end
end
function SpiderEnemy:subDraw()
	local o = self.shoot and 5 or 1
	self.quads.batch:add(self.quads[math.floor(self.tick / self.frame_length) % 4 + o],
		self.x, self.y, -self.sprite_ang, 4 * self.dir, 4, self.size / 2, self.size / 2)
--	G.polygon("line", self.trans_model)
end
SpiderBullet = Bullet:New {
	color = { 1.0, 0.94, 0 },
	model = { 4, 4, 4, -4, -4, -4, -4, 4, },
	size = 8,
	frame_length = 4,
}
SpiderBullet:InitQuads("media/spider_bullet.png")
initPolygonRadius(SpiderBullet.model)
function SpiderBullet:init(x, y, dx, dy)
	self:super(x, y, dx, dy)
--	self.ang = math.atan2(dx, dy)
end

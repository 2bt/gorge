local G = love.graphics


Ball = Object:new {
	model = { 6, 6, 6, -6, -6, -6, -6, 6, },
	img = G.newImage("media/ball.png")
}
genQuads(Ball, 8)
function Ball:init(player, dir)
	self.player = player
	self.dir = dir
	self.ox = 28 * dir
	self.oy = 8
	self.alive = false
	self.trans_model = {}
--	self.x = 0
--	self.y = 0
--	transform(self)
end
function Ball:activate()
	self.alive = true
	self.x = self.player.x
	self.y = self.player.y
	self.glide = 0
end
function Ball:shoot(side_shoot)
	if not self.alive then return end
	if side_shoot then
		SmallLaser(self.x - 16 * self.dir, self.y, 4 * self.dir, -0.4)
	else
		SmallLaser(self.x, self.y + 16, 0.4 * self.dir, -4)
	end
end
function Ball:hit()
	if not self.alive then return end
	self.alive = false
	for i = 1, 10 do
		ExplosionSparkParticle(self.x, self.y)
	end
	local sm = SmokeParticle(self.x, self.y)
	sm.dx = 0
	sm.dy = 0
	sm.ttl = 8
end
function Ball:update()
	if not self.alive then return end
	local dx = self.player.x + self.ox - self.x
	local dy = self.player.y + self.oy - self.y
	if self.glide < 0.3 then
		self.glide = self.glide + 0.02
	end
	self.x = self.x + dx * self.glide
	self.y = self.y + dy * self.glide
	transform(self)

	-- collision with wall
	local d, n, w = game.walls:checkCollision(self.trans_model, true)
	if d > 0 then
		self:hit()
		return
	end
	-- collision with enemies
	for _, e in ipairs(Enemy.list) do
		local d, n, w = polygonCollision(self.trans_model, e.trans_model)
		if d > 0 then
			e:hit(1)
			self:hit()
			return
		end
	end
end
function Ball:draw()
	if not self.alive then return end
	G.setColor(255, 255, 255)
	local f = math.floor(self.player.tick / 4) % #self.quads + 1
	G.draw(self.img, self.quads[f], self.x, self.y, 0, 4 * self.dir, 4, 4, 4)
--	G.polygon("line", self.trans_model)
end






Player = Object:new {
	img = G.newImage("media/player.png"),
	model = { 16, 16, 16, 0, 4, -12, -4, -12, -16, 0, -16, 16, }
}
genQuads(Player, 16)
function Player:init()
	self.trans_model = {}
	self.balls = { Ball(self, -1), Ball(self, 1) }
end
function Player:reset()
	self.tick = 0
	self.x = 0
	self.y = 350
	self.shield = 3
	self.max_shield = self.shield
	self.alive = true
	self.invincible = 0
	self.score = 0
	self.shoot_delay = 0
	self.side_shoot = false
	self.blast = 0
	self.blast_x = 0
	self.blast_y = 0
	self.flash = 0

	self.balls[1].alive = false
	self.balls[2].alive = false

--	transform(self)
end
function Player:hit(d, n, w, e)
	-- collision
	if d then
		self.x = self.x + n[1] * d
		self.y = self.y + n[2] * d

		-- instand death
		if self.y > 284 and (not e or e.alive) then
			self.invincible = 0
			self.shield = 0
		end

		self.blast_x = n[1] * 7
		self.blast_y = n[2] * 7
		self.blast = 15
		transform(self)
		for i = 1, 10 do
			ExplosionSparkParticle(w[1], w[2])
		end
	end
	-- damage
	if self.invincible == 0 then
		self.invincible = 100
		self.flash = 5
		self.shield = self.shield - 1
		if self.shield <= 0 then
			self.alive = false
			self.balls[1]:hit()
			self.balls[2]:hit()
			makeExplosion(self.x, self.y)
		end
	end
end
function Player:update(input)
	if not self.alive then return end

	self.tick = self.tick + 1
	if self.flash > 0 then self.flash = self.flash - 1 end
	self.blast_x = self.blast_x * 0.85
	self.blast_y = self.blast_y * 0.85

	-- move
	local speed = 3
	if self.shoot_delay > 0 or input.shoot then
		speed = speed * 0.5
	end
	if self.blast > 0 then
		self.blast = self.blast - 1
		speed = 0
	end

	if self.tick < 60 then
		self.y = self.y - 3
		return
	else
		self.x = self.x + self.blast_x + input.dx * speed
		self.y = self.y + self.blast_y + input.dy * speed
		if self.x > 384 then self.x = 384 end
		if self.x <-384 then self.x =-384 end
		if self.y > 284 then self.y = 284 end
		if self.y <-284 then self.y =-284 end
	end
	-- collision with walls
	transform(self)
	local d, n, w = game.walls:checkCollision(self.trans_model, true)
	if d > 0 then
		n[1] = -n[1]
		n[2] = -n[2]
		self:hit(d, n, w)
	end

	-- balls
	self.balls[1]:update()
	self.balls[2]:update()

	-- shoot
	if input.dy > 0 then
		self.side_shoot = false
	elseif input.dy < 0 then
		self.side_shoot = true
	end
	if input.shoot and self.shoot_delay == 0 then
		self.shoot_delay = 10
		Laser(self.x, self.y - 4)
		self.balls[1]:shoot(self.side_shoot)
		self.balls[2]:shoot(self.side_shoot)
	end
	if self.shoot_delay > 0 then
		self.shoot_delay = self.shoot_delay - 1
	end


	-- collision with enemies
	for _, e in ipairs(Enemy.list) do
		local d, n, w = polygonCollision(self.trans_model, e.trans_model)
		if d > 0 then
			e:hit(1)
			self:hit(d, n, w, e)
		end
	end


	if self.invincible > 0 then
		self.invincible = self.invincible - 1
	end
end
function Player:draw()
	if not self.alive then return end

	G.setColor(255, 255, 255)
	self.balls[1]:draw()
	self.balls[2]:draw()

	if self.invincible % 8 >= 4 then return end

	if self.flash > 0 then G.setShader(flash_shader) end

	G.draw(self.img,
		self.quads[1 + math.floor(self.tick / 8 % 2)],
		self.x, self.y, 0, 4, 4, 8, 8)

	if self.flash > 0 then G.setShader() end

--	G.polygon("line", self.trans_model)
end




Laser = Object:new {
	list = {},
	img = G.newImage("media/laser.png"),
	model = { -2, 10, 2, 10, 2, -10, -2, -10, },
	damage = 1
}
function Laser:init(x, y, dx, dy)
	table.insert(self.list, self)
	self.x = x
	self.y = y
	self.dx = dx or 0
	self.dy = dy or -4
	self.trans_model = {}
end
function Laser:update()
	for i = 1, 4 do
		self.x = self.x + self.dx
		self.y = self.y + self.dy
		if self.y < -310 or self.y > 310
		or self.x < -410 or self.x > 410 then return "kill" end
		transform(self)

		local d, n, w = game.walls:checkCollision(self.trans_model, true)
		if d > 0 then
			for i = 1, 10 do
				LaserParticle(w[1], w[2])
			end
			return "kill"
		end

		for _, e in ipairs(Enemy.list) do
			local d, n, w = polygonCollision(self.trans_model, e.trans_model)
			if d > 0 then
				e:hit(self.damage)
				for i = 1, 10 do
					LaserParticle(w[1], w[2])
				end
				return "kill"
			end

		end
	end
end
function Laser:draw()
	local rot = math.atan2(-self.dx, self.dy)
	G.setColor(255, 255, 255)
	G.draw(self.img, self.x, self.y, rot, 4, 4, 1.5, 3)
--	G.polygon("line", self.trans_model)
end

SmallLaser = Laser:new {
	img = G.newImage("media/small_laser.png"),
	model = { -2, 5, 2, 5, 2, -5, -2, -5, },
	damage = 0.5
}

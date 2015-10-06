local G = love.graphics

BallField = Object:new {
	img = G.newImage("media/ball_field.png"),
	model = { 8, 16, 16, 8, 16, -8, 8, -16, -8, -16, -16, -8, -16, 8, -8, 16, },
}
genQuads(BallField, 16)
function BallField:init()
	self.trans_model = {}
end

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
	self.field = BallField()
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

	playSound("hit", self.x, self.y)

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

	self.field.x = self.x
	self.field.y = self.y
	transform(self.field)


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
function Ball:drawField()
	if not self.alive then return end
	local q1 = math.floor( self.player.tick      / 4) % #self.field.quads + 1
	local q2 = math.floor((self.player.tick + 3) / 4) % #self.field.quads + 1
	G.setColor(0, 80, 80, 200)
	G.draw(self.field.img, self.field.quads[q1], self.x, self.y, 0, 4, 4, 8, 8)
	G.setColor(40 + math.sin(self.player.tick / 2) * 40, 80, 80, 200)
	G.draw(self.field.img, self.field.quads[q2], self.x, self.y, 0, 4, 4, 8, 8)
end
function Ball:draw()
	if not self.alive then return end
	G.setColor(255, 255, 255)
	local f = math.floor(self.player.tick / 4) % #self.quads + 1
	G.draw(self.img, self.quads[f], self.x, self.y, 0, 4 * self.dir, 4, 4, 4)
--	G.polygon("line", self.trans_model)
--	if self.field.trans_model[1] then G.polygon("line", self.field.trans_model) end
end




Player = Object:new {
	img = G.newImage("media/player.png"),
	model = { 16, 16, 16, 0, 4, -12, -4, -12, -16, 0, -16, 16, },
	field = {
		img = G.newImage("media/field.png"),
		model = { 16, 24, 24, 16, 24, 0, 4, -20, -4, -20, -24, 0, -24, 16, -16, 24, },
		trans_model = {},
	}
}
genQuads(Player, 16)
genQuads(Player.field, 16)
function Player:init()
	self.trans_model = {}
	self.balls = { Ball(self, -1), Ball(self, 1) }
	self.energy_blast = EnergyBlast()
	self.field_sound = newLoopSound("field")
end
function Player:reset()
	self.tick = 0
	self.x = 0
	self.y = 350
	self.shield = 3
	self.max_shield = self.shield
	self.score = 0
	self.energy = 0
	self.max_energy = 30
	self.field_active = false
	self.speed_boost = 0
	self.alive = true
	self.invincible = 0
	self.shoot_delay = 0
	self.side_shoot = false
	self.blast = 0
	self.blast_x = 0
	self.blast_y = 0
	self.flash = 0

	self.balls[1].alive = false
	self.balls[2].alive = false
	self.energy_blast.alive = false

--	transform(self)
end
function Player:hit(d, n, w, e)
	playSound("hit", self.x, self.y)

	if DEBUG then return end
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
		self.invincible = 120
		self.flash = 5
		self.shield = self.shield - 1
		if self.shield <= 0 then
			self.alive = false
			self.field_sound:stop()
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

	-- calc speed
	local speed = 0
	if self.blast > 0 then
		self.blast = self.blast - 1
	else
--		speed = 3 + self.speed_boost * 0.2
		speed = math.sqrt(self.speed_boost + 9)

		if self.shoot_delay > 0 or input.a then
			speed = speed * 0.5
		end
	end

	-- move
	if self.tick < 60 then
		self.y = self.y - 3
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

	if self.tick < 60 then return end

	-- shoot
	if input.dy > 0 then
		self.side_shoot = false
	elseif input.dy < 0 then
		self.side_shoot = true
	end
	if input.a and self.shoot_delay == 0 and self.blast == 0 then
		playSound("laser", self.x, self.y)
		self.shoot_delay = 10
		Laser(self.x, self.y - 4)
		self.balls[1]:shoot(self.side_shoot)
		self.balls[2]:shoot(self.side_shoot)
	end
	if self.shoot_delay > 0 then
		self.shoot_delay = self.shoot_delay - 1
	end


	-- field
	if self.field_active then
		self.energy = self.energy - 0.075
		if self.energy < 0 then
			self.energy = 0
			self.field_active = false
			self.field_sound:stop()
		end

		-- energy blast
		if input.b and not self.input_b then

			self.energy_blast:activate(self.x, self.y)
			self.energy = 0
			self.field_active = false
			self.field_sound:stop()
		end

	elseif input.b and self.energy >= self.max_energy then
		self.field_active = true
		self.field_sound:play()
	end


	self.energy_blast:update()

	self.field_sound:setPosition(self.x, self.y, 0)

	self.input_b = input.b

	self.field.x = self.x
	self.field.y = self.y
	transform(self.field)


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
	self.energy_blast:draw()

	if not self.alive then return end


	-- field
	if self.field_active then

		self.balls[1]:drawField()
		self.balls[2]:drawField()

		local q1 = math.floor( self.tick      / 4) % #self.field.quads + 1
		local q2 = math.floor((self.tick + 3) / 4) % #self.field.quads + 1
		G.setColor(0, 80, 80, 200)
		G.draw(self.field.img, self.field.quads[q1], self.x, self.y, 0, 4, 4, 8, 8)
		G.setColor(40 + math.sin(self.tick / 2) * 40, 80, 80, 200)
		G.draw(self.field.img, self.field.quads[q2], self.x, self.y, 0, 4, 4, 8, 8)
	end

	-- balls
	self.balls[1]:draw()
	self.balls[2]:draw()


	if self.invincible % 8 >= 4 then return end


	if self.flash > 0 then G.setShader(flash_shader) end
	G.setColor(255, 255, 255)
	G.draw(self.img,
		self.quads[1 + math.floor(self.tick / 8 % 2)],
		self.x, self.y, 0, 4, 4, 8, 8)

	if self.flash > 0 then G.setShader() end

--	if self.trans_model[1] then G.polygon("line", self.trans_model) end
--	if self.field.trans_model[1] then G.polygon("line", self.field.trans_model) end
end




Laser = Object:new {
	list = {},
	img = G.newImage("media/laser.png"),
	model = { -2, 10, 2, 10, 2, -10, -2, -10, },
	damage = 1
}
function Laser:init(x, y, vx, vy)
	table.insert(self.list, self)
	self.x = x
	self.y = y
	self.vx = vx or 0
	self.vy = vy or -4
	self.ang = math.atan2(self.vx, self.vy)
	self.trans_model = {}
end
function Laser:update()
	for i = 1, 4 do
		self.x = self.x + self.vx
		self.y = self.y + self.vy
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
			local d, n, w = polygonCollision(e.trans_model, self.trans_model)
			if d > 0 then
				e:hit(self.damage)
				for i = 1, 10 do
					LaserParticle(w[1], w[2])
				end
				return "kill"
			end

		end
	end
	if self.ttl then
		self.ttl = self.ttl - 1
		if self.ttl <= 0 then return "kill" end
	end
end
function Laser:draw()
	G.setColor(255, 255, 255)
	G.draw(self.img, self.x, self.y, -self.ang, 4, 4, 1.5, 3)
--	G.polygon("line", self.trans_model)
end

SmallLaser = Laser:new {
	img = G.newImage("media/small_laser.png"),
	model = { -2, 5, 2, 5, 2, -5, -2, -5, },
	damage = 0.5
}



EnergyBlast = Object:new {
	canvas = G.newCanvas(100, 100),
	shader = G.newShader([[
		uniform float r;
		uniform float s;
		float a[] = float[]( 0, 1, 1, 0, 0, 1 );
		vec4 effect(vec4 col, sampler2D tex, vec2 tex_coords, vec2 screen_coords) {

			float d = distance(vec2(50, 50), screen_coords);
			if (d > r) return vec4(0);
			if (d < s) {
				int i = int(floor(s - d));
				float x = i < a.length ? a[i] : 0;
				return vec4(0, 1, 1, 0.6) * x;
			}
			if (d > r - 1) return vec4(1, 1, 1, 1);
			return vec4(0, 1, 1, 0.6);
		}
	]]),
}

function EnergyBlast:activate(x, y)
	playSound("blast", self.x, self.y)
	self.damage = 4
	self.alive = true
	self.x = x
	self.y = y
	self.level = 0
	self.radius = 0
	self.hit_enemies = {}
end
function EnergyBlast:update()
	if not self.alive then return end

	self.y = self.y + game.walls.speed

	self.level = self.level + 0.025

	self.r = (1 - 2 ^ (-4 * self.level)) * 40
	self.s = (1 - 2 ^ (-1.7 * self.level)) * 60
	self.radius = self.r * 4

	if self.level >= 1.2 then
		self.alive = false
	end
end
function EnergyBlast:draw()
	if not self.alive then return end

	self.canvas:renderTo(function()
		G.clear()
		G.push()
		G.origin()
		self.shader:send("r", self.r)
		self.shader:send("s", self.s)

		G.setShader(self.shader)
		G.rectangle("fill", 0, 0, 128, 128)
		G.setShader()
		G.pop()
	end)
	G.setColor(255, 255, 255, 200)
	G.draw(self.canvas, self.x, self.y, 0, 4, 4, 50, 50)
end


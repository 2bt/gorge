local G = love.graphics

SaucerEnemy = Enemy:New {
	size = 24,
	score = 5000,
	model = {
		-16, 24,
		16, 24,
		40, 8,
		40, 0,
		8, -28,
		-8, -28,
		-40, 0,
		-40, 8,
	},
	bounce_model = {
		32, 64,
		64, 32,
		64, -32,
		32, -64,
		-32, -64,
		-64, -32,
		-64, 32,
		-32, 64,
	},

	shield = 20,
}
SaucerEnemy:InitQuads("media/saucer.png")
initPolygonRadius(SaucerEnemy.model)
function SaucerEnemy:init(rand, x, y)
	self:super(rand, x, y)
	transform(self)
	self.tx = rand.int(0, 1) * 2 - 1
	self.ty = -1
	self.vx = 0
	self.vy = 0
	self.r = rand.float(0, math.pi * 2)
end
function SaucerEnemy:die()
	makeEnergyItem(self.x, self.y, self.rand, 10)
	SaucerParticle(self.x, self.y)
end
function SaucerEnemy:subUpdate()
	if love.keyboard.isDown("q") then return end

	self.x = self.x + self.vx
	self.y = self.y + game.walls.speed + self.vy + math.sin(self.tick / 8) * 0.7


	if self.vx < self.tx then self.vx = math.min(self.vx + 0.1, self.tx) end
	if self.vx > self.tx then self.vx = math.max(self.vx - 0.1, self.tx) end
	if self.vy < self.ty then self.vy = math.min(self.vy + 0.1, self.ty) end
	if self.vy > self.ty then self.vy = math.max(self.vy - 0.1, self.ty) end


	transform(self, self.bounce_model)
	local d, n, w = game.walls:checkCollision(self.trans_model)
	if d > 0 then
		if n[1] > 0.1 then
			self.tx = -1
		elseif n[1] < -0.1 then
			self.tx = 1
		end

		if n[2] > 0.1 then
			self.ty = -1
		elseif n[2] < -0.1 then
			self.ty = 0.5
		end

	else

		-- hover for a while
		if self.tick < 2000 then
			local oy = -80 + math.sin(self.r + self.tick / 200) * 150
			self.ty = math.max(-0.5, math.min(0.5, oy - self.y)) - 1
		else
			self.ty = 0.5
		end

		-- don't leave the screen
		if self.x < -350 then self.tx =  1 end
		if self.x >  350 then self.tx = -1 end
	end


	-- shoot
	if self.y > -270 then
		local t = self.tick % 200
		if t >= 5 and t < 90 and t % 5 == 0 then
			local p = t / 5 % 4 - 1
			if p == 2 then p = 0 end
			SaucerBullet(self.x + p * 20, self.y + 24, 0, 10)
			sound.play("saucer", self.x, self.y)
		end
	end


	transform(self, self.model)
end

SaucerParticle = Particle:New {
	size = 24,
	quads = SaucerEnemy.quads,
	layer = "back",
}
function SaucerParticle:update()
	self.y = self.y + game.walls.speed
	self.tick = self.tick + 1
	if self.tick % 10 == 0 then
		makeExplosion(self.x + math.random(-40, 40), self.y + math.random(-28, 24))
	end
	if self.tick == 40 then
		-- big explosion
		quake = 10 -- shake screen
		sound.play("big_explosion", self.x, self.y)

		makeExplosion(self.x, self.y)
		for i = 1, 4 do
			makeExplosion(self.x + math.random(-40, 40), self.y + math.random(-28, 24))
		end
		PraxisParticle(self.x, self.y)


		game:trySpawnHeart(self.x, self.y, 5)

		return "kill"
	end
end
function SaucerParticle:draw()
	self.quads.batch:setColor(127, 127, 127)
	self.quads.batch:add(self.quads[1],
		self.x, self.y, 0, 4, 4, self.size / 2, self.size / 2)
end


SaucerBullet = Bullet:New {
	model = { 2,  10, 2, -10, -2, -10, -2,  10, },
	size = 9,
	color = { 255, 255, 120 },
}
SaucerBullet:InitQuads("media/saucer_bullet.png")
initPolygonRadius(SaucerBullet.model)


-- explosion wave
PraxisParticle = Particle:New {
	layer = "back",
	canvas = G.newCanvas(80, 80),
	-- TODO: fix this for android
--[=[
	shader = G.newShader([[
		uniform float f;
		float a[5] = float[5]( 1.0, 1.0, 0.0, 0.0, 1.0 );
		vec4 effect(vec4 col, sampler2D tex, vec2 tex_coords, vec2 screen_coords) {
			float d = distance(vec2(40.0, 40.0), screen_coords);
			int i = int(f - d);
			if (i >= 0 && i < a.length()) return vec4(col.rgb, col.a * a[i]);
			return vec4(0.0);
		}
	]]),
--]=]
	shader = G.newShader([[
		uniform float f;
		vec4 effect(vec4 col, sampler2D tex, vec2 tex_coords, vec2 screen_coords) {
			float d = distance(vec2(40.0, 40.0), screen_coords);
//			int i = int(f - d);
//			if (i >= 0 && i < 5 && i != 2) return vec4(col.rgb, col.a);
			d = f - d;
			if (d >= 0.0 && d < 5.0 && !(d > 2.0 && d < 4.0)) return vec4(col.rgb, col.a);
			return vec4(0.0);
		}
	]]),
}
function PraxisParticle:init(x, y)
	table.insert(self.list, self)
	self.x = x
	self.y = y
	self.tick = 0
end
function PraxisParticle:update()
	self.tick = self.tick + 1
	self.y = self.y + game.walls.speed
	if self.tick > 30 then return "kill" end
end
function PraxisParticle:draw()

	local f = self.tick / 30
	local c = (1 - f) ^ 0.4 * 200
	self.canvas:renderTo(function()
		G.clear(0, 0, 0, 0)
		G.push()
		G.origin()
		G.setColor(160, 160, 160, c)
		self.shader:send("f", (1 - 2 ^ (-3 * f)) * 40)
		G.setShader(self.shader)
		G.rectangle("fill", 0, 0, 80, 80)
		G.setShader()
		G.pop()
	end)
	G.setColor(255, 255, 255)
	G.draw(self.canvas, self.x, self.y, 0, 4, 4, 40, 40)
end



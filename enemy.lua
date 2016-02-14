local G = love.graphics

Enemy = Object:New {
	quad_generator = Player.quad_generator,
	list = {},
	ang = 0,
	flash = 0,
	score = 0,
	frame_length = 4,
	alive = true,
	hit_by_energy_blast = false,
}
function Enemy:init(rand, x, y)
	table.insert(self.list, self)
	self.rand = rand
	self.trans_model = {}
	self.x = x
	self.y = y
	self.tick = 0
	self.entered_screen = false
	transform(self)
end
function Enemy:hit(damage)
	sound.play("hit", self.x, self.y)
	self.flash = 3
	self.shield = self.shield - damage
	if self.shield <= 0 then
		self.alive = false
		game.player.score = game.player.score + self.score
	end
end
function Enemy:kill()
end
function Enemy:die()
end
function Enemy:update()
	if not self.alive then
		makeExplosion(self.x, self.y)
		self:die()
		return "kill"
	end
	-- in screen?
	if not self.entered_screen
	and self.x < 428 and self.x > -428
	and self.y < 328 and self.y > -328 then
		self.entered_screen = true
	end
	if self.entered_screen and (self.y < -328 or self.y > 328)
	or self.x > 428 or self.x < -428
	or self.y > 500 then return "kill" end

	if self.flash > 0 then self.flash = self.flash - 1 end
	self.tick = self.tick + 1


	local player = game.player

	if not self.hit_by_energy_blast then
		local blast = player.energy_blast
		if blast.alive then
			local x, y = naivePolygonCircleCollision(self.trans_model, blast.x, blast.y, blast.radius)
			if x then
				self:hit(blast.damage)
				self.hit_by_energy_blast = true
			end
		end
	end

	self:subUpdate()
end
function Enemy:draw()
	if self.flash > 0 then
		self.quads.batch:setColor(255, 255, 255, 127)
	else
		self.quads.batch:setColor(255, 255, 255)
	end
	self:subDraw()
end
function Enemy:subDraw()
	self.quads.batch:add(self.quads[math.floor(self.tick / self.frame_length) % #self.quads + 1],
		self.x, self.y, -self.ang, 4, 4, self.size / 2, self.size / 2)
--	G.polygon("line", self.trans_model)
end






-- bullet ----------------------------------------------------------------------
Bullet = Object:New {
	quad_generator = Laser.quad_generator,
	list = {},
	frame_length = 4,
	size = 8,
	ang = 0,
}
function Bullet:init(x, y, vx, vy)
	table.insert(self.list, self)
	self.trans_model = {}
	self.x = x
	self.y = y
	self.vx = vx
	self.vy = vy
	self.tick = 0
end
function Bullet:makeSparks(x, y)
	local c = self.color
	for i = 1, 10 do BulletParticle(x, y, {c[1] * 0.6, c[2] * 0.6, c[3] * 0.6}) end
end
function Bullet:update()
	self.tick = self.tick + 1
	for i = 1, 2 do
		self.x = self.x + self.vx / 2
		self.y = self.y + self.vy / 2
		transform(self)

		if self.x > 405 or self.x < -405
		or self.y > 305 or self.y < -305 then
			return "kill"
		end

		local d, n, w = game.walls:checkCollision(self.trans_model)
		if d > 0 then
			sound.play("miss", w[1], w[2])
			self:makeSparks(w[1], w[2])
			return "kill"
		end

		local player = game.player

		local blast = player.energy_blast
		if blast.alive then
			local x, y = naivePolygonCircleCollision(self.trans_model, blast.x, blast.y, blast.radius)
			if x then
				sound.play("miss", x, y)
				self:makeSparks(x, y)
				return "kill"
			end
		end


		if player.alive then
			if player.field_active then
				local d, n, w = polygonCollision(self.trans_model, player.field.trans_model)
				if d > 0 then
					self:makeSparks(w[1], w[2])
					return "kill"
				end
			elseif player.invincible == 0 then
				local d, n, w = polygonCollision(self.trans_model, player.trans_model)
				if d > 0 then
					player:hit()
					self:makeSparks(w[1], w[2])
					return "kill"
				end
			end
			for _, ball in ipairs(player.balls) do
				if ball.alive then
					if player.field_active then
						local d, n, w = polygonCollision(self.trans_model, ball.field.trans_model)
						if d > 0 then
							self:makeSparks(w[1], w[2])
							return "kill"
						end
					else
						local d, n, w = polygonCollision(self.trans_model, ball.trans_model)
						if d > 0 then
							ball:hit()
							self:makeSparks(w[1], w[2])
							return "kill"
						end
					end
				end
			end
		end
	end
end
function Bullet:draw()
	self.quads.batch:add(self.quads[math.floor(self.tick / self.frame_length) % #self.quads + 1],
		self.x, self.y, -self.ang, 4, 4, self.size / 2, self.size / 2)
--	G.polygon("line", self.trans_model)
end


BulletParticle = SparkParticle:New {
	friction = 0.9,
}
function BulletParticle:init(x, y, color)
	self:super(x, y)
	self.color = color
end
PlasmaBullet = Bullet:New {
	color = { 255, 36, 36 },
	model = { 4, 4, 4, -4, -4, -4, -4, 4, },
	frame_length = 2,
	size = 7,
}
PlasmaBullet:InitQuads("media/plasma_bullet.png")
initPolygonRadius(PlasmaBullet.model)




-- more enemies

require "blockade_enemy"
require "cannon_enemy"
require "ring_enemy"
require "rocket_enemy"
require "saucer_enemy"
require "spider_enemy"
require "square_enemy"
require "twister_enemy"

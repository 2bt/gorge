local G = love.graphics

Enemy = Object:new {
	list = {},
	alive = true,
	ang = 0,
	flash = 0,
	score = 0,
	frame_length = 4,
	size = 16,
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
	self.flash = 3
	self.shield = self.shield - damage
	if self.shield <= 0 then
		self.alive = false
		game.player.score = game.player.score + self.score
	end
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
	and self.x < 420 and self.x > -420
	and self.y < 320 and self.y > -320 then
		self.entered_screen = true
	end
	if self.entered_screen and (self.y < -320 or self.y > 320)
	or self.x > 420 or self.x < -420
	or self.y > 500 then
		return "kill"
	end

	if self.flash > 0 then self.flash = self.flash - 1 end
	self.tick = self.tick + 1

	self:subUpdate()
end
function Enemy:draw()
	if self.flash > 0 then G.setShader(flash_shader) end
	self:subDraw()
	if self.flash > 0 then G.setShader() end
end
function Enemy:subDraw()
	G.setColor(255, 255, 255)
	G.draw(self.img, self.quads[math.floor(self.tick / self.frame_length) % #self.quads + 1],
		self.x, self.y, -self.ang, 4, 4, self.size / 2, self.size / 2)
--	G.polygon("line", self.trans_model)
end


Bullet = Object:new {
	list = {},
	color = { 255, 36, 36 },
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
			self:makeSparks(w[1], w[2])
			return "kill"
		end

		local player = game.player

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
function Bullet:draw()
	G.setColor(255, 255, 255)
	G.draw(self.img, self.quads[math.floor(self.tick / self.frame_length) % #self.quads + 1],
		self.x, self.y, -self.ang, 4, 4, self.size / 2, self.size / 2)
--	G.polygon("line", self.trans_model)
end


BulletParticle = SparkParticle:new {
	friction = 0.9,
}
function BulletParticle:init(x, y, color)
	self:super(x, y)
	self.color = color
end
PlasmaBullet = Bullet:new {
	model = { 4, 4, 4, -4, -4, -4, -4, 4, },
	img = G.newImage("media/plasma.png"),
	frame_length = 2,
	size = 7,
}
genQuads(PlasmaBullet, 7)

require "ring_enemy"
require "square_enemy"
require "rocket_enemy"
require "cannon_enemy"
require "blockade_enemy"
require "twister_enemy"
require "saucer_enemy"

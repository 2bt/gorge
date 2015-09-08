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
	transform(self)
end
function Enemy:hit(damage)
	self.flash = 5
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
	if self.x > 440 or self.x < -440
	or self.y > 340 or self.y < -388 then
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
		self.x, self.y, -self.ang or 0, 4, 4, self.size / 2, self.size / 2)
--	G.polygon("line", self.trans_model)
end


Bullet = Object:new {
	list = {},
	model = { -4, 4, -4, -4, 4, -4, 4, 4 },
	color = { 255, 36, 36 },
}
function Bullet:init(x, y, dx, dy)
	table.insert(self.list, self)
	self.trans_model = {}
	self.x = x
	self.y = y
	self.dx = dx
	self.dy = dy
	self.tick = 0
end
function Bullet:makeSparks(x, y)
	for i = 1, 10 do BulletParticle(x, y) end
end
function Bullet:update()
	self.tick = self.tick + 1
	for i = 1, 2 do
		self.x = self.x + self.dx / 2
		self.y = self.y + self.dy / 2
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

		if game.player.alive then
			if game.player.invincible == 0 then
				local d, n, w = polygonCollision(self.trans_model, game.player.trans_model)
				if d > 0 then
					game.player:hit()
					self:makeSparks(w[1], w[2])
					return "kill"
				end
			end
			for _, ball in ipairs(game.player.balls) do
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
	G.setColor(unpack(self.color))
	G.polygon("fill", self.trans_model)
end
BulletParticle = SparkParticle:new {
	color = { 155, 22, 22 },
	friction = 0.9,
}

PlasmaBullet = Bullet:new {
	img = G.newImage("media/plasma.png")
}
genQuads(PlasmaBullet, 7)
function PlasmaBullet:draw()
	G.setColor(255, 255, 255)
	G.draw(self.img, self.quads[math.floor(self.tick / 2) % #self.quads + 1],
		self.x, self.y, 0, 4, 4, 3.5, 3.5)
end

require "ring_enemy"
require "square_enemy"
require "rocket_enemy"
require "cannon_enemy"
require "blockade_enemy"

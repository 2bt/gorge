local G = love.graphics


Particle = Object:new {
	list = {},
	alive = true,
	frame_length = 3,
	size = 8,
	layer = "front",
}
function Particle:init(x, y)
	table.insert(self.list, self)
	self.x = x
	self.y = y
	self.tick = 0
end
function Particle:draw()
	if self.tick < 0 then return end
	G.setColor(255, 255, 255)
	local f = math.floor(self.tick / self.frame_length) + 1
	if self.quads[f] then
		G.draw(self.img, self.quads[f], self.x, self.y, 0, 4, 4, self.size / 2, self.size / 2)
	else
		self.alive = false
	end
end
function Particle:update()
	self.y = self.y + game.walls.speed
	self.tick = self.tick + 1
	if not self.alive then return "kill" end
end



SparkParticle = Particle:new {
	img = G.newImage("media/spark.png"),
	color = {255, 255, 255},
	friction = 1
}
function SparkParticle:init(x, y)
	table.insert(self.list, self)
	self.x = x
	self.y = y
	local ang = math.random() * 2 * math.pi
	local s = math.random() * 2 + 2
	self.vx = math.sin(ang) * s
	self.vy = math.cos(ang) * s
	self.ttl = math.random(3, 7)
end
function SparkParticle:update()
	self.x = self.x + self.vx
	self.y = self.y + self.vy + game.walls.speed
	self.vx = self.vx * self.friction
	self.vy = self.vy * self.friction
	self.ttl = self.ttl - 1
	if self.ttl <= 0 then return "kill" end
end
function SparkParticle:draw()
	G.setColor(unpack(self.color))
	G.draw(self.img, self.x, self.y, 0, 4, 4, 1.5, 1.5)
end


LaserParticle = SparkParticle:new {
	color = {0, 155, 155},
	friction = 0.7,
}



ExplosionSparkParticle = SparkParticle:new {
	friction = 0.95,
}
function ExplosionSparkParticle:init(x, y)
	table.insert(self.list, self)
	self.x = x
	self.y = y
	local ang = math.random() * 2 * math.pi
	local s = math.random() * 2 + 2
	self.vx = math.sin(ang) * s
	self.vy = math.cos(ang) * s
	self.ttl = math.random(10, 15)
	self.color = {255, math.random(0, 255), 0}
end
function ExplosionSparkParticle:draw()
	local c = self.color
	G.setColor(c[1], c[2], 0, math.min(255, self.ttl * 50))
	G.draw(self.img, self.x, self.y, 0, 4, 4, 1.5, 1.5)
end




SmokeParticle = Particle:new {
	img = G.newImage("media/smoke.png"),
	size = 8,
	friction = 0.8,
	layer = "back"
}
genQuads(SmokeParticle)
function SmokeParticle:init(x, y)
	table.insert(self.list, self)
	self.x = x
	self.y = y
	local ang = math.random() * 2 * math.pi
	local s = math.random() * 2 + 3
	self.vx = math.sin(ang) * s
	self.vy = math.cos(ang) * s
	self.ttl = math.random(20, 25)
end
SmokeParticle.update = SparkParticle.update
function SmokeParticle:draw()
	G.setColor(30, 30, 30, 150)
	local f = math.max(1, #self.quads - math.floor(self.ttl / 3))
	G.draw(self.img, self.quads[f], self.x, self.y, 0, 4, 4, self.size / 2, self.size / 2)
end



ExplosionParticle = Particle:new {
	img = G.newImage("media/explosion.png"),
	size = 16
}
genQuads(ExplosionParticle)


function makeExplosion(x, y)
	playSound("explosion", x, y)
	-- heat wave
	Boom(x, y)

	for i = 1, 10 do
		SmokeParticle(x, y)
	end
	for i = 1, 20 do
		ExplosionSparkParticle(
			x + math.random(-10, 10),
			y + math.random(-10, 10))
	end
	ExplosionParticle(x, y)
end


SparkleParticle = Particle:new {
	img = G.newImage("media/sparkle.png")
}
genQuads(SparkleParticle)
function SparkleParticle:update()
	self.tick = self.tick + 1
	if not self.alive then return "kill" end
end


FastSparkleParticle = Particle:new {
	img = SparkleParticle.img,
	quads = SparkleParticle.quads,
}
function makeFastSparkleParticle(x, y)
	local r = math.random() * 10
	for i = 0, 2 do
		local f = FastSparkleParticle(
			x + math.sin(r) * 12,
			y + math.cos(r) * 12)
			r = r + 2/3 * math.pi
		f.tick = i * -5
	end
end

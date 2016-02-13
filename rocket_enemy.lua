local G = love.graphics

RocketEnemy = Enemy:New {
	size = 16,
	shield = 1,
	score = 150,
	model = { 16, 16, 4, -20, -4, -20, -16, 16, },
	counter = 0,
	active = false,
	suicide = false,
}
RocketEnemy:InitQuads("media/rocket.png")
initPolygonRadius(RocketEnemy.model)
function RocketEnemy:init(rand, x, y, wall)
	self:super(rand, x, y)
	self.vx = 0
	self.vy = 0
	self.nx = 0
	self.ny = 0
	if wall == "up"		then self.ny =  1 end
	if wall == "down"	then self.ny = -1 end
	if wall == "left"	then self.nx =  1 end
	if wall == "right"	then self.nx = -1 end
	self.ang = math.atan2(-self.nx, -self.ny)
	transform(self)
	self.engine_sound = sound.newLoopSource("engine")
end
function RocketEnemy:kill()
	self.engine_sound:stop()
end
function RocketEnemy:die()
	if not self.suicide then
		makeEnergyItem(self.x, self.y, self.rand, 1)
		game:trySpawnFlame(self.x, self.y)
	end
end
function RocketEnemy:subUpdate()
	self.y = self.y + game.walls.speed
	transform(self)


	if self.entered_screen and not self.active and game.player.alive
	and not game.walls:checkSight(self.x, self.y, game.player.x, game.player.y) then
		local dx = game.player.x - self.x
		local dy = game.player.y - self.y
		local dot = self.nx * dx + self.ny * dy
		if dot > 0 then
			local cross = self.nx * dy - self.ny * dx
			if math.abs(cross) < 50 then
				self.active = true
				self.engine_sound:play()
			end
		end
	end
	if self.active then
		self.engine_sound:setPosition(self.x, self.y)
		if self.tick % 4 == 0 then
			local sm = SmokeParticle(self.x - self.nx * 16, self.y - self.ny * 16)
			sm.vx = 0
			sm.vy = 0
			sm.ttl = 8
		end
		self.vx = self.vx + self.nx * 0.1
		self.vy = self.vy + self.ny * 0.1
		self.x = self.x + self.vx
		self.y = self.y + self.vy
		transform(self)
		local d, n, w = game.walls:checkCollision(self.trans_model)
		if d > 0 then
			self.suicide = true
			self.alive = false
		end
	end
end

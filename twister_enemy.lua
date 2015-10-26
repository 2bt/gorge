local G = love.graphics


TwisterSpawn = Particle:new {}
function TwisterSpawn:init(rand, x, y, ang)
	table.insert(self.list, self)
	self.rand = rand
	self.x = x
	self.y = y
	self.tick = 0
	self.ang = ang

	self.count = 4
	self.seed = self.rand.int(0xffffff)
end

function TwisterSpawn:update()
	self.y = self.y + game.walls.speed
	if self.y > 340 then return "kill" end

	if self.tick % 32 == 0 then
		self.count = self.count - 1
		if self.count < 0 then return "kill" end

		local t = TwisterEnemy(self.rand,
			self.x, self.y, self.ang,
			makeRandomGenerator(self.seed))
		t.tick = self.tick / 8
	end

	self.tick = self.tick + 1
end
function TwisterSpawn:draw()
end


TwisterEnemy = Enemy:new {
	model = { 16, 4, 16, -4, -8, -18, -16, -8, -16, 8, -8, 18, },
	left_turn_model = {
		40, 14,
		60, -6,
		60, -48,
		40, -68,
		-16, -68,
		-16, 14,
	},
	right_turn_model = {
		40, 68,
		60, 48,
		60, 6,
		40, -14,
		-16, -14,
		-16, 68,
	},
	img = G.newImage("media/twister.png"),
	frame_length = 4,
	shield = 1,
	score = 120,
	speed = 2,
	turn_speed = 1 / 32.0 * 4
}


genQuads(TwisterEnemy)
function TwisterEnemy:init(rand, x, y, ang, path_rand)
	self:super(rand, x, y)
	self.path_rand = path_rand
	self.ang = ang
	self.dst_ang = self.ang
	self.cnt = self.path_rand.int(50, 200)
end
function TwisterEnemy:subUpdate()


	local vx = math.cos(self.ang) * self.speed
	local vy = -math.sin(self.ang) * self.speed
	self.x = self.x + vx
	self.y = self.y + vy + game.walls.speed


	if self.dst_ang > self.ang then
		self.ang = math.min(self.ang + self.turn_speed, self.dst_ang)
	elseif self.dst_ang < self.ang then
		self.ang = math.max(self.ang - self.turn_speed, self.dst_ang)
	else
		self.cnt = self.cnt - 1

		transform(self, self.left_turn_model)
		local dl = game.walls:checkCollision(self.trans_model)
		transform(self, self.right_turn_model)
		local dr = game.walls:checkCollision(self.trans_model)
		if self.cnt <= 0 or (dl > 0 and dr > 0) then

			self.cnt = self.path_rand.int(10, 200)

			if dl < dr then
				self.dst_ang = self.dst_ang + math.pi * 0.5
			elseif dl > dr then
				self.dst_ang = self.dst_ang - math.pi * 0.5
			else
				self.dst_ang = self.dst_ang + (self.path_rand.int(0, 1) - 0.5) * math.pi
			end
		end


	end
	transform(self)

	-- shoot
	local player = game.player
	if self.y < -300 or self.y > 300 or not player.alive
	or game.walls:checkSight(self.x, self.y, player.x, player.y) then
		return
	end

	if self.rand.int(1, 1000) == 1 then

		local dx = player.x - self.x
		local dy = player.y - self.y
		local ang = math.atan2(dx, dy) + self.rand.float(-0.2, 0.2)
		PlasmaBullet(self.x, self.y, math.sin(ang) * 4, math.cos(ang) * 4)
		sound.play("plasma", self.x, self.y)
	end

end
function TwisterEnemy:die()
	makeEnergyItem(self.x, self.y, self.rand, 1)
	game:trySpawnHeart(self.x, self.y)
end
function TwisterEnemy:subDraw_()
	G.setColor(255, 0, 0)
	G.rectangle("fill", self.x - 10, self.y - 10, 20, 20)
	transform(self, self.right_turn_model)
	G.polygon("line", self.trans_model)
	transform(self, self.left_turn_model)
	G.polygon("line", self.trans_model)
	Enemy.subDraw(self)
end

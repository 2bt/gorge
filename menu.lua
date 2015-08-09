local G = love.graphics
local isDown = love.keyboard.isDown




--if love.filesystem.isFile("score") then
--	print("exists")
--else
--	love.filesystem.newFile("score", "w"):write("hiya")
--	print("new")
--end



Menu = Object()
Menu.img = G.newImage("media/title.png")
Menu.options = {
	main = {
		"START GAME",
		"HIGHSCORE",
		"CREDITS",
		"EXIT"
	},
	credits = { "BACK" },
	score = { "BACK" }
}
function Menu:init()
	self.stars = Stars()
	self.stars:reset(makeRandomGenerator(32))
	self:reset()
end
function Menu:reset()
	self:swapState("main")
end
function Menu:swapState(state)
	self.state = state
	self.action = false
	self.select = 1
	self.tick = 0
	self.blend = 1
	Particle.list = {}
end
function Menu:update()
	self.tick = self.tick + 1


	self.stars:update(1.25)
	updateList(Particle.list)

	if self.state == "main" then
		if math.random() < 0.3 then
			SparkleParticle( math.random(200, 600), math.random(116, 210))
		end
	end


	local dy = bool[isDown("down")] - bool[isDown("up")]
	local pick = isDown("space") or isDown("x")
	local escape = isDown("escape")

	if not self.action then
		if self.blend > 0 then
			self.blend = self.blend - 0.1
		end

		if self.options[self.state] then
			if dy ~= 0 and self.dy == 0 then
				self.select = self.select + dy
				self.select = math.max(self.select, 1)
				self.select = math.min(self.select, #self.options[self.state])
				self.tick = 0
			end
			if pick and not self.pick then
				self.action = self.options[self.state][self.select]
			end
		end


		if escape and not self.escape then
			if self.state == "main" then
				self.action = "EXIT"
			else
				self.action = "BACK"
			end
		end
	else
		if self.blend < 1 then
			self.blend = self.blend + 0.1
		end
	end


	self.dy = dy
	self.pick = pick
	self.escape = escape



	if self.blend >= 1 then
		if self.action == "EXIT" then
			love.event.quit()
		elseif self.action == "BACK" then
				self:swapState("main")
		elseif self.action == "START GAME" then
			state = game
			game:reset()
		elseif self.action == "HIGHSCORE" then
			self:swapState("score")
		elseif self.action == "CREDITS" then
			self:swapState("credits")
		end
	end
end
function Menu:draw()


	G.scale(G.getWidth() / 800, G.getHeight() / 600)
	G.translate(400, 300)
	self.stars:draw()


	G.setColor(255, 255, 255)
	G.origin()
	G.scale(G.getWidth() / 800, G.getHeight() / 600)
	if self.state == "main" then
		G.draw(self.img, 400, 120, 0, 4, 4, self.img:getWidth() / 2)
	end

	drawList(Particle.list)

--	for i = 1, 10 do
--		font:printCentered(
--			("%2d - %08d - %-12s"):format(i, (11 - i) * 1E6, "TWOBIT______"),
--			400,
--			240 + 24 * i, 3)
--	end


	if self.options[self.state] then
		for i, m in ipairs(self.options[self.state]) do
			font:print(m, 400 - 140, 320 + 40 * (i - 1), 4)
		end
		if self.tick % 32 < 24 then
			font:print(">", 228, 320 + 40 * (self.select - 1), 4)
		end
	end



	G.setColor(255, 255, 255, 30)
	font:printCentered("\0 2015 DANIEL LANGNER", 400, 360 + 40 * 5, 4)

	if self.blend > 0 then
		G.setColor(0, 0, 0, 255 * self.blend)
		G.rectangle("fill", 0, 0, 800, 600)
	end
end

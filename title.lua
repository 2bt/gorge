local G = love.graphics
local isDown = love.keyboard.isDown

Title = Object()
Title.img = G.newImage("media/title.png")
function Title:init()
	self.stars = Stars()
	self.stars:reset(makeRandomGenerator(32))
	self:reset()
end
function Title:reset()
	self.blend = 1
	self.action = false
	self.tick = 0
	Particle.list = {}
end
function Title:update()
	self.tick = self.tick + 1

	self.stars:update(1.25)
	updateList(Particle.list)
	if math.random() < 0.3 then
		SparkleParticle(
			math.random(200, 600),
			math.random(116, 210))
	end


	if not self.action then
		if self.blend > 0 then
			self.blend = self.blend - 0.1
		end
		if isDown("space") then
			self.action = "start"
		end
		if isDown("escape") then
			self.action = "quit"
		end
	else
		if self.blend < 1 then
			self.blend = self.blend + 0.1
		end
	end


	if self.blend >= 1 then
		self.blend = 1
		if self.action == "quit" then
			love.event.quit()
		elseif self.action == "start" then
			state = game
			game:reset()
		end
	end
end
function Title:draw()

	G.scale(G.getWidth() / 800, G.getHeight() / 600)
	G.translate(400, 300)
	self.stars:draw()



	G.setColor(255, 255, 255)
	G.origin()
	G.scale(G.getWidth() / 800, G.getHeight() / 600)
	G.draw(self.img, 400, 120, 0, 4, 4, self.img:getWidth() / 2)

	drawList(Particle.list)

--	font:printCentered("START GAME", 	400, 320 + 40 * 0, 3)
--	font:printCentered("WATCH REPLAY",	400, 320 + 40 * 1, 3)
--	font:printCentered("OPTIONS",		400, 320 + 40 * 2, 3)
--	font:printCentered("EXIT",			400, 320 + 40 * 3, 3)

	if self.tick % 30 < 20 then
		font:printCentered("PESS [SPACE] TO PLAY",	400, 380, 3)
	end

--	for i = 1, 10 do
--		font:printCentered(
--			("%2d - %08d - %-12s"):format(i, (11 - i) * 1E6, "TWOBIT______"),
--			400,
--			240 + 24 * i, 3)
--	end



	font:printCentered("\0 2015 DANIEL LANGNER", 400, 360 + 40 * 5, 3)

	if self.blend > 0 then
		G.setColor(0, 0, 0, 255 * self.blend)
		G.rectangle("fill", 0, 0, 800, 600)
	end
end

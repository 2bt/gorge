local G = love.graphics
local isDown = love.keyboard.isDown


local stats

if love.filesystem.isFile("stats") then
	stats = loadstring("return " .. love.filesystem.read("stats"))()
else
	stats = {
		record = false,
		highscore = {
			{ "TWOBIT", 1000 },
			{ "TWOBIT",  900 },
			{ "TWOBIT",  800 },
			{ "TWOBIT",  700 },
			{ "TWOBIT",  600 },
			{ "TWOBIT",  500 },
			{ "TWOBIT",  400 },
			{ "TWOBIT",  300 },
			{ "TWOBIT",  200 },
			{ "TWOBIT",  100 },
		}
	}
end

local function saveStats()
	local f = love.filesystem.newFile("stats", "w")
	local function w(t)
		if type(t) == "table" then
			f:write("{")
			local j = 1
			for i, a in pairs(t) do
				if i == j then
					j = j + 1
				else
					if type(i) == "number" then
						f:write("[" .. i .. "]=")
					else
						f:write(i .. "=")
					end
				end
				w(a)
				f:write(",")
			end
			f:write("}")
		elseif type(t) == "string" then
			f:write(("%q"):format(t))
		else
			f:write(tostring(t))
		end
	end
	w(stats)
	f:close()
end


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
	highscore = { "BACK" }
}
function Menu:init()
	self.stars = Stars()
	self.stars:reset(makeRandomGenerator(32))
	self:swapState("main")
end
function Menu:swapState(state)
	self.state = state
	self.action = false
	self.select = 1
	self.tick = 0
	self.blink = 0
	self.blend = 1
	self.entry = false
	Particle.list = {}
end
function Menu:gameOver(game)
	local entry = {"", game.player.score }

	for i, e in ipairs(stats.highscore) do
		if e[2] < entry[2] then
			table.insert(stats.highscore, i, entry)
			table.remove(stats.highscore)
			if not stats.record or i == 1 then
				stats.record = game.record
			end
			self:swapState("highscore")
			self.entry = entry
			return
		end
	end
	self:swapState("main")
end
function Menu:update()
	self.tick = self.tick + 1
	self.blink = (self.blink + 1) % 32

	self.stars:update(1.25)
	updateList(Particle.list)

	if self.state == "main" then
		if math.random() < 0.3 then
			SparkleParticle(math.random(200, 600), math.random(136, 230))
		end
	end


	if not self.action then
		if self.blend > 0 then
			self.blend = self.blend - 0.1
		end
	else
		if self.blend < 1 then
			self.blend = self.blend + 0.1
		end
	end


	if self.blend >= 1 then
		if self.action == "EXIT" then
			love.event.quit()
		elseif self.action == "BACK" then
				self:swapState("main")
		elseif self.action == "START GAME" then
			state = game
			game:reset()
		elseif self.action == "HIGHSCORE" then
			self:swapState("highscore")
		elseif self.action == "CREDITS" then
			self:swapState("credits")
		end
	end
end
function Menu:keypressed(key, isrepeat)
	if self.state == "highscore" and self.entry then
		if key == "backspace" then
			self.entry[1] = self.entry[1]:sub(1, -2)
			self.blink = 0
		elseif key == "return" or key == "escape" then
			saveStats()
			self.entry = false
			return
		end

		if #self.entry[1] >= 12 then return end

		if #key == 1 and key:match("[%a%d]") then
			self.entry[1] = self.entry[1] .. key:upper()
			self.blink = 0
		elseif key == "space" then
			self.entry[1] = self.entry[1] .. " "
			self.blink = 0
		end
		return
	end


	if self.action then return end

	if self.options[self.state] then
		local dy = bool[key == "down"] - bool[key == "up"]
		if dy ~= 0 then
			local s = self.select
			self.select = self.select + dy
			self.select = math.max(self.select, 1)
			self.select = math.min(self.select, #self.options[self.state])
			if self.select ~= s then self.blink = 0 end
		end
		if key == "return" or key == "space" or key == "x" then
			self.action = self.options[self.state][self.select]
		end
	end

	if key == "escape" then
		if self.state == "main" then
			self.action = "EXIT"
		else
			self.action = "BACK"
		end
	end

end
function Menu:draw()

	G.scale(G.getWidth() / 800, G.getHeight() / 600)
	G.translate(400, 300)
	self.stars:draw()
	G.origin()
	G.scale(G.getWidth() / 800, G.getHeight() / 600)

	if self.state == "main" then
		G.setColor(255, 255, 255)
		G.draw(self.img, 400, 140, 0, 4, 4, self.img:getWidth() / 2)
		drawList(Particle.list)
	end



	-- draw highscore
	if self.state == "highscore" then
		G.setColor(255, 255, 0)
		font:print("HIGHSCORE", 280 - 24 * 4, 140 - 32, 4)

		G.setColor(255, 255, 255)
		for i, e in ipairs(stats.highscore) do
			font:print(
				("%2d  %-12s  %08d"):format(i,
					e[1], e[2]),
				400 - 24 * 13,
				140 + 32 * i, 4)
			if e == self.entry and self.blink < 24 then
				font:print("\x7f",
					400 + 24 * (#self.entry[1] - 9),
					140 + 32 * i, 4)
			end
		end
	end


	-- draw options
--	if self.options[self.state] then
	if self.state == "main" then
		for i, m in ipairs(self.options[self.state]) do
			font:print(m, 280, 320 + 40 * (i - 1), 4)
		end
		if self.blink < 24 then
			font:print(">", 280-32, 320 + 40 * (self.select - 1), 4)
		end
	end



	G.setColor(40, 40, 40)
	font:printCentered("\0 2015 DANIEL LANGNER", 400, 360 + 40 * 5, 4)

	if self.blend > 0 then
		G.setColor(0, 0, 0, 255 * self.blend)
		G.rectangle("fill", 0, 0, 800, 600)
	end
end

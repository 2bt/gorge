local http = require("socket.http")

function submitOnlineHighscore(name, score)
	local url = "http://wwwpub.zih.tu-dresden.de/cgi-bin/cgiwrap/~s8572327/gorge"
	local ret, err = http.request(url, score .." ".. name)
	if ret then return tonumber(ret) end
end



local G = love.graphics


local stats = {
	highscore = {
		{ "TWOBIT", 10000 },
		{ "TWOBIT",  9000 },
		{ "TWOBIT",  8000 },
		{ "TWOBIT",  7000 },
		{ "TWOBIT",  6000 },
		{ "TWOBIT",  5000 },
		{ "TWOBIT",  4000 },
		{ "TWOBIT",  3000 },
		{ "TWOBIT",  2000 },
		{ "TWOBIT",  1000 },
	},
	name = "",
}

if love.filesystem.isFile(VERSION) then
	stats = loadstring("return " .. love.filesystem.read(VERSION))()
end

local function saveStats()
	local f = love.filesystem.newFile(VERSION, "w")
	local function w(o)
		local t = type(o)
		if t == "table" then
			f:write("{")
			if o[1] then
				for _, a in ipairs(o) do
					w(a)
					f:write(",")
				end
			else
				for k, a in pairs(o) do
					f:write(k .. "=")
					w(a)
					f:write(",")
				end
			end
			f:write("}")
		elseif t == "string" then
			f:write(("%q"):format(o))
		else
			f:write(tostring(o))
		end
	end
	w(stats)
	f:close()
end


Menu = Object()
Menu.img = G.newImage("media/title.png")
Menu.options = {
	main = { "START GAME", "HIGHSCORE", "OPTIONS", "CREDITS", "EXIT" },
	credits = { "BACK" },
	highscore = { "BACK" },
	options = { "NORMAL FULLSCREEN", "DESKTOP FULLSCREEN", "WINDOW", "BACK" },
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
	self.blend = 1
	self.entry = false
	self.stats_changed = false
	Particle.list = {}
end
function Menu:gameOver(game)
	local entry = { stats.name or "", game.player.score }

	for i, e in ipairs(stats.highscore) do
		if e[2] < entry[2] then
			table.insert(stats.highscore, i, entry)
			table.remove(stats.highscore)
			if not stats.demo or i == 1 then
				stats.demo = {
					record = game.record,
					seed = game.seed
				}
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

	self.stars:update(1)
	updateList(Particle.list)

	if self.state == "main" then
		if math.random() < 0.3 then
			SparkleParticle(math.random(200, 600), math.random(136, 230))
		end
	end


	-- buttons
	if not self.action then

		-- start demo mode
		if self.state == "main" and self.tick > 60 * 10 and stats.demo then
			self.action = "DEMO"
		elseif self.state == "highscore" and self.entry then
			-- write name
			if Input:gotAnyPressed("start") then
				self:submitHighscore(true)
			end
		else
			-- select option
			if self.options[self.state] then
				local dy = bool[Input:gotAnyPressed("down") and true or false]
						 - bool[Input:gotAnyPressed("up") and true or false]
				if dy ~= 0 then
					local s = self.select
					self.select = self.select + dy
					self.select = math.max(self.select, 1)
					self.select = math.min(self.select, #self.options[self.state])
					if self.select ~= s then
						self.tick = 0
					end
				end

				-- remember who started the game
				self.input = Input:gotAnyPressed("start") or Input:gotAnyPressed("a")
				if self.input then
					self.action = self.options[self.state][self.select]
				end
			end

			-- back
			if Input:gotAnyPressed("back") or Input:gotAnyPressed("b") then
				if self.state == "main" then
					self.action = "EXIT"
				else
					self.action = "BACK"
				end
			end
		end

		if self.blend > 0 then
			self.blend = self.blend - 0.1
		end

	else
		if self.blend < 1 then
			self.blend = self.blend + 0.1
		end
		if self.blend >= 1 then
			if self.action == "EXIT" then
				love.event.quit()
			elseif self.action == "BACK" then
				if self.stats_changed then saveStats() end
				self:swapState("main")
			elseif self.action == "START GAME" then
				state = game
				game:start(love.math.random(0xfffffff), self.input)
			elseif self.action == "HIGHSCORE" then
				self:swapState("highscore")
			elseif self.action == "CREDITS" then
				self:swapState("credits")

			elseif self.action == "OPTIONS" then
				self:swapState("options")
			elseif self.action == "NORMAL FULLSCREEN" then
				self:swapState("options")
				love.window.setFullscreen(true, "normal")
			elseif self.action == "DESKTOP FULLSCREEN" then
				self:swapState("options")
				love.window.setFullscreen(true, "desktop")
			elseif self.action == "WINDOW" then
				self:swapState("options")
				love.window.setFullscreen(false)



			elseif self.action == "DEMO" then
				state = game
				game:playBack(stats.demo)
			end
		end
	end
end
function Menu:submitHighscore(online)
	if online and self.entry[1] > "" then
		local nr = submitOnlineHighscore(self.entry[1], self.entry[2])
	end
	stats.name = self.entry[1]
	self.entry = false
	self.stats_changed = true
end
function Menu:keypressed(key)
	if self.state == "highscore" and self.entry then
		if key == "backspace" then
			self.entry[1] = self.entry[1]:sub(1, -2)
			self.tick = 0
			return

		elseif key == "return" or key == "escape" then
			self:submitHighscore(key == "return")
			return
		end

		if #self.entry[1] >= 13 then return end

		if #key == 1 and key:match("[%a%d.-]") then
			self.entry[1] = self.entry[1] .. key:upper()
			self.tick = 0
		elseif key == "space" then
			self.entry[1] = self.entry[1] .. " "
			self.tick = 0
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

		G.setColor(255, 255, 255)
		for i, m in ipairs(self.options.main) do
			font:print(m, 280, 320 + 40 * (i - 1))
		end
		if self.tick % 32 < 24 then
			font:print(">", 248, 320 + 40 * (self.select - 1))
		end

		G.setColor(40, 40, 40)
		font:printCentered("\0 2015 DANIEL LANGNER", 400, 360 + 40 * 5)

	elseif self.state == "options" then

		G.setColor(255, 255, 0)
		font:print("OPTIONS", 184, 72)

		G.setColor(255, 255, 255)
		for i, m in ipairs(self.options.options) do
			font:print(m, 280, 320 + 40 * (i - 1))
		end
		if self.tick % 32 < 24 then
			font:print(">", 248, 320 + 40 * (self.select - 1))
		end

	elseif self.state == "highscore" then

		G.setColor(255, 255, 0)
		font:print("HIGHSCORE", 184, 72)

		G.setColor(255, 255, 255)
		for i, e in ipairs(stats.highscore) do
			font:print(("%2d. %-13s  %07d"):format(i, e[1], e[2]),
						400 - 24 * 13,
						96 + 40 * i)
			if e == self.entry and self.tick % 32 < 24 then
				font:print("\x7f",
							400 + 24 * (#self.entry[1] - 9),
							96 + 40 * i)
			end
		end
	elseif self.state == "credits" then
		G.setColor(255, 255, 0)
		font:print("CREDITS", 184, 108)
		G.setColor(255, 255, 255)
		font:print("TODO", 184, 172)
	end




	if self.blend > 0 then
		G.setColor(0, 0, 0, 255 * self.blend)
		G.rectangle("fill", 0, 0, 800, 600)
	end
end

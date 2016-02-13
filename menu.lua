local http = require("socket.http")

function submitOnlineHighscore(highscore)
	local url = "http://www.langnerd.de/cgi-bin/gorge"
	local msg = ""
	for _, entry in ipairs(highscore) do
		msg = msg .. entry[2] .. " " .. entry[1] .. "\n"
	end
	local ret, err = http.request(url, msg)
	if err == 200 then return tonumber(ret) end
	print("submitting online highscore failed: " .. err)
	print(ret, err)
end



local G = love.graphics


local stats = {
	version = 1,
	highscore = {
		{ "", 10000 },
		{ "",  9000 },
		{ "",  8000 },
		{ "",  7000 },
		{ "",  6000 },
		{ "",  5000 },
		{ "",  4000 },
		{ "",  3000 },
		{ "",  2000 },
		{ "",  1000 },
	},
	name = "",
	music_vol = 7,
	sound_vol = 7,
	fullscreen = false,
	demo = nil,
}

if love.filesystem.isFile(VERSION) then
	local s = loadstring("return " .. love.filesystem.read(VERSION))()

	-- patch
	if s.version ~= stats.version then
		s.version = stats.version

		-- delete demo as it won't play correctly any more
		s.demo = nil


	end

	stats = s
	sound.setVolume(stats.sound_vol / 10)
	love.window.setFullscreen(stats.fullscreen, "desktop")
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
	main = { "START GAME", "HIGHSCORE", "OPTIONS", "EXIT" },
	highscore = { "BACK" },
	options = { "SOUND VOLUME", "MUSIC VOLUME", "TOGGLE FULLSCREEN", "BACK" },
}
function Menu:init()
	self.stars = Stars()
	self.stars:reset(makeRandomGenerator(4))
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
end
function Menu:gameOver(game)

	-- save demo
	if not stats.demo or stats.demo.score < game.player.score then
		stats.demo = {
			record = game.record,
			seed = game.seed,
			score = game.player.score,
		}
		self.stats_changed = true
	end

	-- check top ten
	local entry = { stats.name or "", game.player.score }
	for i, e in ipairs(stats.highscore) do
		if e[2] < entry[2] then
			table.insert(stats.highscore, i, entry)
			table.remove(stats.highscore)
			self:swapState("highscore")
			self.entry = entry
			self.stats_changed = true
			return
		end
	end
	self:swapState("main")
end
function Menu:update()
	self.tick = self.tick + 1

	self.stars:update(1)
	updateList(Particle.list)

	if math.random() < 0.3 then
		SparkleParticle(math.random(200, 600), math.random(136, 230))
	end


	-- buttons
	if not self.action then

		-- start demo mode
		if self.state == "main" and self.tick > 60 * 10 and stats.demo then
			self.action = "DEMO"
		elseif self.state == "highscore" and self.entry then

			-- done writing name?
			if Input:gotAnyPressed("enter") then
				sound.play("select")
				self:submitHighscore(true)
			elseif Input:gotAnyPressed("back") then
				sound.play("select")
				self:submitHighscore(false)
			end

		else
			-- select option
			local option = self.options[self.state]
			if option then
				local o = option[self.select]

				local dy = bool[Input:gotAnyPressed("down") and true or false]
						 - bool[Input:gotAnyPressed("up") and true or false]

				if dy ~= 0 then
					local s = self.select
					self.select = self.select + dy
					self.select = math.max(self.select, 1)
					self.select = math.min(self.select, #option)
					if self.select ~= s then
						self.tick = 0
					end
				end

				local dx = bool[Input:gotAnyPressed("right") and true or false]
						 - bool[Input:gotAnyPressed("left") and true or false]

				if dx ~= 0 then
					if o == "SOUND VOLUME" then
						self.tick = 0
						self.stats_changed = true
						stats.sound_vol = math.max(0, math.min(stats.sound_vol + dx, 10))
						sound.setVolume(stats.sound_vol / 10)
						sound.play("laser")
					end
					if o == "MUSIC VOLUME" then
						self.tick = 0
						self.stats_changed = true
						stats.music_vol = math.max(0, math.min(stats.music_vol + dx, 10))
						-- TODO
					end
				end

				if o ~= "MUSIC VOLUME"
				and o ~= "SOUND VOLUME" then
					-- remember who started the game
					self.input = Input:gotAnyPressed("start") or Input:gotAnyPressed("a")
					if self.input then
						self.action = option[self.select]
						if self.action == "BACK" then
							sound.play("back")
						elseif self.action ~= "EXIT" then
							sound.play("select")
						end
					end
				end
			end

			-- back
			if Input:gotAnyPressed("back") or Input:gotAnyPressed("b") then
				if self.state == "main" then
					self.action = "EXIT"
				else
					sound.play("back")
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
			elseif self.action == "OPTIONS" then
				self:swapState("options")

			elseif self.action == "TOGGLE FULLSCREEN" then
				self:swapState("options")
				stats.fullscreen = not stats.fullscreen
				self.stats_changed = true
				love.window.setFullscreen(stats.fullscreen, "desktop")

			elseif self.action == "DEMO" then
				state = game
				game:playBack(stats.demo)
			end
		end
	end
end
function Menu:submitHighscore(online)
	if online and self.entry[1] > "" then
		local nr = tonumber(submitOnlineHighscore(stats.highscore))
		if nr > 0 then
			print("Your online rank: " .. nr)
			if nr <= 10 then print("Not bad!") end
		end
	end
	stats.name = self.entry[1]
	self.entry = false
end
function Menu:keypressed(key)
	if self.state == "highscore" and self.entry then
		if key == "backspace" then
			self.entry[1] = self.entry[1]:sub(1, -2)
			self.tick = 0
			return
		end

		if #self.entry[1] >= 13 then return end

		if #key == 1 and key:match("[%a%d.-]") then
			self.entry[1] = self.entry[1] .. key:upper()
			self.tick = 0
		elseif key == "space" or key == " " then
			if #self.entry[1] > 0 then
				self.entry[1] = self.entry[1] .. " "
				self.tick = 0
			end
		end
	end

end


function drawFrame(x, y, w, h)
	r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(r/4, g/4, b/4, a)
	y = y + 4

	G.rectangle("fill", x, y, w, 4)
	G.rectangle("fill", x, y + h - 4, w, 4)

	love.graphics.setColor(r, g, b, a)
	y = y - 4

	G.rectangle("fill", x, y, w, 4)
	G.rectangle("fill", x, y + h - 4, w, 4)
	G.rectangle("fill", x, y, 4, h)
	G.rectangle("fill", x + w - 4, y, 4, h)
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
		Particle:DrawAll()

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

		G.setColor(255, 255, 255)
		G.draw(self.img, 400, 140, 0, 4, 4, self.img:getWidth() / 2)
		Particle:DrawAll()

		local x = 184
		local y = 320

		G.setColor(255, 255, 255)
		for i, m in ipairs(self.options.options) do
			font:print(m, x, y + 40 * (i - 1))
		end
		if self.tick % 32 < 24 then
			font:print(">", x - 32, y + 40 * (self.select - 1))
		end

		drawFrame(x + 4 + 6 * 4 * 13, y+8 + 40 * 0, 8 + 12*10, 20)
		drawFrame(x + 4 + 6 * 4 * 13, y+8 + 40 * 1, 8 + 12*10, 20)

		G.setColor(191, 191, 0)
		G.rectangle("fill", x + 8 + 6 * 4 * 13, y+12 + 40 * 0, 12 * stats.sound_vol, 12)
		G.rectangle("fill", x + 8 + 6 * 4 * 13, y+12 + 40 * 1, 12 * stats.music_vol, 12)


		G.setColor(40, 40, 40)
		font:printCentered("\0 2015 DANIEL LANGNER", 400, 360 + 40 * 5)


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
	end


	if self.blend > 0 then
		G.setColor(0, 0, 0, 255 * self.blend)
		G.rectangle("fill", 0, 0, 800, 600)
	end
end

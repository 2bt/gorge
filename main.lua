local G = love.graphics

-- compatibility
do
	local a, b, c = love.getVersion()
	VERSION = a ..".".. b ..".".. c
	local v = a * 10000 + b * 100 + c
	if v < 1000 then
		COMPATIBILITY = true
		local b = G.setBlendMode
		G.setBlendMode = function(m)
			b(({ ["add"] = "additive" })[m] or m)
		end
	end
end



--MOBILE = true
DEBUG = false


love.mouse.setVisible(false)
G.setDefaultFilter("nearest", "nearest")
G.setBackgroundColor(0, 0, 0, 0)


require "helper"
require "input"
require "font"
require "stars"
require "walls"
require "particle"
require "player"
require "item"
require "enemy"
require "boom"
require "sound"
require "game"
require "menu"

QuadGenerator:GenerateQuads()



font = Font()

game = Game()
menu = Menu()
state = menu

keyboard = Input()



time_draw = 0
time_update = 0

--bg_music = love.audio.newSource("media/music.ogg", "stream")
--bg_music:setLooping(true)


function love.update()
	local t = love.timer.getTime()

	updateList(Input.list)
	state:update()

	-- fast forward
	if love.keyboard.isDown("^") then
		for i = 1, 20 do state:update() end
	end

	time_update = love.timer.getTime() - t
end
function love.draw()
	local t = love.timer.getTime()

	state:draw()

	time_draw = love.timer.getTime() - t

	G.setColor(255, 255, 255)
	G.print(love.timer.getFPS(), 10, 40)
	G.print(("%.2f"):format(time_update * 1000), 10, 60)
	G.print(("%.2f"):format(time_draw   * 1000), 10, 80)
end
function love.keypressed(key)
	keyboard:keypressed(key)
	if state.keypressed then state:keypressed(key) end
--	if key == "tab" then DEBUG = not DEBUG end
end

function love.resize()
	Boom.canvas = G.newCanvas()
	Game.canvas = G.newCanvas()
end

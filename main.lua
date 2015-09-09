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


DEBUG = false


love.mouse.setVisible(false)
G.setDefaultFilter("nearest", "nearest")


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
require "game"
require "menu"




font = Font()

game = Game()
menu = Menu()
state = menu

bg_music = love.audio.newSource("media/music.ogg", "stream")
bg_music:setLooping(true)


local record = 0
local i = 0

function love.update()
	updateList(Input.list)
	state:update()
end
function love.draw()
	state:draw()
	if record > 0 then
		love.graphics.newScreenshot():encode(("%04d.png"):format(i))
		i = i + 1
		record = record - 1
	end
end
function love.keypressed(key)
	if state.keypressed then state:keypressed(key) end
--	if key == "tab" then DEBUG = not DEBUG end
--	if key == "r" then record = 120 end
end

function love.resize()
	Boom.canvas = G.newCanvas()
	Game.canvas = G.newCanvas()
end

local joys = {}
function love.joystickadded(j)
	if not joys[j] then Input(j) end
end

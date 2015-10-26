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
require "game"
require "menu"
require "sound"




font = Font()

game = Game()
menu = Menu()
state = menu

bg_music = love.audio.newSource("media/music.ogg", "stream")
bg_music:setLooping(true)


function love.update()
	updateList(Input.list)
	state:update()
	if love.keyboard.isDown("^") then -- fast forward
		for i = 1, 20 do
			state:update()
		end
	end
end
function love.draw()
	state:draw()
end
function love.keypressed(key)
	if state.keypressed then state:keypressed(key) end
	if key == "tab" then DEBUG = not DEBUG end
end

function love.resize()
	Boom.canvas = G.newCanvas()
	Game.canvas = G.newCanvas()
end

local joys = {}
function love.joystickadded(j)
	if not joys[j] then Input(j) end
end

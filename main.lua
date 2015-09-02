DEBUG = false

local G = love.graphics

love.keyboard.setKeyRepeat(true)
love.mouse.setVisible(false)
G.setDefaultFilter("nearest", "nearest")


require "helper"
require "font"
require "stars"
require "walls"
require "particle"
require "player"
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

function love.update() state:update() end
function love.draw()
	state:draw()
	if record > 0 then
		love.graphics.newScreenshot():encode(("%04d.png"):format(i))
		i = i + 1
		record = record - 1
	end
end
function love.keypressed(key, isrepeat)
	state:keypressed(key, isrepeat)
	if key == "tab" then DEBUG = not DEBUG end
	if key == "r" then record = 120 end
end

function love.resize()
	Boom.canvas = G.newCanvas()
	Game.canvas = G.newCanvas()
end

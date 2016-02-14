MOBILE = (love.system.getOS() == "Android")
DEBUG = false


local G = love.graphics

-- compatibility
do
	local a, b, c = love.getVersion()
	VERSION = a ..".".. b ..".".. c
end


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


--bg_music = love.audio.newSource("media/music.ogg", "stream")
--bg_music:setLooping(true)


function love.update()
	updateList(Input.list)
	state:update()

	-- fast forward
	if love.keyboard.isDown("^") then
		for i = 1, 20 do state:update() end
	end
end
function love.draw()
	state:draw()
--	G.setColor(255, 255, 255)
--	G.print(love.timer.getFPS(), 10, 40)
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

function love.focus(f)
	if f == false and state == game then
		game:setPause(true)
	end
end

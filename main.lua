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


MOBILE = true
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
	if love.keyboard.isDown("^") then -- fast forward
		for i = 1, 20 do
			state:update()
		end
	end
end
--counter = -16
function love.draw()
--	if counter == 0 then Particle.list = {} end

	state:draw()

--	if counter >= 0 then
--		local banner = love.image.newImageData(500, 128)
--		banner:paste(G.newScreenshot(false), 0, 0, 150, 112, 500, 128)
--		banner:encode("png", ("%04d.png"):format(counter))
--	end
--	if counter > 100 and #Particle.list == 0 then
--		os.exit()
--	end
--	counter = counter + 1
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


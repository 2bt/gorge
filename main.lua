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

-- TEST
--game.player.score = 999
--menu:gameOver(game)


function love.update() state:update() end
function love.draw() state:draw() end
function love.keypressed(key, isrepeat)
	state:keypressed(key, isrepeat)
	if key == "tab" then DEBUG = not DEBUG end
end

function love.resize()
	Boom.canvas = G.newCanvas()
	Game.canvas = G.newCanvas()
end

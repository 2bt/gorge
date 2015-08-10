local G = love.graphics
local isDown = love.keyboard.isDown

love.keyboard.setKeyRepeat(true)
love.mouse.setVisible(false)
G.setDefaultFilter("nearest", "nearest")
canvas = G.newCanvas()
flash_shader = G.newShader([[
vec4 effect(vec4 col, sampler2D tex, vec2 tex_coords, vec2 screen_coords) {
	vec4 tc = texture2D(tex, tex_coords) * col;
	return tc + vec4(max(max(tc.rgb, tc.gbr), tc.brg), 0);
}]])



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

DEBUG = false



font = Font()

game = Game()
menu = Menu()


state = menu

-- TEST
--game.player.score = 999
--menu:gameOver(game)


function love.update()
	state:update()
end

function love.draw()
	state:draw()
end


function love.resize()
	Boom.canvas = G.newCanvas()
	canvas = G.newCanvas()
end

function love.keypressed(key, isrepeat)
	if state.keypressed then
		state:keypressed(key, isrepeat)
	end
--	if key == "d" then DEBUG = not DEBUG end
end

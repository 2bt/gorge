local G = love.graphics


Boom = Object:new {
	list = {}
}

Boom.canvas = G.newCanvas()
Boom.img = G.newImage("media/boom.png")
Boom.img:setFilter("linear", "linear")

Boom.shader = G.newShader([[
uniform sampler2D bump;
vec4 effect(vec4 color, sampler2D tex, vec2 tex_pos, vec2 screen_pos) {
	vec2 d = vec2(6, 6) / love_ScreenSize.xy;
	float h  = texture2D(bump, tex_pos).r;
	float h2 = texture2D(bump, tex_pos + d * vec2(1, 0)).r;
	float h3 = texture2D(bump, tex_pos + d * vec2(0, 1)).r;
	return texture2D(tex, tex_pos + vec2(h - h2, h - h3) * 0.04);
}]])

function Boom:init(x, y)
	table.insert(self.list, self)
	self.x = x
	self.y = y
	self.l = 0.15
end
function Boom:update()

	self.l = self.l + 0.015
	if self.l >= 1 then return "kill" end

end
function Boom:draw()
	G.setColor(255, 255, 255, 255 * (1 - self.l) ^ 3)
	local s = self.l * 16
	local o = self.img:getWidth() / 2
	G.draw(self.img, self.x, self.y, 0, s, s, o, o)
end




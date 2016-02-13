local G = love.graphics

Stars = Object:new()
Stars.img = G.newImage("media/stars.png")
genQuads(Stars, 8)

local r = love.math.newRandomGenerator(42)
local data = love.image.newImageData(128, 128)
for x = 0, 127 do
	for y = 0, 127 do
		data:setPixel(x, y,
			r:random(0, 255),
			r:random(0, 255),
			r:random(0, 255),
			r:random(0, 255))
	end
end
Stars.noise = G.newImage(data)


Stars.noise:setWrap("repeat", "repeat")
Stars.noise:setFilter("linear", "linear")
Stars.shader = G.newShader((MOBILE and "precision highp float;" or "")..[[
uniform sampler2D noise;
uniform float xx;
float perlin(vec2 p) {
	float c = texture2D(noise, p * 0.0625).r
			+ texture2D(noise, p * 0.125 ).g * 0.5
			+ texture2D(noise, p * 0.25  ).b * 0.25
			+ texture2D(noise, p * 0.5   ).a * 0.125
			+ texture2D(noise, p         ).r * 0.0625;
	return c / 2.0;
}
vec4 effect(vec4 col, sampler2D tex, vec2 tex_coords, vec2 screen_coords) {
]]..(COMPATIBILITY and "screen_coords.y = 150 - screen_coords.y;" or "")..[[
	vec2 p = (screen_coords - vec2(0.0, xx)) * 0.0016;
	float f = max(0.0, pow(perlin(p), 1.0) - 0.41);
	f = floor(f * 16.0) / 16.0;
	if (f > 0.0) f += 0.1;
	f *= f * 1.2;
	vec3 c = vec3(0.4, 0.5, 0.5) * f;
	return vec4(c, 1.0);
}]])
Stars.canvas = G.newCanvas(200, 151)


function Stars:init()
	self.list = {}
	for i = 1, 200 do self.list[i] = {} end
end
function Stars:resetStar(s)
	s.frame = self.rand.int(1, 4)
	local b = self.rand.float(0.3, 1)
	local c = (b - 0.3) * 100
	local d = c * self.rand.float(1, 2)
	s.color = { c, d, d }
	s.dy = b * 0.7
	s.x = self.rand.float(-410, 410)
	s.y = -310
end
function Stars:reset(rand)
	self.rand = rand
	self.xx = self.rand.int(0, 999999)
	for _, s in ipairs(self.list) do
		self:resetStar(s)
		s.y = self.rand.float(-310, 310)
	end
end
function Stars:update(speed)
	self.xx = self.xx + 0.1 * speed

	for _, s in ipairs(self.list) do
		s.y = s.y + s.dy * speed
		if s.y > 310 then
			self:resetStar(s)
			s.y = -310
		end
	end
end
function Stars:draw()
---[[
	self.canvas:renderTo(function()
		G.clear(0, 0, 0, 255)
		self.shader:send("xx", math.floor(self.xx))
		self.shader:send("noise", self.noise)
		G.setShader(self.shader)
		G.push()
		G.origin()
		G.rectangle("fill", 0, 0, self.canvas:getWidth(), self.canvas:getHeight())
		G.setShader()
		G.pop()
	end)
	G.setColor(255, 255, 255)
	G.draw(self.canvas, -400, -304 + (self.xx % 1 * 4), 0, 4)
--]]
	G.setBlendMode("add")
	for i, s in ipairs(self.list) do
		G.setColor(unpack(s.color))
		G.draw(self.img, self.quads[s.frame], s.x, s.y, 0, 4, 4, 4, 4)
	end
	G.setBlendMode("alpha")
end


local G = love.graphics

Stars = Object:new()
Stars.img = G.newImage("media/stars.png")
genQuads(Stars, 8)

local r = love.math.newRandomGenerator(42)
local data = love.image.newImageData(256, 256)
for x = 0, 255 do
	for y = 0, 255 do
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
Stars.shader = G.newShader([[
float perlin(sampler2D n, vec2 p) {
	float c = texture2D(n, p *  1).r /  1
			+ texture2D(n, p *  2).g /  2
			+ texture2D(n, p *  4).b /  4
			+ texture2D(n, p *  8).a /  8
			+ texture2D(n, p * 16).r / 16;
	return c / 2;
}
uniform sampler2D noise;
uniform float xx;
vec4 effect(vec4 col, sampler2D tex, vec2 tex_coords, vec2 screen_coords) {
]]..(COMPATIBILITY and "screen_coords.y = 150 - screen_coords.y;" or "")..[[
	vec2 p = (screen_coords - vec2(0, xx)) * 0.00005;
	float f = max(0, pow(perlin(noise, p), 1) - 0.41);
	f = floor(f * 16.0) / 16.0;
	if (f > 0) f += 0.1;
	f *= f * 1.2;
	vec3 c = vec3(0.4, 0.5, 0.5) * f;
	return vec4(c, 1);
}]])
Stars.shader:send("noise", Stars.noise)
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
	self.canvas:renderTo(function()
		G.clear()
		self.shader:send("xx", math.floor(self.xx))
		G.setShader(self.shader)
		G.push()
		G.origin()
		G.rectangle("fill", 0, 0, G.getWidth(), G.getHeight())
		G.setShader()
		G.pop()
	end)
	G.setColor(255, 255, 255)
	G.draw(self.canvas, -400, -304 + (self.xx % 1 * 4), 0, 4)

	G.setBlendMode("add")
	for i, s in ipairs(self.list) do
		G.setColor(unpack(s.color))
		G.draw(self.img, self.quads[s.frame], s.x, s.y, 0, 4, 4, 4, 4)
	end
	G.setBlendMode("alpha")
end


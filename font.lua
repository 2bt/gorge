Font = Object:new()

function Font:init()

	self.img = love.graphics.newImage("media/font.png")
	self.img:setFilter("nearest", "nearest")
	self.scale = 2

	self.quads = {}

	local w = self.img:getWidth()
	local h = self.img:getHeight()
	local cw = w / 8
	local ch = h / 16

	for i = 0, 127 do
		local c = string.char(i)
		local x = (i % 8) * cw
		local y = math.floor(i / 8) * ch
		self.quads[c] = love.graphics.newQuad(x, y, cw, ch, w, h)
	end

--	self.char_width = cw
	self.char_width = 6
	self.char_height = ch

end


function Font:printCentered(text, x, y, s)
	local dx = (s or self.scale) * self.char_width
	self:print(text, x - #text * dx * 0.5, y, s)
end

function Font:print(text, x, y, s)
	r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(r/3, g/3, b/3, a)
	self:print_(text, x, y + 4, s)
	love.graphics.setColor(r, g, b, a)
	self:print_(text, x, y, s)
end

function Font:print_(text, x, y, s)
	s = s or self.scale
	local dx = s * self.char_width
	local img = self.img
	local quads = self.quads

	love.graphics.push()
	for c in text:gmatch(".") do
		local q = quads[c]
		if q then
			love.graphics.draw(img, q, x, y, 0, s)
		end
		love.graphics.translate(dx, 0)
	end
	love.graphics.pop()
end

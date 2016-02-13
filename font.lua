local G = love.graphics

Font = Object:New { img = G.newImage("media/font.png") }
function Font:init()
	self.batch = G.newSpriteBatch(self.img, 100, "stream")

	self.img:setFilter("nearest", "nearest")
	self.scale = 4

	self.quads = {}

	local w = self.img:getWidth()
	local h = self.img:getHeight()
	local cw = w / 8
	local ch = h / 16

	for i = 0, 127 do
		local c = string.char(i)
		local x = (i % 8) * cw
		local y = math.floor(i / 8) * ch
		self.quads[c] = G.newQuad(x, y, cw, ch, w, h)
	end

	self.char_width = 6
	self.char_height = ch

end


function Font:printCentered(text, x, y, s)
	local dx = (s or self.scale) * self.char_width
	self:print(text, x - #text * dx * 0.5, y, s)
end
function Font:print(text, x, y, s)
	self.batch:clear()
	self:_print(text, x, y, s)
	G.draw(self.batch)
end

function Font:_print(text, x, y, s)
	r, g, b, a = G.getColor()
	self.batch:setColor(r/4, g/4, b/4, a)
	self:print_(text, x, y+4, s)
	self.batch:setColor(r, g, b, a)
	self:print_(text, x, y, s)
end

function Font:print_(text, x, y, s)
	s = s or self.scale
	local dx = s * self.char_width
	local quads = self.quads
	local batch = self.batch

	for c in text:gmatch(".") do
		local q = quads[c]
		if q then self.batch:add(q, x, y, 0, s) end
		x = x + dx
	end
end

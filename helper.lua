local G = love.graphics

Object = {}
function Object:New(o)
	o = o or {}
	setmetatable(o, self)
	local m = getmetatable(self)
	self.__index = self
	self.__call = m.__call
	self.super = m.__index and m.__index.init
	return o
end
setmetatable(Object, { __call = function(self, ...)
	local o = self:New()
	if o.init then o:init(...) end
	return o
end })


bool = { [true] = 1, [false] = 0 }


function updateList(x)
	local i = 1
	for j, b in ipairs(x) do
		x[j] = nil
		if b:update() ~= "kill" then
			x[i] = b
			i = i + 1
		else
			if b.kill then b:kill() end
		end
	end
end
function drawList(x, layer)
	if layer then
		for _, o in ipairs(x) do
			if o.layer == layer then o:draw() end
		end
	else
		for _, o in ipairs(x) do o:draw() end
	end
end

function makeRandomGenerator(seed)
	local rg = love.math.newRandomGenerator(seed)
	return {
		int = function(a, b)
			return b and rg:random(a, b) or rg:random(a)
		end,
		float = function(a, b)
			return a + rg:random() * (b - a)
		end
	}
end


function genQuads(obj, size)
	size = size or obj.size
	obj.quads = makeQuads(
		obj.img:getWidth(),
		obj.img:getHeight(),
		size)
end

function makeQuads(w, h, s)
	local quads = {}
	for y = 0, h - s, s do
		for x = 0, w - s, s do
			table.insert(quads, G.newQuad(x, y, s, s, w, h))
		end
	end
	return quads
end


function transform(obj, model)
	model = model or obj.model
	local nx = math.sin(obj.ang or 0)
	local ny = math.cos(obj.ang or 0)
	local trans_model = obj.trans_model
	for i = 1, #model, 2 do
		local x = model[i]
		local y = model[i + 1]
		trans_model[i] 		= obj.x + y * nx + x * ny
		trans_model[i + 1]	= obj.y - x * nx + y * ny
	end
	for i = #model + 1, #obj.trans_model do
		trans_model[i] = nil
	end
	trans_model.x = obj.x
	trans_model.y = obj.y
	trans_model.r = model.r
end

function polygonCollision(a, b)
	if a.r and b.r then
		local dx = a.x - b.x
		local dy = a.y - b.y
		if (dx*dx + dy*dy) ^ 0.5 > a.r + b.r then
			return 0
		end
	end

	local normal = {}
	local where = {}
	local distance = 9e99

	for m = 1, 2 do
		local p1x = a[#a - 1]
		local p1y = a[#a]
		for i = 1, #a, 2 do
			local p2x = a[i]
			local p2y = a[i + 1]

			local c_d = 0
			local c_n = {}
			local c_w = {}

			local nx = p1y - p2y
			local ny = p2x - p1x

			for j = 1, #b, 2 do
				local wx = b[j]
				local wy = b[j + 1]

				local d = (p1x - wx) * nx + (p1y - wy) * ny
				if d > c_d then
					c_d = d
					c_n[1] = nx
					c_n[2] = ny
					c_w[1] = wx
					c_w[2] = wy
				end
			end
			if c_d == 0 then return 0 end
			local l = math.sqrt(nx * nx + ny * ny)
			c_d = c_d /  l

			if c_d < distance then
				distance = c_d
				if m == 1 then l = -l end
				normal[1] = nx / l
				normal[2] = ny / l
				where = c_w
			end
			p1x = p2x
			p1y = p2y
		end
		a, b = b, a
	end
	return distance, normal, where
end

function naivePolygonCircleCollision(a, x, y, r)
	for i = 1, #a, 2 do
		local dx = x - a[i]
		local dy = y - a[i+1]
		if dx*dx + dy*dy <= r*r then return a[i], a[i+1] end
	end
	return false
end

function initPolygonRadius(p)
	local r = 0
	for i = 1, #p, 2 do
		local rr = p[i] ^ 2 + p[i+1] ^ 2
		if r < rr then r = rr end
	end
	p.r = r ^ 0.5
end

function checkLineIntersection(ax, ay, bx, by, qx, qy, wx, wy)

	local abx = bx - ax
	local aby = by - ay
	local qwx = wx - qx
	local qwy = wy - qy
	local aqx = qx - ax
	local aqy = qy - ay

	local det = abx*qwy - aby*qwx;
	if math.abs(det) < 0.0001 then -- parallel
		return
	end

	local abi = (aqx*qwy - aqy*qwx) / det
	local qwi = (aqx*aby - aqy*abx) / det

	if abi < 0 or abi > 1
	or qwi < 0 or qwi > 1 then
		return
	end
	return abi, qwi

end



QuadGenerator = Object:New { list = {} }
function QuadGenerator:GenerateQuads()
	for _, p in ipairs(self.list) do
		p:generateQuads()
	end
end
function QuadGenerator:init(maxsprites)
	table.insert(self.list, self)
	self.maxsprites = maxsprites
	self.image_table = {}

end
function QuadGenerator:requestQuads(imagename, size)
	local quads = {}
	local data = love.image.newImageData(imagename)
	table.insert(self.image_table, {
		quads = quads,
		data = data,
		width = data:getWidth(),
		height = size or data:getHeight(),
	})
	return quads
end
function QuadGenerator:generateQuads()
	-- merge image
	local width = 0
	local height = 0
	for _, img in ipairs(self.image_table) do
		width = math.max(width, img.width)
		height = height + img.height
	end
	local data = love.image.newImageData(width, height)
	local y = 0
	for _, img in ipairs(self.image_table) do
		data:paste(img.data, 0, y, 0, 0, img.width, img.height)
		y = y + img.height
	end

	self.img = G.newImage(data)
	self.batch = G.newSpriteBatch(self.img, self.maxsprites, "stream")

	-- generate quads
	local y = 0
	for _, img in ipairs(self.image_table) do
		img.quads.batch = self.batch
		for x = 0, img.width - img.height, img.height do
			table.insert(img.quads, G.newQuad(x, y, img.height, img.height, width, height))
		end
		y = y + img.height
	end

	self.image_table = nil
end


BatchDrawer = Object:New()
function BatchDrawer:init(maxsprites, o)
	for k, v in pairs(o) do self[k] = v end
	self.quad_generator = QuadGenerator(maxsprites)
	self.list = {}
end
function BatchDrawer:InitQuads(imagename)
	self.quads = self.quad_generator:requestQuads(imagename, self.size)
end
function BatchDrawer:DrawBatch(layer)
	self.quad_generator.batch:clear()
	if layer then
		for _, o in ipairs(self.list) do
			if o.layer == layer then o:draw() end
		end
	else
		for _, o in ipairs(self.list) do o:draw() end
	end
	G.draw(self.quad_generator.batch)
end


function Object:InitQuads(imagename)
	self.quads = self.quad_generator:requestQuads(imagename, self.size)
end
function Object:DrawAll()
	for _, o in ipairs(self.list) do o:draw() end
end

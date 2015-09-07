Object = {}
function Object:new(o)
	o = o or {}
	setmetatable(o, self)
	local m = getmetatable(self)
	self.__index = self
	self.__call = m.__call
	self.super = m.__index and m.__index.init
	return o
end
setmetatable(Object, { __call = function(self, ...)
	local o = self:new()
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
		end
	end
end
function drawList(x)
	for _, o in ipairs(x) do o:draw() end
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
			table.insert(quads,
				love.graphics.newQuad(x, y, s, s, w, h))
		end
	end
	return quads
end


function transform(obj, model)
	model = model or obj.model
	local nx = math.sin(obj.ang or 0)
	local ny = math.cos(obj.ang or 0)
	for i = 1, #model, 2 do
		local x = model[i]
		local y = model[i + 1]
		obj.trans_model[i] 		= obj.x + y * nx - x * ny
		obj.trans_model[i + 1]	= obj.y + x * nx + y * ny
	end
end

function polygonCollision(a, b)
	local normal = {}
	local where = {}
	local distance = 9e99

	for m = 1, 2 do
		local p1x = a[#a - 1]
		local p1y = a[#a]
		for i = 1, #a, 2 do
			local p2x = a[i]
			local p2y = a[i+1]

			local c_d = 0
			local c_n = {}
			local c_w = {}

			local nx = p1y - p2y
			local ny = p2x - p1x

			for j = 1, #b, 2 do
				local wx = b[j]
				local wy = b[j+1]

				local d = (p1x - wx) * nx + (p1y - wy) * ny
				if d > c_d then
					c_d = d
					c_n[1] = nx
					c_n[2] = ny
					c_w[1] = wx
					c_w[2] = wy
				end
			end
			if c_d == 0 then
				return 0
			end
			local l = math.sqrt(nx * nx + ny * ny)
			c_d = c_d /  l

			if c_d < distance then
				distance = c_d
				if m == 1 then
					l = -l
				end
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


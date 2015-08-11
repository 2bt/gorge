local G = love.graphics


Walls = Object:new {
	img = G.newImage("media/walls.png"),
	speed = 1,
	W = 26,
	H = 32,
	polys = {
		{ 0, 0, 0, 32, 32, 32, 32, 0 },
		{ 0, 0, 32, 32, 32, 0 },
		{ 0, 32, 32, 32, 32, 0 },
		{ 0, 0, 0, 32, 32, 32 },
		{ 0, 0, 0, 32, 32, 0 },
	}
}
genQuads(Walls, 8)
function Walls:reset(rand)
	self.rand = rand
	self.tick = 0
	self.data = {}
	self.gen_data = {}
	self.fg_data = {}
	self.fg_gen_data = {}

	for y = 1, self.H do
		self.gen_data[y] = {}
		self.fg_gen_data[y] = {}
		for x = 1, self.W do
			self.gen_data[y][x] = y < 13 and 0 or 1
			self.fg_gen_data[y][x] = y < 13 and 0 or 1
		end
	end

	for y = 1, 22 do
		self.data[y] = {}
		self.fg_data[y] = {}
	end

	self.offset = 0
	self.radius = self.W / 2 + 1
	self.cx = self.W / 2 + 0.5
	self.cy = 17
	for i = 1, 20 do self:generate() end

end
function Walls:update()
	self.tick = self.tick + 1

	self.offset = self.offset + self.speed
	while self.offset >= 32 do
		self.offset = self.offset - 32
		self:generate()
	end

end
function Walls:generate()

	local row = table.remove(self.gen_data, 1)
	local fg_row = table.remove(self.fg_gen_data, 1)
	table.insert(self.gen_data, row)
	table.insert(self.fg_gen_data, fg_row)
	for x in ipairs(row) do
		row[x] = 1
		fg_row[x] = 1
	end

	self.cy = self.cy - 1
	while self.cy < 23 do
		for y, row in ipairs(self.gen_data) do
			local fg_row = self.fg_gen_data[y]
			for x in ipairs(row) do
				local dx = x - self.cx
				local dy = y - self.cy
				if dx * dx + dy * dy < self.radius^2 then
					row[x] = 0
				end
				if dx * dx + dy * dy < self.radius^2 + 30 then
					fg_row[x] = 0
				end
			end
		end

		local ang = self.rand.float(0.1, 0.6) * math.pi
		if self.rand.int(2) == 2 then ang = -ang end

		self.cy = self.cy + math.cos(ang) * self.radius
		self.cx = self.cx + math.sin(ang) * self.radius
		self.cx = math.max(1 + 5, self.cx)
		self.cx = math.min(self.W - 5, self.cx)
		self.radius = self.rand.float(2, 8)

	end


	local row = {}
	for x, cell in ipairs(self.gen_data[2]) do
		local n = {
			self.gen_data[1][x],
			self.gen_data[2][x - 1] or 1,
			self.gen_data[3][x],
			self.gen_data[2][x + 1] or 1,
		}
		local s = n[1] + n[2] + n[3] + n[4]
		row[x] = cell
		if cell == 0 then
			if s >=3 then
				row[x] = 1
			elseif s == 2 then
				for i = 1, 4 do
					if n[i] + n[i % 4 + 1] == 0 then
						row[x] = i + 1
					end
				end
			end
		elseif s == 0 then
			local t = (self.gen_data[1][x - 1] or 1)
					+ (self.gen_data[1][x + 1] or 1)
					+ (self.gen_data[3][x - 1] or 1)
					+ (self.gen_data[3][x + 1] or 1)
			if t == 0 then row[x] = 0 end
		end
	end
	table.insert(self.data, row)
	table.remove(self.data, 1)



	local row = {}
	for x, cell in ipairs(self.fg_gen_data[2]) do
		local n = {
			self.fg_gen_data[1][x],
			self.fg_gen_data[2][x - 1] or 1,
			self.fg_gen_data[3][x],
			self.fg_gen_data[2][x + 1] or 1,
		}
		local s = n[1] + n[2] + n[3] + n[4]
		row[x] = cell


		if cell == 0 then
			if s >=3 then
				row[x] = 1
			elseif s == 2 then
				for i = 1, 4 do
					if n[i] + n[i % 4 + 1] == 0 then
						row[x] = i + 1
					end
				end
			end
		elseif s == 0 then
			local t = (self.fg_gen_data[1][x - 1] or 1)
					+ (self.fg_gen_data[1][x + 1] or 1)
					+ (self.fg_gen_data[3][x - 1] or 1)
					+ (self.fg_gen_data[3][x + 1] or 1)
			if t == 0 then row[x] = 0 end
		end
	end
	table.insert(self.fg_data, row)
	table.remove(self.fg_data, 1)


--	f = (f or 0) + 1 print(f)
end
function Walls:draw()

	G.setColor(30, 15, 50)

	-- debug
if DEBUG then
	for y = 3, self.H do
		local row = self.gen_data[y]
		for x, cell in ipairs(row) do
			if cell > 0 then
				G.draw(self.img, self.quads[cell],
					x * 32 - 448,
					300 - y * 32 + self.offset - 32 * 20, 0, 4, 4)
			end
		end
	end
end



	for y, row in ipairs(self.data) do
		for x, cell in ipairs(row) do
			if cell > 0 then
				G.draw(self.img, self.quads[cell],
					x * 32 - 448,
					300 - y * 32 + self.offset, 0, 4, 4)
			end
		end
	end


	-- draw foreground
	G.setColor(65, 30, 70)
	G.push()
	G.scale(1.05)
	for y, row in ipairs(self.fg_data) do
		for x, cell in ipairs(row) do
			if cell > 0 then
				G.draw(self.img, self.quads[cell],
					x * 32 - 448,
					300 - y * 32 + self.offset, 0, 4, 4)
			end
		end
	end
	G.pop()
	G.setColor(255, 255, 255)
end

function Walls:getTileAddress(x, y)
	return	math.floor((x + 448) / 32),
			math.ceil((self.offset - y + 300) / 32)
end
function Walls:getTilePosition(x, y)
	return	x * 32 - 448 + 16,
			300 - y * 32 + self.offset + 16
end

function Walls:checkCollision(poly)
	local dist = 0, norm, where

	local x1 = poly[1]
	local x2 = poly[1]
	local y1 = poly[2]
	local y2 = poly[2]
	for i = 3, #poly, 2 do
		x1 = math.min(x1, poly[i])
		x2 = math.max(x2, poly[i])
		y1 = math.min(y1, poly[i + 1])
		y2 = math.max(y2, poly[i + 1])
	end

	x1, y1 = self:getTileAddress(x1, y1)
	x2, y2 = self:getTileAddress(x2, y2)

	for y = y2, y1 do
		local row = self.data[y]
		if row then
			for x = x1, x2 do
				local p = self.polys[row[x]]
				if p then
					local q = {}
					for i = 1, #p, 2 do
						q[i]   = p[i] + x * 32 - 448
						q[i+1] = p[i+1] + 300 + self.offset - y * 32
					end
					local d, n, w = polygonCollision(q, poly)
					if d > dist then
						dist = d
						norm = n
						where = w
					end
				end
			end
		end
	end
	return dist, norm, where
end

local function checkLineIntersection(ax, ay, bx, by, qx, qy, wx, wy)

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

function Walls:checkSight(ax, ay, bx, by)

--	local dx = bx - ax
--	local dy = by - ay
--	local l = (dx*dx + dy*dy) ^ 0.5
--	dx = dx / l
--	dy = dy / l

	local result

	local x1, y1 = self:getTileAddress(ax, ay)
	local x2, y2 = self:getTileAddress(bx, by)

	for y = math.min(y1, y2), math.max(y1, y2) do
		local row = self.data[y]
		if row then
			for x = math.min(x1, x2), math.max(x1, x2) do
				local p = self.polys[row[x]]
				if p then

					local qx = p[#p-1] + x * 32 - 448
					local qy = p[#p] + 300 + self.offset - y * 32
					for i = 1, #p, 2 do
						local wx = p[i] + x * 32 - 448
						local wy = p[i+1] + 300 + self.offset - y * 32

						local u, v = checkLineIntersection(ax, ay, bx, by, qx, qy, wx, wy)
						if u then
							result = math.min(u, result or 1)
						end

						qx, qy = wx, wy
					end
				end
			end
		end
	end
	return result
end

local isDown = love.keyboard.isDown
local G = love.graphics

Input = Object:New {
	list = {},
}
function Input:init(joy)
	table.insert(self.list, self)
	self.state = {}
	self.prev_state = {}
	if joy then
		self.joy = joy
	else
		self.keyboard_state = {}
	end
end
function Input:_isDown(key)
	return self.keyboard_state[key] or isDown(key)
end
function Input:keypressed(key)
	self.keyboard_state[key] = true
end
function Input:update()
	local s
	if self.joy then	-- joystick
		local x, y = self.joy:getAxes()
		x = x or 0
		y = y or 0
		s = {
			left	= self.joy:isGamepadDown("dpleft")	or x < -0.1,
			right	= self.joy:isGamepadDown("dpright")	or x >  0.1,
			up		= self.joy:isGamepadDown("dpup")	or y < -0.1,
			down	= self.joy:isGamepadDown("dpdown")	or y >  0.1,
			a		= self.joy:isGamepadDown("a") or self.joy:isDown(1),
			b		= self.joy:isGamepadDown("b") or self.joy:isDown(2),
			start	= self.joy:isGamepadDown("start"),
			enter	= self.joy:isGamepadDown("start"),
			back	= self.joy:isGamepadDown("back"),
		}
	else			-- keyboard
		s = {
			left	= self:_isDown("left"),
			right	= self:_isDown("right"),
			up		= self:_isDown("up"),
			down	= self:_isDown("down"),
			a		= self:_isDown("x"),
			b		= self:_isDown("y") or isDown("z"),
			start	= self:_isDown("space") or self:_isDown(" ") or self:_isDown("return"),
			enter	= self:_isDown("return"),
			back	= self:_isDown("escape"),
		}
		self.keyboard_state = {}
	end
	s.dx = bool[s.right] - bool[s.left]
	s.dy = bool[s.down] - bool[s.up]
	self.prev_state = self.state
	self.state = s
end
function Input:gotPressed(key)
	return self.state[key] and not self.prev_state[key]
end
function Input:gotAnyPressed(key)
	for _, input in ipairs(self.list) do
		if input:gotPressed(key) then
			return input
		end
	end
	return false
end


if not MOBILE then

function love.joystickadded(joy)
	Input(joy)
end
function love.joystickremoved(joy)
	local i = 1
	while self.list[i] do
		if self.list[i].joy == joy then
			table.remove(joy, i)
			return
		else
			i = i + 1
		end
	end
end

else


-- touch
TouchInput = Input:New {
	state		= {},
	prev_state	= {},

	touches		= {},
	touch_a		= { active = false },
	touch_b		= { active = false },
	touch_dpad	= { active = false },
}
table.insert(Input.list, TouchInput)
function TouchInput:update()
	local dist = G.getHeight() / 20
	local s = {
		a		= self.touch_a.active,
		b		= self.touch_b.active,
		start	= false,
		enter	= self.touch_a.active,
		back	= false,
		dx		= 0,
		dy		= 0,
	}
	if self.touch_dpad.active then
		local dx = self.touch_dpad.x - self.touch_dpad.ox
		local dy = self.touch_dpad.y - self.touch_dpad.oy

		s.dx = math.max(-1, math.min(1, dx / dist))
		s.dy = math.max(-1, math.min(1, dy / dist))

		s.dx = math.floor(s.dx * 10 + 0.5) / 10
		s.dy = math.floor(s.dy * 10 + 0.5) / 10
	end
	s.left	= s.dx < -0.9
	s.right	= s.dx >  0.9
	s.up	= s.dy < -0.9
	s.down	= s.dy >  0.9

	self.prev_state = self.state
	self.state = s
end
function love.touchpressed(id, x, y, dx, dy, pressure)
	local self = TouchInput
	local w, h = G.getDimensions()
	if x / w > 0.5 then
		local touch
		if y / h < 0.3 then
			touch = self.touch_b
		else
			touch = self.touch_a
		end
		self.touches[id] = touch
		touch.active = true
		touch.x = x
		touch.y = y
	else
		self.touches[id] = self.touch_dpad
		self.touch_dpad.active = true
		self.touch_dpad.x = x
		self.touch_dpad.y = y
		self.touch_dpad.ox = x
		self.touch_dpad.oy = y
	end

end
function love.touchreleased(id, x, y, dx, dy, pressure)
	local self = TouchInput
	local touch = self.touches[id]
	if touch then
		touch.active = false
	end
end
function love.touchmoved(id, x, y, dx, dy, pressure)
	local dist = G.getHeight() / 20
	local self = TouchInput
	local touch = self.touches[id]
	if touch == self.touch_dpad then
		touch.x = x
		touch.y = y
		touch.ox = math.max(x - dist * 1.5, math.min(x + dist * 1.5, touch.ox))
		touch.oy = math.max(y - dist * 1.5, math.min(y + dist * 1.5, touch.oy))
	end
end

end

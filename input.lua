local isDown = love.keyboard.isDown

Input = Object:new { list = {} }
function Input:init(joy)
	table.insert(self.list, self)
	if joy then self.joy = joy end
	self.state = {}
	self.prev_state = {}
end
function Input:update()
	local s
	if self.joy then
		s = {
			left	= self.joy:isGamepadDown("dpleft"),
			right	= self.joy:isGamepadDown("dpright"),
			up		= self.joy:isGamepadDown("dpup"),
			down	= self.joy:isGamepadDown("dpdown"),
			shoot	= self.joy:isGamepadDown("a"),
			start	= self.joy:isGamepadDown("start"),
			back	= self.joy:isGamepadDown("back"),
		}
	else
		s = {
			left	= isDown("left"),
			right	= isDown("right"),
			up		= isDown("up"),
			down	= isDown("down"),
			shoot	= isDown("x"),
			start	= isDown("space") or isDown("return"),
			back	= isDown("escape"),
		}
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
			return true, input
		end
	end
	return false
end
function Input:isConnected()
	if self.joy then self.joy:isConnected() end
	return true
end

Input()

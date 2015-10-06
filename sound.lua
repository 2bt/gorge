

local sounds = {
	pause			= { "media/pause.wav",			1 },

	explosion		= { "media/explosion.wav",		2 },
	big_explosion	= { "media/big_explosion.wav",	2 },
	laser			= { "media/laser.wav",			1 },
	hit				= { "media/hit.wav",			1 },
	plasma			= { "media/plasma.wav",			2 },
	drop			= { "media/drop.wav",			1 },
	collect			= { "media/collect.wav",		1 },
	coin			= { "media/coin.wav",			1 },
	bullet			= { "media/bullet.wav",			2 },
	saucer			= { "media/saucer.wav",			1 },
	blast			= { "media/blast.wav",			1 },

	field			= { "media/field.wav",			0 },
	engine			= { "media/engine.wav",			0 },

}


love.audio.setPosition(0, 0, -700)


function newLoopSound(name)
	local s = love.audio.newSource(sounds[name].data)
	s:setAttenuationDistances(700, 1000)
	s:setLooping(true)
	return s
end


for k, v in pairs(sounds) do

	local data = love.sound.newSoundData(v[1])
	local sources = {}
	for i = 1, v[2] do
		local s = love.audio.newSource(data)
		s:setAttenuationDistances(700, 1000)
		sources[i] = s
	end

	v.data = data
	v.sources = sources

end


function playSound(name, x, y)
	local sources = sounds[name].sources
	local s = table.remove(sources, 1)
	table.insert(sources, s)
	s:stop()
	s:setPosition(x or 0, y or 0, 0)
	s:play()
	return s
end

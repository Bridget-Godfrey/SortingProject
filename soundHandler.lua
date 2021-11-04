audioLib = {}
allSounds = {}
SILENCE_STEP = 0.20
local sndhndlr = {}
sndhndlr.registerSound = function(s)
	local s = s
	table.insert(allSounds, s)
	audioLib[s] = {}
	audioLib[s].stopCompletely = false
	audioLib[s].pitch = 1
	audioLib[s].looping = false
	audioLib[s].volume = 1
	audioLib[s].stopping = false
	audioLib[s].isPlaying = function()
		return( s:isPlaying() and (not audioLib[s].stopping))
	end
	audioLib[s].setLooping = function(b)
		audioLib[s].looping = b
		s:setLooping(true)
	end
	audioLib[s].play = function(pitch, loop)
		-- pitch = pitch or audioLib[s].pitch
		-- loop = loop or audioLib[s].looping
		audioLib[s].stopping = false
		s:setVolume(0)
		s:play()
	end
	audioLib[s].setPitch = function(p)
		s:setPitch(p)
		audioLib[s].pitch = p
	end

	audioLib[s].setVolume = function(v)
		if ( s:isPlaying() and (not audioLib[s].stopping)) then
			s:setVolume(v)
		end
		audioLib[s].volume = v
	end


	audioLib[s].pause = function()
		audioLib[s].stopping = true
	end
	audioLib[s].stop = function()
		audioLib[s].stopping = true
		audioLib[s].stopCompletely = true
	end
	audioLib[s].kill = function()
		audioLib[s].stopping = false
		audioLib[s].stopCompletely = false
		s:stop()
	end

	audioLib[s].update = function (dt)
		if audioLib[s].isPlaying() then
			-- if stop == true then
			if s:getVolume() < audioLib[s].volume  then
				s:setVolume(s:getVolume() + SILENCE_STEP*audioLib[s].volume)
			end
		elseif audioLib[s].stopping then
			if s:getVolume() > 0 then
				local vol = s:getVolume() - SILENCE_STEP*audioLib[s].volume
				if vol < 0 then vol = 0 end
				s:setVolume(vol)
			elseif not audioLib[s].stopCompletely then
				audioLib[s].stopping = false
				s:pause()
			else
				audioLib[s].stopping = false
				audioLib[s].stopCompletely = false
				s:stop()
			end
		end
	end

	return table.getn(allSounds)

end
sndhndlr.playSound = function (s, pitch, loop)
	local snd = s
	if audioLib[snd] == nil and allSounds[snd] == nil then
		registerSound(snd)
	elseif type(s) == "number" then
		snd = allSounds[s]
	end
	audioLib[s].play(pitch, loop)

end

sndhndlr.pauseSound = function (s)
	local snd = s
	if audioLib[snd] == nil and allSounds[snd] == nil then
		registerSound(snd)
	elseif type(s) == "number" then
		snd = allSounds[s]
	end
	audioLib[s].pause()
	
end
sndhndlr.stopSound = function (s)
	local snd = s
	if audioLib[snd] == nil and allSounds[snd] == nil then
		registerSound(snd)
	elseif type(s) == "number" then
		snd = allSounds[s]
	end
	audioLib[s].stop()
	
end
sndhndlr.killSound = function (s)
	local snd = s
	if audioLib[snd] == nil and allSounds[snd] == nil then
		registerSound(snd)
	elseif type(s) == "number" then
		snd = allSounds[s]
	end
	audioLib[s].kill()
	
end

sndhndlr.killAll = function ()
	for i = 1, table.getn(allSounds) do
		audioLib[allSounds[i]].kill()
	end
end
sndhndlr.setLooping = function (s, loopBool)
	local snd = s
	if audioLib[snd] == nil and allSounds[snd] == nil then
		registerSound(snd)
	elseif type(s) == "number" then
		snd = allSounds[s]
	end
	audioLib[s].setLooping(loopBool)
end



sndhndlr.setPitch = function (s, pt)
	local snd = s
	if audioLib[snd] == nil and allSounds[snd] == nil then
		registerSound(snd)
	elseif type(s) == "number" then
		snd = allSounds[s]
	end
	audioLib[s].setPitch(pt)
end


sndhndlr.getPitch = function (s)
	local snd = s
	if audioLib[snd] == nil and allSounds[snd] == nil then
		registerSound(snd)
	elseif type(s) == "number" then
		snd = allSounds[s]
	end
	return audioLib[s].pitch
end



sndhndlr.getVolume = function (s)
	local snd = s
	if audioLib[snd] == nil and allSounds[snd] == nil then
		registerSound(snd)
	elseif type(s) == "number" then
		snd = allSounds[s]
	end
	return audioLib[s].volume
end

sndhndlr.getLooping = function (s)
	local snd = s
	if audioLib[snd] == nil and allSounds[snd] == nil then
		registerSound(snd)
	elseif type(s) == "number" then
		snd = allSounds[s]
	end
	return audioLib[s].looping
end

sndhndlr.setVolume = function (s, vol)
	local snd = s
	if audioLib[snd] == nil and allSounds[snd] == nil then
		registerSound(snd)
	elseif type(s) == "number" then
		snd = allSounds[s]
	end
	audioLib[s].setVolume(vol)
end



sndhndlr.updateSounds = function ()
	for i = 1, table.getn(allSounds) do
		audioLib[allSounds[i]].update()
	end
end

sndhndlr.stopAll = function ()
	for i = 1, table.getn(allSounds) do
		audioLib[allSounds[i]].stop()
	end
end

sndhndlr.pauseAll = function ()
	for i = 1, table.getn(allSounds) do
		audioLib[allSounds[i]].pause()
	end
end

return sndhndlr
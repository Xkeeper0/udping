--
-- Oh lord.
--

local socket	= require "socket"

local address	= "mini.xkeeper.net"
local port		= "37800"
local rate		= 1/60

local oldTimer	= 0
local timer		= 0
local packetN	= 0
local packetT	= {}
local packetC	= {}
local packetH	= 120 * 90 * 1

local sounds	= { bips = {}, farts = {} }
local soundC	= 0
local soundD	= math.ceil(1 / rate) * 2
local soundFD	= math.max(5, math.ceil(soundD * 0.3))
local soundN	= 0
local lastFart	= 0
local lastPing	= 0
local lastPingY = nil
local lastPingDrawn	= false
local consecutiveFarts = 0
local font		= nil

function love.load()
	font			= love.graphics.newFont("XFont.ttf", 16, "mono");

	sounds.bips[1]	= love.audio.newSource("sfx/bip1.wav", "static")
	sounds.bips[2]	= love.audio.newSource("sfx/bip2.wav", "static")
	sounds.bips[1]:setLooping(true)
	sounds.bips[2]:setLooping(true)
	sounds.bips[1]:setVolume(0.20)
	sounds.bips[2]:setVolume(0.20)

	sounds.farts[1]	= love.audio.newSource("sfx/fart1.ogg", "static")
	sounds.farts[2]	= love.audio.newSource("sfx/fart2.ogg", "static")
	sounds.farts[3]	= love.audio.newSource("sfx/fart3.ogg", "static")
	sounds.farts[4]	= love.audio.newSource("sfx/fart4.ogg", "static")
	sounds.farts[5]	= love.audio.newSource("sfx/fart5.ogg", "static")
	sounds.farts[6]	= love.audio.newSource("sfx/fart6.ogg", "static")
	sounds.farts[7]	= love.audio.newSource("sfx/poo2.ogg", "static")
	sounds.farts[8]	= love.audio.newSource("sfx/poo2_robot.ogg", "static")
	sounds.farts[9]	= love.audio.newSource("sfx/superfart.ogg", "static")

	for i = 1, 8 do
		sounds.farts[i]:setVolume(0.7)
	end

	thr			= love.thread.newThread("thread.lua")
	thr:start()

	ch			= love.thread.getChannel("args")
	ch:push(address)
	ch:push(port)
	ch:push(rate)

	udp			= socket.udp()
	udp:settimeout(0)
	udp:setpeername(address, port)

end


function checkFart()

	if soundN > 0 then
		if packetT[soundN][1] then
			consecutiveFarts = 0
			local tD	= packetT[soundN][2]
			--sounds.bips[2]:stop()
			sounds.bips[2]:setPitch(0.33 + tD * 5)
			sounds.bips[2]:play()
			lastPing	= tD
		else
			lastPing	= false
			sounds.bips[2]:stop()
			consecutiveFarts = consecutiveFarts + 1
			if consecutiveFarts == 3 then
				sounds.farts[9]:stop()
				sounds.farts[9]:setPitch(math.random(45, 100) / 100)
				sounds.farts[9]:play()

			elseif (consecutiveFarts < 3) or (consecutiveFarts > (3 + soundFD) and (consecutiveFarts % soundFD) == 0) then
				local fart = math.random(1, 8)
				while fart == lastFart do
					fart = math.random(1, 8)
				end
				sounds.farts[fart]:stop()
				sounds.farts[fart]:setPitch(math.random(60, 130) / 100)
				sounds.farts[fart]:play()
			end

		end
	end

end

function love.update(dt)
	doCheck()

	while ((soundD + soundN) < packetN) do
		soundN	= soundN + 1
		checkFart()

	end
end

failColor	= {1, 0, 0}

function love.draw()
	love.graphics.setFont(font);

	local sX	= 120
	local sY	= 90
	local sW	= 8
	local sH	= 8
	local sP	= 0

	local tn	= math.ceil((packetN - packetH + 2) / sX) * sX
	local xP	= 0
	local yP	= 0
	for i = 0, packetH - 1 do
		xP	= (i % sX) * sW + sP
		yP	= math.floor(i / sX) * sH + sP

		local pI	= tn + i

		if packetT[pI] then

			if packetC[pI] then
				love.graphics.setColor(packetC[pI])

			--elseif packetC[pI] and packetC[pI].fail then
			--	love.graphics.setColor(failColor)

			elseif not packetC[pI] then
				local tV	= packetT[pI][2] - love.timer.getTime()
				local col	= pingToColor(tV)
				if tV < -2.5 then
					packetC[pI]	= failColor
				end
				love.graphics.setColor(col)
			end

		elseif tn+i == packetN + 1 then
			love.graphics.setColor(1, 1, 1)

		elseif tn+i > packetN then
			love.graphics.setColor(0.05, 0.05, 0.05)
		else
			love.graphics.setColor(0.3, 0.3, 0.3)
		end

		love.graphics.rectangle("fill", xP, yP, sW, sH)

		if pI == soundN then
			love.graphics.setColor(1, 1, 1)
			love.graphics.rectangle("line", xP + 1, yP + 1, sW - 2, sH - 2)
		end

	end

	failColor[2]	= (math.sin(love.timer.getTime() * 6)) * 0.5 + 0.5
	failColor[3]	= failColor[2]


	gY	= 680

	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Response Time", 1080, 10)
	lastPingDrawn = false
	doGraph(0.000, 0.100, 0.0005)
	gY	= gY + 1
	doGraph(0.100, 0.250, 0.0005)
	gY	= gY + 1
	doGraph(0.250, 2.001, 0.0125)

end


function doGraph(st, max, step)
	local nP	= 0
	for i = st, max, step do
		love.graphics.setColor(pingToColor(i))
		love.graphics.rectangle("fill", 1100, gY, 10, 1)


		if (not lastPingDrawn and lastPing and lastPing < i) then
			if not lastPingY then
				lastPingY = gY
			end
			lastPingY = lastPingY * 0.9 + gY * 0.1 - 0.2
			local lastPingYD	= math.ceil(lastPingY)

			love.graphics.print(string.format("       >"), 997, gY - 10)
			love.graphics.print(string.format("       >"), 996, gY - 11)

			love.graphics.print(string.format("%4dms", lastPing * 1000), 997, lastPingYD - 10)
			love.graphics.print(string.format("%4dms", lastPing * 1000), 996, lastPingYD - 11)
			love.graphics.setColor(1, 1, 1)
			love.graphics.print(string.format("       >"), 995, gY - 12)
			love.graphics.print(string.format("%4dms", lastPing * 1000), 995, lastPingYD - 12)
			lastPingDrawn	= true
		end
		if nP % 20 == 0 then
			love.graphics.setColor(1, 1, 1)
			love.graphics.print(string.format("- %4dms", i * 1000), 1110, gY - 12)
		end



		gY		= gY - 1
		nP		= nP + 1
	end
end


function cs(v)
	return math.max(0, math.min(1, v))
end

function sv(v, m)
	return cs(v / m)
end



function printColor(c)
	return string.format("%.2f %.2f %.2f", c[1], c[2], c[3])
end

function pingToColor(v)
	if v < -2.5 then
		return { 1, 0, 0 }

	elseif v < -0.5 then
		local tv = math.abs(v) - 0.5
		return { 1, cs(1 - tv / 2), cs(1 - tv / 2) }

	elseif v <= 0 then
		return { 1, 1, 1 }

	elseif v < 0.100 then
		local min = 0
		local max = 0.1
		local pct = (v - min) / (max - min)
		return { 0, cs(pct), 0 }
	
	elseif v < 0.250 then
		local min = 0.1
		local max = 0.25
		local pct = (v - min) / (max - min)
	
		local t = v - 0.100
		local margin = t / 0.100
	
		return { 1, cs(1 - pct), cs(pct * 0.4) }
	
	else
		local min = 0.25
		local max = 2.5
		local pct = (v - min) / (max - min)

		return { 0.7 + cs(pct) / 0.3, cs(pct), 1 }
	
	end
end



function doCheck()
	while true do
		local tmp	= ch:pop()
		if not tmp then
			return
		end
		if not tmp[3] then
			-- new packet
			packetN	= tmp[1];
			packetT[packetN]	= {false, tmp[2]}
			packetC[packetN]	= nil
			packetT[packetN - packetH] = nil
			packetC[packetN - packetH] = nil

		else
			if packetT[tmp[1]] then
				-- ok
				packetT[tmp[1]]	= {true, tmp[2] - packetT[tmp[1]][2]}
				local tx	= packetT[tmp[1]][2]
				packetC[tmp[1]] = pingToColor(tx)
			end

		end
	end
end

--
-- Oh lord.
--

local socket	= require "socket"

local address	= "mini.xkeeper.net"
local port		= "37800"
local rate		= 6/60

local oldTimer	= 0
local timer		= 0
local packetN	= 0
local packetT	= {}
local packetC	= {}
local packetH	= 120 * 90 * 1

function love.load()
	thr			= 	love.thread.newThread("thread.lua")
	thr:start()

	ch			= love.thread.getChannel("args")
	ch:push(address)
	ch:push(port)
	ch:push(rate)

	udp			= socket.udp()
	udp:settimeout(0)
	udp:setpeername(address, port)

end


function love.update(dt)
	doCheck()
end

failColor	= {0.5, 0, 0}

function love.draw()

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

	end

	failColor[1]	= (math.sin(love.timer.getTime() * 2.5)) * 0.5 + 0.5


	gY	= 630

	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Response Time", 1080, 80)

	doGraph(0.000, 0.100, 0.0005)
	gY	= gY + 1
	doGraph(0.100, 0.500, 0.0025)
	gY	= gY + 1
	doGraph(0.500, 2.501, 0.0125)

end


function doGraph(st, max, step)
	local nP	= 0
	for i = st, max, step do
		love.graphics.setColor(pingToColor(i))
		love.graphics.rectangle("fill", 1100, gY, 10, 1)

		if nP % 20 == 0 then
			love.graphics.setColor(1, 1, 1)
			love.graphics.print(string.format("-- %.3fs", i), 1105, gY - 7)
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
		return { 0, cs(v / 0.10), 0 }

	elseif v < 0.500 then
		local t = v - 0.100
		return { 1, cs(1 - t / 0.4), cs(v / 0.75) }

	else
		return { 0.7, cs((v - .5) / 2 * 0.7), 1 }

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

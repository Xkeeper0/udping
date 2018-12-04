socket		= require "socket"
love.timer	= require "love.timer"

ch			= love.thread.getChannel("args")


udp			= socket.udp()
udp:settimeout(0)
local address	= ch:demand()
local port		= ch:demand()
local rate		= ch:demand()
udp:setpeername(address, port)
print(address, port)

local startT	= love.timer.getTime()
local num		= 0;

while true do

	local tT	= love.timer.getTime()
	if (tT - startT) > rate then
		startT	= math.max(tT - rate, startT + rate)
		udp:send(string.format("%d", num))
		ch:push({num, tT, false})
		num		= num + 1
	end

	repeat
		local data, msg	= udp:receive()
		tT	= love.timer.getTime()
		if data then
			local m	= tonumber(data)
			ch:push({m, tT, true})
		end
	until not data

end

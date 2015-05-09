conf = require("conf") -- we will never run concurrent readings, so fine

sensortrap = {} -- module table

function sensortrap._make_payload(ctx)
	ctx.payload = '{ "payload": 666 }'
end

function sensortrap._check_response(expect, got)
	local sfx = string.sub(got, -1, -1)
	if sfx ~= "\n" then
		print(string.format("check_response: invalid suffix '%s'", sfx))
		return false
	end
	got = string.sub(got, 1, -2)
	if got ~= expect then
		print(string.format("check_response: expected '%s' got '%s'", expect, got))
		return false
	else
		return true
	end
end

-- sends the board to deep sleep for some time, reset upon wake.
function sensortrap._again(ctx, con)
	con:close()
	print("Zzz...")
	node.dsleep(ctx.intvl_secs * 1000 * 1000)
end

function sensortrap._mk_rcv_cb(ctx)
	gpio.write(conf.connect_led, gpio.HIGH)
	-- a state machine
	return function(con, data)
		print("rcv: state = " .. ctx.state)
		if ctx.state == "init" then
			if not sensortrap._check_response("HI", data) then
				sensortrap._again(ctx, con)
			else
				sensortrap._make_payload(ctx)
				local resp = string.len(ctx.payload) .. "\r\n"
				conn:send(resp .. "\r\n")
				ctx.state = "lensent"
			end
		elseif ctx.state == "lensent" then
			if not sensortrap._check_response("OK", data) then
				sensortrap._again(ctx, con)
			else
				conn:send(ctx.payload)
				ctx.state = "payloadsent"
			end
		elseif ctx.state == "payloadsent" then
			if not sensortrap._check_response("OK", data) then
				sensortrap._again(ctx, con)
			else
				print("rcv: done")
				sensortrap._again(ctx, con)
			end
		end
	end
end

function sensortrap.start(addr_s, port, intvl_secs, s_group, n_sensors)
	-- Set up a context. Use closures to avoid global scope.
	local ctx = {
		state = "init",		-- state machine current state
		payload = nil,		-- json payload
		intvl_secs = intvl_secs,-- time to sleep between readings
		s_group = s_group,	-- sensor group (integer)
		n_sensors = n_sensors,	-- number of sensors
	}

	conn = net.createConnection(net.TCP, false)
	conn:on("receive", sensortrap._mk_rcv_cb(ctx))
	print(string.format("connecting to %s:%d", addr_s, port))
	conn:connect(port, addr_s)
end

return sensortrap

-- file.remove("user.lua")

local sensortrap = {}

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

function sensortrap._again(ctx, con)
	con:close()
	ctx.state = "init"
	sensortrap._set_alarm(ctx)
end

function sensortrap._mk_rcv_cb(ctx)
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

function sensortrap._mk_alarm_cb(ctx)
	return function()
		conn = net.createConnection(net.TCP, false)
		conn:on("receive", sensortrap._mk_rcv_cb(ctx))
		conn:connect(ctx.port, ctx.addr_s)
	end
end

function sensortrap._set_alarm(ctx)
	tmr.alarm(0, ctx.intvl_ms, 0, ctx.alrm_cb)
end

function sensortrap.start(addr_s, port, intvl_ms, s_group, n_sensors)
	-- Set up a context. Use closures to avoid global scope.
	local ctx = {
		state = "init",
		payload = nil,
		addr_s = addr_s,
		port = port,
		intvl_ms = intvl_ms,
		s_group = s_group,
		n_sensors = n_sensors,
		alrm_cb = nil,
	}

	ctx.alrm_cb = sensortrap._mk_alarm_cb(ctx)
	sensortrap._set_alarm(ctx)
end

return sensortrap

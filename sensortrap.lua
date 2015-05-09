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

-- use a closure to encapsulate context
function sensortrap._mk_rcv()

	local ctx = {
		state = "init",
		payload = nil
	}

	-- a state machine
	return function(con, data)
		print("rcv: state = " .. ctx.state)
		if ctx.state == "init" then
			if not sensortrap._check_response("HI", data) then
				con:close()
				sensortrap._set_alarm()
			else
				sensortrap._make_payload(ctx)
				local resp = string.len(ctx.payload) .. "\r\n"
				conn:send(resp .. "\r\n")
				ctx.state = "lensent"
			end
		elseif ctx.state == "lensent" then
			if not sensortrap._check_response("OK", data) then
				con:close()
				ctx.state = "init"
				sensortrap._set_alarm()
			else
				conn:send(ctx.payload)
				ctx.state = "payloadsent"
			end
		elseif ctx.state == "payloadsent" then
			if not sensortrap._check_response("OK", data) then
				con:close()
			else
				conn:close()
				print("rcv: done")
				ctx.state = "init"
				sensortrap._set_alarm()
			end
		end
	end
end

function sensortrap._set_alarm()
	print("set alarm")
	tmr.alarm(0, 1000, 0, sensortrap._start)
end

function sensortrap.start()
	sensortrap._set_alarm()
end

function sensortrap._start()
	print("fire")
	conn = net.createConnection(net.TCP, false)
	conn:on("receive", sensortrap._mk_rcv())
	conn:connect(5050, "192.168.1.5")
end

return sensortrap

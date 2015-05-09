conf = require("conf") -- we will never run concurrent readings, so fine

sensortrap = {} -- module table

function sensortrap._make_payload()
	conf.payload = '{ "payload": 666 }'
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
function sensortrap._again(con)
	con:close()
	print(string.format("Going to sleep for %d seconds", conf.read_intvl))
	node.dsleep(conf.read_intvl * 1000 * 1000)
end

-- a state machine
function sensortrap._rcv_cb(con, data)
	print("rcv: state = " .. conf.state)
	if conf.state == "init" then
		if not sensortrap._check_response("HI", data) then
			sensortrap._again(con)
		else
			sensortrap._make_payload()
			local resp = string.len(conf.payload) .. "\r\n"
			conn:send(resp .. "\r\n")
			conf.state = "lensent"
		end
	elseif conf.state == "lensent" then
		if not sensortrap._check_response("OK", data) then
			sensortrap._again(con)
		else
			conn:send(conf.payload)
			conf.state = "payloadsent"
		end
	elseif conf.state == "payloadsent" then
		if not sensortrap._check_response("OK", data) then
			sensortrap._again(con)
		else
			print("rcv: done")
			sensortrap._again(con)
		end
	end
end

function sensortrap.f(con)
	print("yeh")
end

function sensortrap.start(conf)
	conn = net.createConnection(net.TCP, false)
	print(sensortrap._rcv_cb)
	conn:on("receive", sensortrap._rcv_cb)

	tmr.delay(1000000)

	print(string.format("connecting to %s:%d", conf.trap_addr, conf.trap_port))
	conf.state = "init"
	conn:connect(conf.trap_port, conf.trap_addr)
end

return sensortrap

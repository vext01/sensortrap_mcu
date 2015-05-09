-- file.remove("user.lua")

print(wifi.sta.getip())

-- context
ctx = {
	state = "init",
	payload = nil
}

function make_payload()
	print("making payload")
	ctx.payload = '{ "payload": 666 }'
end

function rcv(con, data)
	print("rcv: state = " .. ctx.state)
	if ctx.state == "init" then
		print(data)
		make_payload()
		resp = string.len(ctx.payload) .. "\r\n"
		print("resp = " .. resp)
		conn:send(resp .. "\r\n")
		ctx.state = "lensent"
	elseif ctx.state == "lensent" then
		print(data)
		print("json = " .. ctx.payload)
		conn:send(ctx.payload)
		ctx.state = "payloadsent"
	elseif ctx.state == "payloadsent" then
		print(data)
		print("closing connection")
		conn:close()
		ctx.state = "final"
	end
end

conn = net.createConnection(net.TCP, false)
conn:on("receive", rcv)
conn:connect(5050, "192.168.1.5")

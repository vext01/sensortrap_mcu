user:
	sudo python2.7 ~/source/luatool/luatool/luatool.py -p /dev/cuaU0 --src user.lua --dest user.lua

st:
	sudo python2.7 ~/source/luatool/luatool/luatool.py -p /dev/cuaU0 --src sensortrap.lua --dest sensortrap.lua

init:
	sudo python2.7 ~/source/luatool/luatool/luatool.py -p /dev/cuaU0 --src init.lua --dest init.lua -r

conf:
	sudo python2.7 ~/source/luatool/luatool/luatool.py -p /dev/cuaU0 --src conf.lua --dest conf.lua -r

list:
	sudo python2.7 ~/source/luatool/luatool/luatool.py -p /dev/cuaU0 -l

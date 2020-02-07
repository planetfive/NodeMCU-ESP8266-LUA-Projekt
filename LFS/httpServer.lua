
local collectgarbage = collectgarbage

-------------------
-- helper
--------------------
local function urlDecode(url)
	url = string.gsub(url, "+", " ")
	return url:gsub('%%(%x%x)', function(x)
		return string.char(tonumber(x, 16))
	end)
end

local function guessType(filename)
	local types = {
		['.css'] = 'text/css', 
		['.js'] = 'application/javascript', 
		['.html'] = 'text/html',
                ['.htm'] = 'text/html',
		['.png'] = 'image/png',
		['.jpg'] = 'image/jpeg',
		['.lua'] = 'text/x-lua',
		['.txt'] = 'text/plain'
	}
	for ext, type in pairs(types) do
		if string.sub(filename, -string.len(ext)) == ext
			or string.sub(filename, -string.len(ext .. '.gz')) == ext .. '.gz' then
			return type
		end
	end
	return 'text/html'
end

-- httpServer -Tabelle
local httpServer = {
	_srv = nil,
	_mids = {{}},
	_socket = nil,
	_session_id = nil,
	_res = nil,
-- _mids = { { url = url, cb = cb, filter = filter },  { url = url, cb = cb, filter = filter } }
}

--------------------
-- Response
--------------------
local Res = {
	_skt = nil,
	_type = nil,
	_status = nil,
	_redirectUrl = nil,
	_fd = nil,
	_filter = nil,
	_buffer = nil,
}

function Res:new(skt)
	local o = {}
	setmetatable(o, self)
    self.__index = self
    o._skt = skt
    return o
end

function Res:redirect(url)
	self._redirectUrl = url
end

function Res:send(status, type, body)  -- zum Senden von generiertem Text nicht groesser als ~ 1500 chars
	self._status = status or 200
	self._type = type or "text/html"

	local buf = 'HTTP/1.1 ' .. self._status .. '\r\n'
		.. 'Content-Type: ' .. self._type .. '\r\n'
		.. 'Content-Length:' .. string.len(body) .. '\r\n'
	if self._redirectUrl ~= nil then
		buf = buf .. 'Location: ' .. self._redirectUrl .. '\r\n'
	end
	self._buffer = buf .. '\r\n' .. body
	print('* Sending Textstring')

	local function doSend()
		if self._buffer == '' then 
			print('* Finished Textstring')
			self:close()
		else
			self._skt:send(string.sub(self._buffer, 1, 512))
			self._buffer = string.sub(self._buffer, 513) -- Reststring fuer naechstes send()
		end
	end
	self._skt:on('sent', doSend)

	doSend()
end



function Res:sendFile(filename,filter, req) -- sendet eine vorhandene Modul-Datei - evtl. gefiltert
	if filter then
		self._filter = filter(req)
	else
		self._filter = {}
	end

	self._type = self._type or guessType(filename)

	self._status = self._status or 200

	local header = 'HTTP/1.1 ' .. self._status .. '\r\nContent-Type: ' .. self._type .. '\r\n'
	if string.sub(filename, -3) == '.gz' then
		header = header .. 'Content-Encoding: gzip\r\n'
	end
	header = header .. '\r\n'

	if (filename:sub(-3) == "lua") and ((httpServer._session_id == nil)or(httpServer._session_id < tmr.time())) then
		self._status = 401
		self._type = "text/html"
		self:send(401, "text/plain", "Kein Zugriff - bitte zuerst LUA-Dateien freischalten")
		return
	end

	print('* Sending ', filename)
	self._fd = file.open(filename, 'r')
	local function doSend()
		local buf = self._fd:read(500)	
		if buf and (self._type == 'text/html') then
			local b2 = self._fd:readline()
			if b2 then buf = buf .. b2 end
		end
		if buf == nil then
			self:close()
			self._fd:close()
			print('* Finished ', filename)
		else
			if self._filter ~= nil then
				for k, v in pairs(self._filter) do
					buf = buf:gsub(k, v)
				end
			end
			self._skt:send(buf)
		end
	end
	self._skt:on('sent', doSend)
	self._skt:send(header)
end

function Res:close()
	self._skt:on('sent', function() end) -- release closures context
	self._skt:on('receive', function() end)
	self._skt:close()
	self._skt = nil
end

--------------------
-- Middleware
--------------------
local function parseHeader(header)
	local _, _, method, path, vars = string.find(header, '([A-Z]+) (.+)?(.*) HTTP')
	if method == nil then
		_, _, method, path = string.find(header, '([A-Z]+) (.+) HTTP')
	end
	local parameter = {}
	if method == "GET" then
		if (vars ~= nil and vars ~= '') then
			vars = urlDecode(vars)
			for k, v in string.gmatch(vars, '([^&]+)=([^&]*)&*') do
				parameter[k] = v
			end
		end
	end
	return method, path, parameter
end


--------------------
-- HttpServer
--------------------

function httpServer.use(self, url, cb, filter) -- url = dateiname  -  cb = funktion zB sensoren auslesen -  filter = funktion zum ersetzen von text in dateien
	if self._mids[1].url == nil then self._mids[1] = { url = url, cb = cb, filter = filter }
	else
		table.insert(self._mids, { url = url, cb = cb, filter = filter })
	end
end

function httpServer:close()
	self._srv:close()
	self._srv = nil
	_mids = nil
	_socket = nil
	_session_id = nil
	_res = nil
end


function httpServer.listen(self, port)
	print("Starte Server")
        local data = 0
	local bouncy
	local bodyData = {}
	local req = {}
	local fd = nil
	self._srv = net.createServer(net.TCP)
	self._srv:listen(port, function(conn)
		conn:on('disconnection',function(skt,msg)
			if msg then print("unerwartet  disconnected")
			else print("disconnected")
			end
			skt = nil
			if self._res then
				print("close res:socket")
				self._res = nil
			end
			data = 0
			bouncy = nil
			bodyData = {}
			fd = nil
			collectgarbage("collect")
		end)
		conn:on('receive', function(skt, msg)
			if data <= 0 then --Header
				local _, pos = string.find(msg,"\r\n\r\n" )
				local header = string.sub(msg,1,pos)
				local method, path, parameter = parseHeader(header)
				local contentLen = string.match(header,"Content%-Length%D*(%d+)")
				local contentType = string.match(header,"Content.Type.%s*(%w*/[^\r^;]*)")
				req = { method = method, path = path, parameter = parameter, ip = skt:getpeer() }				
				local bodyLen = #msg - #header
				print(req.method, req.path,"***** Message:",#msg,"*** Content-Length =", contentLen, "*** BodyLen =", bodyLen,"**** Content-Type =",contentType)
				-- hier body bearbeiten POST usw
				if method == "POST" then
					if contentType == "application/x-www-form-urlencoded" then -- POST-Parameter
						local _, _, vars = string.find(msg, "\r\n\r\n(.+)" )
						if (vars ~= nil and vars ~= '') then
							vars = urlDecode(vars)
							print("POST-Data: parameter")
							for k, v in string.gmatch(vars, '([^&]+)=([^&]*)&*') do
								print(k,v)
								parameter[k] = v
							end
							req.parameter = parameter
						end
					elseif contentType == "multipart/form-data" then -- Datei uploaden
							local postData = string.match(msg,"\r\n\r\n(.+)\r\n\r\n")
							bouncy = string.match(postData,"([%-]+%d+).")
							local filename = string.match(postData,"filename=\"([^\"]+)")
							print("POST-Filename:",filename)
							fd = nil
							if (not filename) or (not file.exists(filename)) then
								local res = Res:new(skt)
								res._status = 401
								res._type = "text/html"
								res:send(401, "text/plain", "File not found")
								collectgarbage("collect")
								return
							end
							local ext = filename:sub(-3)
							if ((ext == "img") or ext:match("%.?(l[uc]a?)"))
									and ((self._session_id == nil)or(self._session_id < tmr.time())) then
								local res = Res:new(skt)
								res._status = 401
								res._type = "text/html"
								res:send(401, "text/plain", "Kein Zugriff - bitte zuerst LUA-Dateien freischalten")
								collectgarbage("collect")
								return
							end
							file.remove(filename)
							fd = file.open(filename,"a")
							local a_, e_ = string.find(msg,"\r\n\r\n") -- workarround
							a_, e_ = string.find(msg,"\r\n\r\n", e_ +1) -- match (s.unten) funktioniert nicht immer
							-- print(string.match(msg,"\r\n\r\n.*\r\n\r\n(.+)")) -- das funktioniert nicht immer!!! Fehler in match????
							-- table.insert(bodyData,string.sub(msg,e_ +1))  -- potentielle nutzdaten
							bodyData[1] = string.sub(msg,e_ +1)
					else
							print("POST-Data: Kein unterstuetzter Content-Type")
							local res = Res:new(skt)
							res._status = 401
							res._type = "text/plain"
							res:send(401, "text/html", "POST-Data: Kein unterstuetzter Content-Type")
							collectgarbage("collect")
							return
					end
				end
				if contentLen then -- pruefen, ob weitere Datenchunks folgen
					data = contentLen - bodyLen
				else
					data = 0
				end --end Header
			else	-- Datenchunk
				data = data - #msg
				table.insert(bodyData,msg)
				if #bodyData > 2 then -- es werden immer 2 Datenchunks vorgehalten, das stellt komplettes bouncy sicher
					if fd then fd:write(table.remove(bodyData,1)) end
				end
			end
			collectgarbage("collect")
			if data > 0 then return end -- weitere Datenchunks folgen auf den header

			if #bodyData > 0 then -- es sind noch Daten zu schreiben
				if fd then
					local restData = table.concat(bodyData)
					bodyData = {}
					if #restData > (#bouncy + 3) then
						local pos, _ = string.find(restData,bouncy)
						fd:write(string.sub(restData,1,pos - 3)) -- bouncy-string entfernen
					else
						fd:write(restData) -- hmm, daten sind eigentlich nicht gueltig
					end
					restData = nil
					bouncy = nil
					fd:close()
					fd = nil
				end
			end
		
			if req.path == nil then req.path = "/startPage.htm" end
			if req.path == "/" then req.path = "/startPage.htm" end
			req.path = string.sub(req.path,2) -- bei allen Dateien fuehrenden "/" entfernen

			local function middlewareFound()
				for i = 1, #self._mids do
					if (self._mids[i].url == req.path) then
						--print("dynamisch generierter Inhalt (middleware bzw Filter)")
						return i
					end
				end
				return 0
			end

			local res = Res:new(skt) -- ab hier wird response bearbeitet
			self._res = res

			local i = middlewareFound()
			if  i > 0 then
				if self._mids[i].cb then self._mids[i].cb(req, res) end
				--toDo entweder oder ????
				if self._mids[i].filter then res:sendFile(req.path,self._mids[i].filter,req) end
			else
				if file.exists(req.path) == true then
					res:sendFile(req.path)
				else
					--print("Sende FILE NOT FOUND")
					res:send(404, "text/html", 404 .. "File not found")
				end

			end

			collectgarbage("collect")

		end)
	end)
end


-- _G["httpServer"] = httpServer

return httpServer




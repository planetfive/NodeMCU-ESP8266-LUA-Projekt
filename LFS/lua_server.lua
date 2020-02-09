

local function getSchalter() -- schalter und virtuelle schalter im server dynamisch erstellen
   local s = ""
   local z
   if parameter.schalter then
      for k,v in pairs(parameter.schalter) do
         if gpio.read(v) == gpio.HIGH then
            z = " ist HIGH"
         else
            z = " ist LOW"
         end
         s = s .. "<input class='link_button' type='submit' name='" .. k .. "' value='" .. k .. "'><label>" .. z .. "</label><br/><br/>"
      end
   end
   if parameter.virtual_schalter then
      for k,v in pairs(parameter.virtual_schalter) do
         if v == true then
            z = " ist EIN"
         else
            z = " ist AUS"
         end
         s = s .. "<input class='link_button' type='submit' name='" .. k .. "' value='" .. k .. "'><label>" .. z .. "</label><br/><br/>"
      end
   end
   if #s == 0 then return s end
   s = "<form method='POST' action='/'>" .. s .. "</form>"
   return s

end


local function getInput()  -- Alle definierten Inputs im server anzeigen
   local s = ""
   local z
   if parameter.input then
      for k,v in pairs(parameter.input) do
         if gpio.read(v) == gpio.HIGH then
            z = " ist HIGH"
         else
            z = " ist LOW"
         end
         s = s .. k .. z  .."<br/>"
      end
   end
   return s
end





local httpServer = require("httpServer")


-- *******  Achtung: hier die URL immer ohne fuehrendem / eingeben ************
httpServer:use('startPage.htm', nil, function(req)
   local boot = {
      [0] = 'power-on',
      [1] = 'hardware watchdog reset',
      [2] = 'exception reset',
      [3] = 'software watchdog reset',
      [4] = 'software restart',
      [5] = 'wake from deep sleep',
      [6] = 'external reset'
   }
   local _, reason = node.bootreason()

   local t = tmr.time()
   local infostring = string.format("Uptime (Tge:Std:Min) :%d:%02d:%02d<br/>Bootgrund:%s<br/>Heap:%d",
                      math.floor(t/86400), math.floor((t%86400)/3600), math.floor(t%3600)/60, boot[reason], node.heap())

   local tempString = ""
   
   if temp_ds18b20 then -- ds18b20-Temperatursensor(en) vorhanden
      for addr, temp in pairs(temp_ds18b20) do
         local hexstring = ('%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X'):format(addr:byte(1,8)) -- Sensor-ROM-Code als Hex darstellen
         if parameter.alias then  -- hier werden die Aliase fuer die ROM-Codes gesetzt (falls vorhanden )
            for k,v in pairs(parameter.alias) do
               if hexstring == k then
                   hexstring = v
                   break
               end
            end
         end
         tempString = tempString .. string.format("Sensor %s: %s °C<br/>", hexstring, temp)
      end
   end
   if temp_dht then  -- Feuchtesensoren vom Typ DHTXX vorhanden
      tempString = tempString .. "DHT Temperature:" .. temp_dht .. " - Humidity:"..humi_dht .. "<br/>"
   end

   if req.method == "POST" then
      for k, v in pairs(req.parameter) do -- Request-Parameter auswerten
          if parameter.schalter and parameter.schalter[k] then  -- Schalter umschalten
            local p = gpio.read(parameter.schalter[k])
            gpio.write(parameter.schalter[k], (p == gpio.HIGH) and gpio.LOW or gpio.HIGH )
          elseif
               parameter.virtual_schalter and parameter.virtual_schalter[k] ~= nil then  -- Schalter umschalten
               if parameter.virtual_schalter[k] == true then
                  parameter.virtual_schalter[k] = false
               else
                  parameter.virtual_schalter[k] = true
               end
          end
          if k == "reboot" then 
             print("Reboote Modul")
             infostring = infostring .. "<h3>Restarte Modul, bitte ein paar Sekunden warten, dann Startseite erneut aufrufen!</h3>"
             local _t = tmr.create()
             _t:register(2000, tmr.ALARM_SINGLE, node.restart)
             _t:start()
          end
      end
   end
   return { ["$MODULNAME"] = parameter.name, ["$Temperatur"] = tempString,
            ["$Info"] = infostring,
            ["$Schalter"] = getSchalter(), ["$Input"] = getInput() }
   end)


httpServer:use('login.htm', nil,
	function(req)
		local logintext = ""
		if req.method == "POST" then
			if req.parameter.password == parameter.lua_pw then
				print("Lua passwort stimmt")
				httpServer._session_id = tmr.time() + 600 -- 10 min Zeit zum upload von lua-Dateien
				logintext = "Passwort OK - Der Zugriff auf LUA-Dateien ist 10 Minuten freigeschaltet"
			else
				print("lua passwort falsch")
				logintext = "Passwort falsch!"
			end
		end
	return { ["$MODULNAME"] = parameter.name, ["$Login"] = logintext }	
	end)

httpServer:listen(80)

--[[
--local ds = require("ds18b20")

-- Beispiel: startPage.htm mit direktem auslesen des ds18b20
local function handleTemp(filename, req, res)
   local t = tmr.time()
   if req.method == 'GET' then
      ds:read_temp(function(temp)

	local header = 'HTTP/1.1  200\r\nContent-Type: text/html\r\n\r\n'

	print('* Sending ', filename)
	res._fd = file.open(filename, 'r')
	local function doSend()
		local buf = res._fd:read(500)	
		if buf then
			local b2 = res._fd:readline()
			if b2 then buf = buf .. b2 end
		end
		if buf == nil then
			res:close()
			res._fd:close()
			print('* Finished ', filename)
		else
			buf = buf:gsub("$MODULNAME", "Testmodul")
			local tempString = ""
			for addr, temp in pairs(temp) do
    				tempString = tempString .. string.format("Sensor %s: %s °C",
					('%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X'):format(addr:byte(1,8)), temp)
			end
			buf = buf:gsub("$Temperatur", tempString)
			
			buf = buf:gsub("$Info", string.format("Uptime (Tge:Std:Min) :%d:%02d:%02d", math.floor(t/86400), math.floor((t%86400)/3600), math.floor(t%3600)/60))
			res._skt:send(buf)
		end
	end -- ende doSend
	res._skt:on('sent', doSend)
	res._skt:send(header)
      end , 5, ds.C) -- ende read_temp
   else -- ende GET
      -- anfang POST
      local tempString = ""
      for addr, temp in pairs(ds.temp) do
    	   tempString = tempString .. string.format("Sensor %s: %s °C",
					('%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X'):format(addr:byte(1,8)), temp)
      end
      res:sendFile(req.path, function()
		return { ["$MODULNAME"] = "Testmodul", ["$Temperatur"] = tempString,
                         ["$Info"] = string.format("Uptime (Tge:Std:Min) :%d:%02d:%02d", math.floor(t/86400),math.floor((t%86400)/3600), math.floor(t%3600)/60) } end)
   end
end



-- Hier wird json mit Hilfe der Middleware-Funktion direkt aus dem Speicher ohne html-Datei übertragen
httpServer:use('json', function(req, res)
	res:send(200, 'application/json', '{"doge": "smile"}') -- response senden
end, nil)

-- Redirect an url
httpServer:use('index.html', function(req, res)
	res:redirect('/startPage.htm') -- Achtung: hier mit fuehrendem /
	res:send(301,'text/html','redirect') -- statuscode = "moved permanently", type, text der evtl. kurz angezeigt wird
end, nil)
]]

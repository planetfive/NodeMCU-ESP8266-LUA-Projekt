
--[[
***************************************************************************************************
Hier wird die Nachricht generiert, die im Server-Mode per UDP verschickt wird
In der "modulparameter.lua" muss der Schlüssel "action_udp" existieren
Bsp: action_udp =	{ port = 15000, ip = "192.168.1.124", blocking = 0 },
***************************************************************************************************
]]--

local msg = parameter.name .."," .. myIP .. ","

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
      tempString = tempString .. string.format("Sensor %s: %s °C", hexstring, temp)
   end
end
if temp_dht then  -- Feuchtesensoren vom Typ DHTXX vorhanden
   tempString = tempString .. "<br/>Temperatur:" .. temp_dht .. "__Feuchte:" .. humi_dht
end
msg = msg .. tempString .. ",0.0 V ,nix," .. parameter.action_intervall
print(msg)
return msg

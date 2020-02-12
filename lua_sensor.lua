function start_udp()
   if parameter.action_udp then
      local udp_skt = net.createUDPSocket()
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
      msg = msg .. tempString .. ",0.0 ,nix," .. parameter.action_intervall
      print(msg)

      udp_skt:send(parameter.action_udp.port, parameter.action_udp.ip, msg)
   end
   print("going dsleep")
   node.dsleep(parameter.action_intervall*1000000 or 20*1000000)
end




function startSensorMode()
   if parameter.sensor then
      for k,v in pairs(parameter.sensor) do
         if k == "dht" then
            print("Sensor dht mit Pin-NR:"..v.." vorhanden")
            local status
            status, temp_dht, humi_dht = dht.read(parameter.sensor.dht)
         end
         if k == "ds18b20" then
            print("Sensor ds18b20 mit Pin-NR:"..v.." vorhanden")
            sens_ds = require("ds18b20")
            sens_ds:read_temp(function(temp)
               print("ds18b20 readout done, start UDP")
               temp_ds18b20 = sens_ds.temp
               start_udp()
               end, parameter.sensor.ds18b20, sens_ds.C)
         end
      end
      if (sens_ds == nil) and temp_dht then start_udp() end -- nur dht vorhanden
   end
end

startSensorMode()


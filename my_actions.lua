-- hier die bedingungen fuer actions eintragen

-- MQTT-Client
local function send_mqtt()
   if parameter.virtual_schalter and parameter.virtual_schalter["MQTT"] == true then
      -- init mqtt client without logins, keepalive timer 60s
      m = mqtt.Client(parameter.name, 60)
      print("start mqtt")
      m:connect("192.168.1.29", 1883, false,
         function(client) 
            print("mqtt:connected")
            -- hier irgendwas publizieren, QoS = 0 ( fire and forget), retain = 0
            client:publish("/Temperaturen/temperatur", "data xy", 0, 0, function(client) print("sent") m:close()end)
         end,
         function(client, reason) print("mqtt:failed reason: " .. reason) m:close() end
      )
   else
      print("MQTT ist aus")
   end
end



-- **** Achtung! Wichtig! **** In diese Tabelle alle eigenen funktionen eintragen
-- Alle eingetragenen Funktionen werden im Rhytmus von "action_intervall" ( in modulparameter.lua ) ausgeführt

return { ["mqtt"] = send_mqtt, }

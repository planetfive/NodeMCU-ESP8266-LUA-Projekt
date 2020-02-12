
-- allgemeine Parameter aus Datei "modulparameter.lua" einlesen **************
parameter = {}
function modulparameter(p)
	parameter = p
	for k,v in pairs(p) do print(k,v) end
end

if file.exists("modulparameter.lua") then print("Lade Modulparameter") dofile("modulparameter.lua") end
-- ende Parameter ************************************************************

myIP = nil  -- verwendet in setup_udp() und start_udp()

local actions
function setup_basics() -- verwendet im servermode
   -- ***********  installiere actions und conditions  ******************************
      actions = require("actions")
   -- actions.register("myAction", function() print("this is my action") end )
      actions.start()
      -- actions.printActions()
   -- ***********  ende actions  ****************************************************

   -- **********  installiert inputs.lua ********
   if file.exists("inputs.lua") then
      print("binde inputs.lua ein")
      dofile("inputs.lua")
   end
   -- **********  ende inputs  ******************

   -- schalter initialisieren  ********************************
   if parameter.schalter then
      for k,v in pairs(parameter.schalter) do
         print(k .. " mit Pin:" .. v .. " vorhanden")
         gpio.mode(v, gpio.OUTPUT)
         gpio.write(v, gpio.HIGH)
      end
   end
   -- ende schalter  **********************************************
end

-- ********* UDP-Nachrichten aktivieren  *******************************************
function setup_udp()
   if parameter.action_udp then
      local udp_skt = net.createUDPSocket()
      udp_skt:on("sent",function(s)
         print("sent")
         s:on("receive", function(s, data, port, ip)
            print(string.format("received '%s' from %s:%d", data, ip, port)) end)
         end)
      local udp_count
      actions.register("udp_action", function()
         if udp_count and udp_count > 0 then
            print("udp blocking")
            udp_count = udp_count - 1
            return
         end
         udp_count = parameter.action_udp.blocking
         -- ** die bedingung festlegen und den sendetext generieren
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

         -- ********************************************************
      udp_skt:send(parameter.action_udp.port, parameter.action_udp.ip, msg)
      end)
   end
end
-- ********** ende UDP *****************************************************************


-- Modul-LED blinkt solange die Einwahl ins Wlan dauert *********************
local modulLed = parameter.modulLed or 4 -- NodeMCU-Modul-LED D4 = GPIO2
gpio.mode(modulLed, gpio.INPUT, gpio.pullup)

function toggleLED()
   if gpio.read(modulLed) == gpio.HIGH then
      gpio.write(modulLed,gpio.LOW)
   else
      gpio.write(modulLed,gpio.HIGH)
   end
end

local ledTimer
-- ende blinken ***************************************************************

function startup_station()
   if parameter.mode == "Server" then
      setup_basics()
      setup_udp()
      dofile("lua_server.lua")
   else
      print("Modul-Mode nicht bekannt")
      dofile("lua_sensor.lua")
   end
end

function starteAP()
     local cfg={}
     cfg.ssid = "ESP_AP"
     cfg.auth = wifi.OPEN
     wifi.setmode(wifi.SOFTAP)
     if wifi.ap.config(cfg) == true then
        gpio.write(modulLed,gpio.LOW) -- Modul-LED einschalten
        print("Starte AP")
        setup_basics()
        dofile("lua_server.lua")
     else
        print("Accesspoint-Mode fehlgeschlagen")
     end
end


-- Define WiFi station event callbacks ******************************************************************************
wifi_connect_event = function(T)
  print("Connection to AP("..T.SSID..") established!")
  print("Waiting for IP address...")
  if disconnect_ct ~= nil then disconnect_ct = nil end
end

wifi_got_ip_event = function(T)
  -- Note: Having an IP address does not mean there is internet access!
  -- Internet connectivity can be determined with net.dns.resolve().
  print("Wifi connection is ready! IP-address is: "..T.IP)
  myIP = T.IP
  gpio.write(modulLed,gpio.HIGH) -- Modul-LED ausschalten
  ledTimer:stop()
  ledTimer:unregister()
  ledTimer = nil
  tmr.create():alarm(500, tmr.ALARM_SINGLE, startup_station)
  -- startup()
end

wifi_disconnect_event = function(T)
  if T.reason == wifi.eventmon.reason.ASSOC_LEAVE then
    --the station has disassociated from a previously connected AP
    return
  end
  -- total_tries: how many times the station will attempt to connect to the AP. Should consider AP reboot duration.
  local total_tries = 75
  print("\nWiFi connection to AP("..T.SSID..") has failed!")

  --There are many possible disconnect reasons, the following iterates through
  --the list and returns the string corresponding to the disconnect reason.
  for key,val in pairs(wifi.eventmon.reason) do
    if val == T.reason then
      print("Disconnect reason: "..val.."("..key..")")
      break
    end
  end

  if disconnect_ct == nil then
    disconnect_ct = 1
  else
    disconnect_ct = disconnect_ct + 1
  end
  if disconnect_ct < total_tries then
    print("Retrying connection...(attempt "..(disconnect_ct+1).." of "..total_tries..")")
  else
    wifi.sta.disconnect()
    print("Aborting connection to AP!")
    disconnect_ct = nil
    tmr.create():alarm(3000, tmr.ALARM_SINGLE, starteAP)
  end
end
-- ende wifi callbacks **************************************************************************************************************

-- Installiere Reset in den LUA-Standardeingabemode - die Datei init.lua wird umbenannt ********
function gpio0call(_, _, _)
   if file.exists("init.lua") then
      print("call gpio0 - rename init.lua --> lua_start.lua")
      if file.exists("lua_start.lua") then file.remove("lua_start.lua") end
      file.rename("init.lua","lua_start.lua")
   elseif file.exists("lua_start.lua") then
      print("call gpio0 - rename lua_start.lua --> init.lua")
      if file.exists("init.lua") then file.remove("init.lua") end
      file.rename("lua_start.lua","init.lua")
   end
   print("resete Modul")
   node.restart()
end

gpio.mode(3, gpio.INT, gpio.PULLUP)
gpio.trig(3, "up", gpio0call)
-- ende Reset **********************************************************************************



-- ************* wifi definieren ***********************************************************

   -- Register WiFi Station event callbacks
   wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, wifi_connect_event)
   wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, wifi_got_ip_event)
   wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, wifi_disconnect_event)

   if parameter.ssid and parameter.pw then -- Station-Mode
      ledTimer = tmr.create()
      ledTimer:register(500, tmr.ALARM_AUTO, toggleLED)
      ledTimer:start()
      print("Connecting to WiFi access point...")
      wifi.sta.sethostname(parameter.name)
      wifi.setmode(wifi.STATION)
      wifi.sta.config({ssid=parameter.ssid, pwd=parameter.pw})
      -- wifi.sta.connect() -- not necessary because config() uses auto-connect=true by default
   else -- Accesspoint-Mode
     print("Kein Passwort oder SSID in 'modulparameter.lua' angegeben")
     starteAP()
   end










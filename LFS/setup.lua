starttime = tmr.now()
-- allgemeine Parameter aus Datei "modulparameter.lua" einlesen **************
parameter = {}
function modulparameter(p)
	parameter = p
	for k,v in pairs(p) do print(k,v) end
end

if file.exists("modulparameter.lua") then
   print("Lade Modulparameter")
   dofile("modulparameter.lua")
else
   print("Keine modulparameter.lua-Datei gefunden - Starte als AP im Servermode")
   print("Das Passwort zum Hochladen von lua-Dateien lautet <passwort>")
   parameter.mode = "Server"
   parameter.lua_pw = "passwort"
end

local _, reason = node.bootreason()
print("Bootreason:", reason)
if reason == 0 then
   parameter.mode = "Server"
end
reason = nil

-- ende Parameter ************************************************************

myIP = nil  -- verwendet in setup_udp() und start_udp()

local actions
function setup_basics() -- verwendet im servermode
   -- ***********  installiere actions  ******************************
      actions = require("actions")
   -- actions.register("myAction", function() print("this is my action") end )
      actions.registerSensors()
      actions.registerMyActions()
      actions.start()
      -- actions.printActions()
   -- ***********  ende actions  ****************************************************

   -- **********  installiert my_setup.lua (wird nicht periodisch aufgerufen wie actions) ********
   if file.exists("my_setup.lua") then
      print("binde my_setup.lua ein")
      dofile("my_setup.lua")
   end
   -- **********  ende my_setup  ******************
end

-- ********* UDP-Nachrichten aktivieren  (im Server-Mode)  ***************************
function setup_udp()
   if parameter.action_udp then

      local msg = "Fehler in 'udpMessage.lua':"
      local udp,err = assert(loadfile("udpMessage.lua"))

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
      
      if udp == nil then
         print(msg .. err)
      else
         msg = udp()
      end
--      local msg = dofile("udpMessage.lua")
 
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

local station_up = nil

function startup_station()
   if parameter.mode == "Server" then
      setup_basics()
      setup_udp()
      dofile("lua_server.lua")
   elseif parameter.mode == "Sensor" then
      print("starte Sensormode")
      dofile("lua_sensor.lua")
   elseif parameter.mode == "specialSensor" then
      print("starte special Sensormode")
      dofile("lua_specialsensor.lua")
   else
   print("Mode nicht bekannt")
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
  if ledTimer then
     ledTimer:stop()
     ledTimer:unregister()
     ledTimer = nil
  end
  if station_up == nil then
     tmr.create():alarm(500, tmr.ALARM_SINGLE, startup_station)
     station_up = true
  end
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

-- specialSensor-Modus -----------------------------------------------------
function motionDetect()
   gpio.mode(parameter.input["Motion"], gpio.INPUT, gpio.PULLUP)
   return ( gpio.read(parameter.input["Motion"]) == gpio.HIGH )
end

if parameter.mode == "specialSensor" then
   print("specialMode wird ausgefuehrt")
   gpio.mode(2, gpio.OUTPUT) -- schaltet einen Transistor mit ca 50mA Stromverbrauch
   gpio.write(2, gpio.HIGH)  -- das trigert einen Akku (Powerbank)
   -- tmr.create():alarm(20, tmr.ALARM_SINGLE, function() gpio.write(2, gpio.LOW) end )
   if rtcmem.read32(10) ~= 112233 then
      if motionDetect() then
         print("detect true")
         print("lfz", tmr.now() - starttime)
         -- vorbereitung zum senden der nachricht
         rtcmem.write32(10, 112233)
         -- tmr.create():alarm(20, tmr.ALARM_SINGLE, function() rtctime.dsleep(100, 0) end)-- aufwachen mit WiFi
         rtctime.dsleep(10, 0)
         return
      else
         print("detect false")
         print("lfz", tmr.now() - starttime)
         -- beim nächsten Aufwachen kein WiFi
         if rtcmem.read32(11) < 1200 then
            rtcmem.write32(11, rtcmem.read32(11) + 1)
            rtcmem.write32(10, 0)
            tmr.create():alarm(160, tmr.ALARM_SINGLE, function() rtctime.dsleep(parameter.action_intervall*1000000, 4) end) -- aufwachen ohne WiFi
            return
         end
      end
   else
      -- nachricht wird gesendet
      print("lfz", tmr.now() - starttime)
      print("Sende Motion-Nachricht")
   end
end
-- ende specialSensor-Modus --------------------------------------------------


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










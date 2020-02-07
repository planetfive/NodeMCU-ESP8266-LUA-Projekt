
-- globale variablen fuer Temperatursensoren
temp_ds18b20 = nil
temp_dht = nil

-- registrierte Actions-tabelle
local all_actions = {}

local sens_ds = nil
local function action_ds18b20()
    sens_ds:read_temp(function(temp) print("ds18b20 readout done") temp_ds18b20 = sens_ds.temp end, parameter.sensor.ds18b20, sens_ds.C)
end

local function action_dht()
   local status, temp, humi, temp_dec, humi_dec = dht.read(parameter.sensor.dht)
   if status == dht.OK then
      -- Float firmware using this example
      print("DHT Temperature:"..temp..";".."Humidity:"..humi)
      temp_dht = temp

   elseif status == dht.ERROR_CHECKSUM then
      print( "DHT Checksum error." )
   elseif status == dht.ERROR_TIMEOUT then
      print( "DHT timed out." )
   end
end


local function doActions()
   for k,func in pairs(all_actions) do
      func()
   end
end


-- klassen-tabelle
local actions = {}

local act_t = nil

function actions.start()
   if not parameter.action_intervall then
      print("Kein 'action_intervall' in 'modulparameter.lua' vorhanden")
      return
   end
   act_t = tmr.create()
   act_t:register(parameter.action_intervall*1000, tmr.ALARM_AUTO, doActions)
   act_t:start()
end

function actions.stop()
   if act_t == nil then return end
   act_t:stop()
   act_t:unregister()
   act_t = nil
end

function actions.register(key,func)
   all_actions[key] = func
end

function actions.unregister(key,func)
   all_actions[key] = nil
end

function actions.printActions()
   print("folgende Actions sind registriert:")
   for k,v in pairs(all_actions) do
      print(k, v)
   end
end


-- suche nach sensoren in tabelle parameter und registriere sie in all_actions
if parameter.sensor then
      for k,v in pairs(parameter.sensor) do
         if k == "ds18b20" then
            print("Sensor ds18b20 mit Pin-NR:"..v.." vorhanden")
            sens_ds = require("ds18b20")
            action_ds18b20()
            all_actions.ds18b20 = action_ds18b20
         end
         if k == "dht" then
            print("Sensor dht mit Pin-NR:"..v.." vorhanden")
            all_actions.dht = action_dht
         end
      end
end
--end


-- conditions.lua einbinden
if file.exists("conditions.lua") then
   print("conditions.lua exists")
   local conditions,err = assert(loadfile("conditions.lua"))
   if conditions == nil then print("'conditions.lua:'Fehler in loadfile:" .. err)
   else
      tbl = conditions()
      for k, v in pairs(tbl) do
         print("condition hinzugefügt:" , v)
         all_actions[k] = v
      end
   end
end


return actions


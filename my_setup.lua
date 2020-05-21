


local tmr_c = 0
local function motion()
   if tmr.time() <= tmr_c then return end
   tmr_c = tmr.time() + 100 -- verhindert das mehrmalige Aufrufen der Funktion (hier: 10 Sekunden blocking)
   if parameter.virtual_schalter["Motion"] == true then
      print("Motion aufgerufen")
   else
      print("Motion ist durch Schalter 'Motion' ausgeschaltet")
   end
end

--[[
local tm_rel = 0
local function toggleRelais()
   local tmr_c
   if tmr.time() <= tm_rel then return end
   tm_rel = tmr.now() + 10000 -- verhindert das mehrmalige Aufrufen der Funktion (hier: 10 Millisekunden blocking)
   if gpio.read(parameter.schalter["Heizer Vorratsraum"]) == gpio.HIGH then
      gpio.write(parameter.schalter["Heizer Vorratsraum"],gpio.LOW)
   else
      gpio.write(parameter.schalter["Heizer Vorratsraum"],gpio.HIGH)
   end
end
]]--


-- alle hier eingetragenen funktionen werden durch die aufsteigende Flanke des input-pin getriggert
local tbl = { ["Motion"] = motion, }


-- hier werden die inputs initialisiert
   if parameter.input then
      for k,v in pairs(parameter.input) do
         print("Input:" .. k .. " mit Pin:" .. v .. " vorhanden")
         if tbl[k] == nil then
            print(k .. ": Keine Funktion in inputs.lua angelegt")
         else
            gpio.mode(v, gpio.INT, gpio.PULLUP)
            gpio.trig(v, "up", tbl[k])    -- der pin wird mit steigender Flanke getriggert
         end
       end

   end


-- hier werden die schalter initialisiert - geschaltet wird über den webbrowser
-- alternativ kann in my_actions.lua eine funktion programmiert werden, die intervallmaessig aufgerufen wird und den pin schaltet
   if parameter.schalter then
      for k,v in pairs(parameter.schalter) do
         print("Schalter:" .. k .. " mit Pin:" .. v .. " vorhanden")
         gpio.mode(v, gpio.OUTPUT)
         gpio.write(v, gpio.LOW)
      end
   end



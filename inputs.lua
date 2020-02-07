-------------- hier die eigenen Funktionen definieren -------------------------------------------------------------------
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










---------- alle Funktionen in diese Tabelle eintragen, siehe conditions.lua ---------------------------------------------
local tbl = { ["Motion"] = motion, }

--------------------------------------------------------------------------------------------------------------------------







-- ***************************** Achtung, hier nichts verändern, ausser man weiss, was man tut :)
-- inputs initialisieren ------
   if parameter.input then
      for k,v in pairs(parameter.input) do
         print("Input:" .. k .. " mit Pin:" .. v .. " vorhanden")
         if tbl[k] == nil then
            print(k .. ": Keine Funktion in inputs.lua angelegt")
         else
            gpio.mode(v, gpio.INT, gpio.PULLUP)
            gpio.trig(v, "down", tbl[k])    -- ToDo: Achtung!!!!! dieser code muss noch bearbeitet werden
         end
       end

   end


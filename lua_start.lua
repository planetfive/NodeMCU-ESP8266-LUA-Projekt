

-- binde LFS ein ***************************************************
print("binde LFS ein")
node.flashindex("_init")()
print("LFS init:", LFS, LFS._list)
for k,v in pairs(LFS._list)  do print(k,v) end

  -- damit koennen alle im RAM liegenden Strings angezeigt werden
  --local a=debug.getstrings'RAM'
  --for i =1, #a do a[i] = ('%q'):format(a[i]) end
  --print ('local preload='..table.concat(a,','))

-- ende LFS ********************************************************



-- ****************** Bootloopschleife verhindern *******************************************
-- sollte für Testzwecke aktiviert werden um Endlos-Bootschleife zu verhindern
-- Durch Drücken des FLASH-Buttons während das Modul blinkt oder danach wird die Datei init.lua in lua_start.lua umbenannt
--[[
function gpio0call()
   if file.exists("init.lua") then
      print("call gpio0 - rename init.lua --> lua_start.lua")
      file.rename("init.lua","lua_start.lua")
      -- *** Achtung! *** hier Funktion für Testphasen scharfschalten
      -- durch Drücken des BOOT-Tasters am NODE-MCU-Modul wird die init.lua in lua_start.lua umbenannt

      print("resete Modul")
      node.restart()
   end
end
gpio.mode(3, gpio.INT, gpio.PULLUP)
gpio.trig(3, "up", gpio0call)
--]]
-- *********************************************************************************************



-- starte Programmausführung
dofile("setup.lua")




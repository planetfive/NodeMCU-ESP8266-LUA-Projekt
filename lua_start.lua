

-- binde LFS ein ***************************************************
node.flashindex("_init")()
    -- print("LFS init:", LFS, LFS._list)
    --for k,v in pairs(LFS._list)  do print(k,v) end


  -- damit koennen alle im RAM liegenden Strings angezeigt werden
  --local a=debug.getstrings'RAM'
  --for i =1, #a do a[i] = ('%q'):format(a[i]) end
  --print ('local preload='..table.concat(a,','))

-- ende LFS ********************************************************

-- starte Programmausführung
dofile("setup.lua")


-- *************** Achtung *********************************
-- diese Datei zum automatischen Booten in "init.lua" umbenennen
-- bei Endlosbootschleife den FLASH-Taster am Modul drücken ( während der Einwahl, das Modul blinkt )
-- Dadurch wird die init.lua wieder umbenannt in lua_start.lua und der Bootprozess stoppt

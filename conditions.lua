-- hier die bedingungen fuer actions eintragen

local function condition_test()
   print("condition_test")
end


-- **** Achtung! Wichtig! **** In diese Tabelle alle eigenen funktionen eintragen
-- Alle eingetragenen Funktionen werden im Rhytmus von "action_intervall" ( in modulparameter.lua ) ausgeführt

return { ["test"] = condition_test, }

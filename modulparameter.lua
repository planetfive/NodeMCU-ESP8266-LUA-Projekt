-- ************* zentrale Parameterdatei ********************************************************************************************************************************
-- diese Parameter dienen der Steuerung des Moduls

modulparameter {


	name	=	"NodeMCU",	-- Modulname ( sollte mit diesem Namen im Heimnetz auftauchen )

	mode	=	"Server",	-- entweder "Server" (immer erreichbar,am Stromnetz) oder z. B. "Sensor" (Batteriemodus mit Deepsleep, noch nicht programmiert)

	modulLed =	4,		-- Modul-LED (D4 == GPIO2) bei NodeMCU-Modul ist D4 die System-LED

	action_intervall = 120,		-- die Datei "actions.lua" wird intervallmaessig aufgerufen (in Sekunden)

	sensor	=	{ ["ds18b20"] = 5 }, -- Liste: momentan "ds18b20" oder "dht" mit jeweiliger Modul-Nr ( hier D5 ist GPIO14 )

	schalter=	{ ["Heizer Vorratsraum"] = 6, },	-- Liste: Die Namen sind auch die Bezeichnungen der Buttons (D6 ist GPIO12)
	virtual_schalter = { ["Bewegungsmelder Flur"] = true, },		-- Virtuelle Schalter zum z.B. Bewegungssensoren scharf zu schalten (Zustand: true oder false)

	input	=	{ ["Motion"] = 1, },	 -- wie bei schalter, (D1 ist GPIO5 )

        -- action_udp sendet im Beispiel intervallmaessig Daten an IP 192.168.1.124 mit Port 15000
	-- wenn der Comp. 192.168.1.124 Linux als Betriebssystemhat, kann man sich das anzeigen lassen - Befehl: "nc -ul 15000"
        action_udp =	{ port = 15000, ip = "192.168.1.124", blocking = 0 }, -- blocking*action_intervall ergibt die Zeit, in der die UDP-Funktion blockiert wird

	ssid	=	"F7490",	-- Name Wlan-Heimnetz
	pw	=	"meinTollesPasswort",	-- Passwort Wlan-Heimnetz
        -- Falls die Werte für ssid oder pw fehlen, oder falsch sind, geht das Modul beim Booten in den Acesspoint-Modus

	lua_pw	=	"passwort"	,	-- Passwort schaltet den Upload von lua-Dateien fuer 10 Min. frei (in "login.htm")

	-- ***** hier alias festlegen fuer Temperatursensoren vom typ ds1820  *****
	-- ***** wird im Webserver statt ROM-Code der Sensoren angezeigt, dadurch klare Zuordnung bei mehreren DS's möglich  **********************
	alias	= 	{ ["10:8A:AC:C5:02:08:00:4D"] = "Esszimmer", },

	-- **************************************************************************************************************************************************************


}

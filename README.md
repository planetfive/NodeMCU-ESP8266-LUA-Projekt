# NodeMCU-ESP8266-LUA-Projekt

Ein http-Server mit universellem Ansatz für viele Bedürfnisse - getestet mit NodeMCU-Modul.
Wesentlicher Bestandteil: [NodeMCU-HTTP-Server, etwas angepasst](https://github.com/wangzexi/NodeMCU-HTTP-Server).

## Features

* http-Server (Get -und Post-Requests)
* Upload von Dateien
* Upload von lua-Dateien mit login (wenigstens etwas gesichert)
* Generieren von dynamischen und statischen Inhalten als Response ( Dateien oder Buffer )
* Einfügen von dynamischen Inhalten mit Hilfe von Filterfunktion in html-Dateien
* Einfaches Einbinden von Sensoren ( freie GPIO-Wahl )
* Einfaches Einbinden von Schaltern ( GPIO's ) und virtuellen Schaltern ( Softwarefunktionen )
* Einfaches Erweitern der Funktionalität anhand der Softwarebeispiele ( Schalten, Messen, Versenden von Nachrichten ist vorbereitet )
* ca 25 kb RAM stehen noch zur Verfügung
* Konfiguration über zentrale Parameterdatei
* Geeignet sowohl für Programmierer als auch für interessierte Laien

## Inbetriebnahme

Für die Eiligen:

Entpacken der Zip-Datei

Modul mit Firmware "nodemcu-master-float.bin" mit z.B. "esptool.py" flashen ( "esptool.py --port /dev/ttyUSB0 erase_flash", dann "esptool.py --port /dev/ttyUSB0 write_flash --flash_size 4MB 0x00000 /eigeneVerzeichnisse/ESP_Lua/nodemcu-master-float.bin" )

"ssid" , "pw" und modulLed in "modulparameter.lua" anpassen


Mit z.B. ESPlorer folgende Dateien uploaden: alle *.lua-Dateien aus dem Hauptverzeichniss, alle Dateien aus dem "serverFiles"-Verzeichniss und aus dem "LFS"-Verzeichniss die "lfs.img"-Datei.

Modul reseten

In die Kommandozeile von ESPlorer *node.flashreload("lfs.img")* eingeben und Send-Button drücken

Wenns geklappt hat, resetet das Modul

Zum Starten in die Kommandozeile *dofile("lua_start.lua")* eingeben. Send-Button drücken
Jetzt sollte der Server gestartet werden

Zum automatischen Programmstart muss die "lua_start.lua"-Datei in "init.lua" umbenannt werden.

Generell die Ausgaben im ESPlorer beachten.

Bei Erfolg sollte unter Anderem die IP-Adresse des Moduls angezeigt werden. Diese in den Browser eingeben. Testen :)

Wichtig: Der Flash-Taster ( neben Micro-USB-Buchse ) des NodeMCU-Moduls wird benutzt um eine Endlos-Bootschleife zu unterbrechen. Hierbei wird die "init.lua"-Datei in "lua_start.lua" umbenannt.
Hierzu in der Datei "lua_start.lua" bei "Bootloopschleife verhindern" "--[[" mit zwei zusätzlichen "--" scharfschalten.

Der Einwahlmodus ins Heim-WLan wird mit einer blinkenden System-LED angezeigt.

Falls die LED dauerhaft leuchtet, ist das Modul im Accespoint-Modus mit eigenem WLan.



## Beschreibung

Folgende Links sind sehr hilfreich:

*1* [Zentrale Anlaufstation](https://nodemcu.readthedocs.io/en/master/)

Hier findet man eigentlich alles Wichtige zum Programmieren des ESP mit LUA.

*2* [esptool.py und ESPlorer](https://nodemcu.readthedocs.io/en/master/getting-started/#esptoolpy)

*3* [Compile Lua into LFS image](https://nodemcu.readthedocs.io/en/master/getting-started/#compile-lua-into-lfs-image)

*4* [MIT-Lizenz](https://opensource.org/licenses/mit-license.php)



Mit Hilfe obiger Links soll das Verständniss für die Inbetriebnahme des Moduls vermittelt werden.

Die Beispielkonfiguration zeigt die Möglichkeiten der Software. Hier ist ein ds18b20-Temperatursensor an D5 angeschlossen. Ein DHT-Feuchtesensor ist programmiert.

In die "my_actions.lua"-Datei programmiert man alles, was das Modul periodisch tun soll. (siehe "action_intervall" in modulparameter.lua)

Die "my_setup.lua"-Datei wird einmal bei Programmstart von "setup.lua" aufgerufen. Hier kann z.B. die Funktionalität von Input-Pin's programmiert werden.

Im serverFiles-Verzeichniss liegen die Dateien zum Betreiben des Servers. Der Server sollte auch mit *.ico und *.jpg-Dateien klarkommen. Der Kreativität sind wenig Grenzen gesetzt.

Alle lua-Dateien, die nicht mehr verändert werden sollen, kann man in's LFS-Verzeichniss legen. Entsprechend der Beschreibung von obigem Link[3] packen, mit [LUA-Compile-Service](https://blog.ellisons.org.uk/article/nodemcu/a-lua-cross-compile-web-service/) kompilieren und aufs Modul uploaden.

Der Befehl "node.flashreload("lfs.img")" erstellt den LFS-Bereich neu mit dem zuvor gebauten Image.

Dadurch ist es erst möglich mit Lua komplexere Programme für den ESP8266 zu erstellen und den RAM-Verbrauch deutlich zu verkleinern.

Ich hoffe, dass ich alle Themen wenigstens angerissen habe. Wer mehr Infos braucht, Verbesserungsvorschläge hat oder Fehler melden will:

[Reinhold](mailto:reinhold.kreisel@gmail.com)



Lizenz: MIT [4]


--[[

    etc_sslonly_0.1 by pulsar

        Version: Luadch_0.08

        - SSL/TLS Checker, um zu gewährleisten das User mit deaktivierter SSL/TLS-Funktion disconnected werden.

]]--



--------------
--[SETTINGS]--
--------------

--> Scriptname
local scriptname = "etc_sslonly"


--> Warnmeldung an User mit deaktivierter SSL/TLS-Funktion
local usermsg = [[

                                                          +++  WARNUNG - BITTE LESEN +++

        Die SSL/TLS Funktion deines Clienten ist deaktiviert oder das Zertifikat kann nicht eingelesen werden.

        Folgendes ist zu tun:

         - Gehe in deine Client Einstellungen in das Menu "Sicherheitszertifikate"
         - Kontrolliere ob der Pfad für den Privaten Schlüssel richtig ist. (DeinClient\Certificates\client.key)
         - Kontrolliere ob der Pfad für das Zertifikat richtig ist. (DeinClient\Certificates\client.crt)
         - Und ob sich das Zertifikat auch wirklich in diesem Verzeichnis befindet. (DeinClient\Certificates\)
         - Dann setze dort alle Haken bei den TLS Features.

        Sollte es danach noch immer nicht funktionieren hilft es eventuell ein neues Zertifikat zu erstellen.
        Vorgehensweise dazu:

         - Gehe in deine Client Einstellungen in das Menu "Sicherheitszertifikate"
         - Lösche dort in allen drei Feldern den vollständigen Pfad heraus und bestätige unten auf OK.
         - Client schliessen
         - Folgende Dateien löschen:  Certificates/client.crt     &   Certificates/client.key
         - Client starten und in den Settings im Menu "Sicherheitzertifikate" Den Button zum erstellen eines neuen
           Zertifikates drücken.
         - Client neustarten


        MfG Das Hubteam

    ]]

--> Soll Das Hubteam über den geblockten User als PM vom Hubbot informiert werden? (true=JA/false=NEIN)
local informteam = true

--> Hubteam Minlevel
local teamlevel = 60

--> Nachricht an das Hubteam
local teammsg = "Warnung: Folgender User wurde disconnected weil seine SSL/TLS-Funktion deaktiviert ist:  "

--> Sollen alle anderen User über den geblockten User im Main informiert werden? (true=JA/false=NEIN)
local informall = true

--> Nachricht an die User
local mainmsg = "Warnung: Folgender User wurde disconnected weil seine SSL/TLS-Funktion deaktiviert ist:  "


----------
--[CODE]--
----------

local checkSSL = function(user, adccmd)
    local ssl1 = user:hasfeature("ADCS")
    local ssl2 = user:hasfeature("ADC0")
    local user_nick = user:nick()
    local hub_getusers = hub.getusers()
    local hub_getbot = hub.getbot()
    local hub_broadcast = hub.broadcast
    if not (ssl1 or ssl2) then
        user:reply(usermsg, hub_getbot)
        user:kill("sorry")
        if informteam then
            for sid, user in pairs(hub_getusers) do
                local opuser = user:level()
                if opuser >= teamlevel then
                    user:reply(teammsg..user_nick, hub_getbot, hub_getbot)
                end
            end
        end
        if informall then
            hub_broadcast(mainmsg..user_nick, hub_getbot)
        end
        return PROCESSED
    end
    return nil
end

hub.setlistener("onLogin", {}, checkSSL)

hub.debug("** Loaded "..scriptname..".lua **")

---------
--[END]--
---------
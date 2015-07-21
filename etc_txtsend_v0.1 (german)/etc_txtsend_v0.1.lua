--[[

    etc_txtsend_0.1 by pulsar

    Version: Luadch 0.08
    
        - Das Script ermöglicht das senden von Textdateien in den Mainchat/als PM
        - WICHTIG: Die Textdateien müssen im UTF8 Format gespeichert werden
        
        Befehl: [+!#]txtsend <dateiname>    <- (ohne .txt)

]]--



--[SETTINGS]

local scriptname = "etc_txtsend"  --> Scriptname
local cmd = "txtsend"  --> Befehl
local sendmode = 1  --> Wohin soll der Text geschickt werden? (1=MAIN/2=PM)
local minlevel = 30  --> Ab welchem Level darf gesendet werden?

local failmsg = "Du bist nicht befugt den Befehl 'txtsend' zu nutzen!"  --> Fehlermeldung bei unzureichenden Nutzungsrechten
local failsend = "Fehler: Datei nicht gefunden!"  --> Fehlermeldung falls Datei nicht geladen werden kann

local txtpath = "scripts/etc_txtsend/"  --> Verzeichnis der Textdateien

local ucmd_menu = {"User", "Messages", "Textdatei senden"}  --> Rechtsklickmenu


--[CODE]

hub.setlistener("onBroadcast", {},
    function(user, adccmd, txt)
        local cmd1, cmd2 = utf.match(txt, "^[+!#](%a+) (.+)")
        if cmd1 == cmd and cmd2 then
            if user:level() >= minlevel then
                local file = io.open(txtpath..cmd2..".txt", "r")
                local msg
                if file == nil then
                    user:reply(failsend, hub.getbot())
                    return PROCESSED
                else
                    msg = file:read("*a")
                    file:close()
                end
                if sendmode == 1 then
                    user:reply("\n\n"..msg, hub.getbot())
                    return PROCESSED
                else
                    if sendmode == 2 then
                        user:reply("\n\n"..msg, hub.getbot(), hub.getbot())
                        return PROCESSED
                    end
                end
            else
                user:reply(failmsg, hub.getbot())
                return PROCESSED
            end
        end
    end
)

hub.setlistener("onStart", {},
    function()
        local ucmd = hub.import "etc_usercommands"
        if ucmd then
            ucmd.add( ucmd_menu, cmd, {"%[line:Dateiname?]"}, {"CT1"}, minlevel)
        end
        return nil
    end
)

hub.debug("** Loaded "..scriptname..".lua **")

--[END]

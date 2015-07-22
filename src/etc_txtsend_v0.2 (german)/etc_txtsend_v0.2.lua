--[[

    etc_txtsend by pulsar

    
        Version: Luadch 0.08

        
        v0.1
            - Das Script ermöglicht das senden von Textdateien (Main/PM)
        
        v0.2
            - Code-Kosmetik
            - Hinzugefügt: Help Feature (hub.import "cmd_help")
            
            
    Befehl: [+!#]txtsend <dateiname>    <- (ohne .txt)
    WICHTIG: Die Textdateien müssen im UTF8 Format gespeichert werden
]]--



--------------
--[SETTINGS]--
--------------

--> Scriptname
local scriptname = "etc_txtsend"

--> Befehl
local cmd = "txtsend"

--> Wohin soll der Text geschickt werden? (1=MAIN/2=PM)
local sendmode = 1

--> Ab welchem Level darf gesendet werden?
local minlevel = 60

--> Fehlermeldung bei unzureichenden Nutzungsrechten
local failmsg = "*** Du bist nicht befugt diesen Befehl zu nutzen!"

--> Fehlermeldung falls Datei nicht geladen werden kann
local failsend = "*** Fehler: Datei nicht gefunden!"

--> Verzeichnis der Textdateien
local txtpath = "scripts/etc_txtsend/"

--> Rechtsklickmenu/Submenu
local ucmd_menu = {"User", "Messages", "Textdatei senden"}

--> Help Feature
local help_title = "TXT Send"
local help_usage = "[+!#]txtsend <dateiname>    <- (ohne .txt)"
local help_desc = "Das Script ermöglicht das senden von Textdateien (Main/PM)"


----------
--[CODE]--
----------

hub.setlistener("onBroadcast", {},
    function(user, adccmd, txt)
        local cmd1, cmd2 = utf.match(txt, "^[+!#](%a+) (.+)")
        local hub_getbot = hub.getbot()
        local user_level = user:level()
        if cmd1 == cmd and cmd2 then
            if user_level >= minlevel then
                local file = io.open(txtpath..cmd2..".txt", "r")
                local msg
                if file == nil then
                    user:reply(failsend, hub_getbot)
                    return PROCESSED
                else
                    msg = file:read("*a")
                    file:close()
                end
                if sendmode == 1 then
                    user:reply("\n\n"..msg, hub_getbot)
                    return PROCESSED
                else
                    if sendmode == 2 then
                        user:reply("\n\n"..msg, hub_getbot, hub_getbot)
                        return PROCESSED
                    end
                end
            else
                user:reply(failmsg, hub_getbot)
                return PROCESSED
            end
        end
    end
)

hub.setlistener("onStart", {},
    function()
        local help = hub.import "cmd_help"
        if help then
            help.reg(help_title, help_usage, help_desc, minlevel)
        end
        local ucmd = hub.import "etc_usercommands"
        if ucmd then
            ucmd.add( ucmd_menu, cmd, {"%[line:Dateiname?]"}, {"CT1"}, minlevel)
        end
        return nil
    end
)

hub.debug("** Loaded "..scriptname..".lua **")

--[END]

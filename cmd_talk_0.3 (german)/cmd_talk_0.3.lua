--[[

	cmd_talk by pulsar

    
		Version: Luadch 0.08
        
        
        v0.2
			- Das Script ermöglicht das 'talken' ohne Nicknamen im Mainchat,
			  die Nachricht wird vom Hubbot gesendet.
		
        v0.3
            - Code-Kosmetik
            - Hinzugefügt: Help Feature (hub.import "cmd_help")
            
]]--


--------------
--[SETTINGS]--
--------------

--> Scriptname
local scriptname = "cmd_talk"

--> Befehl
local cmd = "talk"

--> Fehlermeldung bei unzureichenden Nutzungsrechten
local failmsg = "*** Du bist nicht befugt diesn Befehl zu nutzen!"

--> ab welchem Level darf getalkt werden?
local minlevel = 60

--> Rechtsklickmenu / Submenu
local ucmd_menu = {"User", "Talk", "im Main talken"}

--> Help Feature
local help_title = "Talk"
local help_usage = "[+!#]talk <msg>"
local help_desc = "Im Main chatten ohne Nick"


----------
--[CODE]--
----------

hub.setlistener("onBroadcast", {},
    function(user, adccmd, txt)
        local cmd1, cmd2 = utf.match(txt, "^[+!#](%a+) (.+)")
        local user_level = user:level()
        local hub_getbot = hub.getbot()
        if cmd1 == cmd and cmd2 then
            if user_level >= minlevel then
                hub.broadcast(cmd2, hub_getbot)
            else
                user:reply(failmsg, hub_getbot)
            end
            return PROCESSED
        end
        return nil
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
            ucmd.add( ucmd_menu, cmd, {"%[line:Nachricht?]"}, {"CT1"}, minlevel)
        end
        return nil
    end
)

hub.debug("** Loaded "..scriptname..".lua **")

---------
--[END]--
---------
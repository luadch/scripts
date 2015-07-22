--[[

	cmd_talk_0.2 by pulsar

		Version: Luadch 0.08
			- Das Script ermöglicht das 'talken' ohne Nicknamen im Mainchat,
			  die Nachricht wird vom Hubbot gesendet.
		  
]]--



--[SETTINGS]

local scriptname = "cmd_talk"  --> Scriptname
local cmd = "talk"  --> Befehl
local failmsg = "Du bist nicht befugt den Befehl 'talk' zu nutzen!"  --> Fehlermeldung bei unzureichenden Nutzungsrechten
local minlevel = 60  --> ab welchem Level darf getalkt werden?
local ucmd_menu = {"User", "Talk", "im Main talken"}  --> Rechtsklickmenu Struktur

--[CODE]

hub.setlistener("onBroadcast", {},
    function(user, adccmd, txt)
        local cmd1, cmd2 = utf.match(txt, "^[+!#](%a+) (.+)")
        if cmd1 == cmd and cmd2 then
            if user:level() >= minlevel then
                hub.broadcast(cmd2, hub.getbot())
            else
                user:reply(failmsg, hub.getbot())
            end
            return PROCESSED
        end
        return nil
    end
)

hub.setlistener("onStart", {},
    function()
        local ucmd = hub.import "etc_usercommands"  --> Rechtsklickmenu
        if ucmd then
            ucmd.add( ucmd_menu, cmd, {"%[line:Nachricht?]"}, {"CT1"}, minlevel)
        end
        return nil
    end
)

hub.debug("** Loaded "..scriptname..".lua **")

--[END]
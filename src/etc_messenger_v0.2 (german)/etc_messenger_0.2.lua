--[[

    etc_messenger_0.2 by pulsar (requested by GøLLuM™)

        Version: Luadch LUA 5.1x

        
        v0.1

            - Sendet beim Einloggen eine Nachricht an die User
            
        v0.2
        
            - Hinzugefügt: Auswahlmöglichkeit MAIN/PM
            - Hinzugefügt: Timer
            - Hinzugefügt: Befehl zum Manuellen senden der Nachricht + Rechtsklick

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_messenger"
local scriptversion = "0.2"

--> Befehl zum manuellen Senden der Nachricht
local cmd = "msg"
--> Parameter - MAIN Nachricht
local cmd_p_main = "main"
--> Parameter - MAIN Nachricht
local cmd_p_pm = "pm"

--> Nutzungsrechte zum manuellen Senden der Nachricht
local minlevel = 60
--> Meldung bei fehlenden Nutzungsrechten
local failmsg = "*** Du bist nicht befugt diesen Befehl zu nutzen!"

--> Nachrichtenwiederholung per Timer? (true=JA/false=NEIN)
local autorotate = true
--> Wiederholung, Zeit in Stunden
local time = 6

--> Rechtsklickmenu/Submenu
local ucmd_menu_main = {"Messenger", "Sende Nachricht", "MAIN"}
local ucmd_menu_pm = {"Messenger", "Sende Nachricht", "PM"}

--> An welche Level soll die Nachricht gesendet werden? (true=JA/false=NEIN)
local sendto = {

    [ 0 ] = false, --> unreg
    [ 10 ] = true, --> guest
    [ 20 ] = true, --> reg
    [ 30 ] = true, --> vip
    [ 40 ] = true, --> svip
    [ 60 ] = true, --> operator
    [ 80 ] = true, --> admin
    [ 100 ] = true, --> hubowner
}

--> Sende Nachricht zu MAIN (true=JA/false=NEIN)
local destination_main = true
--> Sende Nachricht zu PM (true=JA/false=NEIN)
local destination_pm = true

--> Nachricht die gesendet werden soll
local msg = [[ 

        ##    ##   ####   ####
        #   #   #   #          #
        #        #   ####   #   ##
        #        #          #   #     #
        #        #   ####   ####

    ]]


----------
--[CODE]--
----------

local hub_getbot = hub.getbot()
local hub_getusers = hub.getusers
local hub_broadcast = hub.broadcast
local utf_match = utf.match
local hubcmd

local delay = time * 60 * 60
local os_time = os.time
local os_difftime = os.difftime
local start = os_time()

hub.setlistener("onLogin", {},
    function(user)
        local user_level = user:level()
        if sendto[user_level] then
            if destination_main then
                hub_broadcast(msg, hub_getbot)
            end
            if destination_pm then
                hub_broadcast(msg, hub_getbot, hub_getbot)
            end
        end
        return PROCESSED
    end
)

local onbmsg = function(user, adccmd, parameters, txt)
    local id = utf_match(parameters, "^(%S+)$")
    local user_level = user:level()
    if id == cmd_p_main then
        if user_level >= minlevel then
            if sendto[user_level] then
                hub_broadcast(msg, hub_getbot)
            end
        else
            user:reply(failmsg, hub_getbot)
        end
        return PROCESSED
    end
    if id == cmd_p_pm then
        if user_level >= minlevel then
            if sendto[user_level] then
                hub_broadcast(msg, hub_getbot, hub_getbot)
            end
        else
            user:reply(failmsg, hub_getbot)
        end
        return PROCESSED
    end
end

hub.setlistener("onTimer", {},
    function()
        if os_difftime(os_time() - start) >= delay then
            if autorotate then
                for sid, user in pairs(hub_getusers()) do
                    if not user:isbot() then
                        if sendto[user:level()] then
                            if destination_main then
                                hub_broadcast(msg, hub_getbot)
                            end
                            if destination_pm then
                                hub_broadcast(msg, hub_getbot, hub_getbot)
                            end
                        end        
                    end
                end
                start = os_time()
            end
        end
        return nil
    end
)

hub.setlistener("onStart", {},
    function()
        local ucmd = hub.import "etc_usercommands"
        if ucmd then
            ucmd.add(ucmd_menu_main, cmd, {cmd_p_main}, {"CT1"}, minlevel)
            ucmd.add(ucmd_menu_pm, cmd, {cmd_p_pm}, {"CT1"}, minlevel)
        end
        hubcmd = hub.import "etc_hubcommands"
        assert(hubcmd)
        assert(hubcmd.add(cmd, onbmsg))
        return nil
    end
)

hub.debug("** Loaded "..scriptname.."_"..scriptversion..".lua **")

---------
--[END]--
---------
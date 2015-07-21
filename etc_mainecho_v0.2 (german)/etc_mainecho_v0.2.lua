--[[

    etc_mainecho_0.2 by pulsar

    
        Version: Luadch 0.08
    
    
        v0.1
        
            - Das Script antwortet im Main auf gewisse Schlüsselwörter und Befehle und um es
              etwas realistischer wirken zu lassen sorgt ein kleiner Timer für ein Delay

        v0.2
        
            - Hinzugefügt: 'string.lower' Funktion, in der 'echomsg' Tabelle muss nun nicht mehr auf
              Gross- und Kleinschreibung geachtet werden
              
]]--



--------------
--[SETTINGS]--
--------------

local scriptname = "etc_mainecho"

--> Berechtigung, wer bekommt ein Echo?
local minlevel = 30

--> Zeitverzögerung des Echos (in Sek.)
local delay = 4

--> Antwort Echo auf Msg des Users
local echo1 = "Guten Morgen "
local echo2 = "Gute Nacht "
local echo3 = "Lass es dir schmecken "
local echo4 = "Hallo "
local echo5 = "Tja, wer weiss das schon so genau "
local echo6 = "Guten Abend "

--> Schlüsselwörter auf die ein Echo ausgelöst wird
local echomsg = {

["moin"] = echo1,
["moin hub"] = echo1,
["morgen"] = echo1,
["moinmoin"] = echo1,
["moin moin"] = echo1,
["guten morgen"] = echo1,
["guten morgen hub"] = echo1,

["gn8"] = echo2,
["gn8 hub"] = echo2,
["n8"] = echo2,
["n8 hub"] = echo2,
["n8i"] = echo2,
["n8i hub"] = echo2,
["n8ti"] = echo2,
["gn8@all"] = echo2,
["nacht"] = echo2,
["nachti"] = echo2,
["gute nacht"] = echo2,
["gute nacht hub"] = echo2,

["prost"] = echo3,
["kaffee"] = echo3,
["bier"] = echo3,
["tee"] = echo3,
["kaba"] = echo3,

["hi"] = echo4,
["hallo"] = echo4,
["huhu"] = echo4,
["hi@all"] = echo4,
["servus"] = echo4,
["sers"] = echo4,
["hallöchen"] = echo4,
["re"] = echo4,

["ein op da"] = echo5,
["ein op da?"] = echo5,
["ist ein op da"] = echo5,
["ist ein op da?"] = echo5,

["nabend"] = echo6,
["guten abend"] = echo6,

}

----------
--[CODE]--
----------

local list = { }

hub.setlistener("onBroadcast", {},
    function(user, adccmd, txt)
        local user_nick = user:nick()
        local user_level = user:level()
        local txt = string.lower(txt)
        local txt = echomsg[txt]
        if txt then
            if user_level >= minlevel then
                list[os.time()] = function()
                    hub.broadcast(txt..user_nick, hub.getbot())
                end
            end
        end
        return nil
    end
)

hub.setlistener("onTimer", {},
    function()
        for time, func in pairs(list) do
            if os.difftime(os.time() - time) >= delay then
                func()
                list[time] = nil
            end
        end
        return nil
    end
)

hub.debug("** Loaded "..scriptname..".lua **")

---------
--[END]--
---------
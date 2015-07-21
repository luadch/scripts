--[[

    etc_mainecho_0.1 by pulsar

        Version: Luadch 0.08
			- Das Script antwortet im Main auf gewisse Schlüsselwörter und um es
			  etwas realistischer wirken zu lassen sorgt ein kleiner Timer für ein Delay

]]--



--[SETTINGS]

local scriptname = "etc_mainecho"
local minlevel = 30  --> Wer bekommt ein Echo?
local delay = 4  --> Zeitverzögerung des Echos (in Sek.)

--> Antwort Echo auf Msg des Users
local echo1 = "Guten Morgen "
local echo2 = "Gute Nacht "
local echo3 = "Lass es dir schmecken "
local echo4 = "Hallo "
local echo5 = "Tja, wer weiss das schon so genau "

local echomsg = { --> Schlüsselwörter auf die ein Echo ausgelöst wird

["moin"] = echo1,
["Moin"] = echo1,
["MOIN"] = echo1,
["moin hub"] = echo1,
["morgen"] = echo1,
["Morgen"] = echo1,
["MOIN"] = echo1,
["moinmoin"] = echo1,
["MOINMOIN"] = echo1,
["moin moin"] = echo1,
["Moin moin"] = echo1,
["Moin Moin"] = echo1,
["MOIN MOIN"] = echo1,
["guten morgen"] = echo1,
["Guten morgen"] = echo1,
["Guten Morgen"] = echo1,
["GUTEN MORGEN"] = echo1,
["guten morgen hub"] = echo1,
["Guten morgen hub"] = echo1,
["Guten Morgen hub"] = echo1,
["Guten Morgen Hub"] = echo1,
["GUTEN MORGEN HUB"] = echo1,

["gn8"] = echo2,
["gn8 hub"] = echo2,
["n8"] = echo2,
["n8 hub"] = echo2,
["n8i"] = echo2,
["n8i hub"] = echo2,
["n8ti"] = echo2,
["gn8@all"] = echo2,
["nacht"] = echo2,
["Nacht"] = echo2,
["NACHT"] = echo2,
["nachti"] = echo2,
["Nachti"] = echo2,
["NACHTI"] = echo2,
["gute nacht"] = echo2,
["Gute nacht"] = echo2,
["Gute Nacht"] = echo2,
["GUTE NACHT"] = echo2,
["gute nacht hub"] = echo2,
["Gute nacht hub"] = echo2,
["Gute Nacht hub"] = echo2,
["Gute Nacht Hub"] = echo2,
["GUTE NACHT HUB"] = echo2,

["prost"] = echo3,
["Prost"] = echo3,
["PROST"] = echo3,
["kaffee"] = echo3,
["Kaffee"] = echo3,
["KAFFEE"] = echo3,
["bier"] = echo3,
["Bier"] = echo3,
["BIER"] = echo3,
["tee"] = echo3,
["Tee"] = echo3,
["TEE"] = echo3,
["kaba"] = echo3,
["Kaba"] = echo3,
["KABA"] = echo3,

["hi"] = echo4,
["Hi"] = echo4,
["HI"] = echo4,
["hallo"] = echo4,
["Hallo"] = echo4,
["HALLO"] = echo4,
["huhu"] = echo4,
["Huhu"] = echo4,
["HUHU"] = echo4,
["hi@all"] = echo4,
["servus"] = echo4,
["sers"] = echo4,
["hallöchen"] = echo4,
["hallöchen"] = echo4,
["re"] = echo4,
["Re"] = echo4,
["RE"] = echo4,

["ein op da"] = echo5,
["ein OP da"] = echo5,
["Ein op da"] = echo5,
["ein Op da"] = echo5,
["Ein Op da"] = echo5,
["Ein OP da"] = echo5,
["EIN OP DA"] = echo5,
["ein op da?"] = echo5,
["ein OP da?"] = echo5,
["Ein op da?"] = echo5,
["ein Op da?"] = echo5,
["Ein Op da?"] = echo5,
["Ein OP da?"] = echo5,
["EIN OP DA?"] = echo5,
["ein op da ?"] = echo5,
["ein OP da ?"] = echo5,
["Ein op da ?"] = echo5,
["ein Op da ?"] = echo5,
["Ein Op da ?"] = echo5,
["Ein OP da ?"] = echo5,
["EIN OP DA ?"] = echo5,
["ist ein op da"] = echo5,
["Ist ein op da"] = echo5,
["ist ein Op da"] = echo5,
["Ist ein Op da"] = echo5,
["ist ein OP da"] = echo5,
["Ist ein OP da"] = echo5,
["IST EIN OP DA"] = echo5,
["ist ein op da?"] = echo5,
["Ist ein op da?"] = echo5,
["ist ein Op da?"] = echo5,
["Ist ein Op da?"] = echo5,
["ist ein OP da?"] = echo5,
["Ist ein OP da?"] = echo5,
["IST EIN OP DA?"] = echo5,
["ist ein op da ?"] = echo5,
["Ist ein op da ?"] = echo5,
["ist ein Op da ?"] = echo5,
["Ist ein Op da ?"] = echo5,
["ist ein OP da ?"] = echo5,
["Ist ein OP da ?"] = echo5,
["IST EIN OP DA ?"] = echo5,
}


--[CODE]

local list = { }

hub.setlistener("onBroadcast", {},
    function(user, adccmd, txt)
        local txt = echomsg[txt]
        if txt then
            if user:level() >= minlevel then
                list[os.time()] = function()
                    local nick = user:nick()
                    hub.broadcast(txt..nick, hub.getbot())
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

--[END]
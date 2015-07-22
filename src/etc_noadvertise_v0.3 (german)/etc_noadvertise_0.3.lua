--[[

    etc_noadvertise_0.3 by pulsar

    
        Version: Luadch_0.08
        
        
        v0.1
        
            - Das Script überprüft den Main/PM auf die Eingabe verbotener Wörter

        v0.2
        
            - Hinzugefügt: Bot Tabelle um Bots zu ignorieren

        v0.3
        
            - Hinzugefügt: 'string.lower' Funktion, es muss nun in der'adverTable' & 'saveTable' nicht mehr auf
              Gross- Kleinschreibung geachtet werden
              

              
    (some code based on a script by NRJ 16/08/2006)
    
]]--


--------------
--[SETTINGS]--
--------------

--> Scriptname
local scriptname = "etc_noadvertise"

--> Bis zu welchem Level soll überprüft werden?
local maxlevel = 50
--> Ab welchem Level soll informiert werden?
local oplevel = 60

--> Infomeldung  an berechtigte User 1/3
local optext_prefix = " ADVERTISE_iNFO:  "
--> Infomeldung an berechtigte User 2/3
local optext_main = " sagte im Main:  "
--> Infomeldung an berechtigte User 2/3
local optext_pm1 = " sagte zu:  "
--> Infomeldung an berechtigte User 3/3
local optext_pm2 = "  folgendes:  "

--> Sollen die Bots ignoriert werden? (JA=true / NEIN=false)
local ignoreBots = true
--> Tabelle mit Bots die ignoriert werden
local botTable = {

	["[BOT]HubSecurity"] = 1,
	["[BOT]OpChat"] = 1,

}

--> Tabelle mit verbotenen Elementen
local adverTable = {

"dchub://",
"d c h u b://",
"adc://",
"a d c : / /",
"adcs://",
"a d c s : / /",
"icq",
"i c q",
"no-ip",
"n o - i p",
"no - ip",
"dyndns",
"d y n d n s",
"ath.cx",
"a t h . c x",

}

--> Tabelle mit erlaubten Elementen
local safeTable = {

"adc://192.168.0.1",
"adc://127.0.0.1",
"adc://yourhubaddy.ath.cx",
"adcs://192.168.0.1",
"adcs://127.0.0.1",
"adcs://yourhubaddy.ath.cx",

}

--> Warnmeldung
local text = [[ 


                                                 <ADVERTISE_DETECTION>

                            Warnung: Es ist hier untersagt Werbung zu versenden!
                                    
                                 PS: Solltest du keine Werbung versendet haben
                                                   (ein Bot ist nicht unfehlbar:)
                                     bitten wir darum diese Warnung zu ignorieren.


  ]]


----------
--[CODE]--
----------

local checkForAdvertising
checkForAdvertising = function(msg)
    for i = 1,table.getn(adverTable) do
        if string.find(msg , adverTable[i], 1, true) then
            return 1
        end
    end
end

local checkForSafe
checkForSafe = function(msg)
    for i = 1,table.getn(safeTable) do
        if string.find(msg , safeTable[i], 1, true) then
            return 1
        end
    end
end

hub.setlistener("onBroadcast", {},
    function(user, adccmd, msg)
        local user_nick = user:nick()
        local user_level = user:level()
        if user_level <= maxlevel then
            if msg then
                local msg = string.lower(msg)
                if checkForAdvertising(msg) then
                    if checkForSafe(msg) then
                        return nil
                    else
                        hub.broadcast(msg, user)
                        user:reply(text, hub.getbot())
                    end
                    for sid, user in pairs(hub.getusers()) do
                        local opuser = user:level()
                        if opuser >= oplevel then
                            user:reply(optext_prefix..user_nick..optext_main..msg, hub.getbot(), hub.getbot())
                        end
                    end
                    return PROCESSED
                end
            end
        end
        return nil
    end
)

hub.setlistener("onPrivateMessage", {},
    function(user, targetuser, adccmd, msg)
        local user_nick = user:nick()
        local user_level = user:level()
        local targetuser_level = targetuser:level()
        local targetuser_nick = targetuser:nick()
        if ignoreBots == true then
            if botTable[targetuser_nick] == nil then
                if user_level <= maxlevel then
                    if msg then
                        local msg = string.lower(msg)
                        if checkForAdvertising(msg) then
                            if checkForSafe(msg) or targetuser_level >= oplevel then
                                return nil
                            else
                                user:reply(msg, user, targetuser)
                                targetuser:reply(msg, user, user)
                                user:reply(text, hub.getbot(), targetuser)
                            end
                            for sid, user in pairs(hub.getusers()) do
                                local opuser = user:level()
                                if opuser >= oplevel then
                                    if targetuser_level < oplevel then
                                        user:reply(optext_prefix..user_nick..optext_pm1..targetuser_nick..optext_pm2..msg, hub.getbot(), hub.getbot())
                                    end
                                end
                            end
                            return PROCESSED
                        end
                    end
                end
                return nil
            end
        else
            if user_level <= maxlevel then
                if msg then
                    local msg = string.lower(msg)
                    if checkForAdvertising(msg) then
                        if checkForSafe(msg) or targetuser_level >= oplevel then
                            return nil
                        else
                            user:reply(msg, user, targetuser)
                            targetuser:reply(msg, user, user)
                            user:reply(text, hub.getbot(), targetuser)
                        end
                        for sid, user in pairs(hub.getusers()) do
                            local opuser = user:level()
                            if opuser >= oplevel then
                                if targetuser_level < oplevel then
                                    user:reply(optext_prefix..user_nick..optext_pm1..targetuser_nick..optext_pm2..msg, hub.getbot(), hub.getbot())
                                end
                            end
                        end
                        return PROCESSED
                    end
                end
            end
            return nil
        end
    end
)

hub.debug("** Loaded "..scriptname..".lua **")

---------
--[END]--
---------
--[[

    etc_noadvertise_0.4 by pulsar

    
        Version: Luadch_0.08
        
        
        v0.1
            - Das Script überprüft den Main/PM auf die Eingabe verbotener Wörter

        v0.2
            - Hinzugefügt: Bot Tabelle um Bots zu ignorieren

        v0.3
            - Hinzugefügt: 'string.lower' Funktion, es muss nun in der'adverTable' & 'saveTable' nicht mehr auf
              Gross- Kleinschreibung geachtet werden
              
        v0.4
            - Fix: 'string.lower' wird nun nur noch zum überprüfen benutzt, die Ausgabe bleibt wie sie war (Gross-/Kleinschreibung)
            - Hinzugefügt: Möglichkeit die Warnmeldung zu deaktivieren
            - Einige optische Änderungen im Code
            
              
    (some code based on a script by NRJ 16/08/2006)
    
]]--


--------------
--[SETTINGS]--
--------------

--> Scriptname
local scriptname = "etc_noadvertise"
local scriptversion = "0.4"

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

--> Soll dem User eine Warnmeldung gesendet werden? (JA=true / NEIN=false)
local warn_user = true

--> Warnmeldung
local warn_msg = [[ 


                        ==================================================
                                                 <ADVERTISE_DETECTION>

                            Warnung: Es ist hier untersagt Werbung zu versenden!
                                    
                                 PS: Solltest du keine Werbung versendet haben
                                                   (ein Bot ist nicht unfehlbar:)
                                     bitten wir darum diese Warnung zu ignorieren.
                        ==================================================


  ]]

--> Tabelle mit Bots/Chats die ignoriert werden
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


----------
--[CODE]--
----------

local hub_getbot = hub.getbot()
local hub_getusers = hub.getusers()
local checkForAdvertising
local checkForSafe

checkForAdvertising = function( msg2 )
    for i = 1, table.getn( adverTable ) do
        if string.find( msg2 , adverTable[ i ], 1, true ) then
            return 1
        end
    end
end

checkForSafe = function( msg2 )
    for i = 1, table.getn( safeTable ) do
        if string.find( msg2 , safeTable[ i ], 1, true ) then
            return 1
        end
    end
end

hub.setlistener( "onBroadcast", {},
    function( user, adccmd, msg )
        local user_nick = user:nick()
        local user_level = user:level()
        if user_level <= maxlevel then
            if msg then
                local msg2 = string.lower( msg )
                --> check MAIN
                if checkForAdvertising( msg2 ) then
                    if checkForSafe( msg2 ) then
                        return nil
                    else
                        hub.broadcast( msg, user )
                        if warn_user then
                            user:reply( warn_msg, hub_getbot )
                        end
                    end
                    for sid, user in pairs( hub_getusers ) do
                        local opuser = user:level()
                        if opuser >= oplevel then
                            user:reply( optext_prefix .. user_nick .. optext_main .. msg, hub_getbot, hub_getbot )
                        end
                    end
                    return PROCESSED
                end
            end
        end
        return nil
    end
)

hub.setlistener( "onPrivateMessage", {},
    function( user, targetuser, adccmd, msg )
        local user_nick = user:nick()
        local user_level = user:level()
        local targetuser_level = targetuser:level()
        local targetuser_nick = targetuser:nick()
        if ignoreBots == true then
            if botTable[ targetuser_nick ] == nil then
                if user_level <= maxlevel then
                    if msg then
                        local msg2 = string.lower( msg )
                        --> check PM
                        if checkForAdvertising( msg2 ) then
                            if checkForSafe( msg2 ) or targetuser_level >= oplevel then
                                return nil
                            else
                                user:reply( msg, user, targetuser )
                                targetuser:reply( msg, user, user )
                                if warn_user then
                                    user:reply( warn_msg, hub_getbot, targetuser )
                                end
                            end
                            for sid, user in pairs( hub_getusers ) do
                                local opuser = user:level()
                                if opuser >= oplevel then
                                    if targetuser_level < oplevel then
                                        user:reply( optext_prefix .. user_nick .. optext_pm1 .. targetuser_nick .. optext_pm2 .. msg, hub_getbot, hub_getbot )
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
                    local msg2 = string.lower( msg )
                    -- check PM
                    if checkForAdvertising( msg2 ) then
                        if checkForSafe( msg2 ) or targetuser_level >= oplevel then
                            return nil
                        else
                            user:reply( msg, user, targetuser )
                            targetuser:reply( msg, user, user )
                            if warn_user then
                                user:reply( warn_msg, hub_getbot, targetuser )
                            end
                        end
                        for sid, user in pairs( hub_getusers ) do
                            local opuser = user:level()
                            if opuser >= oplevel then
                                if targetuser_level < oplevel then
                                    user:reply( optext_prefix .. user_nick .. optext_pm1 .. targetuser_nick .. optext_pm2 .. msg, hub_getbot, hub_getbot )
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

hub.debug("** Loaded " .. scriptname .. " " .. scriptversion .. " **")

---------
--[END]--
---------
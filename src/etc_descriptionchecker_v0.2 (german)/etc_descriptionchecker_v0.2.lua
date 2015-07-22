--[[

    etc_descriptionchecker by pulsar (requested by VincentVega)

        Version: Luadch_0.08
        
        
        v0.1
        
            - Das Script überprüft beim Login die Description des Users auf verbotene Wörter/Werbung
            - Bei einem Treffer wird eine Nachricht an den User und an das Team abgegeben (optional)
            - Disconnect User (optional)


        v0.2
        
            - Hinzugefügt: 'string.lower' Funktion, es muss nun in der 'adverTable' & 'saveTable' nicht
              mehr auf Gross- und Kleinschreibung geachtet werden
            
            
    (some code based on a script by NRJ 16/08/2006)
    
]]--



--------------
--[SETTINGS]--
--------------

--> Scriptname
local scriptname = "etc_descriptionchecker"

--> Bis zu welchem Level soll überprüft werden?
local maxlevel = 50

--> Ab welchem Level soll informiert werden?
local teamlevel = 60


--> Tabelle mit verbotenen Elementen
local adverTable = {

"dchub:",
"adc:",
"adcs:",
"no-ip:",
"dyndns:",
"ath.cx:",

}

--> Tabelle mit erlaubten Elementen
local safeTable = {

"erlaubte Einträge",

}

--> User-Infomeldung 1/3
local usermsg_1 = "DESCRIPTION-CHECKER -> Deine 'Description' beinhaltet etwas, dass hier untersagt ist ->  "

--> User-Infomeldung 2/3
local usermsg_2 = " <- Bitte entfernen! "

--> User-Infomeldung 3/3
local usermsg_3 = " Du wirst nun disconnected!"

--> User disconnecten? (JA=true/NEIN=false)
local userdisc = false


--> Team-Infomeldung 1/3
local teammsg_1 = "DESCRIPTION-CHECKER -> "

--> Team-Infomeldung 2/3
local teammsg_2 = " / Description -> "

--> Team-Infomeldung 3/3
local teammsg_3 = " / Der User wurde disconnected."

--> Team-Infomeldung senden an? (main/pm)
local teammsg_who = "main"


----------
--[CODE]--
----------

hub.setlistener("onLogin", {},
    function(user)
        local user_nick = user:nick()
        local user_level = user:level()
        local user_description = hub.escapefrom(user:description())
        local hub_getbot = hub.getbot()
        local hub_getusers = hub.getusers()
        local checkForAdvertising = function()
            local user_description = string.lower(user_description)
            for i = 1,table.getn(adverTable) do
                if string.find(user_description, adverTable[i], 1, true) then
                    return 1
                end
            end
        end
        local checkForSafe = function()
            local user_description = string.lower(user_description)
            for i = 1,table.getn(safeTable) do
                if string.find(user_description, safeTable[i], 1, true) then
                    return 1
                end
            end
        end
        if user_level <= maxlevel then
            if checkForAdvertising(user_description) then
                if checkForSafe(user_description) then
                    return nil
                else
                    if userdisc == false then
                        user:reply(usermsg_1..user_description..usermsg_2, hub_getbot)
                        if teammsg_who == "main" then
                            for sid, user in pairs(hub_getusers) do
                                local teamuser = user:level()
                                if teamuser >= teamlevel then
                                    user:reply(teammsg_1..user_nick..teammsg_2..user_description, hub_getbot)
                                    return PROCESSED
                                end
                            end
                        elseif teammsg_who == "pm" then
                            for sid, user in pairs(hub_getusers) do
                                local teamuser = user:level()
                                if teamuser >= teamlevel then
                                    user:reply(teammsg_1..user_nick..teammsg_2..user_description, hub_getbot, hub_getbot)
                                    return PROCESSED
                                end
                            end
                        end
                    elseif userdisc == true then
                        user:reply(usermsg_1..user_description..usermsg_2..usermsg_3, hub_getbot)
                        user:kill("sorry")
                        if teammsg_who == "main" then
                            for sid, user in pairs(hub_getusers) do
                                local teamuser = user:level()
                                if teamuser >= teamlevel then
                                    user:reply(teammsg_1..user_nick..teammsg_2..user_description..teammsg_3, hub_getbot)
                                    return PROCESSED
                                end
                            end
                        elseif teammsg_who == "pm" then
                            for sid, user in pairs(hub_getusers) do
                                local teamuser = user:level()
                                if teamuser >= teamlevel then
                                    user:reply(teammsg_1..user_nick..teammsg_2..user_description..teammsg_3, hub_getbot, hub_getbot)
                                    return PROCESSED
                                end
                            end
                        end
                    end
                end
            end
        end
        return PROCESSED
    end
)

hub.debug("** Loaded "..scriptname..".lua **")

---------
--[END]--
---------

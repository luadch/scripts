--[[
    
        etc_openhubs_announcer.lua v0.2 by Motnahp
        
        - Script übersichtlicher + Editierbare teile eingefügt
        - Prüft nun nur noch die User die verbunden sind nach einer bestimmten Zeit und nicht mehr beim login.
            >> recheckdelay dafür editieren (2 Minuten voreingestellt)

            
       etc_openhubs_announcer.lua v0.1 by Motnahp
       
       - Prüft die User kurz nach dem Login auf öffentliche Hubs
            >> delaylogin dafür editieren (120 Sekunden voreingestellt)
       
]]--

--[[ Settings ]]--       

-- Nicht Editieren --
local scriptname = "etc_openhubs_announcer_v0.2"
local hub_bot = hub.getbot()
local min = 60
local start = os.time()
--funtions
local reportItTo
local check
-->> nachfolgende Settings sind editierbar -->>
local recheck = true -- sollen im Abstand von recheckdelay alle User geprüft werden? (true = Ja / false = Nein)
local maxchecklvl = 50 -- maximale Level bis zu dem geprüft werden soll (einschliesslich)
local reportlvl = 60 -- minimale Level zu dem gemeldet werden soll (einschliesslich)
local warnUser = false -- soll der User benachrichtigt/verwarnt werden, dass er OpenHubs offen hat? (true = Ja / false = Nein)
local sendMain = true -- soll im Mainchat an die OPs gemeldet werden? (true = Ja / false = Nein)
local sendPM = true -- soll per PM an die OPs gemeldet werden? (true = Ja / false = Nein)
local recheckdelay = 3 --> Zeitverzögerung des Checks (in Minuten)

-- Nachricht an den User
local badmsg = [[ 

        Du  bist laut deines Tags in einem Öffentlichen Hub,
        diese sind in unserem Hub nicht geduldet. Eine Nachricht 
        über dein Fehlverhalten wurde an alle OP's gesendet.
        
        Fall das nicht zutrifft melde dich bitte unverzüglich bei den OP's
        
        ]]
-- Nachricht an die OPs
local opmsg = "[[OPENHUBS]]--> Folgender User wurde als Benutzer eines öffentlichen Hubs registriert "
-- das Layout der Nachricht kann des weiteren in Zeile 81 verändert werden

--<< ende des editierbaren Teils --<<

recheckdelay = recheckdelay * min

--[[   Code   ]]--     

hub.setlistener("onTimer", {},
    function()
        if recheck and (os.difftime( os.time( ) - start ) >= recheckdelay) then
            for sid, user in pairs(hub.getusers()) do
                check(user)
            end
            start = os.time( )
        end
        return nil
    end
) 
 
function check(user)
    local hn, hr, ho = user:hubs()
    local open = hn or "unbekannt"
    local user_nick = user:nick()
    local user_level = user:level()
    local level = cfg.get("levels")[user_level] or "Unreg"
    local msg =""
    
    if user_level <= maxchecklvl then
        if (open > 0) or (open == "unbekannt") then         
            if warnUser then
                user:reply(badmsg, hub.getbot(), hub.getbot())
            end
            msg = msg..opmsg..user_nick.." mit Profil ["..level.."]" -- Zeile die für die OPs sichtbar ist
            reportItTo(reportlvl, msg)
        end
    end
end

function reportItTo(lvl, msg)
    for sid, user in pairs(hub.getusers()) do
        local targetuser = user:level()
        if targetuser >= lvl then
            if sendPM then
                user:reply(msg, hub_bot, hub_bot)
            end
            if sendMain then
                user:reply(msg, hub_bot)
            end
        end
    end
end

hub.debug( "** Loaded " .. scriptname .. ".lua **" )

--[[   End    ]]--       
--[[

    TagCheck 2.01 LUA 5.1x [Strict] [API 2]

    By Mutor    01/21/07

    Requested by miago

    Checks min/max slots and max hubs for specified reg prefix tags

    +Changes from 1.0   04/21/08
        ~ Converted to Lua 5.1x strict
        ~ Converted to API 2 strict
        + Added report missing slots or hubs in MyINFO

    +Changes from 2.0   09/05/08
        + Added option to check all online users on script start
        + Added full profile table
        + Added check to UserConnected,OpConnected,RegConnected arrivals
        ~ OpNick option, if OpNick = "" then message sent to OpChat]

    +Changes from 2.1
        ~ Converted to Luadch by ?  Date: ?

    +Changes from 2.2   08/14/2015 by Sopor
        + Multi3 (English, German and Swedish)

    +Changes from 2.3   09/20/2015 by pulsar
        + added new ban method (command import from cmd_ban.lua)
        + added report function to send reports to opchat/hubbot
        + added missing table lookups
        ~ changed some parts of code
        ~ removed unneeded parts of code

]]


local scriptname = "ptx_tagcheck"
local scriptversion = "2.3"

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_getbot = hub.getbot()
local hub_import = hub.import
local hub_debug = hub.debug
local hub_getusers = hub.getusers
local hub_escapeto = hub.escapeto
local hub_escapefrom = hub.escapefrom
local utf_format = utf.format

--// imports
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub_debug( err )
local ban = hub_import( "cmd_ban" )
local opchat = hub_import( "bot_opchat" )
local opchat_activate = cfg_get( "bot_opchat_activate" )

--// Script configuration
local tSettings = {}

tSettings.report = true  -- send report (boolean)
tSettings.report_opchat = true  -- send report to opchat (boolean)
tSettings.report_hubbot = false  -- send report to hubbot (boolean)
tSettings.llevel = 60  -- report minlevel (only for hubbot message) (integer)

tSettings.BanTime = 10  -- Time to ban the user, in minutes

tSettings.Profiles = {  -- Profile(s) to check

    [ 0 ] = true,    --"UNREG"
    [ 10 ] = true,   --"GUEST"
    [ 20 ] = true,   --"REG"
    [ 30 ] = true,  --"VIP"
    [ 40 ] = true,  --"SVIP"
    [ 50 ] = false,  --"SERVER"
    [ 55 ] = false,  --"SBOT"
    [ 60 ] = false,  --"OPERATOR"
    [ 70 ] = false,  --"SUPERVISOR"
    [ 80 ] = false,  --"ADMIN"
    [ 100 ] = false, --"HUBOWNER"
}

tSettings.Params = {  -- ["Tag"] = {minslots,maxslots,maxhubs}.

    ["[0.3]"] = {1,3,15},
    ["[0.5]"] = {1,3,15},
    ["[0.7]"] = {1,3,15},
    ["[0.8]"] = {1,3,15},
    ["[1.0]"] = {1,3,15},
    ["[1.5]"] = {1,3,15},
    ["[2.0]"] = {1,3,15},
    ["[2.5]"] = {1,3,15},
    ["[3.0]"] = {1,3,15},
    ["[4.0]"] = {1,3,15},
    ["[4.5]"] = {1,3,15},
    ["[5.0]"] = {1,3,15},
    ["[5.5]"] = {2,5,15},
    ["[6.0]"] = {2,5,15},
    ["[7.0]"] = {2,5,15},
    ["[8.0]"] = {2,5,15},
    ["[9.0]"] = {2,5,15},
    ["[10]"] = {2,5,15},
    ["[11]"] = {5,10,15},
    ["[12]"] = {5,10,15},
    ["[15]"] = {5,10,15},
    ["[20]"] = {5,10,15},
    ["[24]"] = {5,10,15},
    ["[25]"] = {5,10,15},
    ["[30]"] = {5,10,15},
    ["[40]"] = {5,10,15},
    ["[50]"] = {5,10,15},
    ["[60]"] = {5,10,15},
    ["[70]"] = {5,10,15},
    ["[75]"] = {5,10,15},
    ["[80]"] = {5,10,15},
    ["[100]"] = {5,10,15},
    ["[200]"] = {10,20,15},
    ["[250]"] = {10,20,15},
    ["[500]"] = {10,20,15},
    ["[1000]"] = {15,30,15},
}

--// msgs
local msg_too_many_slots = lang.msg_too_many_slots or "You have too many slots open. %s's are required to have a maximum of %s slots open. You have %s slots."
local msg_too_few_slots = lang.msg_too_few_slots or "You have too few slots open. %s's are required to have a minimum of %s slots open. You have only %s slots."
local msg_too_many_hubs = lang.msg_too_many_hubs or "You are in too many hubs. %s's are required to have a maximum of %s hub connections. You are connected to %s hubs."

local msg_ban = lang.msg_ban or "%s was kicked and banned by %s for %s minutes because: %s"

-- CODE

local send_report = function( msg, lvl )
    if tSettings.report then
        if tSettings.report_hubbot then
            for sid, user in pairs( hub_getusers() ) do
                local user_level = user:level()
                if user_level >= lvl then
                    user:reply( msg, hub_getbot, hub_getbot )
                end
            end
        end
        if tSettings.report_opchat then
            if opchat_activate then
                opchat.feed( msg )
            end
        end
    end
end

local OnError = function(msg)
    opchat.feed(msg)
end

local CheckUser = function(user)
    local Msg,Kick = "",false
    local j,p = user:level(),"Unregistered User"
    if j then p = cfg_get("levels")[j] or "LEVEL: "..tostring(j) end
    local _,_,tag = user:nick():find("^(%b[])[^ ]+")
    if tag then
        tag = tag:lower()
        if tSettings.Params[tag] then
            for i,v in ipairs(tSettings.Params[tag]) do
                local slots,hubs,reghubs,ophubs = user:slots( ),user:hubs( )
                if reghubs then
                    if not hubs then
                        hubs = reghubs
                    else
                        hubs = hubs + reghubs
                    end
                end
                if ophubs then
                    if not hubs then
                        hubs = ophubs
                    else
                        hubs = hubs + ophubs
                    end
                end
                if slots and hubs then
                    if i == 2 and slots > v then
                        Msg = utf_format(msg_too_many_slots, tag, v, slots)
                        Kick = true
                        break
                    elseif i == 1 and slots < v then
                        Msg = utf_format(msg_too_few_slots, tag, v, slots)
                        Kick = true
                        break
                    elseif i == 3 and hubs > v then
                        Msg = utf_format(msg_too_many_hubs, tag, v, hubs)
                        Kick = true
                        break
                    end
                else
                    if not slots then OnError(p.." "..user:nick().." bad MyINFO, missing a slots.") end
                    if not hubs then OnError(p.." "..user:nick().." bad MyINFO, missing a hubs.") end
                end
            end
        else
            OnError(p.." "..user:nick().." is using an invalid prefix tag.")
        end
    else
        --OnError(p.." "..user:nick().." is missing a prefix tag.")
    end
    if Kick then
        local bantime = tSettings.BanTime * 60
        local msg = utf_format( msg_ban, user:nick(), "-=TagCheck=-", tSettings.BanTime, Msg )
        ban.add( nil, user, bantime, Msg, "-=TagCheck=-" )
        send_report( msg, tSettings.llevel )
        return PROCESSED
    end
end

hub.setlistener( "onStart", { },
    function()
        for sid, user in pairs( hub.getusers( ) ) do
            if tSettings.Profiles[user:level()] then
                CheckUser(user)
            end
        end
    end
)
hub.setlistener( "onInf", { },
    function( user, cmd )
        if ( cmd:getnp "HN" or cmd:getnp "HR" or cmd:getnp "HO" or cmd:getnp "SL" ) and tSettings.Profiles[user:level()] then
            return CheckUser(user)
        end
        return nil
    end
)

hub.setlistener( "onLogin", { },
    function( user )
        if tSettings.Profiles[user:level()] then
            return CheckUser(user)
        end
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
--[[

    etc_mainecho.lua by pulsar

        v0.3:
            - cleaning code
            - add table lookups
            - add trigger echoes to table (as value)
            - at possibility to use own botname
            - translate the script to english
            - exclude trigger table to "scripts/data/etc_mainecho.tbl"

        v0.2:
            - added: 'string.lower' function

        v0.1:
            - its a trigger bot :)

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_mainecho"
local scriptversion = "0.3"

local permission = {  --// choose which levels can trigger the bot

    [ 0 ] = false,  -- unreg
    [ 10 ] = true,  -- guest
    [ 20 ] = true,  -- reg
    [ 30 ] = true,  -- vip
    [ 40 ] = true,  -- svip
    [ 50 ] = true,  -- server
    [ 60 ] = true,  -- operator
    [ 70 ] = true,  -- supervisor
    [ 80 ] = true,  -- admin
    [ 100 ] = true,  -- hubowner
}

local bot_name = "[BOT]Triggy"  --// without whitespaces!
local bot_desc = "[ BOT ] trigger me softly :)"
local use_own_bot = true  --// if false then the msg will be send from hubbot
local delay = 4  --// delay for trigger msg in seconds

local echo_file = "scripts/data/etc_mainecho.tbl"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local hub_getbot = hub.getbot
local hub_regbot = hub.regbot
local hub_isnickonline = hub.isnickonline
local hub_broadcast = hub.broadcast
local hub_debug = hub.debug
local os_time = os.time
local os_difftime = os.difftime
local utf_format = utf.format
local util_loadtable = util.loadtable

--// imports
local echo_tbl = util_loadtable( echo_file )


----------
--[CODE]--
----------

local reg_bot = function()
    local err, bot
    local nick, desc = bot_name, bot_desc
    bot, err = hub_regbot{ nick = nick, desc = desc, client = function( bot, cmd ) return true end }
end

if use_own_bot then reg_bot() end

local botname = function()
    local bot = hub_getbot()
    if use_own_bot then bot = hub_isnickonline( bot_name ) end
    return bot
end

local list = {}

hub.setlistener("onBroadcast", {},
    function( user, adccmd, txt )
        local user_nick = user:nick()
        local user_level = user:level()
        local trig
        if permission[ user_level ] then
            for k, v in pairs( echo_tbl ) do
                local s = txt:lower():find( k )
                if s then trig = echo_tbl[ k ] end
            end
            if trig then
                list[ os_time() ] = function()
                    local msg = utf_format( trig, user_nick )
                    hub_broadcast( msg, botname() )
                end
            end
        end
        return nil
    end
)

hub.setlistener("onTimer", {},
    function()
        for time, func in pairs( list ) do
            if os_difftime( os_time() - time ) >= delay then
                func()
                list[ time ] = nil
            end
        end
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
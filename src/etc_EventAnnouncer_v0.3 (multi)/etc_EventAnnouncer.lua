--[[

    etc_EventAnnouncer.lua by pulsar  / requested by Speedboat

        v0.3:
            - small improvements in epochTable()

        v0.2:
            - display announces sorted by the date of the next event  / requested by Kaas

        v0.1:
            - announces events and their remaining time to a predefined rotation time

]]


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_EventAnnouncer"
local scriptversion = "0.3"

--// Who receives the announces (true=YES/false=NO)
local permission = {

    [ 0 ] = false,  -- unreg
    [ 10 ] = true,  -- guest
    [ 20 ] = true,  -- reg
    [ 30 ] = true,  -- vip
    [ 40 ] = true,  -- svip
    [ 50 ] = true,  -- server
    [ 55 ] = false,  -- sbot
    [ 60 ] = true,  -- operator
    [ 70 ] = true,  -- supervisor
    [ 80 ] = true,  -- admin
    [ 100 ] = true,  -- hubowner
}

--// rotation time of the announces (hours)
local rotation = 12

--// announce destination
local dest_main = true
local dest_pm = false

--// announces
local announces = {

 -- [ "month|day" ] = "announce msg",

    [ "12|24" ] = "Christmas",
    [ "01|01" ] = "New Year",

}


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_getbot = hub.getbot()
local hub_getusers = hub.getusers
local hub_debug = hub.debug
local util_formatseconds = util.formatseconds
local utf_format = utf.format
local os_time = os.time
local os_difftime = os.difftime
local os_date = os.date
local table_insert = table.insert
local table_sort = table.sort

--// imports
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )

--// msgs
local msg_years = lang.msg_years or " years, "
local msg_days = lang.msg_days or " days, "
local msg_hours = lang.msg_hours or " hours, "
local msg_minutes = lang.msg_minutes or " minutes, "
local msg_seconds = lang.msg_seconds or " seconds"
local msg_line = lang.msg_line or "\n\t%s:\n\t%s\n"
local msg_out = lang.msg_out or [[


=== Event Announcer ====================================

        Time remaining until:
%s
==================================== Event Announcer ===
  ]]


----------
--[CODE]--
----------

local delay = rotation * 60 * 60
local start = os_time()

local genOrderedIndex = function( t )
    local orderedIndex = {}
    for key in pairs( t ) do table_insert( orderedIndex, key ) end
    table_sort( orderedIndex )
    return orderedIndex
end

local orderedNext = function( t, state )
    local key = nil
    if state == nil then
        t.orderedIndex = genOrderedIndex( t )
        key = t.orderedIndex[ 1 ]
    else
        for i = 1, #t.orderedIndex do
            if t.orderedIndex[ i ] == state then key = t.orderedIndex[ i + 1 ] end
        end
    end
    if key then return key, t[ key ] end
    t.orderedIndex = nil
    return
end

local orderedPairs = function( t )
    return orderedNext, t, nil
end

local epochTable = function()
    local t = {}
    for k, v in pairs( announces ) do
        local dest_m, dest_d = k:match( "^(%d*)|(%d*)" )
        if dest_m and dest_d then
            dest_m, dest_d = tonumber( dest_m ), tonumber( dest_d )
            local cur_year, cur_month, cur_day = tonumber( os_date( "%Y" ) ), tonumber( os_date( "%m" ) ), tonumber( os_date( "%d" ) )
            if ( dest_m < cur_month ) or ( ( dest_m == cur_month ) and ( dest_d < cur_day ) ) then
                cur_year = cur_year + 1
            end
            local epoch_time = os_time{ year=cur_year, month=dest_m, day=dest_d }
            if epoch_time then t[ epoch_time ] = v end
        end
    end
    return t
end

local makeAnnounces = function()
    local msg = ""
    for k, v in orderedPairs( epochTable() ) do
        local d, h, m, s = util_formatseconds( os_difftime( tonumber( k ) - os_time() ) )
        msg = msg .. utf_format( msg_line, v, d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds )
    end
    return msg
end

local check = function()
    local msg = utf_format( msg_out, makeAnnounces() )
    for sid, user in pairs( hub_getusers() ) do
        if not user:isbot() then
            if permission[ user:level() ] then
                if dest_main then user:reply( msg, hub_getbot ) end
                if dest_pm then user:reply( msg, hub_getbot, hub_getbot ) end
            end
        end
    end
end

hub.setlistener( "onTimer", { },
    function()
        if os_difftime( os_time() - start ) >= delay then
            check()
            start = os_time()
        end
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " ".. scriptversion .. ".lua **" )
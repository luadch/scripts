--[[

    etc_messenger.lua by pulsar (requested by GoLLuM)

        v0.4:
            by blastbeat:
                - translated into english
                - fixed timer method
            by pulsar:
                - improved send method
                    - possibility to choose destination for each message
                    - possibility to send message on login

        v0.3:
            - bugfix: hub.broadcast
            - code cleaning
            - using timer instead of on login

        v0.2:
            added: possibility to send message to MAIN and PM

        v0.1:
            - send a message on login

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_messenger"
local scriptversion = "0.4"

--// Wich level receives the Topic message? (true=YES/false=NO)
local sendto = {

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

--// What topics should be posted: time [hh:mm]
local message = {}

message[ "06:00" ] = {}
message[ "06:00" ][ "send_on_login" ] = false
message[ "06:00" ][ "send_main" ] = true
message[ "06:00" ][ "send_pm" ] = true
message[ "06:00" ][ "msg" ] = [[


        add here your message
    ]]

message[ "12:30" ] = {}
message[ "12:30" ][ "send_on_login" ] = false
message[ "12:30" ][ "send_main" ] = true
message[ "12:30" ][ "send_pm" ] = true
message[ "12:30" ][ "msg" ] = [[


        add here your message
    ]]

message[ "18:00" ] = {}
message[ "18:00" ][ "send_on_login" ] = false
message[ "18:00" ][ "send_main" ] = true
message[ "18:00" ][ "send_pm" ] = true
message[ "18:00" ][ "msg" ] = [[


        add here your message
    ]]

message[ "21:00" ] = {}
message[ "21:00" ][ "send_on_login" ] = false
message[ "21:00" ][ "send_main" ] = true
message[ "21:00" ][ "send_pm" ] = true
message[ "21:00" ][ "msg" ] = [[


        add here your message
    ]]


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local hub_getbot = hub.getbot()
local hub_getusers = hub.getusers
local hub_debug = hub.debug
local os_time = os.time
local os_date = os.date
local os_difftime = os.difftime


----------
--[CODE]--
----------

local delay = 30  -- In seconds
local start = os_time()
local last_time

local time = function()
    if ( os_date( "%H:%M" ) == last_time ) then
        return false
    else
        last_time = os_date( "%H:%M" )
        return last_time
    end
end

hub.setlistener( "onTimer", {},
    function( )
        if os_difftime( os_time() - start ) >= delay then
            local is_time = message[ time() ]
            if is_time then
                local send_main = message[ os_date( "%H:%M" ) ][ "send_main" ]
                local send_pm = message[ os_date( "%H:%M" ) ][ "send_pm" ]
                local msg = message[ os_date( "%H:%M" ) ][ "msg" ]
                for sid, user in pairs( hub_getusers() ) do
                    if not user:isbot() then
                        if sendto[ user:level() ] then
                            if send_main then
                                user:reply( msg, hub_getbot )
                            end
                            if send_pm then
                                user:reply( msg, hub_getbot, hub_getbot )
                            end
                        end
                    end
                end
            end
            start = os_time()
        end
        return nil
    end
)

hub.setlistener( "onLogin", {},
    function( user )
        local user_level = user:level()
        if sendto[ user_level ] then
            for k, v in pairs( message ) do
                local on_login = v[ "send_on_login" ]
                local send_main = v[ "send_main" ]
                local send_pm = v[ "send_pm" ]
                local msg = v[ "msg" ]
                if on_login then
                    if send_main then user:reply( msg, hub_getbot ) end
                    if send_pm then user:reply( msg, hub_getbot, hub_getbot ) end
                end
            end
            return PROCESSED
        end
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " ".. scriptversion .. ".lua **" )
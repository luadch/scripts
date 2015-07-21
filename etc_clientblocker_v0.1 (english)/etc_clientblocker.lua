--[[

	etc_clientblocker.lua by pulsar

        v0.1:
            - blocks clients
        
]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_clientblocker"
local scriptversion = "0.1"

local check_level = {

		[ 0 ] = true,  --> UNREG
		[ 10 ] = true,  --> GUEST
		[ 20 ] = true,  --> REG
		[ 30 ] = true,  --> VIP
		[ 40 ] = true,  --> SVIP
		[ 50 ] = true,  --> SERVER
		[ 60 ] = false,  --> OPERATOR
		[ 70 ] = false,  --> SUPERVISOR
		[ 80 ] = false,  --> ADMIN
		[ 100 ] = true,  --> HUBOWNER

}

local client_tbl = {
    
    [ "0.7" ] = "Your Client ist not allowed",  -- searching for all clients that includes "0.7" (all dc++ 0.7xx clients)
    [ "0.8" ] = "Your Client ist not allowed",  -- searching for all clients that includes "0.8" (all dc++ 0.8xx clients)
    [ "AirDC%+%+%s2" ] = "Your Client ist not allowed",  -- searching for all AirDC++ 2.xx
    [ "AirDC%+%+%s2.9" ] = "Your Client ist not allowed",  -- searching for all AirDC++ 2.9x
    [ "AirDC%+%+%s3" ] = "Your Client ist not allowed",  -- searching for all AirDC++ 3.xx
    [ "AirDC%+%+%s3.0" ] = "Your Client ist not allowed",  -- searching for all AirDC++ 3.0x
}


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local hub_escapefrom = hub.escapefrom
local hub_escapeto = hub.escapeto
local hub_debug = hub.debug


----------
--[CODE]--
----------

local check_clients = function( user )
    local user_level = user:level()
    if check_level[ user_level ] then
        local user_client = hub_escapefrom( user:version() )
        for k, v in pairs( client_tbl ) do
            if user_client:find( k ) then
                user:kill( "ISTA 231 " .. hub_escapeto( v ) .. " TL-1 \n" )
                return PROCESSED
            end
        end
    end
end

hub.setlistener( "onConnect", {}, check_clients )

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
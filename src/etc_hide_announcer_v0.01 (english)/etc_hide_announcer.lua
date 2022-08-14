--[[

    etc_hide_announcer.lua by pulsar

        based on etc_hide_opchat.lua by blastbeat

        v0.01:
            - requested by Sopor

]]--

local scriptname = "etc_hide_announcer"
local scriptversion = "0.01"

local nickname = "[SBOT]Announcer" -- registered announcer nick with nicktag (if nicktags are active)

--// hide nickname for these levels
local blind_levels = {

    [ 0 ] = true,  -- unreg
    [ 10 ] = true,  -- guest
    [ 20 ] = true,  -- reg
    [ 30 ] = true,  -- vip
    [ 40 ] = true,  -- svip
    [ 50 ] = true,  -- server
    [ 55 ] = true,  -- sbot
    [ 60 ] = true,  -- operator
    [ 70 ] = true,  -- supervisor
    [ 80 ] = true,  -- admin
    [ 100 ] = true,  -- hubowner
}

hub.setlistener( "onLogin", {},
    function( user )
        if user:nick() == nickname then
            local target = hub.isnickonline( nickname )
            if target then
                for sid, user in pairs( hub.getusers() ) do
                    if not user:isbot() and blind_levels[ user:level() ] then
                        user:send( "IQUI " .. target:sid() .. "\n")
                    end
                end
            end
            return nil
        end
        local target = hub.isnickonline( nickname )
        if target and blind_levels[ user:level() ] then
           user:send( "IQUI " .. target:sid() .. "\n")
        end
        return nil
    end
)

hub.setlistener( "onStart", {},
    function()
        local target = hub.isnickonline( nickname )
        if target then
            for sid, user in pairs( hub.getusers() ) do
                if not user:isbot() and blind_levels[ user:level() ] then
                    user:send( "IQUI " .. target:sid() .. "\n")
                end
            end
        end
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
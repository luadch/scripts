--[[

    usr_speedinfo.lua by blastbeat

    - Usage:   [+!#]csi add <SID> <connection speed info about user> / [+!#]csi del <SID>
    - Example: +csi add ABED 100/10
    - Minimum permission: Default is 100.
    - Above command will permanently change the email of the user to the given connection speed info.
    - Instead of the Email, one can use any other field of the INF. This is controlled by the variable "field".

    v0.02: by pulsar
        - added own script database
        - added del command to remove speedinfo

]]--

local scriptname = "usr_speedinfo"
local scriptversion = "0.02"

local path = "scripts/data/usr_speedinfo.tbl"
local user_tbl = util.loadtable( path ) or {}

local minlevel = 100
local field = "EM"

local cmd = "csi"
local param_add = "add"
local param_del = "del"

local ucmd_menu_ct2_add = { "Change", "Speed Info", "add" }
local ucmd_menu_ct2_del = { "Change", "Speed Info", "del" }
local ucmd_line = "New Speed:"

local msg_denied = "You are not allowed to use this command."
local msg_fail = "User not found."
local msg_add = "Entry changed."
local msg_del = "Entry removed."
local msg_usage = "[+!#]csi add <SID> <connection speed info about user> / [+!#]csi del <SID>"

local onbmsg = function( user, command, parameters )
    if user:level( ) < minlevel then
        user:reply( msg_denied, hub.getbot( ) )
        return PROCESSED
    end
    local param, sid, speed = utf.match( parameters, "^(%S+) (%S+) ?(.*)" )
    local target = hub.issidonline( sid )
    if not target then
        user:reply( msg_fail, hub.getbot( ) )
        return PROCESSED
    end
    if param == param_add then
        hub.sendtoall( "BINF " .. sid .. " " .. field .. hub.escapeto( speed ) .. "\n" )
        if target:isregged( ) then
            ---target:profile( ).speedinfo = speed
            ---local regs = hub.getregusers( )
            ---cfg.saveusers( regs )
            user_tbl[ target:firstnick() ] = speed
            util.savetable( user_tbl, "user_tbl", path )
        end
        user:reply( msg_add, hub.getbot( ) )
        return PROCESSED
    end
    if param == param_del then
        if type( user_tbl[ target:firstnick() ] ) ~= "nil" then
            user_tbl[ target:firstnick() ] = nil
            util.savetable( user_tbl, "user_tbl", path )
            local inf = target:inf( )
            inf:setnp( field, "" )
            hub.sendtoall( "BINF " .. sid .. " " .. field .. hub.escapeto( "" ) .. "\n" )
            user:reply( msg_del, hub.getbot( ) )
            return PROCESSED
        else
            user:reply( msg_fail, hub.getbot( ) )
            return PROCESSED
        end
    end
    user:reply( msg_usage, hub.getbot( ) )
    return PROCESSED
end

local hook_1 = function( user )
    if user:isregged( ) then
        local inf = user:inf( )
        local value = inf:getnp( field )
        local speed = user_tbl[ user:firstnick() ] or value or ""
        inf:setnp( field, speed )
    end
    return nil
end

local hook_2 = function( user, cmd )
    local value = cmd:getnp( field )
    if value then
        if user:isregged( ) then
            local speed = user_tbl[ user:firstnick() ] or value
            cmd:setnp( field, speed )
        end
    end
    return nil
end

hub.setlistener( "onConnect", { }, hook_1 )
hub.setlistener( "onInf", { }, hook_2 )
hub.setlistener( "onStart", { },
    function( )
        local ucmd = hub.import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_ct2_add, cmd, { param_add, "%[userSID]", "%[line:" .. ucmd_line .. "]" }, { "CT2" }, minlevel )
            ucmd.add( ucmd_menu_ct2_del, cmd, { param_del, "%[userSID]" }, { "CT2" }, minlevel )
        end
        local hubcmd = hub.import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)


hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
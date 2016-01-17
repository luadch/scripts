--[[

    etc_NewPasswords.lua by pulsar  / requested by Sopor

        v0.1:
            - generate a new password for the user on login
                - send msg
                - send op report
                - disconnect after msg
]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_NewPasswords"
local scriptversion = "0.1"

local cmd = "newpw"
local cmd_p_true = "true"
local cmd_p_false = "false"

--// levels to check
local levels = {

    [ 10 ] = true,  -- guest
    [ 20 ] = true,  -- reg
    [ 30 ] = true,  -- vip
    [ 40 ] = true,  -- svip
    [ 50 ] = true,  -- server
    [ 55 ] = true,  -- sbot
    [ 60 ] = false,  -- operator
    [ 70 ] = false,  -- supervisor
    [ 80 ] = false,  -- admin
    [ 100 ] = false,  -- hubowner
}

--// send target msg to main?
local target_msg_main = true
--// send target msg to pm?
local target_msg_pm = true

--// send op report msg?
local report_activate = true
--// send report to hubbot?
local report_hubbot = false
--// send report to opchat?
local report_opchat = true
--// report level (for hubbot report)
local llevel = 60


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local hub_debug = hub.debug
local hub_import = hub.import
local hub_getbot = hub.getbot()
local hub_reloadusers = hub.reloadusers
local hub_escapeto = hub.escapeto
local utf_format = utf.format
local utf_match = utf.match
local util_loadtable = util.loadtable
local util_savetable = util.savetable
local util_savearray = util.savearray
local util_generatepass = util.generatepass
local util_getlowestlevel = util.getlowestlevel

--// imports
local target_db = "scripts/data/etc_NewPasswords.tbl"
local user_db = "cfg/user.tbl"
local user_tbl, target_tbl
local report = hub_import( "etc_report" )

--// msgs
local help_title = "etc_NewPasswords.lua"
local help_usage = "[+!#]newpw true|false"
local help_desc = "Generate a new password for the user on login"
local msg_denied = "You are not allowed to use this command."
local msg_usage = "Usage: [+!#]newpw true|false"
local msg_report = "The following user got a new password and was disconnected now: %s"
local msg_target = [[


=== NEW PASSWORD FOR YOU =====================================

     Hello %s, you got a new password, use it  to login now!!!
     Your new password is:  %s

     You will be disconnect now.

===================================== NEW PASSWORD FOR YOU ===
  ]]

local msg_disconnect = "You were disconnected because of new password. Add new password to your favs and login again."

local msg_users_true = [[


=== NEW PASSWORDS =====================================

Users with changed passwords:

%s
===================================== NEW PASSWORDS ===
  ]]

local msg_users_false = [[


=== NEW PASSWORDS =====================================

Users with not changed passwords:

%s
===================================== NEW PASSWORDS ===
  ]]

local ucmd_menu_ct1 = { "Hub", "etc", "NewPasswords", "show users with new passwords" }
local ucmd_menu_ct2 = { "Hub", "etc", "NewPasswords", "show users with old passwords" }


----------
--[CODE]--
----------

local minlevel = util_getlowestlevel( levels )

--// if user logs in
hub.setlistener( "onLogin", {},
    function( target )
        local target_level = target:level()
        local target_nick = target:nick()
        local target_firstnick = target:firstnick()
        if levels[ target_level ] and not target_tbl[ target_firstnick ] then
            user_tbl = util_loadtable( user_db )
            local new_pw = util_generatepass()
            for k, v in pairs( user_tbl ) do
                if not user_tbl[ k ].is_bot then
                    if user_tbl[ k ].nick == target_firstnick then
                        target_tbl[ target_firstnick ] = true
                        user_tbl[ k ].password = new_pw
                        util_savetable( target_tbl, "target_tbl", target_db )
                        util_savearray( user_tbl, user_db )
                        hub_reloadusers()
                        --// send target msg
                        local target_msg = utf_format( msg_target, target_firstnick, new_pw )
                        if target_msg_main then target:reply( target_msg, hub_getbot ) end
                        if target_msg_pm then target:reply( target_msg, hub_getbot, hub_getbot ) end
                        --// disconnect target
                        target:kill( "ISTA 230 " .. hub_escapeto( msg_disconnect ) .. "\n" )
                        --// send report msg
                        local report_msg = utf_format( msg_report, target_nick )
                        report.send( report_activate, report_hubbot, report_opchat, llevel, report_msg )
                        return PROCESSED
                    end
                end
            end
        end
        return nil
    end
)

local onbmsg = function( user, command, parameters )
    local user_level = user:level()
    local msg = ""
    target_tbl = util_loadtable( target_db )
    if user_level < minlevel then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end
    local param = utf_match( parameters, "^(%S+)$" )
    if param == cmd_p_true then
        for k, v in pairs( target_tbl ) do if v then msg = msg .. "\t" .. k .. "\n" end end
        local msg_out = utf_format( msg_users_true, msg )
        user:reply( msg_out, hub_getbot )
        return PROCESSED
    end
    if param == cmd_p_false then
        for k, v in pairs( target_tbl ) do if not v then msg = msg .. "\t" .. k .. "\n" end end
        local msg_out = utf_format( msg_users_false, msg )
        user:reply( msg_out, hub_getbot )
        return PROCESSED
    end
    user:reply( msg_usage, hub_getbot )
    return PROCESSED
end

--// script start
hub.setlistener( "onStart", {},
    function()
        --// iterate user.tbl and add user to script db if not exists
        user_tbl = util_loadtable( user_db )
        target_tbl = util_loadtable( target_db )
        for k, v in pairs( user_tbl ) do
            if not user_tbl[ k ].is_bot then
                local user_firstnick = user_tbl[ k ].nick
                local user_level = tonumber( user_tbl[ k ].level )
                if levels[ user_level ] then
                    if type( target_tbl[ user_firstnick ] ) == "nil" then
                        target_tbl[ user_firstnick ] = false
                    end
                end
            end
        end
        util_savetable( target_tbl, "target_tbl", target_db )
        local help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        local ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_ct1, cmd, { cmd_p_true }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct2, cmd, { cmd_p_false }, { "CT1" }, minlevel )
        end
        local hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
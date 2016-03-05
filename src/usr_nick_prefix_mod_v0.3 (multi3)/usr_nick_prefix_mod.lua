--[[

    usr_nick_prefix_mod.lua by pulsar  / Idea by Sopor

        based on the script "usr_nick_prefix.lua" by blastbeat

        - this script adds a prefix to the nick of a user
        - this mod adds the prefixes user specified

        Usage: [+!#]nickprefix add <NICK> <PREFIX>  /  [+!#]nickprefix del <NICK>
        
        Note: This script only works if the default "usr_nick_prefix.lua" is disabled in cfg.tbl,
              therefore you need to set: usr_nick_prefix_activate = false,

        v0.3: by Jerker
           - updates CurrentNick in etc_onlinecounter //requested by Sopor

        v0.2: by Sopor
           - added language files
           - typo fix

        v0.1:
            - add rightclick to add/remove a prefix to/from a user
            - add help feature

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "usr_nick_prefix_mod"
local scriptversion = "0.3"

local cmd = "nickprefix"
local cmd_a = "add"
local cmd_d = "del"

local prefix_file = "scripts/data/usr_nick_prefix_mod.tbl"

local permission = {  -- min level to use this cmd

    -- [ user_level ] = level   means 'user_level' can add/remove prefixes from users with 'level' max

    [ 0 ] = 0,  -- unreg
    [ 10 ] = 0,  -- guest
    [ 20 ] = 0,  -- reg
    [ 30 ] = 0,  -- vip
    [ 40 ] = 0,  -- svip
    [ 50 ] = 0,  -- server
    [ 55 ] = 0,  -- sbot
    [ 60 ] = 50,  -- operator
    [ 70 ] = 60,  -- supervisor
    [ 80 ] = 70,  -- admin
    [ 100 ] = 100,  -- hubowner
}

local forbidden_chars = {  -- forbidden nick prefix characters

    "|", "/", "\\",

}

local report = true  -- send report
local report_opchat = true  -- send report to opchat
local report_hubbot = false  -- send report to hubbot
local llevel = 60  -- report minlevel (only for hubbot message)


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local hub_getbot = hub.getbot()
local hub_debug = hub.debug
local hub_import = hub.import
local hub_getusers = hub.getusers
local hub_escapeto = hub.escapeto
local hub_isnickonline = hub.isnickonline
local utf_len = utf.len
local utf_sub = utf.sub
local utf_match = utf.match
local utf_format = utf.format
local util_loadtable = util.loadtable
local util_savetable = util.savetable
local util_getlowestlevel = util.getlowestlevel

--// imports
local prefix_tbl
local prefix_activate = cfg_get( "usr_nick_prefix_activate" )
local opchat = hub_import( "bot_opchat" )
local opchat_activate = cfg_get( "bot_opchat_activate" )

--// msgs
local scriptlang = cfg_get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )

local help_title = lang.help_title or "usr_nick_prefix_mod.lua"
local help_usage = lang.help_usage or "[+!#]nickprefix add <NICK> <PREFIX>  /  [+!#]nickprefix del <NICK>"
local help_desc = lang.help_desc or "This script adds a prefix to the nick of a user"

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_god = lang.msg_god or "You are not allowed to add/change the nick prefix of this user."
local msg_isbot = lang.msg_isbot or "User is a bot."
local msg_notonline = lang.msg_notonline or "User is offline."
local msg_notfound = lang.msg_notfound or "No prefix found."
local msg_forbidden = lang.msg_forbidden or "The prefix includes forbidden characters or whitespaces."
local msg_usage = lang.msg_usage or "Usage: [+!#]nickprefix add <NICK> <PREFIX>  /  [+!#]nickprefix del <NICK>"

local msg_prefix_add = lang.msg_prefix_add or "%s  added the nick prefix on user: %s  prefix: %s"
local msg_prefix_change = lang.msg_prefix_change or "%s  changed the nick prefix on user: %s  new prefix: %s"
local msg_prefix_remove = lang.msg_prefix_remove or "%s  removed the nick prefix on user: %s"

local ucmd_menu_ct2_1 = lang.ucmd_menu_ct2_1 or { "Nick Prefix", "add//change" }
local ucmd_menu_ct2_2 = lang.ucmd_menu_ct2_2 or { "Nick Prefix", "remove" }
local ucmd_prefix = lang.ucmd_prefix or "New nick prefix:"

--// functions
local onbmsg
local is_online
local check_prefix
local send_report


----------
--[CODE]--
----------

local oplevel = util_getlowestlevel( permission )

--// update onlinecounter db
local updateOnlinecounter = function( firstnick, newnick )
    local onlinecounter = hub.import "etc_onlinecounter"
	if onlinecounter then
        local tNick = onlinecounter.tOnlineCounter[ firstnick ]
		if tNick then
		    tNick.CurrentNick = newnick
		end
	end
end

--// check if target user is online
is_online = function( target )
    local target = hub_isnickonline( target )
    if target then
        if target:isbot() then
            return "bot"
        else
            return target, target:firstnick(), target:nick(), target:level()
        end
    end
    return nil
end

--// check if prefix includes forbidden chars or whitespaces
check_prefix = function( prefix )
    if prefix:find( " " ) then return true end
    for k, v in pairs( forbidden_chars ) do
        if prefix:find( v ) then return true end
    end
    return false
end

--// report
send_report = function( msg, minlevel )
    if report then
        if report_hubbot then
            for sid, user in pairs( hub_getusers() ) do
                local user_level = user:level()
                if user_level >= minlevel then
                    user:reply( msg, hub_getbot, hub_getbot )
                end
            end
        end
        if report_opchat then
            if opchat_activate then
                opchat.feed( msg )
            end
        end
    end
end

if not prefix_activate then
    onbmsg = function( user, command, parameters )
        local user_nick = user:nick()
        local user_level = user:level()
        local target_firstnick, target_nick, target_level
        local p1, p2, p3 = utf_match( parameters, "^(%S+) (%S+) (%S+)" )
        local p4, p5 = utf_match( parameters, "^(%S+) (%S+)" )
        if user_level < oplevel then
            user:reply( msg_denied, hub_getbot )
            return PROCESSED
        end
        --// [+!#]nickprefix add <NICK> <PREFIX>
        if ( ( p1 == cmd_a ) and p2 and p3 ) then
            local target, target_firstnick, target_nick, target_level = is_online( p2 )
            if target then
                if target ~= "bot" then
                    if ( ( permission[ user_level ] or 0 ) < target_level ) then
                        user:reply( msg_god, hub_getbot )
                        return PROCESSED
                    end
                    if check_prefix( p3 ) then
                        user:reply( msg_forbidden, hub_getbot )
                        return PROCESSED
                    end
                    prefix_tbl = util_loadtable( prefix_file )
                    local msg
                    if prefix_tbl[ target_firstnick ] then
                        msg = utf_format( msg_prefix_change, user_nick, target_nick, p3 )
                    else
                        msg = utf_format( msg_prefix_add, user_nick, target_nick, p3 )
                    end
                    prefix_tbl[ target_firstnick ] = p3
                    util_savetable( prefix_tbl, "prefix_tbl", prefix_file )
                    local prefix = hub_escapeto( prefix_tbl[ target_firstnick ] )
                    target:updatenick( prefix .. target_firstnick )
					updateOnlinecounter(target_firstnick, p3..target_firstnick)
                    user:reply( msg, hub_getbot )
                    send_report( msg, llevel )
                    return PROCESSED
                else
                    user:reply( msg_isbot, hub_getbot )
                    return PROCESSED
                end
            else
                user:reply( msg_notonline, hub_getbot )
                return PROCESSED
            end
        end
        --// [+!#]nickprefix del <NICK>
        if ( ( p4 == cmd_d ) and p5 ) then
            local target, target_firstnick, target_nick, target_level = is_online( p5 )
            if target then
                prefix_tbl = util_loadtable( prefix_file )
                local found = false
                for k, v in pairs( prefix_tbl ) do
                    if k == target_firstnick then
                        prefix_tbl[ k ] = nil
                        found = true
                        break
                    end
                end
                if found then
                    util_savetable( prefix_tbl, "prefix_tbl", prefix_file )
                    target:updatenick( target_firstnick, false, true )
					updateOnlinecounter(target_firstnick, target_firstnick)
                    local msg = utf_format( msg_prefix_remove, user_nick, target_nick )
                    user:reply( msg, hub_getbot )
                    send_report( msg, llevel )
                    return PROCESSED
                else
                    user:reply( msg_notfound, hub_getbot )
                    return PROCESSED
                end
            else
                user:reply( msg_notonline, hub_getbot )
                return PROCESSED
            end
        end
        user:reply( msg_usage, hub_getbot )
        return PROCESSED
    end
    --// script start
    hub.setlistener( "onStart", {},
        function()
            prefix_tbl = util_loadtable( prefix_file )
            --// help, ucmd, hucmd
            local help = hub_import( "cmd_help" )
            if help then
                help.reg( help_title, help_usage, help_desc, oplevel )
            end
            local ucmd = hub_import( "etc_usercommands" )
            if ucmd then
                ucmd.add( ucmd_menu_ct2_1, cmd, { cmd_a, "%[userNI]", "%[line:" .. ucmd_prefix .. "]" }, { "CT2" }, oplevel )
                ucmd.add( ucmd_menu_ct2_2, cmd, { cmd_d, "%[userNI]" }, { "CT2" }, oplevel )
            end
            local hubcmd = hub_import( "etc_hubcommands" )
            assert( hubcmd )
            assert( hubcmd.add( cmd, onbmsg ) )
            return nil
        end
    )
    hub.setlistener( "onStart", { },  -- add prefix to already connected users
        function( )
            for sid, user in pairs( hub_getusers() ) do
                if prefix_tbl[ user:firstnick() ] then
                    local prefix = hub_escapeto( prefix_tbl[ user:firstnick() ] )
                    user:updatenick( prefix .. user:nick() )
					updateOnlinecounter(user:firstnick(), prefix_tbl[ user:firstnick() ]..user:firstnick())
                end
            end
            return nil
        end
    )
    hub.setlistener( "onInf", { },  -- add prefix to already connected users
        function( user, cmd )
            if cmd:getnp "NI" then
                if prefix_tbl[ user:firstnick() ] then
                    local prefix = hub_escapeto( prefix_tbl[ user:firstnick() ] )
                    user:updatenick( prefix .. user:nick() )
					updateOnlinecounter(user:firstnick(), prefix_tbl[ user:firstnick() ]..user:firstnick())
                    return PROCESSED
                end
            end
            return nil
        end
    )
    hub.setlistener( "onExit", { },  -- remove prefix on script exit
        function( )
            for sid, user in pairs( hub_getusers() ) do
                if prefix_tbl[ user:firstnick() ] then
                    local prefix = hub_escapeto( prefix_tbl[ user:firstnick() ] )
                    local original_nick = utf_sub( user:nick(), utf_len( prefix ) + 1, -1 )
                    user:updatenick( original_nick, false, true )
                end
            end
            return nil
        end
    )
    hub.setlistener( "onConnect", { },  -- add prefix to connecting user
        function( user )
            local prefix = hub_escapeto( prefix_tbl[ user:firstnick() ] ) or ""
            local bol, err = user:updatenick( prefix .. user:nick(), true )
            if prefix_tbl[ user:firstnick() ] then
                if not bol then
                    user:kill( "ISTA 220 " .. hub_escapeto( err ) .. "\n" )
                    return PROCESSED
                end
            end
            return nil
        end
    )
end

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
--[[

    bot_advanced_chat by pulsar
    
        - this script regs an advanced chat
        - it exports also a module to access the advancedchat from other scripts    
    
        v0.1:
            - level permissions
            - nick permissions
                - members database
                - command add|del
                - chat command show
                - rightclick
    
    
    based on bot_opchat.lua v0.05 by blastbeat

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "bot_advanced_chat"
local scriptversion = "0.1"

--// chat name
local chatname = "[CHAT]AdvancedChat"
--// chat description
local chatdesc = "[ CHAT ] chatroom"

--// command
local cmd = "advancedchat"
--// parameter
local cmd_p_add = "add"
--// parameter
local cmd_p_del = "del"
--// parameter
local cmd_p_show = "members"

--// who can use this command
local masterlevel = 100

--// level permissions - who is allowed to join the chat? (array of boolean)
local permission_level = {

    [ 0 ] = false,  -- unreg
    [ 10 ] = false,  -- guest
    [ 20 ] = false,  -- reg
    [ 30 ] = false,  -- vip
    [ 40 ] = false,  -- svip
    [ 50 ] = false,  -- server
    [ 60 ] = false,  -- operator
    [ 70 ] = false,  -- supervisor
    [ 80 ] = false,  -- admin
    [ 100 ] = true,  -- hubowner

}

--// msgs
local scriptlang = cfg.get "language"
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )

local help_title = lang.help_title or "AdvancedChat"
local help_usage = lang.help_usage or "[+!#]advancedchat add|del <nick>  /  [+!#]advancedchat members  / in the chat: [+!#]members"
local help_desc = lang.help_desc or "Chat with advanced features"

local ucmd_menu_ct1_del_1 = lang.ucmd_menu_ct1_del_1 or "User"
local ucmd_menu_ct1_del_2 = lang.ucmd_menu_ct1_del_2 or "Messages"
local ucmd_menu_ct1_del_3 = lang.ucmd_menu_ct1_del_3 or "Chats"
local ucmd_menu_ct1_del_4 = lang.ucmd_menu_ct1_del_4 or "remove"
local ucmd_menu_ct1_show = lang.ucmd_menu_ct1_show or { "User", "Messages", "Chats", "[CHAT]AdvancedChat", "show all members" }
local ucmd_menu_ct2_add = lang.ucmd_menu_ct2_add or { "Chats", "[CHAT]AdvancedChat", "add" }
local ucmd_menu_ct2_del = lang.ucmd_menu_ct2_del or { "Chats", "[CHAT]AdvancedChat", "remove" }
local ucmd_menu_ct2_show = lang.ucmd_menu_ct2_show or { "Chats", "[CHAT]AdvancedChat", "show all members" }

local msg_denied = lang.msg_denied or "You are not allowed to use this command!"
local msg_denied_2 = lang.msg_denied_2 or "You are not allowed to use this chat!"
local msg_usage = lang.msg_usage or "Usage: [+!#]advancedchat add|del <nick>  /  [+!#]advancedchat members"

local msg_new_member = lang.msg_new_member or "The following user was added as member: "
local msg_welcome = lang.msg_welcome or "Welcome "
local msg_already = lang.msg_already or "The following user is already a member: "
local msg_isbot = lang.msg_isbot or "User is a bot"
local msg_del = lang.msg_del or "The followig user is no longer a member: "
local msg_nomember = lang.msg_nomember or "The following user is not a member: "

local msg_out = lang.msg_out or [[


===  MEMBERS =========================

%s

========================= MEMBERS ===
  ]]


----------
--[CODE]--
----------

--// table lookups
local hub_getbot = hub.getbot
local hub_getuser = hub.getuser
local hub_getusers = hub.getusers
local hub_getregusers = hub.getregusers
local hub_regbot = hub.regbot
local hub_import = hub.import
local hub_debug = hub.debug
local utf_match = utf.match
local utf_format = utf.format
local util_loadtable = util.loadtable
local util_savetable = util.savetable
local table_concat = table.concat
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort
local table_getn = table.getn

--// imports
local help, ucmd, hubcmd

--// functions
local checkPermission, getMembers, checkIfMember, checkIfBot, feed, client, onbmsg

--// database
local members_file = "scripts/data/bot_advanced_chat_members.tbl"
local members_tbl = util_loadtable( members_file ) or {}

--// check user permission
checkPermission = function( user )
    local user_nick = user:nick()
    local user_level = user:level()
    local permission = false
    if permission_level[ user_level ] then
        permission = true
    end
    for k, v in pairs( members_tbl ) do
        if v == user_nick then
            permission = true
        end
    end
    return permission
end

--// get all members from table
getMembers = function()
    members_tbl = util_loadtable( members_file ) or {}
    local tbl = {}
    for k, v in pairs( members_tbl ) do
        tbl[ k ] = "\t" .. v
    end
    local msg = table_concat( tbl, "\n" )
    return msg
end

--// check if user is member
checkIfMember = function( user )
    members_tbl = util_loadtable( members_file ) or {}
    local isMember = false
    for k, v in pairs( members_tbl ) do
        if v == user then
            isMember = true
        end
    end
    return isMember
end

--// check if bot
checkIfBot = function( user )
    local isBot = false
    local regusers, reggednicks, reggedcids = hub_getregusers()
    for i, reguser in ipairs( regusers ) do
        if reguser.is_bot then
            if reguser.nick == user then
                isBot = true
            end
        end
    end
    return isBot
end

local advancedchat, err
feed = function( msg, dispatch )
    local from, pm
    if dispatch ~= "send" then
        dispatch = "reply"
        pm = advancedchat or hub_getbot()
        from = hub_getbot() or advancedchat
    end
    for sid, user in pairs( hub_getusers() ) do
        if checkPermission( user ) then
            user[ dispatch ]( nil, msg, from, pm )
        end
    end
end

client = function( bot, cmd )
    if cmd:fourcc() == "EMSG" then
        local user = hub_getuser( cmd:mysid() )
        if not user then
            return true
        end
        if not checkPermission( user ) then
            user:reply( msg_denied_2, advancedchat, advancedchat )
            return true
        end
        cmd:setnp( "PM", bot:sid() )
        feed( cmd:adcstring(), "send" )
    end
    return true
end

onbmsg = function( user, command, parameters )
    members_tbl = util_loadtable( members_file ) or {}
    local param, nick, desc = utf_match( parameters, "^(%S+) (%S+)$" )
    local param2 = utf_match( parameters, "^(%S+)$" )
    local user_level = user:level()
    local user_nick = user:nick()
    if not checkPermission( user ) then
        user:reply( msg_denied, hub_getusers() )
        return PROCESSED
    end
    if param == cmd_p_add and nick then
        if not checkIfBot( nick ) then
            if not checkIfMember( nick ) then
                local target = hub.isnickonline( nick )
                table_insert( members_tbl, nick )
                util_savetable( members_tbl, "members_tbl", members_file )
                user:reply( msg_new_member .. nick, hub_getbot() )
                target:reply( msg_welcome .. nick, advancedchat, advancedchat )
                return PROCESSED
            else
                user:reply( msg_already .. nick, hub_getbot() )
                return PROCESSED
            end
        else
            user:reply( msg_isbot, hub_getbot() )
            return PROCESSED
        end
    end
    if param == cmd_p_del and nick then
        if checkIfMember( nick ) then
            for k, v in pairs( members_tbl ) do
                if v == nick then
                    table_remove( members_tbl, k )
                    util_savetable( members_tbl, "members_tbl", members_file )
                    user:reply( msg_del .. nick, hub_getbot() )
                    return PROCESSED
                end
            end
        else
            user:reply( msg_nomember .. nick, hub_getbot() )
            return PROCESSED
        end
    end
    if param2 == cmd_p_show then
        local msg = utf_format( msg_out, getMembers() )
        user:reply( msg, hub_getbot() )
        return PROCESSED
    end
    user:reply( msg_usage, hub_getbot() )
    return PROCESSED
end

hub.setlistener( "onPrivateMessage", {},
    function( user, targetuser, adccmd, msg )
        local cmd = utf_match( msg, "^[+!#](%S+)" )
        if msg then
            if targetuser == advancedchat then
                if checkPermission( user ) then
                    if cmd == "members" then
                        local msg = utf_format( msg_out, getMembers() )
                        user:reply( msg, advancedchat, advancedchat )
                        return PROCESSED
                    end
                end
            end
        end
        return nil
    end
)

hub.setlistener( "onStart", {},
    function()
        help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, masterlevel )
        end
        ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            members_tbl = util_loadtable( members_file ) or {}
            local i = table_getn( members_tbl ) or 0
            if i > 0 then
                local usertbl = { }
                for k, v in pairs( members_tbl ) do table_insert( usertbl, v ) end table_sort( usertbl )
                for _, nick in pairs( usertbl ) do
                    ucmd.add( { ucmd_menu_ct1_del_1, ucmd_menu_ct1_del_2, ucmd_menu_ct1_del_3, chatname, ucmd_menu_ct1_del_4, nick }, cmd, { cmd_p_del, nick }, { "CT1" }, masterlevel )
                end
                ucmd.add( ucmd_menu_ct1_show, cmd, { cmd_p_show }, { "CT1" }, masterlevel )
            end
            ucmd.add( ucmd_menu_ct2_add, cmd, { cmd_p_add, "%[userNI]" }, { "CT2" }, masterlevel )
            ucmd.add( ucmd_menu_ct2_del, cmd, { cmd_p_del, "%[userNI]" }, { "CT2" }, masterlevel )
            ucmd.add( ucmd_menu_ct2_show, cmd, { cmd_p_show }, { "CT2" }, masterlevel )
        end
        hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

local nick, desc = chatname, chatdesc
advancedchat, err = hub_regbot{ nick = nick, desc = desc, client = client }
err = err and error( err )

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )

--// public //--

return {

    feed = feed,    -- use advancedchat = hub.import "bot_advanced_chat"; advancedchat.feed( msg ) in other scripts to send a normal message to the advancedchat

}
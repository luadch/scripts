--[[

    bot_session_chat by pulsar

        - this script can reg session chats
        
        - permissions:
            - if an user creates a session chat then only he has the permission to add/remove members
            - only members can read/write

        v0.1:
            - command: [+!#]sessionchat <chatname>
            - chat command: [+!#]help
            - chat command: [+!#]members
            - chat owner command: [+!#]add <nick>
            - chat owner command: [+!#]del <nick>

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "bot_session_chat"
local scriptversion = "0.1"

--// prefix for all session chats (no whitespaces allowed)
local chatprefix = "[SESSION-CHAT]"

--// command in main (rightclick)
local cmd = "sessionchat"
local cmd_p = "delall"
--// commands in chat
local cmd_help = "help"
local cmd_members = "members"
local cmd_add = "add"
local cmd_del = "del"

--// who can create session chats
local minlevel = 20
--// who can clean the session chats database (removes all existing session chats from hub)
local masterlevel = 100

--// msgs
local scriptlang = cfg.get "language"
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )

local help_title = lang.help_title or "Session Chat"
local help_usage = lang.help_usage or"[+!#]sessionchat <chatname>"
local help_desc = lang.help_desc or "Session Chats are temporary chats for one user session"

local msg_help_1 = lang.msg_help_1 or "  [+!#]help  \t| List of available commands in chat"
local msg_help_2 = lang.msg_help_2 or "  [+!#]members\t| List of all members"
local msg_help_3 = lang.msg_help_3 or "  [+!#]add <nick>\t| add a new member"
local msg_help_4 = lang.msg_help_4 or "  [+!#]del <nick>\t| remove an existing member"

local ucmd_menu_ct1_create = lang.ucmd_menu_ct1_create or { "User", "Messages", "Chats", "Session Chat", "create a chat for this session" }
local ucmd_menu_ct1_remove = lang.ucmd_menu_ct1_remove or { "User", "Messages", "Chats", "Session Chat", "remove all session chats" }
local ucmd_popup = lang.ucmd_popup or "Chatname (no whitespaces!)"

local chatdesc = lang.chatdesc or "by: %s | members: %s"

local msg_denied = lang.msg_denied or "You are not allowed to use this command!"
local msg_denied_2 = lang.msg_denied_2 or "You are not allowed to use this chat!"
local msg_denied_3 = lang.msg_denied_3 or "You can not remove yourself."
local msg_usage = lang.msg_usage or "Usage: [+!#]sessionchat <chatname>"
local msg_already = lang.msg_already or "User is already a member: "
local msg_nomember = lang.msg_nomember or "User is not a member: "
local msg_notonline = lang.msg_notonline or "User is not online: "
local msg_welcome = lang.msg_welcome or "Welcome "
local msg_new_member = lang.msg_new_member or "The following user was added as member: "
local msg_del = lang.msg_del or "The following user is no longer a member: "
local msg_del_2 = lang.msg_del_2 or "You are no longer a member of this chat."
local msg_delall = lang.msg_delall or "All Session Chats removed."
local msg_create = lang.msg_create or "%s has added a new Session Chat: %s"
local msg_create2 = lang.msg_create2 or "You have added a new Session Chat: %s"
local msg_create3 = lang.msg_create3 or "You are the only one who can add or remove members in your chat!"
local msg_chatexists = lang.msg_chatexists or "Chat already exists."

local msg_members = lang.msg_members or [[


=== MEMBERS ==============================

%s

============================== MEMBERS ===
  ]]

local msg_help_owner = lang.msg_help_owner or [[


=== OWNER HELP ===================================

List of all in-chat commands:

%s
%s
%s
%s

=================================== OWNER HELP ===
  ]]
  
local msg_help_member = lang.msg_help_member or [[


=== MEMBERS HELP =================================

List of all in-chat commands:

%s
%s

================================= MEMBERS HELP ===
  ]]

  
----------
--[CODE]--
----------

--// flags
local owner, members = "owner", "members"

--// table lookups
local hub_getbot = hub.getbot
local hub_getuser = hub.getuser
local hub_getusers = hub.getusers
local hub_regbot = hub.regbot
local hub_import = hub.import
local hub_debug = hub.debug
local hub_broadcast = hub.broadcast
local hub_escapefrom = hub.escapefrom
local hub_escapeto = hub.escapeto
local hub_isnickonline = hub.isnickonline
local utf_match = utf.match
local utf_format = utf.format
local util_loadtable = util.loadtable
local util_savetable = util.savetable
local table_concat = table.concat
local table_insert = table.insert
local table_remove = table.remove
local string_find = string.find

--// imports
local help, ucmd, hubcmd

--// functions
local feed, client, onbmsg
local regChatsOnStart, checkIfChatExists, checkIfMember, checkIfOwner, getMembers, checkIfOnline, refreshBot, msgToMembers

--// database
local sessions_file = "scripts/data/bot_session_chat.tbl"
local sessions_tbl = util_loadtable( sessions_file ) or {}


--// reg session chats on scriptstart
local sessionchat, err
regChatsOnStart = function()
    sessions_tbl = util_loadtable( sessions_file ) or {}
    local i = 0
    for k, v in pairs( sessions_tbl ) do
        if k then
            local err, sessionchat
            local chatname = k
            local owner = sessions_tbl[ k ].owner
            for k, v in pairs( v ) do
                if k == "members" then
                    for k, v in pairs( v ) do
                        i = i + 1
                    end
                end
            end
            local description = utf_format( chatdesc, owner, i )
            local nick, desc = chatname, description
            sessionchat, err = hub_regbot{ nick = nick, desc = desc, client = client }
            i = 0
        end
    end
end

--// check if chat exists
checkIfChatExists = function( chat )
    sessions_tbl = util_loadtable( sessions_file ) or {}
    local check = false
    for k, v in pairs( sessions_tbl ) do
        if k == chat then
            check = true
            break
        end
    end
    return check
end

--// check if user is member
checkIfMember = function( user, chat )
    sessions_tbl = util_loadtable( sessions_file ) or {}
    local check = false
    for k, v in pairs( sessions_tbl ) do
        if k == chat then
            for k, v in pairs( v ) do
                if k == "members" then
                    for i, usr in pairs( v ) do
                        if usr == user then
                            check = true
                            break
                        end
                    end
                end
            end
        end
    end
    return check
end

--// check if user is chat owner
checkIfOwner = function( user, chat )
    sessions_tbl = util_loadtable( sessions_file ) or {}
    local user_nick = user:nick()
    local check = false
    for k, v in pairs( sessions_tbl ) do
        if k == chat then
            for k, v in pairs( v ) do
                if k == "owner" then
                    if v == user_nick then
                        check = true
                        break
                    end
                end
            end
        end
    end
    return check
end

--// get all members from chat
getMembers = function( chat )
    sessions_tbl = util_loadtable( sessions_file ) or {}
    local tbl = {}
    for k, v in pairs( sessions_tbl ) do
        if k == chat then
            for k, v in pairs( v ) do
                if k == "members" then
                    for i, usr in pairs( v ) do
                        tbl[ i ] = "\t" .. usr
                    end
                end
            end
        end
    end
    local msg = table_concat( tbl, "\n" )
    return msg
end

--// check if user is online and not a bot
checkIfOnline = function( user )
    local check = false
    for sid, onlineuser in pairs( hub_getusers() ) do
        if not onlineuser:isbot() then
            if onlineuser == user then
                check = true
            end
        end
    end
    return check
end

--// refresh members count of chats
refreshBot = function( chat )
    sessions_tbl = util_loadtable( sessions_file ) or {}
    local i = 0
    for k, v in pairs( sessions_tbl ) do
        if k == chat then
            --// kill the bot
            chat = hub_isnickonline( k )
            chat:kill( "ISTA 230 " )
            --// reg him new -> ok this is an ugly hack
            local err, sessionchat
            local chatname = k
            local owner = sessions_tbl[ k ].owner
            for k, v in pairs( v ) do
                if k == "members" then
                    for k, v in pairs( v ) do
                        i = i + 1
                    end
                end
            end
            local description = utf_format( chatdesc, owner, i )
            --local desc = hub_escapeto( description )
            --chatname:inf():setnp( "DE", desc )
            local nick, desc = chatname, description
            sessionchat, err = hub_regbot{ nick = nick, desc = desc, client = client }
        end
    end
end

--// send msg to all members
msgToMembers = function( chat, msg )
    sessions_tbl = util_loadtable( sessions_file ) or {}
    for k, v in pairs( sessions_tbl ) do
        if k == chat then
            local bot_name = hub_isnickonline( chat )
            for k, v in pairs( v ) do
                if k == "members" then
                    for i, usr in pairs( v ) do
                        local user = hub_isnickonline( usr ) or false
                        if user then
                            user:reply( msg, bot_name, bot_name )
                        end
                    end
                end
            end
        end
    end
end

feed = function( msg, dispatch, chat )
    local from, pm
    if dispatch ~= "send" then
        dispatch = "reply"
        pm = chat or hub_getbot()
        from = hub_getbot() or chat
    end
    for sid, user in pairs( hub_getusers() ) do
        local bot_nick = chat:nick()
        local user_nick = user:nick()
        if checkIfMember( user_nick, bot_nick ) then
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
        local user_nick = user:nick()
        if not checkIfMember( user_nick, bot:nick() ) then
            user:reply( msg_denied_2, bot, bot )
            return true
        end
        cmd:setnp( "PM", bot:sid() )
        feed( cmd:adcstring(), "send", bot )
        local bot_name = hub_isnickonline( bot:nick() )
        local msg = hub_escapefrom( cmd:pos( 4 ) )
        local cmd = utf_match( msg, "^[+!#](%S+)" )
        local cmd2, id = utf_match( msg, "^[+!#](%S+) (%S+)" )
        if cmd == cmd_help then
            if checkIfOwner( user, bot:nick() ) then
                local msg_help = utf_format( msg_help_owner, msg_help_1, msg_help_2, msg_help_3, msg_help_4 )
                user:reply( msg_help, bot_name, bot_name )
            else
                local msg_help = utf_format( msg_help_member, msg_help_1, msg_help_2 )
                user:reply( msg_help, bot_name, bot_name )
            end
        end
        if cmd == cmd_members then
            local msg = utf_format( msg_members, getMembers( bot:nick() ) )
            user:reply( msg, bot_name, bot_name )
        end
        if cmd2 == cmd_add and id then
            if checkIfOwner( user, bot:nick() ) then
                local target = hub_isnickonline( id ) or false
                if target then
                    if not checkIfMember( id, bot:nick() ) then
                        sessions_tbl = util_loadtable( sessions_file ) or {}
                        --// add user
                        table_insert( sessions_tbl[ bot:nick() ][ members ], id )
                        util_savetable( sessions_tbl, "sessions_tbl", sessions_file )
                        --// msg to existing members
                        msgToMembers( bot:nick(), msg_new_member .. id )
                        --// msg to new member
                        local msg_help = utf_format( msg_help_member, msg_help_1, msg_help_2 )
                        target:reply( msg_help, bot_name, bot_name )
                        target:reply( msg_welcome .. id, bot_name, bot_name )
                        --// refresh members count in description
                        refreshBot( bot:nick() )
                    else
                        user:reply( msg_already .. id, bot_name, bot_name )
                    end
                else
                    user:reply( msg_notonline .. id, bot_name, bot_name )
                end
                
            else
                user:reply( msg_denied, bot_name, bot_name )
            end
        end
        if cmd2 == cmd_del and id then
            if checkIfOwner( user, bot:nick() ) then
                if checkIfMember( id, bot:nick() ) then
                    sessions_tbl = util_loadtable( sessions_file ) or {}
                    if user_nick ~= id then
                        for k, v in pairs( sessions_tbl ) do
                            if k == bot:nick() then
                                for k, v in pairs( v ) do
                                    if k == "members" then
                                        for i, usr in pairs( v ) do
                                            if id == usr then
                                                --// del user
                                                table_remove( sessions_tbl[ bot:nick() ][ members ], i )
                                                util_savetable( sessions_tbl, "sessions_tbl", sessions_file )
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        --// msg to still existing members
                        msgToMembers( bot:nick(), msg_del .. id )
                        --// msg to member
                        local target = hub_isnickonline( id ) or false
                        if target then
                            target:reply( msg_del_2, bot_name, bot_name )
                        end
                        --// refresh members count in description
                        refreshBot( bot:nick() )
                    else
                        user:reply( msg_denied_3, bot_name, bot_name )
                    end
                else
                    user:reply( msg_nomember .. id, bot_name, bot_name )
                end
            else
                user:reply( msg_denied, bot_name, bot_name )
            end
        end
    end
    return true
end

onbmsg = function( user, command, parameters )
    sessions_tbl = util_loadtable( sessions_file ) or {}
    local chatname = utf_match( parameters, "^(%S+)$" )
    local user_level = user:level()
    local user_nick = user:nick()
    if user_level < minlevel then
        user:reply( msg_denied, hub_getbot() )
        return PROCESSED
    end
    if chatname == cmd_p then
        if user_level >= masterlevel then
            sessions_tbl = util_loadtable( sessions_file ) or {}
            for k, v in pairs( sessions_tbl ) do
                if k then
                    local chat = hub_isnickonline( k )
                    chat:kill( "ISTA 230 " )
                    sessions_tbl[ k ] = nil
                    util_savetable( sessions_tbl, "sessions_tbl", sessions_file )
                end
            end
            user:reply( msg_delall, hub_getbot() )
            return PROCESSED
        else
            user:reply( msg_denied, hub_getbot() )
            return PROCESSED
        end
    elseif chatname then
        --// check if chatname already exists
        local chat = chatprefix .. chatname
        if checkIfChatExists( chat ) then
            user:reply( msg_chatexists, hub_getbot() )
            return PROCESSED
        else
            --// reg the chat
            local description = utf_format( chatdesc, user_nick, 1 )
            local nick, desc = chatprefix .. chatname, description
            sessionchat, err = hub_regbot{ nick = nick, desc = desc, client = client }
            err = err and error( err )
            --// save chat infos to tbl
            sessions_tbl[ nick ] = {}
            sessions_tbl[ nick ].owner = user_nick
            sessions_tbl[ nick ].members = {}
            table_insert( sessions_tbl[ nick ][ members ], user_nick )
            util_savetable( sessions_tbl, "sessions_tbl", sessions_file )
            --// send msg to all
            local msg = utf_format( msg_create, user_nick, nick )
            hub_broadcast( msg, hub_getbot() )
            --// send info msg to chat-owner
            local msg2 = utf_format( msg_create2, nick )
            local msg_help = utf_format( msg_help_owner, msg_help_1, msg_help_2, msg_help_3, msg_help_4 )
            local bot_name = hub_isnickonline( nick )
            user:reply( msg_help, bot_name, bot_name )
            user:reply( msg2, bot_name, bot_name )
            user:reply( msg_create3, bot_name, bot_name )
            return PROCESSED
        end
    end
    user:reply( msg_usage, hub_getbot() )
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function()
        regChatsOnStart()
        help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_ct1_create, cmd, { "%[line:" .. ucmd_popup .. "]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct1_remove, cmd, { cmd_p }, { "CT1" }, masterlevel )
        end
        hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.setlistener( "onLogout", {},
    function( user )
        sessions_tbl = util_loadtable( sessions_file ) or {}
        local user_nick = user:nick()
        local chat
        for k, v in pairs( sessions_tbl ) do
            if k then
                if sessions_tbl[ k ].owner == user_nick then
                    chat = hub_isnickonline( k )
                    chat:kill( "ISTA 230 " )
                    sessions_tbl[ k ] = nil
                    util_savetable( sessions_tbl, "sessions_tbl", sessions_file )
                end
            end
        end
    end
)

hub.setlistener( "onExit", {},
    function()
        util_savetable( sessions_tbl, "sessions_tbl", sessions_file )
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
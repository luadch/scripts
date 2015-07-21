--[[

    bot_advanced_chat by pulsar

        - this script regs an advanced chat with chathistory
        - it exports also a module to access the advanced chat from other scripts

        - permissions:
            - a user can use the chat either her level ist true according with permission table or he is a member according with members table
            - masterlevel hast permission to add/del members and access to the rightclick

        v0.5:
            - pm2op chat functionality, forward messages from unauthorized users to members if needed

        v0.4:
            - command: help
            - chat command: add
            - chat command: del
            - fix some bugs

        v0.3:
            - chat command: help
            - code cleaning

        v0.2:
            - chat history (some code based on etc_chatlog.lua by Motnahp, thx)
            - chat command: history
            - chat command: historyall

        v0.1:
            - level permissions
            - nick permissions
                - members database
                - command: add|del
                - chat command: show
                - rightclick


    based on bot_opchat.lua v0.05 by blastbeat

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "bot_advanced_chat"
local scriptversion = "0.5"

--// chat name
local chatname = "[CHAT]AdvancedChat"
--// chat description
local chatdesc = "[ CHAT ] chatroom"

--// command in main
local cmd = "advancedchat"
local cmd_p_help = "help"
local cmd_p_add = "add"
local cmd_p_del = "del"
local cmd_p_members = "members"
local cmd_p_history = "history"
local cmd_p_historyall = "historyall"

--// commands in chat
local cmd_help = "help"
local cmd_members = "members"
local cmd_history = "history"
local cmd_historyall = "historyall"
local cmd_add = "add"
local cmd_del = "del"

--// minlevel to get the full rightclick
local masterlevel = 100

--// level permissions - who is allowed to join the chat? (array of boolean)
local permission_level = {

    [ 0 ] = false,  -- unreg
    [ 10 ] = false,  -- guest
    [ 20 ] = false,  -- reg
    [ 30 ] = false,  -- vip
    [ 40 ] = false,  -- svip
    [ 50 ] = false,  -- server
    [ 60 ] = true,  -- operator
    [ 70 ] = true,  -- supervisor
    [ 80 ] = true,  -- admin
    [ 100 ] = true,  -- hubowner

}

--// pm2op chat functionality, forward messages from unauthorized users to members
local use_pm2op = true

--// history: default amount of posts to show
local default_lines = 5

--// history: max posts to save in database
local max_lines = 200

--// history: chat arrivals to save history_tbl
local saveit = 5

--// msgs
local scriptlang = cfg.get "language"
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )

local help_title = lang.help_title or "Advanced Chat"
local help_desc = lang.help_desc or "Chat with advanced features"

local msg_help_1 = lang.msg_help_1 or "  [+!#]help \t | List of available commands in chat"
local msg_help_2 = lang.msg_help_2 or "  [+!#]members \t | List of all members"
local msg_help_3 = lang.msg_help_3 or "  [+!#]history \t | Shows the last posts from chat"
local msg_help_4 = lang.msg_help_4 or "  [+!#]historyall \t | Shows all saved posts from chat"

local msg_help_5 = lang.msg_help_5 or "  [+!#]add <nick> \t | Add new member"
local msg_help_6 = lang.msg_help_6 or "  [+!#]del <nick> \t | Remove a member"
local msg_help_7 = lang.msg_help_7 or "  [+!#]advancedchat help"
local msg_help_8 = lang.msg_help_8 or "  [+!#]advancedchat add|del <nick>"
local msg_help_9 = lang.msg_help_9 or "  [+!#]advancedchat members"
local msg_help_10 = lang.msg_help_10 or "  [+!#]advancedchat history"
local msg_help_11 = lang.msg_help_11 or "  [+!#]advancedchat historyall"

local ucmd_menu_ct1_del_1 = lang.ucmd_menu_ct1_del_1 or "User"
local ucmd_menu_ct1_del_2 = lang.ucmd_menu_ct1_del_2 or "Messages"
local ucmd_menu_ct1_del_3 = lang.ucmd_menu_ct1_del_3 or "Chats"
local ucmd_menu_ct1_del_4 = lang.ucmd_menu_ct1_del_4 or "Advanced Chat"
local ucmd_menu_ct1_del_5 = lang.ucmd_menu_ct1_del_5 or "remove"

local ucmd_menu_ct1_help = lang.ucmd_menu_ct1_help or { "User", "Messages", "Chats", "Advanced Chat", "show help" }
local ucmd_menu_ct1_members = lang.ucmd_menu_ct1_members or { "User", "Messages", "Chats", "Advanced Chat", "show all members" }
local ucmd_menu_ct1_history = lang.ucmd_menu_ct1_history or { "User", "Messages", "Chats", "Advanced Chat", "show chat history (latest)" }
local ucmd_menu_ct1_historyall = lang.ucmd_menu_ct1_historyall or { "User", "Messages", "Chats", "Advanced Chat", "show chat history (all saved)" }

local ucmd_menu_ct2_add = lang.ucmd_menu_ct2_add or { "Chats", "Advanced Chat", "add" }
local ucmd_menu_ct2_del = lang.ucmd_menu_ct2_del or { "Chats", "Advanced Chat", "remove" }

local msg_denied = lang.msg_denied or "You are not allowed to use this command!"
local msg_denied_2 = lang.msg_denied_2 or "You are not allowed to use this chat!"
local msg_new_member = lang.msg_new_member or "The following user was added as member: "
local msg_welcome = lang.msg_welcome or "Welcome "
local msg_already = lang.msg_already or "The following user is already a member: "
local msg_isbot = lang.msg_isbot or "User is a bot"
local msg_del = lang.msg_del or "The followig user is no longer a member: "
local msg_del_2 = lang.msg_del_2 or "You are no longer a member of this chat."
local msg_nomember = lang.msg_nomember or "The following user is not a member: "
local msg_intro = lang.msg_intro or "\t\t\t\t   The last %s posts from chat:"
local msg_pm2ops_user = lang.msg_pm2ops_user or "The following message was send to all members of this Chat: "

local msg_members = lang.msg_members or [[


=== MEMBERS =========================

%s

========================= MEMBERS ===
  ]]

local msg_levels = lang.msg_levels or [[

=== ALLOWED LEVELS ==================

%s
================== ALLOWED LEVELS ===
  ]]

local msg_history = lang.msg_history or [[


========== CHATLOG ==============================================================================
%s
%s
============================================================================== CHATLOG ==========
  ]]

local msg_help_master = lang.msg_help_master or [[


=== MASTER HELP ==========================================

List of all in-chat commands:

%s
%s
%s
%s
%s
%s

List of all main commands:

%s
%s
%s
%s
%s

========================================== MASTER HELP ===
  ]]


local msg_help_member = lang.msg_help_member or [[


=== MEMBER HELP ==========================================

List of all in-chat commands:

%s
%s
%s
%s

========================================== MEMBER HELP ===
  ]]

local msg_pm2ops_op = lang.msg_pm2ops_op or [[


========== PM 2 OP FUNCTION ======================================================================

New message from unauthorized user:

User: %s
Msg:  %s

====================================================================== PM 2 OP FUNCTION ==========
  ]]


----------
--[CODE]--
----------

--// table lookups
local hub_getbot = hub.getbot
local hub_getuser = hub.getuser
local hub_getusers = hub.getusers
local hub_getregusers = hub.getregusers
local hub_isnickonline = hub.isnickonline
local hub_regbot = hub.regbot
local hub_import = hub.import
local hub_debug = hub.debug
local hub_escapefrom = hub.escapefrom
local utf_match = utf.match
local utf_format = utf.format
local util_loadtable = util.loadtable
local util_savetable = util.savetable
local util_savearray = util.savearray
local table_concat = table.concat
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort
local string_byte = string.byte
local os_date = os.date

--// imports
local help, ucmd, hubcmd

--// functions
local checkPermission, getMembers, checkIfMember, checkIfBot, feed, client, onbmsg, buildlog, getLevels

--// database
local members_file = "scripts/data/bot_advanced_chat_members.tbl"
local members_tbl = util_loadtable( members_file ) or {}
local history_file = "scripts/data/bot_advanced_chat_history.tbl"
local history_tbl = util_loadtable( history_file ) or {}

--// parse date output
local dateparser = function()
    if scriptlang == "de" then
        local day = os_date( "%d" )
        local month = os_date( "%m" )
        local year = os_date( "%Y" )
        local weekday = os_date( "%A" )
        local time = os_date( "%X" )
        local Datum = day .. "." .. month .. "." .. year .. " | " .. time
        return Datum
    elseif scriptlang == "en" then
        local day = os_date( "%d" )
        local month = os_date( "%m" )
        local year = os_date( "%y" )
        local time = os_date( "%X" )
        local Date = month .. "/" .. day .. "/" .. year .. " | " .. time
        return Date
    else
        local day = os_date( "%d" )
        local month = os_date( "%m" )
        local year = os_date( "%y" )
        local time = os_date( "%X" )
        local Date = month .. "/" .. day .. "/" .. year .. " | " .. time
        return Date
    end
end

--// check user permission
checkPermission = function( user )
    members_tbl = util_loadtable( members_file ) or {}
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

--// get all levels from table
getLevels = function()
    local levels = cfg.get( "levels" ) or {}
    local tbl = {}
    local i = 1
    local msg = ""
    for k, v in pairs( permission_level ) do
        if k > 0 then
            if v then
                tbl[ i ] = k
                i = i + 1
            end
        end
    end
    table_sort( tbl )
    for _, level in pairs( tbl ) do
        msg = msg .. "\t" .. levels[ level ] .. "\n"
    end
    local msg_out = utf_format( msg_levels, msg )
    return msg_out
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

--// create history (by Motnahp)
buildlog = function( amount_lines )
    local amount = ( amount_lines or default_lines )
    --// make sure nobody lets it "spam"
    if amount >= max_lines then
        amount = max_lines
    end
    local log_msg = "\n"
    local lines_msg = ""
    --// set variables for loop
    local x = amount
    --// makes sure it doesn't send more as it got
    if amount > #history_tbl then
        x,amount = #history_tbl,#history_tbl
    end
    x = #history_tbl - x
    --// loop thru the table
    for i,v in ipairs( history_tbl ) do
        --// makes sure it doesn't send more than you want
        if i > x then
            log_msg = log_msg .. " [" .. i .. "] - [ " .. v[ 1 ] .. " ] <" .. v[ 2 ] .. "> " .. v[ 3 ] .. "\n"
        end
    end
    --// adds amount into 'header'
    lines_msg = utf_format( msg_intro, amount )
    --// combines 'header' and logos with history
    log_msg = utf_format( msg_history, lines_msg, log_msg )
    return log_msg
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
            if use_pm2op then
                local user_msg = hub_escapefrom( cmd:pos( 4 ) )
                local msg = utf_format( msg_pm2ops_op, user:nick(), user_msg )
                user:reply( msg_pm2ops_user .. user_msg, advancedchat, advancedchat )
                feed( msg )
                return true
            else
                user:reply( msg_denied_2, advancedchat, advancedchat )
                return true
            end
        end
        cmd:setnp( "PM", bot:sid() )
        feed( cmd:adcstring(), "send" )
    end
    return true
end

onbmsg = function( user, command, parameters )
    members_tbl = util_loadtable( members_file ) or {}
    local param, id = utf_match( parameters, "^(%S+) (%S+)$" )
    local param2 = utf_match( parameters, "^(%S+)$" )
    local user_level = user:level()
    local user_nick = user:nick()
    if user_level < masterlevel then
        user:reply( msg_denied, hub_getbot() )
        return PROCESSED
    end
    if param == cmd_p_add and id then
        if not checkIfBot( id ) then
            if not checkIfMember( id ) then
                local target = hub_isnickonline( id ) or false
                --// add member
                table_insert( members_tbl, id )
                util_savetable( members_tbl, "members_tbl", members_file )
                --// msg to master in main
                user:reply( msg_new_member .. id, hub_getbot() )
                --// msg to member in chat
                if target then
                    local msg = utf_format( msg_help_member, msg_help_1, msg_help_2, msg_help_3, msg_help_4 )
                    target:reply( msg, advancedchat, advancedchat )
                    target:reply( msg_welcome .. id, advancedchat, advancedchat )
                end
                return PROCESSED
            else
                user:reply( msg_already .. id, hub_getbot() )
                return PROCESSED
            end
        else
            user:reply( msg_isbot, hub_getbot() )
            return PROCESSED
        end
    end
    if param == cmd_p_del and id then
        if checkIfMember( id ) then
            for k, v in pairs( members_tbl ) do
                if v == id then
                    local target = hub_isnickonline( id ) or false
                    --// del member
                    table_remove( members_tbl, k )
                    util_savetable( members_tbl, "members_tbl", members_file )
                    --// msg to master in main
                    user:reply( msg_del .. id, hub_getbot() )
                    if target then
                        --// msg to member in main
                        target:reply( msg_del_2, hub_getbot() )
                        --// msg to member in chat
                        target:reply( msg_del_2, advancedchat, advancedchat )
                    end
                    return PROCESSED
                end
            end
        else
            user:reply( msg_nomember .. id, hub_getbot() )
            return PROCESSED
        end
    end
    if param2 == cmd_p_help then
        local msg = utf_format( msg_help_master,
                                msg_help_1, msg_help_2, msg_help_3, msg_help_4, msg_help_5, msg_help_6,
                                msg_help_7, msg_help_8, msg_help_9, msg_help_10, msg_help_11 )
        user:reply( msg, hub_getbot() )
        return PROCESSED
    end
    if param2 == cmd_p_members then
        local msg = utf_format( msg_members, getMembers() )
        user:reply( msg .. getLevels(), hub_getbot() )
        return PROCESSED
    end
    if param2 == cmd_p_history then
        user:reply( buildlog( default_lines ), hub_getbot() )
        return PROCESSED
    end
    if param2 == cmd_p_historyall then
        user:reply( buildlog( max_lines ), hub_getbot() )
        return PROCESSED
    end
end

local savehistory = 0
hub.setlistener( "onPrivateMessage", {},
    function( user, targetuser, adccmd, msg )
        local cmd = utf_match( msg, "^[+!#](%S+)" )
        local cmd2, id = utf_match( msg, "^[+!#](%S+) (%S+)" )
        local user_level = user:level()
        if msg then
            if targetuser == advancedchat then
                local result = 48
                result = string_byte( msg, 1 )
                if result ~= 33 and result ~= 35 and result ~= 43 then
                    --// increment savehistory to save if it reaches saveit
                    savehistory = savehistory + 1
                    --// get data
                    local data = utf_match(  msg, "(.+)" )
                    --// build table
                    local t = {
                        [1] = dateparser(),
                        [2] = user:nick( ),
                        [3] = data
                    }
                    --// add table to history_tbl
                    table_insert( history_tbl,t )
                    --// remove an item of history_tbl if there are to many items in
                    for x = 1, #history_tbl -  max_lines do
                        table_remove( history_tbl, 1 )
                    end
                    --// save history_tbl and set savehistory 0
                    if savehistory >= saveit then
                        savehistory = 0
                        util_savearray( history_tbl, history_file )
                    end
                end
                if checkPermission( user ) then
                    if cmd == cmd_help then
                        if user_level >= masterlevel then
                            local msg = utf_format( msg_help_master,
                                                    msg_help_1, msg_help_2, msg_help_3, msg_help_4, msg_help_5, msg_help_6,
                                                    msg_help_7, msg_help_8, msg_help_9, msg_help_10, msg_help_11 )
                            user:reply( msg, advancedchat, advancedchat )
                            return PROCESSED
                        else
                            local msg = utf_format( msg_help_member, msg_help_1, msg_help_2, msg_help_3, msg_help_4 )
                            user:reply( msg, advancedchat, advancedchat )
                            return PROCESSED
                        end
                    end
                    if cmd == cmd_members then
                        local msg = utf_format( msg_members, getMembers() )
                        user:reply( msg .. getLevels(), advancedchat, advancedchat )
                        return PROCESSED
                    end
                    if cmd == cmd_history then
                        user:reply( buildlog( default_lines ), advancedchat, advancedchat )
                        return PROCESSED
                    end
                    if cmd == cmd_historyall then
                        user:reply( buildlog( max_lines ), advancedchat, advancedchat )
                        return PROCESSED
                    end
                    if cmd2 == cmd_add and id then
                        if user_level >= masterlevel then
                            if not checkIfBot( id ) then
                                if not checkIfMember( id ) then
                                    local target = hub_isnickonline( id ) or false
                                    --// add member
                                    table_insert( members_tbl, id )
                                    util_savetable( members_tbl, "members_tbl", members_file )
                                    --// msg to master in main
                                    user:reply( msg_new_member .. id, hub_getbot() )
                                    --// msg to master in chat
                                    user:reply( msg_new_member .. id, advancedchat, advancedchat )
                                    --// msg to member in chat
                                    if target then
                                        local msg = utf_format( msg_help_member, msg_help_1, msg_help_2, msg_help_3, msg_help_4 )
                                        target:reply( msg, advancedchat, advancedchat )
                                        target:reply( msg_welcome .. id, advancedchat, advancedchat )
                                    end
                                    return PROCESSED
                                else
                                    user:reply( msg_already .. id, advancedchat, advancedchat )
                                    return PROCESSED
                                end
                            else
                                user:reply( msg_isbot, advancedchat, advancedchat )
                                return PROCESSED
                            end
                        else
                            user:reply( msg_denied, advancedchat, advancedchat )
                            return PROCESSED
                        end
                    end
                    if cmd2 == cmd_del and id then
                        if user_level >= masterlevel then
                            if checkIfMember( id ) then
                                for k, v in pairs( members_tbl ) do
                                    if v == id then
                                        local target = hub_isnickonline( id ) or false
                                        --// del member
                                        table_remove( members_tbl, k )
                                        util_savetable( members_tbl, "members_tbl", members_file )
                                        --// msg to master in chat
                                        user:reply( msg_del .. id, advancedchat, advancedchat )
                                        --// msg to master in main
                                        user:reply( msg_del .. id, hub_getbot() )
                                        if target then
                                            --// msg to member in main
                                            target:reply( msg_del_2, hub_getbot() )
                                            --// msg to member in chat
                                            target:reply( msg_del_2, advancedchat, advancedchat )
                                        end
                                        return PROCESSED
                                    end
                                end
                            else
                                user:reply( msg_nomember .. id, advancedchat, advancedchat )
                                return PROCESSED
                            end
                        else
                            user:reply( msg_denied, advancedchat, advancedchat )
                            return PROCESSED
                        end
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
            local help_usage = utf_format( msg_help_master,
                                           msg_help_1, msg_help_2, msg_help_3, msg_help_4, msg_help_5, msg_help_6,
                                           msg_help_7, msg_help_8, msg_help_9, msg_help_10, msg_help_11 )
            help.reg( help_title, help_usage, help_desc, masterlevel )
        end
        ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            members_tbl = util_loadtable( members_file ) or {}
            ucmd.add( ucmd_menu_ct1_help, cmd, { cmd_p_help }, { "CT1" }, masterlevel )
            ucmd.add( ucmd_menu_ct1_members, cmd, { cmd_p_members }, { "CT1" }, masterlevel )
            ucmd.add( ucmd_menu_ct1_history, cmd, { cmd_p_history }, { "CT1" }, masterlevel )
            ucmd.add( ucmd_menu_ct1_historyall, cmd, { cmd_p_historyall }, { "CT1" }, masterlevel )
            local i = #members_tbl or 0
            if i > 0 then
                local usertbl = {}
                for k, v in pairs( members_tbl ) do table_insert( usertbl, v ) end table_sort( usertbl )
                for _, nick in pairs( usertbl ) do
                    ucmd.add( { ucmd_menu_ct1_del_1, ucmd_menu_ct1_del_2, ucmd_menu_ct1_del_3, ucmd_menu_ct1_del_4, ucmd_menu_ct1_del_5, nick }, cmd, { cmd_p_del, nick }, { "CT1" }, masterlevel )
                end
            end
            ucmd.add( ucmd_menu_ct2_add, cmd, { cmd_p_add, "%[userNI]" }, { "CT2" }, masterlevel )
            ucmd.add( ucmd_menu_ct2_del, cmd, { cmd_p_del, "%[userNI]" }, { "CT2" }, masterlevel )
        end
        hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.setlistener( "onExit", {},
    function()
        util_savetable( members_tbl, "members_tbl", members_file )
        util_savearray( history_tbl, history_file )
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
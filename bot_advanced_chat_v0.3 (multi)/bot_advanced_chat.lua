--[[

    bot_advanced_chat by pulsar

        - this script regs an advanced chat
        - it exports also a module to access the advancedchat from other scripts
        - permissions: a user can use the chat either her level ist true accourding with permission table or he is a member according with members table

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
local scriptversion = "0.3"

--// chat name
local chatname = "[CHAT]AdvancedChat"
--// chat description
local chatdesc = "[ CHAT ] chatroom"

--// command in main
local cmd = "advancedchat"
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

--// history: default amount of posts to show
local default_lines = 5
--// history: max posts to save in database
local max_lines = 200
--// history: chat arrivals to save history_tbl
local saveit = 5

--// msgs
local scriptlang = cfg.get "language"
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )

local help_title = lang.help_title or "AdvancedChat"
local help_usage = lang.help_usage or "[+!#]advancedchat add|del <nick>  /  [+!#]advancedchat members  / in the chat: [+!#]help|[+!#]members|[+!#]history|[+!#]historyall"
local help_desc = lang.help_desc or "Chat with advanced features"

local msg_help_1 = lang.msg_help_1 or "  [+!#]help \t/ List of available commands in chat"
local msg_help_2 = lang.msg_help_2 or "  [+!#]members \t/ List of all members"
local msg_help_3 = lang.msg_help_3 or "  [+!#]history \t/ Shows the last posts from chat"
local msg_help_4 = lang.msg_help_4 or "  [+!#]historyall \t/ Shows all saved posts from chat"

local ucmd_menu_ct1_del_1 = lang.ucmd_menu_ct1_del_1 or "User"
local ucmd_menu_ct1_del_2 = lang.ucmd_menu_ct1_del_2 or "Messages"
local ucmd_menu_ct1_del_3 = lang.ucmd_menu_ct1_del_3 or "Chats"
local ucmd_menu_ct1_del_4 = lang.ucmd_menu_ct1_del_4 or "[CHAT]AdvancedChat"
local ucmd_menu_ct1_del_5 = lang.ucmd_menu_ct1_del_5 or "remove"

local ucmd_menu_ct1_members = lang.ucmd_menu_ct1_members or { "User", "Messages", "Chats", "[CHAT]AdvancedChat", "show all members" }
local ucmd_menu_ct1_history = lang.ucmd_menu_ct1_history or { "User", "Messages", "Chats", "[CHAT]AdvancedChat", "show chat history (latest)" }
local ucmd_menu_ct1_historyall = lang.ucmd_menu_ct1_historyall or { "User", "Messages", "Chats", "[CHAT]AdvancedChat", "show chat history (all saved)" }

local ucmd_menu_ct2_add = lang.ucmd_menu_ct2_add or { "Chats", "[CHAT]AdvancedChat", "add" }
local ucmd_menu_ct2_del = lang.ucmd_menu_ct2_del or { "Chats", "[CHAT]AdvancedChat", "remove" }

local msg_denied = lang.msg_denied or "You are not allowed to use this command!"
local msg_denied_2 = lang.msg_denied_2 or "You are not allowed to use this chat!"
local msg_usage = lang.msg_usage or "Usage: [+!#]advancedchat add|del <nick>  /  [+!#]advancedchat members"

local msg_new_member = lang.msg_new_member or "The following user was added as member: "
local msg_welcome = lang.msg_welcome or "Welcome "
local msg_already = lang.msg_already or "The following user is already a member: "
local msg_isbot = lang.msg_isbot or "User is a bot"
local msg_del = lang.msg_del or "The followig user is no longer a member: "
local msg_nomember = lang.msg_nomember or "The following user is not a member: "
local msg_intro = lang.msg_intro or "\t\t\t\t   The last %s posts from chat:"
local msg_out = lang.msg_out or [[


=== MEMBERS =========================

%s

========================= MEMBERS ===
  ]]

local msg_history = lang.msg_history or [[


========== CHATLOG ==============================================================================
%s
%s
============================================================================== CHATLOG ==========
  ]]


local msg_help_5 = lang.msg_help_5 or [[


=== HELP ==========================================

List of all in-chat commands:

%s
%s
%s
%s

========================================== HELP ===
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
local checkPermission, getMembers, checkIfMember, checkIfBot, feed, client, onbmsg, buildlog

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
    if param2 == cmd_p_members then
        local msg = utf_format( msg_out, getMembers() )
        user:reply( msg, hub_getbot() )
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



    user:reply( msg_usage, hub_getbot() )
    return PROCESSED
end

local savehistory = 0
hub.setlistener( "onPrivateMessage", {},
    function( user, targetuser, adccmd, msg )
        local cmd = utf_match( msg, "^[+!#](%S+)" )
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
                        local msg = utf_format( msg_help_5, msg_help_1, msg_help_2, msg_help_3, msg_help_4 )
                        user:reply( msg, advancedchat, advancedchat )
                        return PROCESSED
                    end
                    if cmd == cmd_members then
                        local msg = utf_format( msg_out, getMembers() )
                        user:reply( msg, advancedchat, advancedchat )
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
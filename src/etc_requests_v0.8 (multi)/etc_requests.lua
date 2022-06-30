--[[

    etc_requests.lua by pulsar

        latest changes: 2022-06-30


        description:

            - a script to request / fill releases

        warning:

            - incompatible with database of scriptversion < v0.8

        usage:

            - list of all in-chat commands:

                    [+!#]show
                    [+!#]add <release>
                    [+!#]fill <release>
                    [+!#]del <release>
                    [+!#]delold <max age in days>

                    [+!#]help
                    [+!#]history
                    [+!#]historyall
                    [+!#]historyclear

            - list of all main commands:

                    [+!#]request show
                    [+!#]request add <release>
                    [+!#]request fill <release>
                    [+!#]request del <release>
                    [+!#]request delold <max age in days>

                    [+!#]request help
                    [+!#]request history
                    [+!#]request historyall
                    [+!#]request historyclear


        v0.8: by pulsar

            - most parts of the code have been completely rewritten
                - WARNING: incompatible with database of scriptversion < v0.8
                - changed requests_file path to: "scripts/data/etc_requests.tbl"
                - new command parameters
                - removed table lookups
                - changed cmd params
                - using english comments as default
                - changed database table stucture
                - prepairing and caching output message to improve performance
                    - no more table iterations on each user login or on timer needed
                - using epoch time instead of dateparser string
                - optimize permissions
                - additional comments have been added for better understanding
                - possibility to remove releases older than n days
                - remove whitespaces from both ends of the request string
                - added optional auto deletion after n days (opt out)
                - added optional request chat bot functionality with feed export
                    - shows amount of requests/filled in bot description
                    - chat is optional (opt out)

        v0.7: by Jerker

            - Fixed problem with empty message

        v0.6:

            - Verbessert / Erweitert: Datenbank
            - Hinzugefügt: Nummerierung
            - Hinzugefügt: Datum

        v0.5:

            - Korrigiert: Fehler in Timer Funktion

        v0.4:

            - Korrigiert: Fehler in den Language-Dateien
            - Funktion: Senden der Liste beim Login
            - Änderung: Timer Funktion

        v0.3:

            - Funktion: Aktivierung / Deaktivierung der Leerstellenprüfung

        v0.2:

            - Funktion: Eingabe prüfen auf Leerstellen
            - Befehl: [+!#]request delr  / löschen aller Request Einträge
            - Befehl: [+!#]request delf  / löschen aller Filled Einträge

        v0.1:

            - initial release
]]


--------------
--[SETTINGS]--
--------------

local scriptname    = "etc_requests"
local scriptversion = "0.8"

--// imports - do not change
local scriptlang    = cfg.get( "language" )
local lang, err     = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )
local requests_file = "scripts/data/etc_requests.tbl"
local requests_tbl  = util.loadtable( requests_file )
local history_file  = "scripts/data/etc_requests_history.tbl"
local history_tbl   = util.loadtable( history_file )

--// command
local cmd                = "request"
--// parameters
local cmd_p_show         = "show"
local cmd_p_add          = "add"
local cmd_p_fill         = "fill"
local cmd_p_del          = "del"
local cmd_p_del_old      = "delold"
--// parameters if bot and chat is activated
local cmd_p_help         = "help"
local cmd_p_history      = "history"
local cmd_p_historyall   = "historyall"
local cmd_p_historyclear = "historyclear"

--// permissions
local minlevel = { -- who is allowed to use this script?

    [ 0 ]  = false, -- unreg
    [ 10 ] = false, -- guest
    [ 20 ] = true, -- reg
    [ 30 ] = true, -- vip
    [ 40 ] = true, -- svip
    [ 50 ] = true, -- server
    [ 55 ] = false,  -- sbot
    [ 60 ] = true, -- operator
    [ 70 ] = true, -- supervisor
    [ 80 ] = true, -- admin
    [ 100 ] = true, -- hubowner
}

local oplevel = { -- who is allowed to remove a database entry or clean all old entries?

    [ 0 ] = false, -- unreg
    [ 10 ] = false, -- guest
    [ 20 ] = false, -- reg
    [ 30 ] = false, -- vip
    [ 40 ] = false, -- svip
    [ 50 ] = false, -- server
    [ 55 ] = false,  -- sbot
    [ 60 ] = true, -- operator
    [ 70 ] = true, -- supervisor
    [ 80 ] = true, -- admin
    [ 100 ] = true, -- hubowner
}

--// show requests on timer? (boolean)
local sendontimer = true

--// timer
local sendtime = {

    ["03:00"] = false,
    ["06:00"] = false,
    ["09:00"] = false,
    ["12:00"] = true,
    ["15:00"] = false,
    ["18:00"] = true,
    ["21:00"] = false,
    ["23:00"] = false,
    ["00:00"] = true,
}

--// show requests on login?
local sendonlogin = false

--// check spaces of releases?
local check_spaces = true

--// remove old releases on timer?
local auto_remove       = true
local auto_remove_timer = 30 -- check every n days
local auto_remove_age   = 180 -- max age of the release in days

--// use bot?
local activate_bot      = true -- activate bot?
local nick              = "[CHAT]Requests" -- reg chat name?
local desc              = "[ CHAT ] " -- reg chat description tag

--// should the bot have a chat function?
local activate_chat     = true -- activate cats? if true then all messages will be send to the chat
local max_lines         = 300 -- history: max posts to save in database?
local default_lines     = 10 -- history: default amount of posts to show?

--// timestamp for releases
local msg_timestamp = "[ %Y-%m-%d  %X ]    "  -- lua os.date function parameters

--[[ you can use these parameters for the timestamp

    %a	abbreviated weekday name (e.g., Wed)
    %A	full weekday name (e.g., Wednesday)
    %b	abbreviated month name (e.g., Sep)
    %B	full month name (e.g., September)
    %c	date and time (e.g., 09/16/98 23:48:10)
    %d	day of the month (16) [01-31]
    %H	hour, using a 24-hour clock (23) [00-23]
    %I	hour, using a 12-hour clock (11) [01-12]
    %M	minute (48) [00-59]
    %m	month (09) [01-12]
    %p	either "am" or "pm" (pm)
    %S	second (10) [00-61]
    %w	weekday (3) [0-6 = Sunday-Saturday]
    %x	date (e.g., 09/16/98)
    %X	time (e.g., 23:48:10)
    %Y	full year (1998)
    %y	two-digit year (98) [00-99]
]]

--// messages
local help_title = lang.help_title or "etc_requests.lua"
local help_desc  = lang.help_desc  or  "a script to request / fill releases"

local msg_help_01 = lang.msg_help_01 or "[+!#]show"
local msg_help_02 = lang.msg_help_02 or "[+!#]add <release>"
local msg_help_03 = lang.msg_help_03 or "[+!#]fill <release>"
local msg_help_04 = lang.msg_help_04 or "[+!#]del <release>"
local msg_help_05 = lang.msg_help_05 or "[+!#]delold <max age in days>"

local msg_help_06 = lang.msg_help_06 or "[+!#]help"
local msg_help_07 = lang.msg_help_07 or "[+!#]history"
local msg_help_08 = lang.msg_help_08 or "[+!#]historyall"
local msg_help_09 = lang.msg_help_09 or "[+!#]historyclear"

local msg_help_10 = lang.msg_help_10 or "[+!#]request show"
local msg_help_11 = lang.msg_help_11 or "[+!#]request add <release>"
local msg_help_12 = lang.msg_help_12 or "[+!#]request fill <release>"
local msg_help_13 = lang.msg_help_13 or "[+!#]request del <release>"
local msg_help_14 = lang.msg_help_14 or "[+!#]request delold <max age in days>"

local msg_help_15 = lang.msg_help_15 or "[+!#]request help"
local msg_help_16 = lang.msg_help_16 or "[+!#]request history"
local msg_help_17 = lang.msg_help_17 or "[+!#]request historyall"
local msg_help_18 = lang.msg_help_18 or "[+!#]request historyclear"

local ucmd_relname = lang.ucmd_relname or "Releasename"
local ucmd_age     = lang.ucmd_age     or "max. age in days"
local ucmd_add     = lang.ucmd_add     or { "Requests", "add", "request" }
local ucmd_fill    = lang.ucmd_fill    or { "Requests", "add", "filled" }
local ucmd_del     = lang.ucmd_del     or { "Requests", "delete", "delete a release" }
local ucmd_del_old = lang.ucmd_del_old or { "Requests", "delete", "delete old releases" }
local ucmd_show    = lang.ucmd_show    or { "Requests", "show" }

local ucmd_menu_ct1_help         = lang.ucmd_menu_ct1_help         or { "Requests", "chat", "show help" }
local ucmd_menu_ct1_history      = lang.ucmd_menu_ct1_history      or { "Requests", "chat", "show chat history (latest)" }
local ucmd_menu_ct1_historyall   = lang.ucmd_menu_ct1_historyall   or { "Requests", "chat", "show chat history (all saved)" }
local ucmd_menu_ct1_historyclear = lang.ucmd_menu_ct1_historyclear or { "Requests", "chat", "clear history" }

local msg_denied           = lang.msg_denied           or "[ REQUESTS ]--> You are not allowed to use this command."
local msg_denied_2         = lang.msg_denied_2         or "[ REQUESTS ]--> You are not allowed to use this chat."
local msg_spaces           = lang.msg_spaces           or "[ REQUESTS ]--> Spaces in the release names are not allowed."
local msg_already_exists   = lang.msg_already_exists   or "[ REQUESTS ]--> The following release already exists: %s"
local msg_already_filled   = lang.msg_already_filled   or "[ REQUESTS ]--> The following release already filled: %s"
local msg_not_found        = lang.msg_not_found        or "[ REQUESTS ]--> The following release was not found: %s"

local msg_added_by         = lang.msg_added_by         or "[ REQUESTS ]--> Added by %s: %s"
local msg_filled_by        = lang.msg_filled_by        or "[ REQUESTS ]--> Filled by %s: %s"
local msg_deleted_by       = lang.msg_deleted_by       or "[ REQUESTS ]--> Deleted by %s: %s"
local msg_old_deleted_by   = lang.msg_old_deleted_by   or "[ REQUESTS ]--> All releases older than %s days deleted by: %s  |  deleted releases: %s"
local msg_old_deleted_auto = lang.msg_old_deleted_auto or "[ REQUESTS ]--> Auto deletion started. All releases older than %s days was deleted  |  deleted releases: %s"
local msg_no_old_rel       = lang.msg_no_old_rel       or "[ REQUESTS ]--> There is no release older than %s days."
local msg_empty_db         = lang.msg_empty_db         or "[ REQUESTS ]--> No request found."
local msg_clear            = lang.msg_clear            or "[ REQUESTS ]--> Chat history was cleared."

local msg_desc_request = lang.msg_desc_request or "Requests: "
local msg_desc_filled  = lang.msg_desc_filled  or " | Filled: "
local msg_intro        = lang.msg_intro        or "\t\t\t\t   The last %s posts from chat:"
local msg_by           = lang.msg_by           or "    [ by ]--> "
local msg_disabled     = lang.msg_disabled     or "disabled"

local msg_requests = lang.msg_requests or [[


=== REQUESTS ==================================================================================================================

    [ FILLED ]
%s
    [ REQUESTS ]
%s
================================================================================================================== REQUESTS ===
   ]]

local msg_history = lang.msg_history or [[


=== CHATLOG =====================================================================================
%s
%s
===================================================================================== CHATLOG ===
  ]]

local msg_chat_help = lang.msg_chat_help or [[


=== REQUESTS HELP ==========================================

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
                    %s

========================================== REQUESTS HELP ===
  ]]

local msg_chat_help_op = lang.msg_chat_help_op or [[


=== REQUESTS HELP ==========================================

            List of all in-chat commands:

                    %s
                    %s
                    %s
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

                    %s
                    %s
                    %s
                    %s

========================================== REQUESTS HELP ===
  ]]


----------
--[CODE]--
----------

--// defaults - do not change
local delay, start, start_auto_remove_timer = 60, os.time(), os.time()
local msg_output = ""
local saveit = 1
local cmd_chat_show, cmd_chat_add, cmd_chat_fill, cmd_chat_del, cmd_chat_del_old = "cs", "ca", "cf", "cd", "do"
local requestchat, err

--// functions
local help, ucmd, hubcmd, onbmsg
local refresh_msg_output, remove_old_releases, handle_releases
local feed, client, buildlog, clear_history
local get_rel_amount, build_description, refresh_description

--// prepair and cache output msg
refresh_msg_output = function()
    if next( requests_tbl ) == nil then -- table is empty?
        msg_output = ""
    else
        local req, fil = "\n", "\n"
        -- add all table entries to strings
        for k, v in ipairs( requests_tbl ) do
            local t = os.date( msg_timestamp, v[ 4 ] )
            if v[ 2 ] == "R" then
                req = req .. "\t" .. t .. v[ 1 ] .. msg_by .. v[ 3 ] .. "\n"
            else
                fil = fil .. "\t" .. t .. v[ 1 ] .. msg_by .. v[ 3 ] .. "\n"
            end
        end
        msg_output = utf.format( msg_requests, fil, req )
    end
end

--// function to remove old releases
remove_old_releases = function( days )
    local age = tonumber( days )
    if not age or age < 0 then
        -- invalid max age
        return false, "no_valid_age"
    else
        age = age * 60 * 60 * 24 -- calc days to seconds
    end
    local num = 0 -- counter for removed releases
    local tbl = requests_tbl
    local tbl_size = #tbl
    local i = 1
    while i <= tbl_size do
        local v = tbl[ i ]
        if v[ 4 ] < ( os.time() - age ) then
            tbl[ i ] = tbl[ tbl_size ]
            tbl[ tbl_size ] = nil
            tbl_size = tbl_size - 1
            num = num + 1
        else
            i = i + 1
        end
    end
    if num > 0 then
        return true, num
    else
        return false, "no_old_rel"
    end
end

--// chat feed
if activate_bot and activate_chat then
    feed = function( msg, dispatch )
        local from, pm
        if dispatch ~= "send" then
            dispatch = "reply"
            pm = requestchat or hub.getbot()
            from = requestchat or hub.getbot()
        end
        for sid, user in pairs( hub.getusers() ) do
            if minlevel[ user:level() ] then
                user[ dispatch ]( nil, msg, from, pm )
            end
        end
        if activate_chat then
            local str = string.find( msg, "EMSG" )
            if not str then
                local t = { [1] = os.date( "%Y-%m-%d  %H:%M:%S" ), [2] = " ", [3] = msg }
                table.insert( history_tbl,t )
                util.savearray( history_tbl, history_file )
            end
        end
    end
    client = function( bot, cmd )
        if cmd:fourcc() == "EMSG" then
            local user = hub.getuser( cmd:mysid() )
            if not user then
                return true
            end
            if not minlevel[ user:level() ] then
                user:reply( msg_denied_2, requestchat, requestchat )
                return true
            end
            cmd:setnp( "PM", bot:sid() )
            feed( cmd:adcstring(), "send" )
        end
        return true
    end
end

if activate_bot then
    --// get amount of requests and filled
    get_rel_amount = function()
        local req, fil = 0, 0
        for k, v in ipairs( requests_tbl ) do
            if v[ 2 ] == "R" then req = req + 1 else fil = fil + 1 end
        end
        return req, fil
    end
    --// generate bot description
    build_description = function()
        local req, fil = get_rel_amount()
        return desc .. msg_desc_request .. req .. msg_desc_filled .. fil
    end
    --// reg bot and add description
    requestchat, err = hub.regbot{ nick = nick, desc = build_description(), client = client }
    err = err and error( err )
    --// refresh bot description
    refresh_description = function()
        requestchat:inf():setnp( "DE", hub.escapeto( build_description() ) )
        hub.sendtoall( "BINF " .. requestchat:sid() .. " DE" .. hub.escapeto( build_description() ) .. "\n" )
    end
end

--// create history (by Motnahp)
if activate_bot and activate_chat then
    --// clear chat history
    clear_history = function()
        history_tbl = {}
        util.savearray( history_tbl, history_file )
    end
    --// generate chatlog output
    buildlog = function( amount_lines )
        local amount = ( amount_lines or default_lines )
        if amount >= max_lines then
            amount = max_lines
        end
        local log_msg = "\n"
        local lines_msg = ""
        local x = amount
        if amount > #history_tbl then
            x,amount = #history_tbl,#history_tbl
        end
        x = #history_tbl - x
        for i,v in ipairs( history_tbl ) do
            if i > x then
                log_msg = log_msg .. " [" .. i .. "] - [ " .. v[ 1 ] .. " ] <" .. v[ 2 ] .. "> " .. v[ 3 ] .. "\n"
            end
        end
        lines_msg = utf.format( msg_intro, amount )
        log_msg = utf.format( msg_history, lines_msg, log_msg )
        return log_msg
    end
end

--// release handler
handle_releases = function( user, param, rel )
    -- remove whitespaces from both ends of the request string
    local rel = util.trimstring( rel )
    -- add
    if ( param == cmd_p_add ) or ( param == cmd_chat_add ) then
        if check_spaces and string.find( rel, "%s" ) then -- check spaces in releasename
            -- send msg to user
            if param == cmd_p_add then
                user:reply( msg_spaces, hub.getbot() )
            else
                user:reply( msg_spaces, requestchat, requestchat )
            end
            return PROCESSED
        else
            local exists = false
            for k, v in ipairs( requests_tbl ) do
                -- check if request already exists
                if v[ 1 ] == rel then exists = true break end
            end
            if exists then
                -- send msg to user
                if param == cmd_p_add then
                    user:reply( utf.format( msg_already_exists, rel ), hub.getbot() )
                else
                    user:reply( utf.format( msg_already_exists, rel ), requestchat, requestchat )
                end
                return PROCESSED
            else
                -- add request to table
                table.insert( requests_tbl, { rel, "R", user.firstnick(), os.time() } )
                -- save table
                util.savetable( requests_tbl, "requests_tbl", requests_file )
                -- refresh msg_output
                refresh_msg_output()
                -- send chat feed
                if activate_bot and activate_chat then
                    feed( utf.format( msg_added_by, user:firstnick(), rel ) )
                    refresh_description()
                end
                -- send msg to all
                hub.broadcast( utf.format( msg_added_by, user:firstnick(), rel ), hub.getbot() )
                return PROCESSED
            end
        end
    end
    -- fill
    if ( param == cmd_p_fill ) or ( param == cmd_chat_fill ) then
        for k, v in ipairs( requests_tbl ) do
            if v[1] == rel then
                if v[2] == "F" then
                    -- release already filled, send msg to user
                    if param == cmd_p_fill then
                        user:reply( utf.format( msg_already_filled, rel ), hub.getbot() )
                    else
                        user:reply( utf.format( msg_already_filled, rel ), requestchat, requestchat )
                    end
                    return PROCESSED
                else
                    -- change release flag to "F"
                    v[2] = "F"
                    -- change user firstnick
                    v[3] = user:firstnick()
                    -- change time
                    v[4] = os.time()
                    -- save table
                    util.savetable( requests_tbl, "requests_tbl", requests_file )
                    -- refresh msg_output
                    refresh_msg_output()
                    if activate_bot and activate_chat then
                        -- send chat feed
                        feed( utf.format( msg_filled_by, user:firstnick(), rel ) )
                        refresh_description()
                    end
                    -- send msg to all
                    hub.broadcast( utf.format( msg_filled_by, user:firstnick(), rel ), hub.getbot() )
                    return PROCESSED
                end
            end
        end
        -- no release found, send msg to user
        if param == cmd_p_fill then
            user:reply( utf.format( msg_not_found, rel ), hub.getbot() )
        else
            user:reply( utf.format( msg_not_found, rel ), requestchat, requestchat )
        end
        return PROCESSED
    end
    -- del
    if ( param == cmd_p_del ) or ( param == cmd_chat_del ) then
        for k, v in ipairs( requests_tbl ) do
            if v[1] == rel then
                -- delete release
                table.remove( requests_tbl, k )
                -- save table
                util.savetable( requests_tbl, "requests_tbl", requests_file )
                -- refresh msg_output
                refresh_msg_output()
                if activate_bot and activate_chat then
                    -- send chat feed
                    feed( utf.format( msg_deleted_by, user:firstnick(), rel ) )
                    refresh_description()
                end
                -- send msg to all
                hub.broadcast( utf.format( msg_deleted_by, user:firstnick(), rel ), hub.getbot() )
                return PROCESSED
            end
        end
        -- no release found, send msg to user
        if param == cmd_p_del then
            user:reply( utf.format( msg_not_found, rel ), hub.getbot() )
        else
            user:reply( utf.format( msg_not_found, rel ), requestchat, requestchat )
        end
        return PROCESSED
    end
    -- delold
    if ( param == cmd_p_del_old ) or ( param == cmd_chat_del_old ) then
        local was_removed, amount = remove_old_releases( rel )
        if was_removed then
            -- save table
            util.savetable( requests_tbl, "requests_tbl", requests_file )
            -- refresh msg_output
            refresh_msg_output()
            if activate_bot and activate_chat then
                -- send chat feed
                feed( utf.format( msg_old_deleted_by, rel, user:firstnick(), amount ) )
                refresh_description()
            end
            -- send msg to all
            hub.broadcast( utf.format( msg_old_deleted_by, rel, user:firstnick(), amount ), hub.getbot() )
            return PROCESSED
        else
            if amount == "no_valid_age" then
                -- invalid max age, send msg to user
                if param == cmd_p_del_old then
                    user:reply( utf.format( msg_chat_help_op, msg_help_01, msg_help_02, msg_help_03, msg_help_04, msg_help_05, msg_help_06, msg_help_07, msg_help_08, msg_help_09,
                                            msg_help_10, msg_help_11, msg_help_12, msg_help_13, msg_help_14, msg_help_15, msg_help_16, msg_help_17, msg_help_18 ), hub.getbot() )
                else
                    user:reply( utf.format( msg_chat_help_op, msg_help_01, msg_help_02, msg_help_03, msg_help_04, msg_help_05, msg_help_06, msg_help_07, msg_help_08, msg_help_09,
                                            msg_help_10, msg_help_11, msg_help_12, msg_help_13, msg_help_14, msg_help_15, msg_help_16, msg_help_17, msg_help_18 ), requestchat, requestchat )
                end
                return PROCESSED
            elseif amount == "no_old_rel" then
                -- no release is old enough, send msg to user
                if param == cmd_p_del_old then
                    user:reply( utf.format( msg_no_old_rel, rel ), hub.getbot() )
                else
                    user:reply( utf.format( msg_no_old_rel, rel ), requestchat, requestchat )
                end
                return PROCESSED
            end
        end
    end
    -- show
    if ( param == cmd_p_show ) or ( param == cmd_chat_show ) then
        if msg_output == "" then
            -- table is empty, send msg to user
            if param == cmd_p_show then
                user:reply( msg_empty_db, hub.getbot() )
            else
                user:reply( msg_empty_db, requestchat, requestchat )
            end
        else
            -- send msg to user
            if param == cmd_p_show then
                user:reply( msg_output, hub.getbot() )
            else
                user:reply( msg_output, requestchat, requestchat )
            end
        end
        return PROCESSED
    end
end

--// chat pm
if activate_bot and activate_chat then
    hub.setlistener( "onPrivateMessage", {},
        function( user, targetuser, adccmd, msg )
            local cmd, param = utf.match( msg, "^[+!#](%S+) ?(.*)" )
            if msg and ( targetuser == requestchat ) then
                -- chatlog
                local savehistory, result = 0, 48
                result = string.byte( msg, 1 )
                if result ~= 33 and result ~= 35 and result ~= 43 then
                    savehistory = savehistory + 1
                    local data = utf.match(  msg, "(.+)" )
                    local tbl = { [1] = os.date( "%Y-%m-%d  %H:%M:%S" ), [2] = user:nick( ), [3] = data }
                    table.insert( history_tbl, tbl )
                    for x = 1, #history_tbl -  max_lines do
                        table.remove( history_tbl, 1 )
                    end
                    if savehistory >= saveit then
                        savehistory = 0
                        util.savearray( history_tbl, history_file )
                    end
                end
                -- commands
                if minlevel[ user:level() ] then
                    -- help
                    if cmd == cmd_p_help then
                        if not oplevel[ user:level() ] then
                            user:reply( utf.format( msg_chat_help, msg_help_01, msg_help_02, msg_help_03, msg_help_06, msg_help_07, msg_help_08,
                                                    msg_help_10, msg_help_11, msg_help_12, msg_help_15, msg_help_16, msg_help_17 ), requestchat, requestchat )
                        else
                            user:reply( utf.format( msg_chat_help_op, msg_help_01, msg_help_02, msg_help_03, msg_help_04, msg_help_05, msg_help_06, msg_help_07, msg_help_08, msg_help_09,
                                                    msg_help_10, msg_help_11, msg_help_12, msg_help_13, msg_help_14, msg_help_15, msg_help_16, msg_help_17, msg_help_18 ), requestchat, requestchat )
                        end
                        return PROCESSED
                    end
                    -- history
                    if cmd == cmd_p_history then
                        user:reply( buildlog( default_lines ), requestchat, requestchat )
                        return PROCESSED
                    end
                    -- historyall
                    if cmd == cmd_p_historyall then
                        user:reply( buildlog( max_lines ), requestchat, requestchat )
                        return PROCESSED
                    end
                    -- historyclear
                    if cmd == cmd_p_historyclear then
                        if oplevel[ user:level() ] then
                            clear_history()
                            user:reply( msg_clear , requestchat, requestchat )
                        else
                            user:reply( msg_denied, requestchat, requestchat )
                        end
                        return PROCESSED
                    end
                    -- add
                    if ( cmd == cmd_p_add ) and ( param ~= "" ) then
                        handle_releases( user, cmd_chat_add, param )
                        return PROCESSED
                    end
                    -- fill
                    if ( cmd == cmd_p_fill ) and ( param ~= "" ) then
                        handle_releases( user, cmd_chat_fill, param )
                        return PROCESSED
                    end
                    -- del
                    if ( cmd == cmd_p_del ) and ( param ~= "" ) then
                        if oplevel[ user:level() ] then
                            handle_releases( user, cmd_chat_del, param )
                            return PROCESSED
                        else
                            user:reply( msg_denied, requestchat, requestchat )
                            return PROCESSED
                        end
                    end
                    -- delold
                    if ( cmd == cmd_p_del_old ) and ( param ~= "" ) then
                        if oplevel[ user:level() ] then
                            handle_releases( user, cmd_chat_del_old, param )
                            return PROCESSED
                        else
                            user:reply( msg_denied, requestchat, requestchat )
                            return PROCESSED
                        end
                    end
                    -- show
                    if cmd == cmd_p_show then
                        handle_releases( user, cmd_chat_show )
                        return PROCESSED
                    end
                end
            end
            return nil
        end
    )
end

if activate_bot and activate_chat then
    hub.setlistener( "onExit", {},
        function()
            util.savearray( history_tbl, history_file )
        end
    )
end

--// check command
onbmsg = function( user, command, parameters )
    local p1, p2 = utf.match( parameters, "^(%S+) ?(.*)" )
    local p3     = utf.match( parameters, "^(%S+)$" )
    if not minlevel[ user:level() ] then
        -- no permissions, send msg to user
        user:reply( msg_denied, hub.getbot() )
        return PROCESSED
    end
    -- add
    if ( p1 == cmd_p_add ) and ( p2 ~= "" ) then
        handle_releases( user, cmd_p_add, p2 )
        return PROCESSED
    end
    -- fill
    if ( p1 == cmd_p_fill ) and ( p2 ~= "" ) then
        handle_releases( user, cmd_p_fill, p2 )
        return PROCESSED
    end
    -- del
    if ( p1 == cmd_p_del ) and ( p2 ~= "" ) then
        if not oplevel[ user:level() ] then
            -- no permissions, send msg to user
            user:reply( msg_denied, hub.getbot() )
            return PROCESSED
        else
            handle_releases( user, cmd_p_del, p2 )
            return PROCESSED
        end
    end
    -- delold
    if ( p1 == cmd_p_del_old ) and ( p2 ~= "" ) then
        if not oplevel[ user:level() ] then
            -- no permissions, send msg to user
            user:reply( msg_denied, hub.getbot() )
            return PROCESSED
        else
            handle_releases( user, cmd_p_del_old, p2 )
            return PROCESSED
        end
    end
    -- show
    if p1 == cmd_p_show then
        handle_releases( user, cmd_p_show )
        return PROCESSED
    end
    -- chat history
    if activate_bot and activate_chat then
        -- help
        if p3 == cmd_p_help then
            if not oplevel[ user:level() ] then
                user:reply( utf.format( msg_chat_help, msg_help_01, msg_help_02, msg_help_03, msg_help_06, msg_help_07, msg_help_08,
                                        msg_help_10, msg_help_11, msg_help_12, msg_help_15, msg_help_16, msg_help_17 ), hub.getbot() )
            else
                user:reply( utf.format( msg_chat_help_op, msg_help_01, msg_help_02, msg_help_03, msg_help_04, msg_help_05, msg_help_06, msg_help_07, msg_help_08, msg_help_09,
                                        msg_help_10, msg_help_11, msg_help_12, msg_help_13, msg_help_14, msg_help_15, msg_help_16, msg_help_17, msg_help_18 ), hub.getbot() )
            end
            return PROCESSED
        end
        -- history
        if p3 == cmd_p_history then
            user:reply( buildlog( default_lines ), hub.getbot() )
            return PROCESSED
        end
        -- historyall
        if p3 == cmd_p_historyall then
            user:reply( buildlog( max_lines ), hub.getbot() )
            return PROCESSED
        end
        -- historyclear
        if p3 == cmd_p_historyclear then
            if oplevel[ user:level() ] then
                clear_history()
                user:reply( msg_clear, hub.getbot() )
            else
                user:reply( msg_denied, hub.getbot() )
            end
            return PROCESSED
        end
    end
    -- command incomplete, send help to user
    if oplevel[ user:level() ] then
        if activate_bot and activate_chat then
            user:reply( utf.format( msg_chat_help_op, msg_help_01, msg_help_02, msg_help_03, msg_help_04, msg_help_05, msg_help_06, msg_help_07, msg_help_08, msg_help_09,
                                    msg_help_10, msg_help_11, msg_help_12, msg_help_13, msg_help_14, msg_help_15, msg_help_16, msg_help_17, msg_help_18 ), hub.getbot() )
        else
            user:reply( utf.format( msg_chat_help_op, msg_help_01, msg_help_02, msg_help_03, msg_help_04, msg_help_05, msg_disabled, msg_disabled, msg_disabled, msg_disabled,
                                    msg_help_10, msg_help_11, msg_help_12, msg_help_13, msg_help_14, msg_disabled, msg_disabled, msg_disabled, msg_disabled ), hub.getbot() )
        end
    else
        if activate_bot and activate_chat then
            user:reply( utf.format( msg_chat_help, msg_help_01, msg_help_02, msg_help_03, msg_help_06, msg_help_07, msg_help_08,
                                    msg_help_10, msg_help_11, msg_help_12, msg_help_15, msg_help_16, msg_help_17 ), hub.getbot() )
        else
            user:reply( utf.format( msg_chat_help, msg_help_01, msg_help_02, msg_help_03, msg_disabled, msg_disabled, msg_disabled,
                                    msg_help_10, msg_help_11, msg_help_12, msg_disabled, msg_disabled, msg_disabled ), hub.getbot() )
        end
    end
    return PROCESSED
end

--// message on login
hub.setlistener( "onLogin", {},
    function( user )
        if sendonlogin and minlevel[ user:level() ] and ( msg_output ~= "" ) then
            -- send msg to user
            user:reply( msg_output, hub.getbot() )
            return PROCESSED
        end
        if activate_bot then
            if ( not user:isbot() ) and not minlevel[ user:level() ] then
                -- hide bot in userlist (fake a disconnect)
                user:send( "IQUI " .. requestchat:sid() .. "\n" )
            end
        end
    end
)

--// message on timer
hub.setlistener( "onTimer", { },
    function()
        if os.difftime( os.time() - start ) >= delay then
            if sendtime[ os.date( "%H:%M" ) ] and sendontimer and ( msg_output ~= "" ) then
                for sid, user in pairs( hub.getusers() ) do
                    if minlevel[ user:level() ] then
                        -- send msg to user
                        user:reply( msg_output, hub.getbot() )
                    end
                end
            end
            if auto_remove then
                local remove_time = ( os.time() - start_auto_remove_timer )
                local y, d, h, m, s = util.formatseconds( remove_time )

                --TEST - shows the elapsed time
                --hub.broadcast( "\n\n\t[ TIME ]\n\n" .. "\tYears: " .. y .. "\n" ..
                --"\tDays: " .. d .. "\n" .. "\tHours: " .. h .. "\n" .. "\tMinutes: " .. m .. "\n", hub.getbot() )

                --TEST - shows the remaining time
                --local remaining = auto_remove_timer * 24 * 60 * 60 + start_auto_remove_timer - os.time()
                --local ye, da, ho, mi, se = util.formatseconds( remaining )
                --hub.broadcast( "\n\n\t[ REMAINING TIME ]\n\n" .. "\tYears: " .. ye .. "\n" ..
                --"\tDays: " .. da .. "\n" .. "\tHours: " .. ho .. "\n" .. "\tMinutes: " .. mi .. "\n", hub.getbot() )

                if d == auto_remove_timer then
                    local was_removed, amount = remove_old_releases( auto_remove_age )
                    if was_removed then
                        -- save table
                        util.savetable( requests_tbl, "requests_tbl", requests_file )
                        -- refresh msg_output
                        refresh_msg_output()
                        -- send chat feed
                        if activate_bot and activate_chat then
                            feed( utf.format( msg_old_deleted_auto, auto_remove_age, amount ) )
                            refresh_description()
                        end
                        -- send msg to all
                        hub.broadcast( utf.format( msg_old_deleted_auto, auto_remove_age, amount ), hub.getbot() )
                    end
                end
            end
            start = os.time() -- reset every 60 seconds
        end
        return nil
    end
)

hub.setlistener( "onStart", {},
    function()
        -- refresh msg output
        refresh_msg_output()
        -- get permissions for ucmd (rightclick menu)
        local minlvl = util.getlowestlevel( minlevel )
        local oplvl  = util.getlowestlevel( oplevel )
        -- hide bot in userlist (fake a disconnect)
        if activate_bot then
            for sid, user in pairs( hub.getusers() ) do
                if ( not user:isbot() ) and not minlevel[ user:level() ] then
                    user:send( "IQUI " .. requestchat:sid() .. "\n" )
                end
            end
        end
        -- import help feature
        help = hub.import( "cmd_help" )
        if help then
            local help_usage
            if activate_bot and activate_chat then
                help_usage = utf.format( msg_chat_help_op, msg_help_01, msg_help_02, msg_help_03, msg_help_04, msg_help_05, msg_disabled, msg_disabled, msg_disabled, msg_disabled,
                                         msg_help_10, msg_help_11, msg_help_12, msg_help_13, msg_help_14, msg_disabled, msg_disabled, msg_disabled, msg_disabled )
            else
                help_usage = utf.format( msg_chat_help_op, msg_help_01, msg_help_02, msg_help_03, msg_help_04, msg_help_05, msg_help_06, msg_help_07, msg_help_08, msg_help_09,
                                         msg_help_10, msg_help_11, msg_help_12, msg_help_13, msg_help_14, msg_help_15, msg_help_16, msg_help_17, msg_help_18 )
            end
            help.reg( help_title, help_usage, help_desc, minlvl )
        end
        -- user commands
        ucmd = hub.import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_add,     cmd, { cmd_p_add,     "%[line:" .. ucmd_relname .. "]" }, { "CT1" }, minlvl )
            ucmd.add( ucmd_fill,    cmd, { cmd_p_fill,    "%[line:" .. ucmd_relname .. "]" }, { "CT1" }, minlvl )
            ucmd.add( ucmd_del,     cmd, { cmd_p_del,     "%[line:" .. ucmd_relname .. "]" }, { "CT1" }, oplvl )
            ucmd.add( ucmd_del_old, cmd, { cmd_p_del_old, "%[line:" .. ucmd_age .. "]" },     { "CT1" }, oplvl )
            ucmd.add( ucmd_show,    cmd, { cmd_p_show }, { "CT1" }, minlvl )
            -- chat history
            if activate_bot then
                ucmd.add( ucmd_menu_ct1_help, cmd, { cmd_p_help }, { "CT1" }, minlvl )
            end
            if activate_bot and activate_chat then
                ucmd.add( ucmd_menu_ct1_history,      cmd, { cmd_p_history },      { "CT1" }, minlvl )
                ucmd.add( ucmd_menu_ct1_historyall,   cmd, { cmd_p_historyall },   { "CT1" }, minlvl )
                ucmd.add( ucmd_menu_ct1_historyclear, cmd, { cmd_p_historyclear }, { "CT1" }, oplvl )
            end
        end
        -- import hubcmd for "onbmsg" function
        hubcmd = hub.import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
--[[

    etc_noadvertise by pulsar
        
        v0.5:
            - code cleaning
            - multilanguage support
            - help feature
            - optimized string parser
            - added: database for settings, allowed strings, forbidden strings
            - added: rightclick:
                - toggle check mode on/off (toggle the functionality of the whole script)
                - toggle check main on/off
                - toggle ignore bots on/off
                - toggle user warning on/off
                - toggle send report to hubbot on/off (send report to hubbot or opchat)
                - show/add/remove allowed strings
                - show/add/remove forbidden strings
        
        v0.4:
            - fix: 'string.lower' output
            - added: toggle warn msgs
            - Einige optische Änderungen im Code
            
        v0.3:
            - added: 'string.lower' function, makes it easier to check 'forbiddenStrings_tbl' & 'saveTable'
              
        v0.2:
            - added: bot table, to ignore chats
            
        v0.1:
            - checks chat in main/pm


    (some code based on a script by NRJ 16/08/2006)
    
    Note: use this script really carefully! PMs are "Private" Messages and they should be private.
          the script wasn't write to impose a massive censorship! any kind of abuse from this script
          to spy PMs is lame! any hubowner has to bear responsibility to respect the privacy of the users.
          therefore keep fair, and respect the users.
          
]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_noadvertise"
local scriptversion = "0.5"

local cmd = "noad"
local cmd_p1 = "set"
local cmd_p2 = "showf"
local cmd_p3 = "addf"
local cmd_p4 = "delf"
local cmd_p5 = "showa"
local cmd_p6 = "adda"
local cmd_p7 = "dela"

--// max level to check
local checklevel = 50

--// min level to get a report (only if report is send to hubbot else report will send to opchat)
local oplevel = 60

--// min level to get rightclick (change settings)
local masterlevel = 100

--[[ default database settings are:

    checkMode = true  --> activate/deactivate the functionality of the whole script
    checkMain = true  --> check advertising in main
    ignoreBots = false  --> ignore messages who send to a bot/chat
    warnUser = true  --> send warn message to user
    sendToHubbot = true  --> if true message will be send to hubbot else message feeded to opchat

]]-- you can change this settings on the fly per command/rightclick or directly in the file

--// msgs
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )

local help_title = lang.help_title or "noAdvertise"
local help_usage = lang.help_usage or "[+!#]noad set checkMode|checkMain|ignoreBots|warnUser|sendToHubbot\nand:     [+!#]noad showf|showa|addf|adda|delf|dela <string>"
local help_desc = lang.help_desc or "checks main/pm for advertising"

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_usage_1 = lang.msg_usage_1 or "Usage: [+!#]noad set checkMode|checkMain|ignoreBots|warnUser|sendToHubbot"
local msg_usage_2 = lang.msg_usage_2 or "Usage: [+!#]noad showf|showa|addf|adda|delf|dela <string>"
local msg_prefix = lang.msg_prefix or "noAdvertise  |  "
local msg_main = lang.msg_main or " writes in main:  "
local msg_pm_1 = lang.msg_pm_1 or " writes to:  "
local msg_pm_2 = lang.msg_pm_2 or "  |  msg:  "

local msg_checkmode_1 = lang.msg_checkmode_1 or "noAdvertise  |  set check Mode: off"
local msg_checkmode_2 = lang.msg_checkmode_2 or "noAdvertise  |  set check Mode: on"
local msg_checkmain_1 = lang.msg_checkmain_1 or "noAdvertise  |  set check Main: off"
local msg_checkmain_2 = lang.msg_checkmain_2 or "noAdvertise  |  set check Main: on"
local msg_ignorebots_1 = lang.msg_ignorebots_1 or "noAdvertise  |  set check Bots: off"
local msg_ignorebots_2 = lang.msg_ignorebots_2 or "noAdvertise  |  set check Bots: on"
local msg_warnuser_1 = lang.msg_warnuser_1 or "noAdvertise  |  set warn User: off"
local msg_warnuser_2 = lang.msg_warnuser_2 or "noAdvertise  |  set warn User: on"
local msg_sendreport_1 = lang.msg_sendreport_1 or "noAdvertise  |  set report: OpChat"
local msg_sendreport_2 = lang.msg_sendreport_2 or "noAdvertise  |  set report: HubBot"
local msg_show_forbidden = lang.msg_show_forbidden or "noAdvertise  |  forbidden strings:\n\n"
local msg_add_forbidden_1 = lang.msg_add_forbidden_1 or "noAdvertise  |  forbidden string already exists: "
local msg_add_forbidden_2 = lang.msg_add_forbidden_2 or "noAdvertise  |  added forbidden string: "
local msg_del_forbidden_1 = lang.msg_del_forbidden_1 or "noAdvertise  |  forbidden string removed: "
local msg_del_forbidden_2 = lang.msg_del_forbidden_2 or "noAdvertise  |  forbidden string not found: "
local msg_show_allowed = lang.msg_show_allowed or "noAdvertise  |  allowed strings:\n\n"
local msg_add_allowed_1 = lang.msg_add_allowed_1 or "noAdvertise  |  allowed string already exists: "
local msg_add_allowed_2 = lang.msg_add_allowed_2 or "noAdvertise  |  added allowed string: "
local msg_del_allowed_1 = lang.msg_del_allowed_1 or "noAdvertise  |  allowed string removed: "
local msg_del_allowed_2 = lang.msg_del_allowed_2 or "noAdvertise  |  allowed string not found: "

local ucmd_popup = lang.ucmd_popup or "enter string:"

local ucmd_menu_set_checkmode = lang.ucmd_menu_set_checkmode or { "noAdvertise", "set", "check Mode", "on\\off" }
local ucmd_menu_set_checkmain = lang.ucmd_menu_set_checkmain or { "noAdvertise", "set", "check Main", "on\\off" }
local ucmd_menu_set_ignorebots = lang.ucmd_menu_set_ignorebots or { "noAdvertise", "set", "check Bots", "on\\off" }
local ucmd_menu_set_warnuser = lang.ucmd_menu_set_warnuser or { "noAdvertise", "set", "warn User", "on\\off" }
local ucmd_menu_set_sendtohubbot = lang.ucmd_menu_set_sendtohubbot or { "noAdvertise", "set", "send report to", "Hubbot\\OpChat" }

local ucmd_menu_show_forbidden = lang.ucmd_menu_show_forbidden or { "noAdvertise", "show", "forbidden" }
local ucmd_menu_show_allowed = lang.ucmd_menu_show_allowed or { "noAdvertise", "show", "allowed" }

local ucmd_menu_add_forbidden = lang.ucmd_menu_add_forbidden or { "noAdvertise", "add", "forbidden" }
local ucmd_menu_add_allowed = lang.ucmd_menu_add_allowed or { "noAdvertise", "add", "allowed" }

local ucmd_menu_del_forbidden = lang.ucmd_menu_del_forbidden or { "noAdvertise", "del", "forbidden" }
local ucmd_menu_del_allowed = lang.ucmd_menu_del_allowed or { "noAdvertise", "del", "allowed" }

local msg_warn = lang.msg_warn or [[ 


                        ========== ADVERTISE DETECTION ========================================

                                                          Warning: Advertising is not allowed in this hub!

                        ======================================== ADVERTISE DETECTION ==========

  ]]


----------
--[CODE]--
----------

--// table lookups
local hub_getbot = hub.getbot()
local hub_getusers = hub.getusers()
local hub_broadcast = hub.broadcast
local hub_import = hub.import
local hub_debug = hub.debug
--local hub_restartscripts = hub.restartscripts( )

local utf_match = utf.match

local util_loadtable = util.loadtable
local util_savetable = util.savetable

local table_getn = table.getn
local table_maxn = table.maxn
local table_concat = table.concat
local table_remove = table.remove

local string_find = string.find
local string_gsub = string.gsub
local string_lower = string.lower

--// functions
local checkForbidden, checkAllowed, checkPM, checkIfExists, removeString, onbmsg

--// imports
local help, ucmd, hubcmd

--// databases
local settings_file = "scripts/data/etc_noadvertise_settings.tbl"
local forbiddenStrings_file = "scripts/data/etc_noadvertise_forbidden.tbl"
local allowedStrings_file = "scripts/data/etc_noadvertise_allowed.tbl"

local settings_tbl, forbiddenStrings_tbl, allowedStrings_tbl


checkForbidden = function( s )
    local s = string_lower( string_gsub( s, "%s+", "" ) )
    for i = 1, table_getn( forbiddenStrings_tbl ) do
        if string_find( s, forbiddenStrings_tbl[ i ], 1, true ) then
            return 1
        end
    end
end

checkAllowed = function( s )
    local s = string_lower( string_gsub( s, "%s+", "" ) )
    for i = 1, table_getn( allowedStrings_tbl ) do
        if string_find( s, allowedStrings_tbl[ i ], 1, true ) then
            return 1
        end
    end
end

checkPM = function( user, targetuser, msg )
    local user_nick = user:nick()
    local user_level = user:level()
    local targetuser_nick = targetuser:nick()
    local msg2 = msg
    if settings_tbl.checkMode then
        if user_level <= checklevel then
            if checkForbidden( msg2 ) then
                if checkAllowed( msg2 ) then
                    return nil
                else
                    if settings_tbl.warnUser then
                        user:reply( msg_warn, hub_getbot, targetuser )
                    end
                    if settings_tbl.sendToHubbot then
                        for sid, user in pairs( hub_getusers ) do
                            local opuser = user:level()
                            if opuser >= oplevel then
                                user:reply( msg_prefix .. user_nick .. msg_pm_1 .. targetuser_nick .. msg_pm_2 .. msg, hub_getbot, hub_getbot )
                            end
                        end
                    else
                        local opchat = hub_import( "bot_opchat" )
                        opchat.feed( msg_prefix .. user_nick .. msg_pm_1 .. targetuser_nick .. msg_pm_2 .. msg )
                    end
                    return nil
                end
                return PROCESSED
            end
        end
    end
end

checkIfExists = function( tbl, s )
    local result = false
    local forbiddenStrings_tbl = util_loadtable( forbiddenStrings_file ) or {}
    local allowedStrings_tbl = util_loadtable( allowedStrings_file ) or {}
    for k, v in ipairs( tbl ) do
        if tbl[ k ] == s then
            result = true
        end
    end
    return result
end

removeString = function( tbl, s )
    local forbiddenStrings_tbl = util_loadtable( forbiddenStrings_file ) or {}
    local allowedStrings_tbl = util_loadtable( allowedStrings_file ) or {}
    for k, v in ipairs( tbl ) do
        if tbl[ k ] == s then
            table_remove( tbl, k )
        end
    end
end

hub.setlistener( "onBroadcast", {},
    function( user, adccmd, msg )
        local user_nick = user:nick()
        local user_level = user:level()
        settings_tbl = util_loadtable( settings_file ) or {}
        forbiddenStrings_tbl = util_loadtable( forbiddenStrings_file ) or {}
        allowedStrings_tbl = util_loadtable( allowedStrings_file ) or {}
        if not settings_tbl.checkMode then
            hub_broadcast( msg, user )
            return PROCESSED
        end
        if not settings_tbl.checkMain then
            hub_broadcast( msg, user )
            return PROCESSED
        end 
        if user_level > checklevel then
            hub_broadcast( msg, user )
            return PROCESSED
        end
        if msg then
            local msg2 = msg
            if checkForbidden( msg2 ) then
                if checkAllowed( msg2 ) then
                    hub_broadcast( msg, user )
                else
                    hub_broadcast( msg, user )
                    if settings_tbl.warnUser then
                        user:reply( msg_warn, hub_getbot )
                    end
                    if settings_tbl.sendToHubbot then
                        for sid, user in pairs( hub_getusers ) do
                            local opuser = user:level()
                            if opuser >= oplevel then
                                user:reply( msg_prefix .. user_nick .. msg_main .. msg, hub_getbot, hub_getbot )
                            end
                        end
                    else
                        local opchat = hub_import( "bot_opchat" )
                        opchat.feed( msg_prefix .. user_nick .. msg_main .. msg )
                    end
                end
                return PROCESSED
            end
        end
        return nil
    end
)

hub.setlistener( "onPrivateMessage", {},
    function( user, targetuser, adccmd, msg )
        local targetuser_nick = targetuser:nick()
        local targetuser_level = targetuser:level()
        if msg then
            if targetuser:isbot() then
                if not settings_tbl.ignoreBots then
                    checkPM( user, targetuser, msg )
                end
            else
                if targetuser_level <= checklevel then
                    checkPM( user, targetuser, msg )
                end
            end
        end
        return nil
    end
)

onbmsg = function( user, command, parameters )
    local user_level = user:level()
    settings_tbl = util_loadtable( settings_file ) or {}
    forbiddenStrings_tbl = util_loadtable( forbiddenStrings_file ) or {}
    allowedStrings_tbl = util_loadtable( allowedStrings_file ) or {}
    if user_level < masterlevel then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end
    local param, id = utf_match( parameters, "^(%S+) (%S+)" )
    local param2 = utf_match( parameters, "^(.*)" )
    --// set
    if param == cmd_p1 then
        if id == "checkMode" then
            if settings_tbl["checkMode"] then
                settings_tbl["checkMode"] = false
                user:reply( msg_checkmode_1, hub_getbot )
            else
                settings_tbl["checkMode"] = true
                user:reply( msg_checkmode_2, hub_getbot )
            end
            util_savetable( settings_tbl, "settings_tbl", settings_file )
            return PROCESSED
        elseif id == "checkMain" then
            if settings_tbl["checkMain"] then
                settings_tbl["checkMain"] = false
                user:reply( msg_checkmain_1, hub_getbot )
            else
                settings_tbl["checkMain"] = true
                user:reply( msg_checkmain_2, hub_getbot )
            end
            util_savetable( settings_tbl, "settings_tbl", settings_file )
            return PROCESSED
        elseif id == "ignoreBots" then
            if settings_tbl["ignoreBots"] then
                settings_tbl["ignoreBots"] = false
                user:reply( msg_ignorebots_1, hub_getbot )
            else
                settings_tbl["ignoreBots"] = true
                user:reply( msg_ignorebots_2, hub_getbot )
            end
            util_savetable( settings_tbl, "settings_tbl", settings_file )
            return PROCESSED
        elseif id == "warnUser" then
            if settings_tbl["warnUser"] then
                settings_tbl["warnUser"] = false
                user:reply( msg_warnuser_1, hub_getbot )
            else
                settings_tbl["warnUser"] = true
                user:reply( msg_warnuser_2, hub_getbot )
            end
            util_savetable( settings_tbl, "settings_tbl", settings_file )
            return PROCESSED
        elseif id == "sendToHubbot" then
            if settings_tbl["sendToHubbot"] then
                settings_tbl["sendToHubbot"] = false
                user:reply( msg_sendreport_1, hub_getbot )
            else
                settings_tbl["sendToHubbot"] = true
                user:reply( msg_sendreport_2, hub_getbot )
            end
            util_savetable( settings_tbl, "settings_tbl", settings_file )
            return PROCESSED
        else
            user:reply( msg_usage_1, hub_getbot )
            user:reply( msg_usage_2, hub_getbot )
            return PROCESSED
        end
    --// add forbidden
    elseif param == cmd_p3 then
        if id then
            if checkIfExists( forbiddenStrings_tbl, id ) then
                user:reply( msg_add_forbidden_1 .. tostring( id ), hub_getbot )
                return PROCESSED
            else
                local n = table_maxn( forbiddenStrings_tbl )
                local i = n + 1
                forbiddenStrings_tbl[ i ] = tostring( id )
                util_savetable( forbiddenStrings_tbl, "forbiddenStrings_tbl", forbiddenStrings_file )
                user:reply( msg_add_forbidden_2 .. tostring( id ), hub_getbot )
                return PROCESSED
            end
        else
            user:reply( msg_usage_1, hub_getbot )
            user:reply( msg_usage_2, hub_getbot )
            return PROCESSED
        end
    --// add allowed
    elseif param == cmd_p6 then
        if id then
            if checkIfExists( allowedStrings_tbl, id ) then
                user:reply( msg_add_allowed_1 .. tostring( id ), hub_getbot )
                return PROCESSED
            else
                local n = table_maxn( allowedStrings_tbl )
                local i = n + 1
                allowedStrings_tbl[ i ] = tostring( id )
                util_savetable( allowedStrings_tbl, "allowedStrings_tbl", allowedStrings_file )
                user:reply( msg_add_allowed_2 .. tostring( id ), hub_getbot )
                return PROCESSED
            end
        else
            user:reply( msg_usage_1, hub_getbot )
            user:reply( msg_usage_2, hub_getbot )
            return PROCESSED
        end
    --// del forbidden
    elseif param == cmd_p4 then
        if id then
            if checkIfExists( forbiddenStrings_tbl, id ) then
                removeString( forbiddenStrings_tbl, id )
                util_savetable( forbiddenStrings_tbl, "forbiddenStrings_tbl", forbiddenStrings_file )
                user:reply( msg_del_forbidden_1 .. tostring( id ), hub_getbot )
                return PROCESSED
            else
                user:reply( msg_del_forbidden_2 .. tostring( id ), hub_getbot )
                return PROCESSED
            end
        else
            user:reply( msg_usage_1, hub_getbot )
            user:reply( msg_usage_2, hub_getbot )
            return PROCESSED
        end
    --// del allowed
    elseif param == cmd_p7 then
        if id then
            if checkIfExists( allowedStrings_tbl, id ) then
                removeString( allowedStrings_tbl, id )
                util_savetable( allowedStrings_tbl, "allowedStrings_tbl", allowedStrings_file )
                user:reply( msg_del_allowed_1 .. tostring( id ), hub_getbot )
                return PROCESSED
            else
                user:reply( msg_del_allowed_2 .. tostring( id ), hub_getbot )
                return PROCESSED
            end
        else
            user:reply( msg_usage_1, hub_getbot )
            user:reply( msg_usage_2, hub_getbot )
            return PROCESSED
        end
    end
    --// show forbidden
    if param2 == cmd_p2 then
        local tbl = table_concat( forbiddenStrings_tbl, "\n" )
        local msg = msg_show_forbidden .. tbl .. "\n"
        user:reply( msg, hub_getbot )
        return PROCESSED
    --// show allowed
    elseif param2 == cmd_p5 then
        local tbl = table_concat( allowedStrings_tbl, "\n" )
        local msg = msg_show_allowed .. tbl .. "\n"
        user:reply( msg, hub_getbot )
        return PROCESSED
    else
        user:reply( msg_usage_1, hub_getbot )
        user:reply( msg_usage_2, hub_getbot )
        return PROCESSED
    end
    user:reply( msg_usage_1, hub_getbot )
    user:reply( msg_usage_2, hub_getbot )
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function()
        help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, masterlevel )
        end
        ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_set_checkmode, cmd, { cmd_p1, "checkMode" }, { "CT1" }, masterlevel )
            ucmd.add( ucmd_menu_set_checkmain, cmd, { cmd_p1, "checkMain" }, { "CT1" }, masterlevel )
            ucmd.add( ucmd_menu_set_ignorebots, cmd, { cmd_p1, "ignoreBots" }, { "CT1" }, masterlevel )
            ucmd.add( ucmd_menu_set_warnuser, cmd, { cmd_p1, "warnUser" }, { "CT1" }, masterlevel )
            ucmd.add( ucmd_menu_set_sendtohubbot, cmd, { cmd_p1, "sendToHubbot" }, { "CT1" }, masterlevel )
            ucmd.add( ucmd_menu_show_forbidden, cmd, { cmd_p2 }, { "CT1" }, masterlevel )
            ucmd.add( ucmd_menu_show_allowed, cmd, { cmd_p5 }, { "CT1" }, masterlevel )
            ucmd.add( ucmd_menu_add_forbidden, cmd, { cmd_p3, "%[line:" .. ucmd_popup .. "]" }, { "CT1" }, masterlevel )
            ucmd.add( ucmd_menu_add_allowed, cmd, { cmd_p6, "%[line:" .. ucmd_popup .. "]" }, { "CT1" }, masterlevel )
            ucmd.add( ucmd_menu_del_forbidden, cmd, { cmd_p4, "%[line:" .. ucmd_popup .. "]" }, { "CT1" }, masterlevel )
            ucmd.add( ucmd_menu_del_allowed, cmd, { cmd_p7, "%[line:" .. ucmd_popup .. "]" }, { "CT1" }, masterlevel )
        end
        hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )

---------
--[END]--
---------
--[[

    etc_requests_0.2 by pulsar

        Version: Luadch LUA 5.1x

        v0.1

            - Befehl: [+!#]request show  / anzeigen aller Request Einträge
            - Befehl: [+!#]request showall  / anzeigen aller Einträge
            - Befehl: [+!#]request add <relname>  / eintragen eines Request Releases
            - Befehl: [+!#]request del <relname>  / löschen eines Releases (Request/Filled)
            - Befehl: [+!#]request delall  / löschen aller Releases
            - Befehl: [+!#]filled show  / anzeigen aller Filled Releases
            - Befehl: [+!#]filled add <relname>  / eintragen eines FilledReleases

        v0.2

            - Funktion: Eingabe prüfen auf Leerstellen
            - Befehl: [+!#]request delr  / löschen aller Request Einträge
            - Befehl: [+!#]request delf  / löschen aller Filled Einträge

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_requests"
local scriptversion = "0.2"

local scriptlang = cfg.get "language"
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )

--> Befehl Request
local cmd_request = "request"
--> Parameter Request
local cmd_p_request_add = "add"
local cmd_p_request_show = "show"
local cmd_p_request_showall = "showall"
local cmd_p_request_del = "del"
local cmd_p_request_delall = "delall"
local cmd_p_request_delr = "delr"
local cmd_p_request_delf = "delf"

--> Befehl Filled
local cmd_filled = "filled"
--> Parameter Filled
local cmd_p_filled_add = "add"
local cmd_p_filled_show = "show"

--> Wer darf die normalen Befehle nutzen?
local minlevel = 20

--> Wer darf einzelne Release aus der Datenbank löschen?
local oplevel = 60

--> Wer darf alle Requests, Filled oder die kompl. Datenbank löschen?
local masterlevel = 100

--> Meldung bei fehlenden Nutzungsrechten
local msg_denied = lang.msg_denied or "Du bist nicht befugt diesen Befehl zu nutzen!"

--> Tabelle automatisch wiederholt senden (true=JA/false=NEIN)
local autorotate = true

--> Zeit der Wiederholung in Stunden
local time = 2

--> Datenbank
local releases_file = "scripts/etc_requests/releases.tbl"

--> Sonstige Nachrichten
local msg_etc_01 = lang.msg_etc_01 or "     [ von ]-> "
local msg_etc_02 = lang.msg_etc_02 or "Release requested von:   "
local msg_etc_03 = lang.msg_etc_03 or "Release Request filled von:   "
local msg_etc_04 = lang.msg_etc_04 or "Das Release wurde bereits in der Datenbank eingetragen."
local msg_etc_05 = lang.msg_etc_05 or "Das Release wurde nicht gefunden."
local msg_etc_06 = lang.msg_etc_06 or "Das Release wurde bereits als FILLED in der Datenbank eingetragen."
local msg_etc_07 = lang.msg_etc_07 or "Request: Unbekannter Parameter [2]"
local msg_etc_08 = lang.msg_etc_08 or "Filled: Unbekannter Parameter [2]"
local msg_etc_09 = lang.msg_etc_09 or "Folgendes Release wurde aus der Datenbank gelöscht:   "
local msg_etc_10 = lang.msg_etc_10 or "Alle Releases wurden aus der Datenbank gelöscht."
local msg_etc_11 = lang.msg_etc_11 or "Es wurden keine Releases in der Datenbank gefunden."
local msg_etc_12 = lang.msg_etc_12 or "Alle Releases mit dem Status REQUEST wurden gelöscht."
local msg_etc_13 = lang.msg_etc_13 or "Alle Releases mit dem Status FILLED wurden gelöscht."
local msg_etc_14 = lang.msg_etc_14 or "Fehler: In deiner Eingabe befinden sich Leerstellen, bitte überprüfen!"

--> Rechtsklickmenu/Submenu
local ucmd_menu_request_add = lang.ucmd_menu_request_add or { "Requests", "eintragen", "request" }
local ucmd_menu_filled_add = lang.ucmd_menu_filled_add or { "Requests", "eintragen", "filled" }
local ucmd_menu_request_show = lang.ucmd_menu_request_show or { "Requests", "anzeigen", "Alle Requests anzeigen" }
local ucmd_menu_filled_show = lang.ucmd_menu_filled_show or { "Requests", "anzeigen", "Alle Filled anzeigen" }
local ucmd_menu_request_showall = lang.ucmd_menu_request_showall or { "Requests", "anzeigen", "Alle anzeigen" }
local ucmd_menu_del_request = lang.ucmd_menu_del_request or { "Requests", "löschen", "Einen löschen" }
local ucmd_menu_del_requests_all_r = lang.ucmd_menu_del_requests_all_r or { "Requests", "löschen", "Alle Requests löschen" }
local ucmd_menu_del_requests_all_f = lang.ucmd_menu_del_requests_all_f or { "Requests", "löschen", "Alle Filled löschen" }
local ucmd_menu_del_requests_all = lang.ucmd_menu_del_requests_all or { "Requests", "löschen", "Alle löschen" }

local ucmd_relname = lang.ucmd_relname or "Releasename"

--> Help Funktion
local help_title = lang.help_title or "Requests"
local help_usage = lang.help_usage or "[+!#]request show / [+!#]request showall / [+!#]request add <relname> / [+!#]request del <relname> / [+!#]request delall / [+!#]filled show / [+!#]filled add <relname>"
local help_desc = lang.help_desc or  "Releases als Request eintragen"

--> Nachrichten header
local msg_header = [[


===========================================================================================================================================
                                                                                                                              REQUESTS

    ]]

--> Nachrichten footer
local msg_footer = [[

===========================================================================================================================================
    ]]


----------
--[CODE]--
----------

local hub_getbot = hub.getbot()
local hub_getusers = hub.getusers
local hub_broadcast = hub.broadcast
local utf_match = utf.match
local util_savetable = util.savetable
local util_loadtable = util.loadtable

local request_add
local request_show
local filled_add
local filled_show
local request_showall
local del_request
local del_requests_all_r
local del_requests_all_f
local del_requests_all

local delay = time * 60 * 60
local os_time = os.time
local os_difftime = os.difftime
local start = os_time()

local releases_tbl = util_loadtable( releases_file ) or {}

--> Flags
local R = "REQUEST"
local F = "FILLED"

hub.setlistener( "onBroadcast", { },
    function( user, adccmd, txt )
        local s1, s2, s3 = utf.match( txt, "^[+!#](%a+) (%a+) (.+)" )

        request_add = function()
            local user_level = user:level()
            local user_nick = user:nick()
            if user_level >= minlevel then
                local space = string.find( s3, "%s" )
                if not space then
                    local check = false
                    for rel, v in pairs( releases_tbl ) do
                        if s3 == rel then
                            check = true
                            break
                        end
                    end
                    if check then
                        user:reply( msg_etc_04, hub_getbot )
                        return PROCESSED
                    else
                        releases_tbl[ s3 ] = { [ user_nick ] = R, }
                        util_savetable( releases_tbl, "releases_tbl", releases_file )
                        hub_broadcast( msg_etc_02 .. user_nick .. ":   " .. s3, hub_getbot )
                        return PROCESSED
                    end
                else
                    user:reply( msg_etc_14, hub_getbot )
                    return PROCESSED
                end
            else
                user:reply( msg_denied, hub_getbot )
                return PROCESSED
            end
        end

        request_show = function()
            local user_level = user:level()
            if user_level >= minlevel then
                local msg = "\n"
                for rel, v in pairs( releases_tbl ) do
                    for nick, flag in pairs( v ) do
                        if flag == R then
                            msg = msg .. flag .. "\t" .. rel .. msg_etc_01 .. nick .. "\n"
                        end
                    end
                end
                user:reply( msg_header .. msg .. msg_footer, hub_getbot )
                return PROCESSED
            else
                user:reply( msg_denied, hub_getbot )
                return PROCESSED
            end
        end

        filled_add = function()
            local user_level = user:level()
            local user_nick = user:nick()
            if user_level >= minlevel then
                local space = string.find( s3, "%s" )
                if not space then
                    local check = false
                    local checkflag = false
                    for rel, v in pairs( releases_tbl ) do
                        if s3 == rel then
                            check = true
                            for nick, flag in pairs( v ) do
                                if flag == R then
                                    checkflag = true
                                end
                            end
                            break
                        end
                    end
                    if not check then
                        user:reply( msg_etc_05, hub_getbot )
                        return PROCESSED
                    end
                    if check and not checkflag then
                        user:reply( msg_etc_06, hub_getbot )
                        return PROCESSED
                    end
                    if check and checkflag then
                        releases_tbl[ s3 ] = { [ user_nick ] = F, }
                        util_savetable( releases_tbl, "releases_tbl", releases_file )
                        hub_broadcast( msg_etc_03 .. user_nick .. ":   " .. s3, hub_getbot )
                        return PROCESSED
                    end
                else
                    user:reply( msg_etc_14, hub_getbot )
                    return PROCESSED
                end
            else
                user:reply( msg_denied, hub_getbot )
                return PROCESSED
            end
        end

        filled_show = function()
            local user_level = user:level()
            if user_level >= minlevel then
                local msg = "\n"
                for rel, v in pairs( releases_tbl ) do
                    for nick, flag in pairs( v ) do
                        if flag == F then
                            msg = msg .. flag .. "\t\t" .. rel .. msg_etc_01 .. nick .. "\n"
                        end
                    end
                end
                user:reply( msg_header .. msg .. msg_footer, hub_getbot )
                return PROCESSED
            else
                user:reply( msg_denied, hub_getbot )
                return PROCESSED
            end
        end

        request_showall = function()
            local user_level = user:level()
            if user_level >= minlevel then
                local msg = "\n"
                local msg2 = "\n"
                for rel, v in pairs( releases_tbl ) do
                    for nick, flag in pairs( v ) do
                        if flag == R then
                            msg = msg .. flag .. "\t" .. rel .. msg_etc_01 .. nick .. "\n"
                        end
                        if flag == F then
                            msg2 = msg2 .. flag .. "\t\t" .. rel .. msg_etc_01 .. nick .. "\n"
                        end
                    end
                end
                user:reply( msg_header .. msg .. msg2 .. msg_footer, hub_getbot )
                return PROCESSED
            else
                user:reply( msg_denied, hub_getbot )
                return PROCESSED
            end
        end

        del_request = function()
            local user_level = user:level()
            if user_level >= oplevel then
                local check = false
                for key, value in pairs( releases_tbl ) do
                    if key == s3 then
                        check = true
                        break
                    end
                end
                if check then
                    for rel, v in pairs( releases_tbl ) do
                        if rel == s3 then
                            releases_tbl[ rel ] = nil
                            break
                        end
                    end
                    util_savetable( releases_tbl, "releases_tbl", releases_file )
                    user:reply( msg_etc_09 .. s3, hub_getbot )
                    return PROCESSED
                else
                    user:reply( msg_etc_05, hub_getbot )
                    return PROCESSED
                end
            else
                user:reply( msg_denied, hub_getbot )
                return PROCESSED
            end
        end

        del_requests_all_r = function()
            local user_level = user:level()
            if user_level >= masterlevel then
                local check = false
                for key, value in pairs( releases_tbl ) do
                    if key ~= nil then
                        check = true
                        break
                    end
                end
                if check then
                    for rel, v in pairs( releases_tbl ) do
                        for nick, flag in pairs( v ) do
                            if flag == R then
                                releases_tbl[ rel ] = nil
                            end
                        end
                    end
                    util_savetable( releases_tbl, "releases_tbl", releases_file )
                    user:reply( msg_etc_12, hub_getbot )
                    return PROCESSED
                else
                    user:reply( msg_etc_11, hub_getbot )
                    return PROCESSED
                end
            else
                user:reply( msg_denied, hub_getbot )
                return PROCESSED
            end
        end

        del_requests_all_f = function()
            local user_level = user:level()
            if user_level >= masterlevel then
                local check = false
                for key, value in pairs( releases_tbl ) do
                    if key ~= nil then
                        check = true
                        break
                    end
                end
                if check then
                    for rel, v in pairs( releases_tbl ) do
                        for nick, flag in pairs( v ) do
                            if flag == F then
                                releases_tbl[ rel ] = nil
                            end
                        end
                    end
                    util_savetable( releases_tbl, "releases_tbl", releases_file )
                    user:reply( msg_etc_13, hub_getbot )
                    return PROCESSED
                else
                    user:reply( msg_etc_11, hub_getbot )
                    return PROCESSED
                end
            else
                user:reply( msg_denied, hub_getbot )
                return PROCESSED
            end
        end

        del_requests_all = function()
            local user_level = user:level()
            if user_level >= masterlevel then
                local check = false
                for key, value in pairs( releases_tbl ) do
                    if key ~= nil then
                        check = true
                        break
                    end
                end
                if check then
                    for rel, v in pairs( releases_tbl ) do
                        releases_tbl[ rel ] = nil
                    end
                    util_savetable( releases_tbl, "releases_tbl", releases_file )
                    user:reply( msg_etc_10, hub_getbot )
                    return PROCESSED
                else
                    user:reply( msg_etc_11, hub_getbot )
                    return PROCESSED
                end
            else
                user:reply( msg_denied, hub_getbot )
                return PROCESSED
            end
        end

        --> request
        if s1 == cmd_request then
            local user_level = user:level()
            if user_level >= minlevel then
                if s2 == cmd_p_request_add then
                    request_add()
                elseif s2 == cmd_p_request_show then
                    request_show()
                elseif s2 == cmd_p_request_showall then
                    request_showall()
                elseif s2 == cmd_p_request_del then
                    del_request()
                elseif s2 == cmd_p_request_delr then
                    del_requests_all_r()
                elseif s2 == cmd_p_request_delf then
                    del_requests_all_f()
                elseif s2 == cmd_p_request_delall then
                    del_requests_all()
                else
                    user:reply( msg_etc_07, hub_getbot )
                end
                return PROCESSED
            else
                user:reply( msg_denied, hub_getbot )
                return PROCESSED
            end
        end

        --> filled
        if s1 == cmd_filled then
            local user_level = user:level()
            if user_level >= minlevel then
                if s2 == cmd_p_filled_add then
                    filled_add()
                elseif s2 == cmd_p_filled_show then
                    filled_show()
                else
                    user:reply( msg_etc_08, hub_getbot )
                end
                return PROCESSED
            else
                user:reply( msg_denied, hub_getbot )
                return PROCESSED
            end
        end
        return nil
    end
)

hub.setlistener( "onTimer", {},
    function()
        if autorotate then
            local msg = "\n"
            local msg2 = "\n"
            for rel, v in pairs( releases_tbl ) do
                for nick, flag in pairs( v ) do
                    if flag == R then
                        msg = msg .. " " .. flag .. "\t" .. rel .. msg_etc_01 .. nick .. "\n"
                    end
                    if flag == F then
                        msg2 = msg2 .. " " .. flag .. "\t\t" .. rel .. msg_etc_01 .. nick .. "\n"
                    end
                end
            end
            if os_difftime( os_time() - start ) >= delay then
                hub_broadcast( msg_header .. msg .. msg2 .. msg_footer, hub_getbot )
                start = os_time()
            end
            return nil
        else
            return nil
        end
    end
)

hub.setlistener( "onStart", {},
    function()
        local help = hub.import "cmd_help"
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        local ucmd = hub.import "etc_usercommands"
        if ucmd then
            ucmd.add( ucmd_menu_request_add, cmd_request, { cmd_p_request_add, "%[line:" .. ucmd_relname .. "]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_filled_add, cmd_filled, { cmd_p_filled_add, "%[line:" .. ucmd_relname .. "]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_request_showall, cmd_request, { cmd_p_request_showall, " " }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_request_show, cmd_request, { cmd_p_request_show, " " }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_filled_show, cmd_filled, { cmd_p_filled_show, " " }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_del_request, cmd_request, { cmd_p_request_del, "%[line:" .. ucmd_relname .. "]" }, { "CT1" }, oplevel )
            ucmd.add( ucmd_menu_del_requests_all_r, cmd_request, { cmd_p_request_delr, " " }, { "CT1" }, masterlevel )
            ucmd.add( ucmd_menu_del_requests_all_f, cmd_request, { cmd_p_request_delf, " " }, { "CT1" }, masterlevel )
            ucmd.add( ucmd_menu_del_requests_all, cmd_request, { cmd_p_request_delall, " " }, { "CT1" }, masterlevel )
        end
        return nil
    end
)

hub.debug( "** Loaded "..scriptname.."_"..scriptversion..".lua **" )

---------
--[END]--
---------
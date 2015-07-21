--[[

    etc_requests_0.1 by pulsar

        Version: Luadch LUA 5.1x

        v0.1

            - Befehl: [+!#]request show
            - Befehl: [+!#]request showall
            - Befehl: [+!#]request add <relname>
            - Befehl: [+!#]request del <relname>
            - Befehl: [+!#]request delall
            - Befehl: [+!#]filled show
            - Befehl: [+!#]filled add <relname>

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_requests"
local scriptversion = "0.1"

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

--> Befehl Filled
local cmd_filled = "filled"
--> Parameter Filled
local cmd_p_filled_add = "add"
local cmd_p_filled_show = "show"

--> Wer darf die normalen Befehle nutzen?
local minlevel = 20

--> Wer darf einzelne Release aus der Datenbank löschen?
local oplevel = 60

--> Wer darf die kompl. Datenbank löschen?
local masterlevel = 100

--> Meldung bei fehlenden Nutzungsrechten
local msg_denied = lang.msg_denied or "error loading lang file"

--> Requests/Filled Tabelle automatisch wiederholt senden (true=JA/false=NEIN)
local autorotate = true

--> Zeit der Wiederholung in Stunden
local time = 6

--> Datenbank
local releases_file = "scripts/etc_requests/releases.tbl"

--> Sonstige Nachrichten
local msg_etc_01 = lang.msg_etc_01 or "error loading lang file"
local msg_etc_02 = lang.msg_etc_02 or "error loading lang file"
local msg_etc_03 = lang.msg_etc_03 or "error loading lang file"
local msg_etc_04 = lang.msg_etc_04 or "error loading lang file"
local msg_etc_05 = lang.msg_etc_05 or "error loading lang file"
local msg_etc_06 = lang.msg_etc_06 or "error loading lang file"
local msg_etc_07 = lang.msg_etc_07 or "error loading lang file"
local msg_etc_08 = lang.msg_etc_08 or "error loading lang file"
local msg_etc_09 = lang.msg_etc_09 or "error loading lang file"
local msg_etc_10 = lang.msg_etc_10 or "error loading lang file"
local msg_etc_11 = lang.msg_etc_11 or "error loading lang file"

--> Rechtsklickmenu/Submenu
local ucmd_menu_request_add = lang.ucmd_menu_request_add or { "error loading lang file" }
local ucmd_menu_filled_add = lang.ucmd_menu_filled_add or { "error loading lang file" }
local ucmd_menu_request_show = lang.ucmd_menu_request_show or { "error loading lang file" }
local ucmd_menu_filled_show = lang.ucmd_menu_filled_show or { "error loading lang file" }
local ucmd_menu_request_showall = lang.ucmd_menu_request_showall or { "error loading lang file" }
local ucmd_menu_del_request = lang.ucmd_menu_del_request or { "error loading lang file" }
local ucmd_menu_del_requests = lang.ucmd_menu_del_requests or { "error loading lang file" }
local ucmd_relname = lang.ucmd_relname or "error loading lang file"

--> Help Funktion
local help_title = lang.help_title or "error loading lang file"
local help_usage = lang.help_usage or "error loading lang file"
local help_desc = lang.help_desc or  "error loading lang file"

--> Nachrichten header
local msg_header = [[


===========================================================================================================
                                                                                               REQUESTS

    ]]

--> Nachrichten footer
local msg_footer = [[

===========================================================================================================
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
local del_requests

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
                            msg = msg .. " " .. flag .. "\t" .. rel .. msg_etc_01 .. nick .. "\n"
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
                            msg = msg .. " " .. flag .. "\t\t" .. rel .. msg_etc_01 .. nick .. "\n"
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
                            msg = msg .. " " .. flag .. "\t" .. rel .. msg_etc_01 .. nick .. "\n"
                        end
                        if flag == F then
                            msg2 = msg2 .. " " .. flag .. "\t\t" .. rel .. msg_etc_01 .. nick .. "\n"
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
        
        del_requests = function()
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
                elseif s2 == cmd_p_request_delall then
                    del_requests()
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
            ucmd.add( ucmd_menu_request_show, cmd_request, { cmd_p_request_show, " " }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_filled_show, cmd_filled, { cmd_p_filled_show, " " }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_request_showall, cmd_request, { cmd_p_request_showall, " " }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_del_request, cmd_request, { cmd_p_request_del, "%[line:" .. ucmd_relname .. "]" }, { "CT1" }, oplevel )
            ucmd.add( ucmd_menu_del_requests, cmd_request, { cmd_p_request_delall, " " }, { "CT1" }, masterlevel )
        end
        return nil
    end
)

hub.debug( "** Loaded "..scriptname.."_"..scriptversion..".lua **" )

---------
--[END]--
---------
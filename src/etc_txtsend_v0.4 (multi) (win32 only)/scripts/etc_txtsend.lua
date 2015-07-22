--[[

    etc_txtsend by pulsar

        usage: [+!#]txtsend <textfile>

        v0.4:
            - using external lib "lfs" to get a list of all textfiles
            - generate an automatic rightclick entry for each textfile  / requested by Mr.Egg
                - rightclick will only generate if at least one textfile exists
            - read ANSI and UTF-8 textfiles
            - rewrite code, new functions, new table lookups

        v0.3:
            - added: Lang Feature (english, german)
            - some code cleanup

        v0.2:
            - code cleanup
            - added: Help Feature

        v0.1:
            - this script sends the complete content of a textfile to Main or PM

]]--



--------------
--[SETTINGS]--
--------------

local scriptname = "etc_txtsend"
local scriptversion = "0.4"

--// command
local cmd = "txtsend"

--// text destination
local send_to_main = true
local send_to_pm = false

--// minlevel to get textfiles
local minlevel = 20

--// textfile path
local txtpath = "scripts/data/textfiles/"

----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local hub_debug = hub.debug
local hub_getbot = hub.getbot()
local hub_import = hub.import
local utf_match = utf.match
local table_insert = table.insert

--// imports
local help, ucmd, hubcmd
local scriptlang = cfg_get( "language" )
local lfs = require "lfs"

--// msgs
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )

local help_title = lang.help_title or "txtsend"
local help_usage = lang.help_usage or "[+!#]txtsend <textfile>"
local help_desc = lang.help_desc or "this script sends the complete content of a textfile to Main or PM"

local msg_denied = lang.msg_denied or "You are not allowed to use this command!"
local msg_notfound = lang.msg_notfound or "The following textfile was not found: "
local msg_usage = lang.msg_usage or "Usage: [+!#]txtsend <textfile>"

local ucmd_menu_01 = lang.ucmd_menu_01 or "User"
local ucmd_menu_02 = lang.ucmd_menu_02 or "Messages"
local ucmd_menu_03 = lang.ucmd_menu_03 or "send textfile"


----------
--[CODE]--
----------

local getfiles = function()
    local tbl = {}
    for file in lfs.dir( txtpath ) do
        if not ( file == "." or file == ".." ) then
            if file then table_insert( tbl, file ) end
        end
    end
    return tbl
end

local readfile = function( file )
    local f = io.open( txtpath .. file, "r" )
    if f then
        local msg = f:read( "*a" ); f:close()
        return "\n\n" .. msg .. "\n"
    else
        return msg_notfound .. txtpath .. file
    end
end

local onbmsg = function( user, command, parameters )
    local user_level = user:level()
    if user_level < minlevel then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end
    local param = utf_match( parameters, "^(.+)$" )
    if param then
        if send_to_main then
            user:reply( readfile( param ), hub_getbot )
            return PROCESSED
        end
        if send_to_pm then
            user:reply( readfile( param ), hub_getbot, hub_getbot )
            return PROCESSED
        end
    else
        user:reply( msg_usage, hub_getbot )
        return PROCESSED
    end
end

hub.setlistener( "onStart", {},
    function()
        help = hub_import( "cmd_help" )
        if help then help.reg( help_title, help_usage, help_desc, minlevel ) end
        ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            if next( getfiles() ) ~= nil then
                for _, file in ipairs( getfiles() ) do
                    ucmd.add( { ucmd_menu_01, ucmd_menu_02, ucmd_menu_03, file } , cmd, { file }, { "CT1" }, minlevel )
                end
            end
        end
        hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
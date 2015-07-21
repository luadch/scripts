--[[

    etc_txtsend by pulsar

        v0.3:
            - added: Lang Feature (english, german)
            - some code cleanup

        v0.2:
            - code cleanup
            - added: Help Feature

        v0.1:
            - this script sends the complete content of a textfile to Main or PM


    usage: [+!#]txtsend <filename>    <- (without .txt)
    important: the textfiles must be UTF-8

]]--



--------------
--[SETTINGS]--
--------------

local scriptname = "etc_txtsend"
local scriptversion = "0.3"

--// command
local cmd = "txtsend"

--// text destination (1=MAIN/2=PM)
local sendmode = 1

--// minlevel to send textfiles
local minlevel = 20

--// textfile path
local txtpath = "scripts/data/textfiles/"

--// msgs

local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )

local help_title = lang.help_title or "txtsend"
local help_usage = lang.help_usage or "[+!#]txtsend <filename>    <- (without .txt)"
local help_desc = lang.help_desc or "this script sends the complete content of a textfile to Main or PM"

local msg_denied = lang.msg_denied or "You are not allowed to use this command!"
local msg_notfound = lang.msg_notfound or "The following textfile was not found: "

local ucmd_menu = lang.ucmd_menu or { "User", "Messages", "send textfile" }

--// table lookups
local hub_getbot = hub.getbot()

--// imports
local help, ucmd


----------
--[CODE]--
----------

hub.setlistener( "onBroadcast", {},
    function( user, adccmd, txt )
        local cmd1, cmd2 = utf.match( txt, "^[+!#](%S+) (.+)" )
        local user_level = user:level()
        if cmd1 == cmd and cmd2 then
            if user_level >= minlevel then
                local file = io.open( txtpath .. cmd2 .. ".txt", "r" )
                local msg
                if file == nil then
                    user:reply( msg_notfound .. txtpath .. cmd2 .. ".txt", hub_getbot )
                    return PROCESSED
                else
                    msg = file:read( "*a" )
                    file:close()
                end
                if sendmode == 1 then
                    user:reply( "\n\n" .. msg, hub_getbot )
                    return PROCESSED
                end
                if sendmode == 2 then
                    user:reply( "\n\n" .. msg, hub_getbot, hub_getbot )
                    return PROCESSED
                end
            else
                user:reply( msg_denied, hub_getbot )
                return PROCESSED
            end
        end
    end
)

hub.setlistener( "onStart", {},
    function()
        help = hub.import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        ucmd = hub.import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu, cmd, { "%[line:filename?]" }, { "CT1" }, minlevel )
        end
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
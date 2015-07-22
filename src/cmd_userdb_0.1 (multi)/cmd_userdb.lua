--[[

	cmd_userdb_0.1 by pulsar

	Version: Luadch LUA 5.1x
		- Dieses Script sendet den Inhalt der 'user.tbl' als PM

]]--

--[SETTINGS]

local scriptname = "cmd_userdb"
local scriptlang = cfg.get "language"

local minlevel = 100    -- minimum level to get the help/ucmd

local permission = {    -- who is allowed to use this command?

   		[ 0 ] = false,  --> UNREG
		[ 10 ] = false,  --> GAST
		[ 20 ] = false,  --> REG
		[ 30 ] = false,  --> VIP
		[ 40 ] = false,  --> SVIP
		[ 50 ] = false,  --> VERTEILER
		[ 60 ] = false,  --> OPERATOR
		[ 70 ] = false,  --> SUPERVISOR
		[ 80 ] = false,  --> ADMIN
		[ 100 ] = true,  --> MASTER

}

local cmd = "userdb"


--[CODE]

local utf_match = utf.match

local path = "cfg/user.tbl"

local lang, err = cfg.loadlanguage(scriptlang, scriptname); lang = lang or { }; err = err and hub.debug(err)

local help_title = lang.help_title or "userdb"
local help_usage = lang.help_usage or "[+!#]userdb"
local help_desc = lang.help_desc or "sendet user.tbl in PM"

local ucmd_menu = lang.ucmd_menu or { "Zeige userdb" }

local msg_denied = lang.msg_denied or "Du bist nicht berechtigt diesen Befehl zu nutzen!"

hub:setListener("onStart", { },
    function()
        local help = hub.import "cmd_help"
        if help then
            help.reg(help_title, help_usage, help_desc, minlevel)
        end
        local ucmd = hub.import "etc_usercommands"    -- add usercommand
        if ucmd then
            ucmd.add(ucmd_menu, cmd, { }, { "CT1" }, minlevel)
        end
        return nil
    end
)

hub:setListener("onBroadcast", { },
    function(user, adccmd, txt)
        local command, parameters = utf_match(txt, "^[+!#](%a+) ?(.*)")
        if command == cmd then
            if not permission[user:getLevel()] then
                user:reply(msg_denied, hub.getbot())
                return PROCESSED
            end
            local log
            local file, err = io.open(path, "r")
            if file then
                log = file:read("*a")
                file:close()
            end
            user:reply(log, hub.getbot(), hub.getbot())
            return PROCESSED
        end
        return nil
    end
)

hub.debug("** Loaded " .. scriptname .. ".lua **")
--[[
        "cmd_mainclear.lua" v0.02 by Motnahp
        
        - Anzahl der zeilen können nun eingestellt werden.
        - sends a few empty lines to mainchat and seems to clear it 

]]--


--[Settings}

local scriptname = "cmd_mainclear"
local min_level = 60
local msg_denid = "Du bist nicht befugt diesen Befehl zu benutzen."

local help_title = "Clear"
local help_usage = "[+!#]clear"
local help_desc = "sends a few empty lines to mainchat and seems to clear it"
local cmd = "clear"
local hubcmd
local ucmd_menu = { "OP-Menü", "Main säubern" }
local emptylines = 7500
local hub_bot = hub.getbot()

local msg = string.rep("\n",emptylines)


--[Code]

local onbmsg = function( user)
    if user:level() < min_level then
        user:reply(msg_denid, hub_bot)
    else
        msg = msg.."\t Mainclean durchgeführt von "..user:nick()
        hub.broadcast(msg, hub_bot)
    end
    return PROCESSED
end

hub.setlistener( "onStart", { },
    function( )
        local help = hub.import "cmd_help"
        if help then
            help.reg( help_title, help_usage, help_desc, min_level )    -- reg help
        end
        local ucmd = hub.import "etc_usercommands"    -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu, cmd, { }, { "CT1" }, min_level )
        end
        hubcmd = hub.import "etc_hubcommands"    -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)
hub.debug("** Loaded "..scriptname..".lua **")

--[END]
 	  	 

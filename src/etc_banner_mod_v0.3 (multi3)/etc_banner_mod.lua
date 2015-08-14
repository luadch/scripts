--[[

    etc_banner_mod.lua

        - this script sends a banner in regular intervals to mainchat
        - message and timeinterval are configurable via ucmd
        - based on etc_banner.lua v0.09 of luadch

        v0.03: by Sopor
            - added Swedish
            - updated Luadch URL
            - msg_denied sentence is now using the same words as Luadch do
            - a small typo

        v0.02: by motnahp
            - registers command [+!#]banner [show|set_msg <text>|set_time <time>]
                - 'show' shows the banner
                - 'set_msg <text>' sets <text> as new banner text
                - 'set_time <time>' sets <time> as new time interval

        v0.01: by motnahp
            - initial script version
]]--



--------------
--[SETTINGS]--
--------------

local scriptname = "etc_banner_mod"
local scriptversion = "0.03"

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local scriptlang = cfg_get( "language" )
local util_savetable = util.savetable
local util_loadtable = util.loadtable
local utf_format = utf.format
local utf_match = utf.match
local os_time = os.time
local os_difftime = os.difftime
local hubcmd, help

--// imports
local banner_tbl_name = "etc_banner_mod"
local banner_path = "scripts/data/"..banner_tbl_name..".tbl"
local banner_tbl = util_loadtable(banner_path)
local banner, disabled
local banner_skeleton, msg, time = banner_tbl.banner, banner_tbl.msg, banner_tbl.time
if banner_skeleton and msg and time then
    banner = utf_format( banner_skeleton, msg )
    disabled = false
else
    banner = cfg_get( "etc_banner_banner" )
    disabled = true
end

local destination_main = cfg_get( "etc_banner_destination_main" )
local destination_pm = cfg_get( "etc_banner_destination_pm" )
local permission = {
        -- adapted from etc_banner_permision
        [ 0 ] = false,  -- unreg
        [ 10 ] = true,  -- guest
        [ 20 ] = true,  -- reg
        [ 30 ] = true,  -- vip
        [ 40 ] = true,  -- svip
        [ 50 ] = true,  -- server
        [ 55 ] = false,  -- sbot
        [ 60 ] = true,  -- operator
        [ 70 ] = true,  -- supervisor
        [ 80 ] = true,  -- admin
        [ 100 ] = true,  -- hubowner

}

local activate = cfg_get( "etc_banner_activate" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )


--// msgs
local ucmd_menu_show = lang.ucmd_menu_show or { "Crew Commands", "Banner", "Show Banner" }
local ucmd_menu_set_msg = lang.ucmd_menu_set_msg or { "Crew Commands", "Banner", "Set Banner" }
local ucmd_menu_set_time = lang.ucmd_menu_set_time or { "Crew Commands", "Banner", "Set Interval" }

local msg_usage = lang.msg_usage or "Usage: [+!#]banner show and [+!#]banner set_msg <text> and [+!#]banner set_time <time>"
local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_time = lang.msg_time or "The Banner will be send every %s hours."

local help_title = lang.help_title or  "Banner"
local help_usage = lang.help_usage or "[+!#]banner [show|set_msg <text>|set_time <time>]"
local help_desc = lang.help_desc or "show shows the banner | set_msg <text> sets <text> as banner text | set_time <time> sets <time> as time interval."

local ucmd_popup1 = lang.ucmd_popup1 or "Enter the new banner text."
local ucmd_popup2 = lang.ucmd_popup2 or "Enter the new banner interval (in hours)."

local min_level = 60
local cmd = "banner"
local prm1 = "show"
local prm2 = "set_msg"
local prm3 = "set_time"


----------
--[CODE]--
----------


local delay = time * 60 * 60
local start = os_time()

local hub_getusers = hub.getusers
local hub_getbot = hub.getbot()

local check = function()
    for sid, user in pairs( hub_getusers() ) do
        local user_level = user:level()
        local user_isbot = user:isbot()
        if not user_isbot then
            if permission[ user_level ] then
                if destination_main then
                    user:reply( banner, hub_getbot )
                end
                if destination_pm then
                    user:reply( banner, hub_getbot, hub_getbot )
                end
            end
        end
    end
end

hub.setlistener( "onTimer", { },
    function()
        if activate then
            if os_difftime( os_time() - start ) >= delay then
                check()
                start = os_time()
            end
        end
        return nil
    end
)
local onbmsg = function( user, adccmd, parameters )
    if disabled then
        user:reply("files incomplete or unable to load", hub_getbot)
        return PROCESSED
    end

    local local_prms = parameters.." "
    local user_level = user:level( )
    local id, others = utf_match( local_prms, "^(%S+) (.*)" )

    if id == prm1 then  -- show
        if user_level >= min_level then
            user:reply( banner, hub_getbot )
            user:reply( utf_format(msg_time, time), hub_getbot )
        else
            user:reply( msg_denied, hub_getbot)
        end
        return PROCESSED
    end

    if id == prm2 then  -- set_msg
        if user_level >= min_level then 
            banner_tbl.msg = others
            hub.debug(banner_tbl)
            util_savetable( banner_tbl, banner_tbl_name, banner_path )
            banner = utf_format( banner_skeleton, others )
            user:reply( banner, hub_getbot )
        else
            user:reply( msg_denied, hub_getbot )
        end
        return PROCESSED
    end
    if id == prm3 then  -- set_time
        if user_level >= min_level then 
            banner_tbl.time = others
            time = banner_tbl.time
            delay = time * 60 * 60
            util_savetable( banner_tbl, banner_tbl_name, banner_path )
            user:reply( utf_format(msg_time, time), hub_getbot )
        else
            user:reply( msg_denied, hub_getbot )
        end
        return PROCESSED
    end

    user:reply( msg_usage, hub_getbot )  -- if no id hittes
    return PROCESSED
end

hub.setlistener( "onStart", { },
    function( )
        local ucmd = hub.import "etc_usercommands"    -- add usercommand
        if help then
            help.reg( help_title, help_usage, help_desc, min_level )
        end
        if ucmd then
            ucmd.add( ucmd_menu_show, cmd, { prm1 }, { "CT1" }, min_level ) 
			ucmd.add( ucmd_menu_set_msg, cmd, { prm2, "%[line:" .. ucmd_popup1 .. "]" }, { "CT1" }, min_level )
			ucmd.add( ucmd_menu_set_time, cmd, { prm3, "%[line:" .. ucmd_popup2 .. "]" }, { "CT1" }, min_level )
		end
        hubcmd = hub.import "etc_hubcommands"    -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )

---------
--[END]--
---------
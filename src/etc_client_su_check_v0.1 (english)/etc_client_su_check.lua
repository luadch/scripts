--[[

    etc_client_su_check.lua by pulsar

        v0.1
            - this script checks the "SU" string of the clients "INF" for the presence of various features
]]


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_client_su_check"
local scriptversion = "0.1"

--// Checked users
local checked_levels = {

    [ 0 ] = true,  -- unreg
    [ 10 ] = true,  -- guest
    [ 20 ] = true,  -- reg
    [ 30 ] = true,  -- vip
    [ 40 ] = false,  -- svip
    [ 50 ] = false,  -- server
    [ 55 ] = false,  -- sbot
    [ 60 ] = false,  -- operator
    [ 70 ] = false,  -- supervisor
    [ 80 ] = false,  -- admin
    [ 100 ] = false,  -- hubowner
}

local checked_flags = {

    --// ADC Protocol

    [ "BASE" ] = true,  -- https://adc.sourceforge.io/ADC.html#_base
    [ "TCP4" ] = true,  -- https://adc.sourceforge.io/ADC.html#_tcp4_tcp6
    [ "TCP6" ] = true,  -- https://adc.sourceforge.io/ADC.html#_tcp4_tcp6
    [ "UDP4" ] = true,  -- https://adc.sourceforge.io/ADC.html#_udp4_udp6
    [ "UDP6" ] = true,  -- https://adc.sourceforge.io/ADC.html#_udp4_udp6

    --// ADC Extensions

    [ "SEGA" ] = true,  -- Grouping of file extensions in SCH: https://adc.sourceforge.io/ADC-EXT.html#_sega_grouping_of_file_extensions_in_sch
    [ "ADCS" ] = true,  -- Symmetrical Encryption in ADC: https://adc.sourceforge.io/ADC-EXT.html#_adcs_symmetrical_encryption_in_adc
    [ "ASCH" ] = true,  -- Extended searching capability: https://adc.sourceforge.io/ADC-EXT.html#_asch_extended_searching_capability
    [ "SUDP" ] = true,  -- Encrypting UDP traffic: https://adc.sourceforge.io/ADC-EXT.html#_sudp_encrypting_udp_traffic
    [ "TYPE" ] = true,  -- Typing notification: https://adc.sourceforge.io/ADC-EXT.html#_type_typing_notification
    [ "FEED" ] = true,  -- RSS feeds: https://adc.sourceforge.io/ADC-EXT.html#_feed_rss_feeds
    [ "DFAV" ] = true,  -- Distributed Favorites: https://adc.sourceforge.io/ADC-EXT.html#_dfav_distributed_favorites
    [ "NATT" ] = true,  -- NAT traversal: https://adc.sourceforge.io/ADC-EXT.html#_natt_nat_traversal
    [ "ONID" ] = true,  -- Online identification: https://adc.sourceforge.io/ADC-EXT.html#_onid_online_identification

    --// DC++ / AirDC++ Extensions

    [ "CCPM" ] = true,  -- CCPM / CPMI - Client to Client Private Message: https://forum.dcbase.org/viewtopic.php?f=55&t=724&sid=71c7026976992ddd7ed3ca6e4868424b&start=10

    --// Not found in any reference

    [ "ADC0" ] = true,  -- If the client "Settings/Security/Use TLS" option is set, then the client sends this flag

}

--// Report
local report_activate = true  -- send status report? (boolean)
local report_hubbot = false  -- send report as hubbot msg? (boolean)
local report_opchat = true  -- send report as opchat feed? (boolean)
local report_level = 60  -- min level to get a report? (only for hubbot msg) (integer)
local msg_report = "[ CLIENT SU CHECK ]--> User:  %s  |  Missing flag(s):  %s"

--// Disconnect client on missing flag
local disconnect = false
local msg_disconnect = "[ CLIENT SU CHECK ]--> You were disconnected because of missing client flag(s) in SU: %s"
local msg_disconnect_report = "[ CLIENT SU CHECK ]--> User:  %s  |  were disconnected because of missing flag(s) in SU: %s"


----------
--[CODE]--
----------

--// Imports
local report = hub.import( "etc_report" )

local check_su = function( user, su )
    local flags, msg, s, e = "", "", "", ""
    if checked_levels[ user:level() ] then
        for flag, check in pairs( checked_flags ) do
            if check then
                s, e = string.find( su, flag )
                if s then flags = flags .. flag .. " " end
            end
        end
        if flags ~= "" then
            local msg = utf.format( msg_report, user:nick(), flags )
            report.send( report_activate, report_hubbot, report_opchat, report_level, msg )
            if disconnect then
                msg = utf.format( msg_disconnect, flags )
                user:kill( "ISTA 230 " .. hub.escapeto( msg ) .. "\n", "TL-1" )
                msg = utf.format( msg_disconnect_report, user:nick(), flags )
                report.send( report_activate, report_hubbot, report_opchat, report_level, msg )
            end
        end
    end
end

local connect_listener = function( user )
    local cmd = user:inf()
    local su = cmd:getnp( "SU" )
    if su then check_su( user, su ) end
    return nil
end

local inf_listener = function( user, cmd )
    local su = cmd:getnp( "SU" )
    if su then check_su( user, su ) end
    return nil
end

local ctm_listener = function( user, target, cmd )
    local su = cmd:getnp( "SU" )
    if su then check_su( user, su ) end
    return nil
end

local rctm_listener = function( user, target, cmd )
    local su = cmd:getnp( "SU" )
    if su then check_su( user, su ) end
    return nil
end

hub.setlistener( "onConnect", { }, connect_listener )
hub.setlistener( "onInf", { }, inf_listener )
hub.setlistener( "onConnectToMe", { }, ctm_listener )
hub.setlistener( "onRevConnectToMe", { }, rctm_listener )

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
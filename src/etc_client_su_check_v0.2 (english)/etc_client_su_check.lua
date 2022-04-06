--[[

    etc_client_su_check.lua by pulsar

        v0.2
            - check for the presence AND absence of various features

        v0.1
            - this script checks the "SU" string of the clients "INF" for the presence of various features
]]


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_client_su_check"
local scriptversion = "0.2"

local checked_levels = {  -- Checked users

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

local checked_flags = {  -- mode: 0 = no check / 1 = check for presence / 2 = check for absence

    --// ADC Protocol

    [ "BASE" ] = 0,  -- https://adc.sourceforge.io/ADC.html#_base
    [ "TCP4" ] = 0,  -- https://adc.sourceforge.io/ADC.html#_tcp4_tcp6
    [ "TCP6" ] = 0,  -- https://adc.sourceforge.io/ADC.html#_tcp4_tcp6
    [ "UDP4" ] = 0,  -- https://adc.sourceforge.io/ADC.html#_udp4_udp6
    [ "UDP6" ] = 0,  -- https://adc.sourceforge.io/ADC.html#_udp4_udp6

    --// ADC Extensions

    [ "SEGA" ] = 0,  -- Grouping of file extensions in SCH: https://adc.sourceforge.io/ADC-EXT.html#_sega_grouping_of_file_extensions_in_sch
    [ "ADCS" ] = 2,  -- Symmetrical Encryption in ADC: https://adc.sourceforge.io/ADC-EXT.html#_adcs_symmetrical_encryption_in_adc
    [ "ASCH" ] = 0,  -- Extended searching capability: https://adc.sourceforge.io/ADC-EXT.html#_asch_extended_searching_capability
    [ "SUDP" ] = 2,  -- Encrypting UDP traffic: https://adc.sourceforge.io/ADC-EXT.html#_sudp_encrypting_udp_traffic
    [ "TYPE" ] = 0,  -- Typing notification: https://adc.sourceforge.io/ADC-EXT.html#_type_typing_notification
    [ "FEED" ] = 1,  -- RSS feeds: https://adc.sourceforge.io/ADC-EXT.html#_feed_rss_feeds
    [ "DFAV" ] = 0,  -- Distributed Favorites: https://adc.sourceforge.io/ADC-EXT.html#_dfav_distributed_favorites
    [ "NATT" ] = 0,  -- NAT traversal: https://adc.sourceforge.io/ADC-EXT.html#_natt_nat_traversal
    [ "ONID" ] = 1,  -- Online identification: https://adc.sourceforge.io/ADC-EXT.html#_onid_online_identification

    --// DC++ / AirDC++ Extensions

    [ "CCPM" ] = 2,  -- CCPM / CPMI - Client to Client Private Message: https://forum.dcbase.org/viewtopic.php?f=55&t=724&sid=71c7026976992ddd7ed3ca6e4868424b&start=10

    --// Not found in any reference

    [ "ADC0" ] = 2,  -- If the client "Settings/Security/Use TLS" option is set, then the client sends this flag

}

--// Report
local report_activate = true  -- send status report? (boolean)
local report_hubbot = false  -- send report as hubbot msg? (boolean)
local report_opchat = true  -- send report as opchat feed? (boolean)
local report_level = 60  -- min level to get a report? (only for hubbot msg) (integer)

--// Disconnect client if found "1" flag(s) / or missing "2" flag(S)
local disconnect = true

--// Messages
local msg_not_found = "not found"
local msg_dis = ""; if disconnect then msg_dis = "YES" else msg_dis = "NO" end
local msg_report = "[ CLIENT SU CHECK ]--> User: %s  |  forbidden flag(s):  %s  |  missing flag(s):  %s  |  disconnected:  %s"
local msg_disconnect = "[ CLIENT SU CHECK ]--> You were disconnected because: forbidden client feature(s):  %s  |  missing client feature(s):  %s"


----------
--[CODE]--
----------

--// Imports
local report = hub.import( "etc_report" )

local check_su = function( user, su )
    local flags_mode1, flags_mode2, msg, s, e = "", "", "", "", ""
    if checked_levels[ user:level() ] then
        for flag, check in pairs( checked_flags ) do
            s, e = string.find( su, flag )
            if s and ( check == 1 ) then
                flags_mode1 = flags_mode1 .. flag .. " "
            end
            if not s and ( check == 2 ) then
                flags_mode2 = flags_mode2 .. flag .. " "
            end
        end
        if ( flags_mode1 ~= "" ) or ( flags_mode2 ~= "" ) then
            if flags_mode1 == "" then flags_mode1 = msg_not_found end
            if flags_mode2 == "" then flags_mode2 = msg_not_found end
            --// Report
            local msg = utf.format( msg_report, user:nick(), flags_mode1, flags_mode2, msg_dis )
            report.send( report_activate, report_hubbot, report_opchat, report_level, msg )
            --// Disconnect
            if disconnect then
                msg = utf.format( msg_disconnect, flags_mode1, flags_mode2 )
                user:kill( "ISTA 230 " .. hub.escapeto( msg ) .. "\n", "TL-1" )
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
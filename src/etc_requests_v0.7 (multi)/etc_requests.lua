--[[

	etc_requests by pulsar

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

		v0.3

			- Funktion: Aktivierung / Deaktivierung der Leerstellenprüfung

		v0.4

			- Korrigiert: Fehler in den Language-Dateien
			- Funktion: Senden der Liste beim Login
			- Änderung: Timer Funktion

		v0.5

			- Korrigiert: Fehler in Timer Funktion

		v0.6

			- Verbessert / Erweitert: Datenbank
			- Hinzugefügt: Nummerierung
			- Hinzugefügt: Datum

		v0.7: by Jerker

			- Fixed problem with empty message

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_requests"
local scriptversion = "0.7"

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
local cmd_p_request_showdel = "showdel"

--> Befehl Filled
local cmd_filled = "filled"
--> Parameter Filled
local cmd_p_filled_add = "add"
local cmd_p_filled_show = "show"

--> Wer darf die normalen Befehle nutzen?
local minlevel = 10

--> Wer darf einzelne Release aus der Datenbank löschen?
local oplevel = 60

--> Wer darf alle Requests, Filled oder die kompl. Datenbank löschen?
local masterlevel = 100

--> An welche Level soll die Tabelle beim Login bzw. Timer gesendet werden? (true=JA/false=NEIN)
local sendto = {

	[ 0 ] = false, --> unreg
	[ 10 ] = true, --> guest
	[ 20 ] = true, --> reg
	[ 30 ] = true, --> vip
	[ 40 ] = true, --> svip
	[ 50 ] = true, --> server
	[ 60 ] = true, --> operator
	[ 70 ] = true, --> supervisor
	[ 80 ] = true, --> admin
	[ 100 ] = true, --> hubowner
}

--> Wann soll die Tabelle verschickt werden?
local sendtime = {

	["03:00"] = true,
	["06:00"] = true,
	["09:00"] = true,
	["12:00"] = true,
	["15:00"] = true,
	["18:00"] = true,
	["21:00"] = true,
	["23:00"] = true,
	["00:00"] = true,

}

--> Tabelle beim Login in den Hub senden? (true=JA/false=NEIN)
local sendonconnect = true

--> Soll auf Leerstellen geprüft werden? (true=JA/false=NEIN)
local check_spaces = true

--> Datenbank
local requests_file = "scripts/etc_requests/releases.tbl"

--> Meldung bei fehlenden Nutzungsrechten
local msg_denied = lang.msg_denied or "Du bist nicht befugt diesen Befehl zu nutzen!"

--> Sonstige Nachrichten
local msgs = {

msg_etc_001 = lang.msg_etc_001 or "   |   von: ",
msg_etc_002 = lang.msg_etc_002 or "   |   requested von: ",
msg_etc_003 = lang.msg_etc_003 or "   |   filled von: ",
msg_etc_004 = lang.msg_etc_004 or "   |   gelöscht von: ",
msg_etc_005 = lang.msg_etc_005 or "REQUEST      ",
msg_etc_006 = lang.msg_etc_006 or "FILLED       ",
msg_etc_007 = lang.msg_etc_007 or "DELETED      ",
msg_etc_008 = lang.msg_etc_008 or "ID: ",
msg_etc_009 = lang.msg_etc_009 or "Release requested von:   ",
msg_etc_010 = lang.msg_etc_010 or "Release Request filled von:   ",

msg_etc_101 = lang.msg_etc_101 or "Folgendes Release wurde aus der Datenbank gelöscht:   ",
msg_etc_102 = lang.msg_etc_102 or "Alle Releases wurden aus der Datenbank gelöscht.",
msg_etc_103 = lang.msg_etc_103 or "Alle Releases mit dem Status REQUEST wurden gelöscht.",
msg_etc_104 = lang.msg_etc_104 or "Alle Releases mit dem Status FILLED wurden gelöscht.",

msg_etc_201 = lang.msg_etc_201 or "Fehler: Das Release wurde nicht gefunden.",
msg_etc_202 = lang.msg_etc_202 or "Fehler: Es wurden keine Releases in der Datenbank gefunden.",
msg_etc_203 = lang.msg_etc_203 or "Fehler: In deiner Eingabe befinden sich Leerstellen, bitte überprüfen!",
msg_etc_204 = lang.msg_etc_204 or "Fehler: Request: Unbekannter Parameter [2]",
msg_etc_205 = lang.msg_etc_205 or "Fehler: Filled: Unbekannter Parameter [2]",
msg_etc_206 = lang.msg_etc_206 or "Fehler: Das Release wurde bereits als REQUEST in der Datenbank eingetragen.",
msg_etc_207 = lang.msg_etc_207 or "Fehler: Das Release wurde bereits als FILLED in der Datenbank eingetragen.",
msg_etc_208 = lang.msg_etc_208 or "Fehler: Das Release wurde bereits als DELETED in der Datenbank eingetragen.",

}

--> Rechtsklickmenu/Submenu
local ucmd_menu_request_add = lang.ucmd_menu_request_add or { "Requests", "eintragen", "request" }
local ucmd_menu_filled_add = lang.ucmd_menu_filled_add or { "Requests", "eintragen", "filled" }
local ucmd_menu_request_show = lang.ucmd_menu_request_show or { "Requests", "anzeigen", "Alle Requests anzeigen" }
local ucmd_menu_filled_show = lang.ucmd_menu_filled_show or { "Requests", "anzeigen", "Alle Filled anzeigen" }
local ucmd_menu_del_show = lang.ucmd_menu_del_show or { "Requests", "anzeigen", "Alle Deleted anzeigen" }
local ucmd_menu_request_showall = lang.ucmd_menu_request_showall or { "Requests", "anzeigen", "Alle anzeigen" }
local ucmd_menu_del_request = lang.ucmd_menu_del_request or { "Requests", "löschen", "Einen löschen" }
local ucmd_menu_del_requests_all_r = lang.ucmd_menu_del_requests_all_r or { "Requests", "löschen", "Alle Requests löschen" }
local ucmd_menu_del_requests_all_f = lang.ucmd_menu_del_requests_all_f or { "Requests", "löschen", "Alle Filled löschen" }
local ucmd_menu_del_requests_all = lang.ucmd_menu_del_requests_all or { "Requests", "löschen", "Alle löschen" }

local ucmd_relname = lang.ucmd_relname or "Releasename"

--> Help Funktion
local help_title = lang.help_title or "Requests"
local help_usage = lang.help_usage or "[+!#]request show / [+!#]request showall / [+!#]request add <relname> / [+!#]request del <relname> / [+!#]request delall / [+!#]filled show / [+!#]filled add <relname> / [+!#]request showdel"
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
local del_show

local delay = 60
local os_time = os.time
local os_date = os.date
local os_difftime = os.difftime
local start = os_time()

local requests_tbl = util_loadtable( requests_file ) or {}

--> Flags ( nicht verändern! / dont change it! )
local tDate = "tDate"
local tNick_R = "tNick_R"
local tNick_F = "tNick_F"
local tNick_D = "tNick_D"
local tRel = "tRel"
local tRelFlag = "tRelFlag"
local R = "R"
local F = "F"
local D = "D"

local dateparser = function()
	if scriptlang == "de" then
		local day = os_date( "%d" )
		local month = os_date( "%m" )
		local year = os_date( "%Y" )
		local datum = day .. "." .. month .. "." .. year
		return datum
	elseif scriptlang == "en" then
		local day = os_date( "%d" )
		local month = os_date( "%m" )
		local year = os_date( "%Y" )
		local datum = month .. "/" .. day .. "/" .. year
		return datum
	else
		local day = os_date( "%d" )
		local month = os_date( "%m" )
		local year = os_date( "%Y" )
		local datum = day .. "." .. month .. "." .. year
		return datum
	end
end

hub.setlistener( "onBroadcast", { },
	function( user, adccmd, txt )
		local s1, s2, s3 = utf.match( txt, "^[+!#](%a+) (%a+) (.+)" )

		request_add = function()
			local user_level = user:level()
			local user_nick = user:nick()
			if user_level >= minlevel then
				if check_spaces then
					local space = string.find( s3, "%s" )
					if not space then
						local check_tRelFlag_R = false
						local check_tRelFlag_F = false
						local check_tRelFlag_D = false
						for index, tbl in pairs( requests_tbl ) do
							for k, v in pairs( tbl ) do
								if ( k == tRel and v == s3 ) then
									if requests_tbl[ index ].tRelFlag == R then
										check_tRelFlag_R = true
										break
									end
									if requests_tbl[ index ].tRelFlag == F then
										check_tRelFlag_F = true
										break
									end
									if requests_tbl[ index ].tRelFlag == D then
										check_tRelFlag_D = true
										break
									end
								end
							end
						end
						if check_tRelFlag_R then
							user:reply( msgs.msg_etc_206, hub_getbot )
							return PROCESSED
						elseif check_tRelFlag_F then
							user:reply( msgs.msg_etc_207, hub_getbot )
							return PROCESSED
						elseif check_tRelFlag_D then
							user:reply( msgs.msg_etc_208, hub_getbot )
							return PROCESSED
						else
							local n = table.maxn( requests_tbl )
							local i = n + 1
							requests_tbl[ i ] = {}
							requests_tbl[ i ].tDate = dateparser()
							requests_tbl[ i ].tNick_R = user_nick
							requests_tbl[ i ].tRel = s3
							requests_tbl[ i ].tRelFlag = R
							util_savetable( requests_tbl, "requests_tbl", requests_file )
							hub_broadcast( msgs.msg_etc_009 .. user_nick .. ":   " .. s3, hub_getbot )
							return PROCESSED
						end

					else
						user:reply( msgs.msg_etc_203, hub_getbot )
						return PROCESSED
					end
				else
					local check_tRelFlag_R = false
					local check_tRelFlag_F = false
					local check_tRelFlag_D = false
					for index, tbl in pairs( requests_tbl ) do
						for k, v in pairs( tbl ) do
							if ( k == tRel and v == s3 ) then
								if requests_tbl[ index ].tRelFlag == R then
									check_tRelFlag_R = true
									break
								end
								if requests_tbl[ index ].tRelFlag == F then
									check_tRelFlag_F = true
									break
								end
								if requests_tbl[ index ].tRelFlag == D then
									check_tRelFlag_D = true
									break
								end
							end
						end
					end
					if check_tRelFlag_R then
						user:reply( msgs.msg_etc_206, hub_getbot )
						return PROCESSED
					elseif check_tRelFlag_F then
						user:reply( msgs.msg_etc_207, hub_getbot )
						return PROCESSED
					elseif check_tRelFlag_D then
						user:reply( msgs.msg_etc_208, hub_getbot )
						return PROCESSED
					else
						local n = table.maxn( requests_tbl )
						local i = n + 1
						requests_tbl[ i ] = {}
						requests_tbl[ i ].tDate = dateparser()
						requests_tbl[ i ].tNick_R = user_nick
						requests_tbl[ i ].tRel = s3
						requests_tbl[ i ].tRelFlag = R
						util_savetable( requests_tbl, "requests_tbl", requests_file )
						hub_broadcast( msgs.msg_etc_009 .. user_nick .. ":   " .. s3, hub_getbot )
						return PROCESSED
					end
				end
			else
				user:reply( msg_denied, hub_getbot )
				return PROCESSED
			end
		end

		filled_add = function()
			local user_level = user:level()
			local user_nick = user:nick()
			if user_level >= minlevel then
				local check_tRel = false
				local check_tRelFlag_R = false
				local check_tRelFlag_F = false
				local check_tRelFlag_D = false
				local i
				for index, tbl in pairs( requests_tbl ) do
					for k, v in pairs( tbl ) do
						if ( k == tRel and v == s3 ) then
							i = index
							check_tRel = true
							if requests_tbl[ index ].tRelFlag == R then
								check_tRelFlag_R = true
								break
							end
							if requests_tbl[ index ].tRelFlag == F then
								check_tRelFlag_F = true
								break
							end
							if requests_tbl[ index ].tRelFlag == D then
								check_tRelFlag_D = true
								break
							end
						end
					end
				end
				if not check_tRel then
					user:reply( msgs.msg_etc_201, hub_getbot )
					return PROCESSED
				end
				if check_tRelFlag_F then
					user:reply( msgs.msg_etc_207, hub_getbot )
					return PROCESSED
				end
				if check_tRelFlag_D then
					user:reply( msgs.msg_etc_208, hub_getbot )
					return PROCESSED
				end
				if check_tRelFlag_R then
					requests_tbl[ i ].tNick_F = user_nick
					requests_tbl[ i ].tRelFlag = F
					util_savetable( requests_tbl, "requests_tbl", requests_file )
					hub_broadcast( msgs.msg_etc_010 .. user_nick .. ":   " .. s3, hub_getbot )
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
				if requests_tbl[ 1 ] ~= nil then
					for index, tbl in ipairs( requests_tbl ) do
						for k, v in pairs( tbl ) do
							if ( k == tRelFlag and v == R ) then
								msg = msg .. msgs.msg_etc_008 .. index .. "  |  " .. tbl[ tDate ] .. "  |  " .. msgs.msg_etc_005 ..
								"\t" .. tbl[ tRel ] .. msgs.msg_etc_002 .. tbl[ tNick_R ] .. "\n"
							end
						end
					end
					if msg ~= "\n" then
						user:reply( msg_header .. msg .. msg_footer, hub_getbot, hub_getbot )
					else
						user:reply( msgs.msg_etc_202, hub_getbot )
					end
					return PROCESSED
				else
					user:reply( msgs.msg_etc_202, hub_getbot )
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
				if requests_tbl[ 1 ] ~= nil then
					for index, tbl in ipairs( requests_tbl ) do
						for k, v in pairs( tbl ) do
							if ( k == tRelFlag and v == F ) then
								msg = msg .. msgs.msg_etc_008 .. index .. "  |  " .. tbl[ tDate ] .. "  |  " .. msgs.msg_etc_006 ..
								"\t" .. tbl[ tRel ] .. msgs.msg_etc_002 .. tbl[ tNick_R ] .. msgs.msg_etc_003 .. tbl[ tNick_F ] .. "\n"
							end
						end
					end
					if msg ~= "\n" then
						user:reply( msg_header .. msg .. msg_footer, hub_getbot, hub_getbot )
					else
						user:reply( msgs.msg_etc_202, hub_getbot )
					end
					return PROCESSED
				else
					user:reply( msgs.msg_etc_202, hub_getbot )
					return PROCESSED
				end
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
				local msg3 = "\n"
				if requests_tbl[ 1 ] ~= nil then
					for index, tbl in ipairs( requests_tbl ) do
						for k, v in pairs( tbl ) do
							if ( k == tRelFlag and v == R ) then
								msg = msg .. msgs.msg_etc_008 .. index .. "  |  " .. tbl[ tDate ] .. "  |  " .. msgs.msg_etc_005 ..
								"\t" .. tbl[ tRel ] .. msgs.msg_etc_002 .. tbl[ tNick_R ] .. "\n"
							end
							if ( k == tRelFlag and v == F ) then
								msg2 = msg2 .. msgs.msg_etc_008 .. index .. "  |  " .. tbl[ tDate ] .. "  |  " .. msgs.msg_etc_006 ..
								"\t" .. tbl[ tRel ] .. msgs.msg_etc_002 .. tbl[ tNick_R ] .. msgs.msg_etc_003 .. tbl[ tNick_F ] .. "\n"
							end
							--if ( k == tRelFlag and v == D ) then
								--msg3 = msg3 .. msgs.msg_etc_008 .. index .. "  |  " .. tbl[ tDate ] .. "  |  " .. msgs.msg_etc_007 ..
								--"\t" .. tbl[ tRel ] .. msgs.msg_etc_002 .. tbl[ tNick_R ] .. msgs.msg_etc_004 .. tbl[ tNick_D ] .. "\n"
							--end
						end
					end
					if msg ~= "\n" or msg2 ~= "\n" or msg3 ~= "\n" then
						user:reply( msg_header .. msg .. msg2 .. msg3 .. msg_footer, hub_getbot, hub_getbot )
					else
						user:reply( msgs.msg_etc_202, hub_getbot )
					end
					return PROCESSED
				else
					user:reply( msgs.msg_etc_202, hub_getbot )
					return PROCESSED
				end
			else
				user:reply( msg_denied, hub_getbot )
				return PROCESSED
			end
		end

		del_show = function()
			local user_level = user:level()
			if user_level >= minlevel then
				local msg = "\n"
				if requests_tbl[ 1 ] ~= nil then
					for index, tbl in ipairs( requests_tbl ) do
						for k, v in pairs( tbl ) do
							if ( k == tRelFlag and v == D ) then
								msg = msg .. msgs.msg_etc_008 .. index .. "  |  " .. tbl[ tDate ] .. "  |  " .. msgs.msg_etc_007 ..
								"\t" .. tbl[ tRel ] .. msgs.msg_etc_002 .. tbl[ tNick_R ] .. msgs.msg_etc_004 .. tbl[ tNick_D ] .. "\n"
							end
						end
					end
					if msg ~= "\n" then
						user:reply( msg_header .. msg .. msg_footer, hub_getbot, hub_getbot )
					else
						user:reply( msgs.msg_etc_202, hub_getbot )
					end
					return PROCESSED
				else
					user:reply( msgs.msg_etc_202, hub_getbot )
					return PROCESSED
				end
			else
				user:reply( msg_denied, hub_getbot )
				return PROCESSED
			end
		end

		del_request = function()
			local user_level = user:level()
			local user_nick = user:nick()
			if user_level >= oplevel then
				local check_tRel = false
				local check_tRelFlag_R = false
				local check_tRelFlag_F = false
				local check_tRelFlag_D = false
				local i
				for index, tbl in pairs( requests_tbl ) do
					for k, v in pairs( tbl ) do
						if ( k == tRel and v == s3 ) then
							check_tRel = true
							i = index
							if requests_tbl[ index ].tRelFlag == R then
								check_tRelFlag_R = true
								break
							end
							if requests_tbl[ index ].tRelFlag == F then
								check_tRelFlag_F = true
								break
							end
							if requests_tbl[ index ].tRelFlag == D then
								check_tRelFlag_D = true
								break
							end
						end
					end
				end
				if check_tRel then
					if check_tRelFlag_R then
						requests_tbl[ i ].tNick_D = user_nick
						requests_tbl[ i ].tRelFlag = D
						util_savetable( requests_tbl, "requests_tbl", requests_file )
						user:reply( msgs.msg_etc_101 .. s3, hub_getbot )
						return PROCESSED
					elseif check_tRelFlag_F then
						requests_tbl[ i ].tNick_D = user_nick
						requests_tbl[ i ].tRelFlag = D
						util_savetable( requests_tbl, "requests_tbl", requests_file )
						user:reply( msgs.msg_etc_101 .. s3, hub_getbot )
						return PROCESSED
					elseif check_tRelFlag_D then
						user:reply( msgs.msg_etc_208, hub_getbot )
						return PROCESSED
					end
				else
					user:reply( msgs.msg_etc_201, hub_getbot )
					return PROCESSED
				end
			else
				user:reply( msg_denied, hub_getbot )
				return PROCESSED
			end
		end

		del_requests_all_r = function()
			local user_level = user:level()
			local user_nick = user:nick()
			if user_level >= masterlevel then
				local check = false
				for key, value in pairs( requests_tbl ) do
					if key ~= nil then
						check = true
						break
					end
				end
				if check then
					for index, tbl in pairs( requests_tbl ) do
						for k, v in pairs( tbl ) do
							if ( k == tRelFlag and v == R ) then
								requests_tbl[ index ].tNick_D = user_nick
								requests_tbl[ index ].tRelFlag = D
								break
							end
						end
					end
					util_savetable( requests_tbl, "requests_tbl", requests_file )
					user:reply( msgs.msg_etc_103, hub_getbot )
					return PROCESSED
				else
					user:reply( msgs.msg_etc_202, hub_getbot )
					return PROCESSED
				end
			else
				user:reply( msg_denied, hub_getbot )
				return PROCESSED
			end
		end

		del_requests_all_f = function()
			local user_level = user:level()
			local user_nick = user:nick()
			if user_level >= masterlevel then
				local check = false
				for key, value in pairs( requests_tbl ) do
					if key ~= nil then
						check = true
						break
					end
				end
				if check then
					for index, tbl in pairs( requests_tbl ) do
						for k, v in pairs( tbl ) do
							if ( k == tRelFlag and v == F ) then
								requests_tbl[ index ].tNick_D = user_nick
								requests_tbl[ index ].tRelFlag = D
								break
							end
						end
					end
					util_savetable( requests_tbl, "requests_tbl", requests_file )
					user:reply( msgs.msg_etc_104, hub_getbot )
					return PROCESSED
				else
					user:reply( msgs.msg_etc_202, hub_getbot )
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
				for key, value in pairs( requests_tbl ) do
					if key ~= nil then
						check = true
						break
					end
				end
				if check then
					for index, tbl in pairs( requests_tbl ) do
						requests_tbl[ index ] = nil
					end
					util_savetable( requests_tbl, "requests_tbl", requests_file )
					user:reply( msgs.msg_etc_102, hub_getbot )
					return PROCESSED
				else
					user:reply( msgs.msg_etc_202, hub_getbot )
					return PROCESSED
				end
			else
				user:reply( msg_denied, hub_getbot )
				return PROCESSED
			end
		end

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
				elseif s2 == cmd_p_request_showdel then
					del_show()
				else
					user:reply( msgs.msg_etc_204, hub_getbot )
				end
				return PROCESSED
			else
				user:reply( msg_denied, hub_getbot )
				return PROCESSED
			end
		end

		if s1 == cmd_filled then
			local user_level = user:level()
			if user_level >= minlevel then
				if s2 == cmd_p_filled_add then
					filled_add()
				elseif s2 == cmd_p_filled_show then
					filled_show()
				else
					user:reply( msgs.msg_etc_205, hub_getbot )
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

hub.setlistener( "onLogin", {},
	function( user )
		if sendonconnect then
			local user_level = user:level()
			if user_level >= minlevel then
				local msg = "\n"
				local msg2 = "\n"
				if requests_tbl[ 1 ] ~= nil then
					for index, tbl in ipairs( requests_tbl ) do
						for k, v in pairs( tbl ) do
							if ( k == tRelFlag and v == R ) then
								msg = msg .. msgs.msg_etc_008 .. index .. "  |  " .. tbl[ tDate ] .. "  |  " .. msgs.msg_etc_005 .. "\t" .. tbl[ tRel ] .. msgs.msg_etc_001 .. tbl[ tNick_R ] .. "\n"
							end
							if ( k == tRelFlag and v == F ) then
								msg2 = msg2 .. msgs.msg_etc_008 .. index .. "  |  " .. tbl[ tDate ] .. "  |  " .. msgs.msg_etc_006 .. "\t" .. tbl[ tRel ] .. msgs.msg_etc_001 .. tbl[ tNick_F ] .. "\n"
							end
						end
					end
					if msg ~= "\n" or msg2 ~= "\n" then
						user:reply( msg_header .. msg .. msg2 .. msg_footer, hub_getbot )
						return nil
					end
				end
			end
		end
	end
)

hub.setlistener( "onTimer", { },
	function()
		if os_difftime( os_time() - start ) >= delay then
			if sendtime[ os.date( "%H:%M" ) ] then
				if requests_tbl[ 1 ] ~= nil then
					local msg = "\n"
					local msg2 = "\n"
					for index, tbl in ipairs( requests_tbl ) do
						for k, v in pairs( tbl ) do
							if ( k == tRelFlag and v == R ) then
								msg = msg .. msgs.msg_etc_008 .. index .. "  |  " .. tbl[ tDate ] .. "  |  " .. msgs.msg_etc_005 .. "\t" .. tbl[ tRel ] .. msgs.msg_etc_001 .. tbl[ tNick_R ] .. "\n"
							end
							if ( k == tRelFlag and v == F ) then
								msg2 = msg2 .. msgs.msg_etc_008 .. index .. "  |  " .. tbl[ tDate ] .. "  |  " .. msgs.msg_etc_006 .. "\t" .. tbl[ tRel ] .. msgs.msg_etc_001 .. tbl[ tNick_F ] .. "\n"
							end
						end
					end
					if msg ~= "\n" or msg2 ~= "\n" then
						for sid, user in pairs( hub_getusers() ) do
							if not user:isbot() then
								if sendto[ user:level() ] then
									user:reply( msg_header .. msg .. msg2 .. msg_footer, hub_getbot )
								end
							end
						end
					end
				end
			end
			start = os_time()
		end
		return nil
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
			ucmd.add( ucmd_menu_del_show, cmd_request, { cmd_p_request_showdel, " " }, { "CT1" }, oplevel )
		end
		return nil
	end
)

hub.debug( "** Loaded "..scriptname.."_"..scriptversion..".lua **" )

---------
--[END]--
---------
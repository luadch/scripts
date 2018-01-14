--[[

	Online Counter 1.4 - By Jerker/Kungen
	- With free months
	- Keeps track of online time
	- Blocks users from search and download if requirements are not met

	Usage:
		[+!#]onlinecounter toponline
		[+!#]onlinecounter toponlinexy x-y
		[+!#]onlinecounter hubtime <nick>
		[+!#]onlinecounter myhubtime
		[+!#]onlinecounter settime <nick> <time>
		[+!#]onlinecounter userlowuptime
		[+!#]onlinecounter setsafe <nick> <months> <reason>
		[+!#]onlinecounter delsafe <nick>
		[+!#]onlinecounter showsafe
		[+!#]onlinecounter showhelp

	v1.4: by Jerker/Kungen
		- Added setting bReset: Total uptime is reset to 0 every new month [true = on; false = off]
		- Minor bug fixes

	v1.3: by Jerker/Kungen
		 Added Safelist and RC for this
		 Added setting bOpWarning: Send message to opchat when user with lower than specified Total uptime logs in [true = on; false = off]
		 Year is shown if users have been online over one year
		 Minor bug fixes

	v1.2: by Jerker
		- Added RC to show help

	v1.1: by Jerker
		- Resets total time after first new month for new accounts
		- Show error if toponline is called with greater start value than number of users

]]--

local scriptname = "etc_onlinecounter"
local scriptversion = "1.3"

local tSettings = {
	-- Bot Name
	sBot = hub.getbot( ),
	
	-- Command
	sCmd = "onlinecounter",
	
	-- RightClick Menu
	sMenu = { "About You", "Online Counter" },

	-- Online Counter's DB
	fOnlineCounter = "scripts/data/etc_onlinecounter.tbl",

	-- Maximum hubbers to show when using !toponline
	iMax = 30,

	-- Send message to users with lower than specified Total uptime (TUT) [true = on; false = off]
	bWarning = true,
	
	-- Send message to opchat when user with lower than specified Total uptime (TUT) logs in [true = on; false = off]
	bOpWarning = false,
	
	-- Minimum Total uptime (hours) that triggers the warning
	iTUT = 150,

	-- Max TotalTime, must be greater than or equal to iTUT
	MaxTime = 9800,

	--Reset uptime every month
	bReset = false,

	-- Send hubtime stats on connect [true = on; false = off]
	bRankOnConnect = false,
	
	-- Block search
	bSearch = true,
	
	-- Message when search is blocked
	sNoSearchMsg = "Your uptime is too low, search is blocked",

	-- Block download
	bCTM = true,
	
	-- Message when download is blocked
	sNoCTMMsg = "Your uptime is too low, download is blocked",

	-- Profiles checked [0 = off; 1 = on]
	tProfiles = {
		[0] = 1,
		[10] = 1,
		[20] = 1,
		[30] = 0,
		[35] = 0,
		[40] = 0,
		[50] = 0,
		[55] = 0,
		[60] = 0,
		[70] = 0,
		[80] = 0,
		[90] = 0,
		[100] = 0,
	},

	tFreeMonth =
	{
		["01"] = 1,
		["06"] = 1,
		["07"] = 1,
		["08"] = 1,
		["12"] = 1,
	},
}

local opchat = hub.import "bot_opchat"
local hub_debug = hub.debug

local tOnlineCounter = util.loadtable( tSettings.fOnlineCounter ) or { }
local Month = nil
local FreeMonth = false

local ShowHelp

--OnError Crew //Zido
local OnError = function(msg)
	opchat.feed(msg)
end
--OnError Crew //Zido

local GetOnliner = function(user)
	-- For each hubber
	for i, v in pairs(tOnlineCounter) do
		-- Compare
		if i:lower() == user:lower() then
			-- Return
			return tOnlineCounter[i]
		end
	end
end

local plural = function(i)
	if i == 0 or i > 1 then
		return "s"
	end
	return ""
end

local MinutesToTime = function(iMinutes, bSmall)
	-- Build table with time fields
	local T = os.date("!*t", math.abs(tonumber(iMinutes*60)));
	local sign = ""
	if tonumber(iMinutes) < 0 then
		sign = "-"
	end
	-- Format to string
	--local sTime = string.format("%i month(s), %i day(s), %i hour(s), %i minute(s)", T.month-1, T.day-1, T.hour, T.min)
	local sTime = string.format("%i month%s, %i day%s, %i hour%s, %i minute%s", T.month-1, plural(T.month-1), T.day-1, plural(T.day-1), T.hour, plural(T.hour), T.min, plural(T.min))
	if T.year > 1970 then
		sTime = string.format("%i year%s, ", T.year - 1970, plural(T.year - 1970))..sTime
	end
	-- Small stat?
	if bSmall then
		-- For each digit
		for i in string.gmatch(sTime, "%d+") do
		-- Reduce if is preceeded by 0
		if tonumber(i) == 0 then sTime = string.gsub(sTime, "^"..i.."%s(%S+),%s", "")
		end

		end
	end
	-- Return
	return sign..sTime
end

local HoursToDays = function(iHours)
	local days = math.floor(tonumber(iHours/24))
	local hours = tonumber(iHours-(days*24))
	return string.format("%i day%s, %i hour%s", days, plural(days), hours, plural(hours))
end

local BuildStats = function(user, nick)
	local tNick = GetOnliner(nick)
	-- In DB
	if tNick then
		-- Generate message
		local sMsg = "\r\n\r\n\t"..string.rep("=", 40).."\r\n\t\t\tStats:\r\n\t"..
		string.rep("-", 80).."\r\n\t- Nick: "..nick.."\r\n\t- Total uptime: "..
		MinutesToTime(tNick.TotalTime, true).."\r\n"
		
		if user:firstnick() == nick then
		sMsg = sMsg.."\r\n\t- If your online time is lower than "..tSettings.iTUT.." hours ("..HoursToDays(tSettings.iTUT)..") every month, your account will be blocked for download!"
		end
		
		if tNick.FreeMonth then
			sMsg = sMsg.."\r\n\r\n\t- Free month(s): "..tNick.FreeMonth.."\r\n\t- Free month reason: "..tNick.FreeMonthReason.."\r\n\t- Added by: "..tNick.FreeMonthAddBy..""
		end
		
		-- Send stats
		user:reply(sMsg, tSettings.sBot, tSettings.sBot)
	else
		user:reply("*** Error: No record found for '"..nick.."'!", tSettings.sBot)
	end
end

local toponline = function(user, data)
	-- Table isn't empty
	if next(tOnlineCounter) then
		-- Parse limits
		local _,_, iStart, iEnd = data:find("^%S+%s+(%d+)%-(%d+)$")
		-- Set if not set
		iStart, iEnd = (iStart or 1), (iEnd or tSettings.iMax)
		-- Header
		local tCopy, msg, iCount = {}, "\r\n\t"..string.rep("=", 140).."\r\n\tNr.\tTotal:\t\t\t\t\tSession:\t\t"..
		"Entered Hub:\t\tLeft Hub:\t\t\tStatus:\tName:\r\n\t"..string.rep("-", 280).."\r\n", 0
		-- Loop through hubbers
		for i, v in pairs(tOnlineCounter) do
			-- Insert stats to temp table
			table.insert(tCopy, { sEnter = v.Enter, iSessionTime = tonumber(v.SessionTime),
			iTotalTime = tonumber(v.TotalTime), sLeave = v.Leave, sNick = v.CurrentNick } )
			if tonumber(v.TotalTime) > 0 then
				iCount = iCount + 1
			end
		end
		if tonumber(iStart) <= iCount then
			-- Sort by total time
			table.sort(tCopy, function(a, b) return (a.iTotalTime > b.iTotalTime) end)
			-- Loop through temp table
			for i = iStart, iEnd, 1 do
				-- i exists
				if tCopy[i] then
					if tCopy[i].iTotalTime <= 0 then
						break
					end
					-- Populate
					local sStatus, v = "*Offline*", tCopy[i]
					if hub.isnickonline(v.sNick) then sStatus = "*Online*" end
					msg = msg.."\t"..i..".\t"..MinutesToTime(v.iTotalTime).."\t"..string.format("%.1f",tonumber(v.iSessionTime)/60).." h\t\t"
					..v.sEnter.."\t"..v.sLeave.."\t"..sStatus.."\t"..v.sNick.."\r\n"
				end
			end
			msg = msg.."\t"..string.rep("-", 280)
			-- Send
			user:reply("Current Top Online:\r\n"..msg.."\r\n", tSettings.sBot, tSettings.sBot)
		else
			user:reply("*** Error: Only "..iCount.." users in table, "..iStart.." is too high!", tSettings.sBot)
		end
	else
		user:reply("*** Error: Online Counter's table is currently empty!", tSettings.sBot)
	end
end

local tCommands = {
	toponline = {
		fFunction = function(user, data)
			toponline(user, "")
			return PROCESSED
		end,
		minLevel = 10,
		tRC = {
			{ { "Show Top "..tSettings.iMax.." Online Time" }, { }, { "CT1" } },
		},
		help = {
			{ "",  "Show Top "..tSettings.iMax.." Online Time" },
		}
	},
	toponlinexy = {
		fFunction = function(user, data)
			toponline(user, data)
			return PROCESSED
		end,
		minLevel = 60,
		tRC = {
			{ { "Show Top X-Y Online Time" }, { "%[line:x-y]" }, { "CT1" } }
		},
		help = {
			{ "<X-Y>", "Show Top X-Y Online Time"}
		}
	},
	hubtime = {
		fFunction = function(user, data)
			-- Parse nick
			local _,_, sNick = data:find("^%S+%s+(%S+)$")
			-- Exists
			if sNick then 
				local tUser = hub.isnickonline(sNick)
				if tUser then
					sNick = tUser:firstnick()
				end
				-- Return
				BuildStats(user, sNick)
			else
				user:reply("*** Syntax Error: Type !"..tSettings.sCmd.." hubtime <nick>", tSettings.sBot)
			end
			return PROCESSED
		end,
		minLevel = 60,
		tRC = {
			{ { "Show User Online Time" }, { "%[line:Nick]" }, { "CT1" } },
			{ { "Show User Online Time" }, { "%[userNI]" }, { "CT2" } }
		},
		help = {
			{ "<nick>", "Show User Online Time" }
		}
	},
	myhubtime = {
		fFunction = function(user)
			-- Return
			BuildStats(user, user:firstnick())
			return PROCESSED
		end,
		minLevel = 20,
		tRC = { 
			{ { "Show My Online Time" }, { }, { "CT1" } }
		},
		help = {
			{ "", "Show My Online Time" }
		}
	},
	settime = {
		fFunction = function(user, data)
			local tMultiplier = {
				["m"] = 1,
				["h"] = 60,
				["d"] = 24 * 60,
				["w"] = 7 * 24 * 60,
				["M"] = 30 * 24 * 60
			}
			local _,_, sNick = data:find("^%S+%s+(%S+)")
			if sNick then
				local tUser = hub.isnickonline(sNick)
				if tUser then
					sNick = tUser:firstnick()
				end
				local _,_, sTime, sMultiplier = data:find("^%S+%s+%S+%s+(-?%d+)(%a?)$")
				if sTime and tonumber(sTime) then
					if sMultiplier and tMultiplier[sMultiplier] then
						if sMultiplier == "M" and tonumber(sTime) > 0 then
							local d = os.date("*t", 0)
							local y = 0
							if tonumber(sTime) >= 12 then
								y = math.floor(tonumber(sTime) / 12)
								sTime = tonumber(sTime) - (tonumber(y) * 12)
							end
							d.year = d.year + tonumber(y)
							d.month = d.month + tonumber(sTime)
							sTime = os.time(d) / 60
						else
							sTime = tonumber(sTime) * tMultiplier[sMultiplier]
						end
					end
					if tonumber(sTime) > tSettings.MaxTime * 60 then
						sTime = tSettings.MaxTime * 60
					end
					local tNick = GetOnliner(sNick)
					if tNick then
						tNick.TotalTime = tonumber(sTime)
						user:reply("New total time for "..sNick.." is "..MinutesToTime(tNick.TotalTime, true)..".", tSettings.sBot)
					else
						user:reply("*** Error: No record found for '"..sNick.."'!", tSettings.sBot)
					end
				else
					user:reply("*** Syntax Error: Type !"..tSettings.sCmd.." settime <nick> <time[m|h|d|w|M]>", tSettings.sBot)
				end
			else
				user:reply("*** Syntax Error: Type !"..tSettings.sCmd.." settime <nick> <time[m|h|d|w|M]>", tSettings.sBot)
			end
			return PROCESSED
		end,
		minLevel = 60,
		tRC = {
			{ { "Set User Online Time" }, { "%[line:Nick]", "%[line:Time]" }, { "CT1" } },
			{ { "Set User Online Time" }, { "%[userNI]", "%[line:Time]" }, { "CT2" } }
		},
		help = {
			{ "<nick> <time[m|h|d|w|M]>", "Set User Online Time" }
		}
	},
	userlowuptime = {
		fFunction = function(user, data)
			local iCount = 0
			local msg = "Users with too low online time:\r\n"
			if next(tOnlineCounter) then
				local _,regnicks = hub.getregusers( )
				for i, v in pairs(tOnlineCounter) do
					--check if user has free month and check profile
					if not v.FreeMonth then
						local tUser = regnicks[ i ]
						if tUser then
							--if to low online time block user
							if v.TotalTime < tSettings.iTUT*60 and tSettings.tProfiles[tUser.level] and tSettings.tProfiles[tUser.level] == 1 then
								msg = msg..i.."\t"..MinutesToTime(v.TotalTime, true).."\r\n"
								iCount = iCount + 1
							end
						end
					end
				end
			end
			if iCount > 0 then
				user:reply(msg, tSettings.sBot, tSettings.sBot)
			else
				user:reply("No users with too low online time.", tSettings.sBot, tSettings.sBot)
			end
            return PROCESSED
		end,
		minLevel = 60,
		tRC = {
			{ { "Show Users With Too Low Online Time" }, { }, { "CT1" } }
		},
		help = {
			{ "", "Show Users With Too Low Online Time" }
		}
	},
	setsafe = {
		fFunction = function(user, data)
			local _,_, sNick, iMonth, sReason = data:find("^%S+%s+(%S+)%s+(%S+)%s+(.+)")
			if not sNick or not tonumber(iMonth) or not sReason then
				user:reply("*** Syntax Error: Type !"..tSettings.sCmd.." setsafe <nick> <months> <reason>", tSettings.sBot)
				return PROCESSED
			end
			
			iMonth = tonumber(iMonth)
			if iMonth > 5 then
				user:reply("Max 5 safe month.", tSettings.sBot)
				return PROCESSED
			end
			
			local tUser = hub.isnickonline(sNick)
			if tUser then
				sNick = tUser:firstnick()
			end
			local tNick = GetOnliner(sNick)
			
			if not tNick then
				user:reply("*** Error: No record found for '"..sNick.."'!", tSettings.sBot)
				return PROCESSED
			end
			
			if iMonth <= 0 then
				tNick.FreeMonth = nil
				tNick.FreeMonthReason = nil
				tNick.FreeMonthAddBy = nil
				
				local msg = sNick.." no clean month is now remove because of "..sReason.."."
				OnError(msg.." //"..user:nick())
				user:reply(msg, tSettings.sBot)
			else
				tNick.FreeMonth = iMonth
				tNick.FreeMonthReason = sReason
				tNick.FreeMonthAddBy = user:nick()
				if tNick.TotalTime < 0 then
					tNick.TotalTime = 0
				end
				local msg = sNick.." have get "..iMonth.." no clean month, because of "..sReason.."."
				OnError(msg.." //"..user:nick())
				user:reply(msg, tSettings.sBot)
			end
			return PROCESSED
		end,
		minLevel = 60,
		tRC = {
			{ { "Add User To Safe List" }, { "%[line:Nick]", "%[line:Months]", "%[line:Reason]" }, { "CT1" } },
			{ { "Add User To Safe List" }, { "%[userNI]", "%[line:Months]", "%[line:Reason]" }, { "CT2" } }
		},
		help = {
			{ "<nick> <months> <reason>", "Add User To Safe List" }
		}
	},
	delsafe = {
		fFunction = function(user, data)
			local _,_, sNick = data:find("^%S+%s+(%S+)")
			if sNick then
				local tUser = hub.isnickonline(sNick)
				if tUser then
					sNick = tUser:firstnick()
				end
				local tNick = GetOnliner(sNick)
				if tNick then
					if tNick.FreeMonth and tNick.FreeMonth > 0 then
						tNick.FreeMonth = nil
						tNick.FreeMonthReason = nil
						tNick.FreeMonthAddBy = nil
						user:reply(sNick.." is removed safe list.", tSettings.sBot)
					else
						user:reply(sNick.." is not on safe list.", tSettings.sBot)
					end
				else
					user:reply("*** Error: No record found for '"..sNick.."'!", tSettings.sBot)
				end
			else
				user:reply("*** Syntax Error: Type !"..tSettings.sCmd.." delsafe <nick>", tSettings.sBot)
			end
			return PROCESSED
		end,
		minLevel = 60,
		tRC = {
			{ { "Remove User From Safe List" }, { "%[line:Nick]" }, { "CT1" } },
			{ { "Remove User From Safe List" }, { "%[userNI]" }, { "CT2" } }
		},
		help = {
			{ "<nick>", "Remove User From Safe List" }
		}
	},
	showsafe = {
		fFunction = function(user)
			local iCount = 0
			local iMaxLen = 0
			local msg = "\r\nUsers on safe list:\r\n"
			if next(tOnlineCounter) then
				local _,regnicks = hub.getregusers( )
				for i, v in pairs(tOnlineCounter) do
					if v.FreeMonth and v.FreeMonth > 0 then
						iCount = iCount + 1
						iMaxLen = math.max(iMaxLen, string.len(i))
					end
				end
				
				local fmt = string.format("%%-%ii%%-%is%%-10s%%s", string.len(tostring(iCount)) + 2, iMaxLen + 4)
				iCount = 0
				for i, v in pairs(tOnlineCounter) do
					--check if user is safe
					if v.FreeMonth and v.FreeMonth > 0 then
						local tUser = regnicks[ i ]
						if tUser then
							iCount = iCount + 1
							msg = msg..string.format(fmt, iCount, i, string.format("%i Month%s", v.FreeMonth, plural(v.FreeMonth)), v.FreeMonthReason).."\r\n"
						end
					end
				end
			end
			if iCount > 0 then
				user:reply(msg, tSettings.sBot, tSettings.sBot)
			else
				user:reply("No users on safe list.", tSettings.sBot, tSettings.sBot)
			end
            return PROCESSED
		end,
		minLevel = 60,
		tRC = {
			{ { "Show Users On Safe List" }, { }, { "CT1" } }
		},
		help = {
			{ "", "Show Users On Safe List" }
		}
	},
	showhelp = {
		fFunction = function(user)
			ShowHelp(user)
			return PROCESSED
		end,
		minLevel = 20,
		tRC = {
			{ { "Show Help" }, { }, { "CT1" } }
		},
		help = {
			{ "", "Show Help" }
		}
	},
}

ShowHelp = function(user)
	local sMsg = ""
	for i, v in pairs(tCommands) do
		if user:level() >= v.minLevel then
			for _, w in ipairs(v.help) do
				if w[1] ~= "" then
					sMsg = sMsg.."\r\n\t[+!#]"..tSettings.sCmd.." "..i.." "..w[1].."\t"..w[2]
				else
					sMsg = sMsg.."\r\n\t[+!#]"..tSettings.sCmd.." "..i.."\t\t"..w[2]
				end
			end
		end
	end
	if sMsg ~= "" then
		user:reply("\r\n\r\n\tUsage:"..sMsg, tSettings.sBot, tSettings.sBot)
	end
end

local onbmsg = function(user, cmd, parameters, msg)
	local _,_, to = msg:find("^$To:%s(%S+)%s+From:")
    -- Parse command
	local subCmd = string.match( parameters, "^(%S+)" )
	-- Exists
	if subCmd and tCommands[string.lower(subCmd)] then
		subCmd = string.lower(subCmd)
		-- PM
		local tmp = nil
		if to and to == tSettings.sBot then tmp = tSettings.sBot end
		-- If user has permission
		if user:level() >= tCommands[subCmd].minLevel then
			return tCommands[subCmd].fFunction(user, parameters), 1
		else
			user:reply("*** Error: You are not allowed to use this command!", tSettings.sBot, tmp)
			return PROCESSED
		end
	end
end

local function TableConcat(t1, t2)
	local result = {}
    for i=1, #t1 do
        result[#result + 1] = t1[i]
    end
	for i=1, #t2 do
        result[#result + 1] = t2[i]
    end
    return result
end

hub.setlistener( "onStart", { },
	function()
		string.gmatch = (string.gmatch or string.gfind)
		local ucmd = hub.import( "etc_usercommands" )
		if ucmd then
			for i, v in pairs(tCommands) do
				for _, w in ipairs(v.tRC) do
					ucmd.add(TableConcat(tSettings.sMenu, w[1]), tSettings.sCmd.." "..i, w[2], w[3], v.minLevel)
				end
			end
		end
		local hubcmd = hub.import( "etc_hubcommands" )    -- add hubcommand
		assert( hubcmd )
		assert( hubcmd.add( tSettings.sCmd, onbmsg ) )

		--Set month //Zido
		Month = os.date("%m")
		
		--make check for free month
		if tSettings.tFreeMonth[ Month ] and tSettings.tFreeMonth[ Month ] == 1 then
			FreeMonth = true
		end

		--add hub reg to tOnlineCounter db
		local regusers, reggednicks, reggedcids = hub.getregusers( )
		if next(regusers) then
			for i, user in ipairs( regusers ) do
				if not user.is_bot then
					local tNick = GetOnliner(user.nick)
					if not tNick then
						-- Create new entry
						tOnlineCounter[user.nick] = {
							CurrentNick = user.nick,
							Julian = os.time(os.date("!*t")),
							Enter = os.date("%Y-%m-%d %H:%M:%S"),
							SessionTime = 0,
							TotalTime = 0,
							Leave = os.date("%Y-%m-%d %H:%M:%S"),
							FreeMonth = 1,
							FreeMonthReason = "New reg",
							FreeMonthAddBy = "Bot"
						}
					end
				end
			end
		end
		
		-- Set and Start Timer
		tSettings.iTimer = os.time()
		tSettings.SaveData = os.time()
	end 
)

hub.setlistener( "onTimer", { },
	function()	
		if tSettings.iTimer and os.difftime( os.time( ) - tSettings.iTimer ) >= 60 then
			tSettings.iTimer = os.time()
			--check db if new month //Zido
			if Month ~= os.date("%m") then
				local _,regnicks = hub.getregusers( )
				local reloadUserList = false
				-- For each hubber
				for i, v in pairs(tOnlineCounter) do
					--check if reg
					local user = regnicks[ i ]
					if user then
						--check if user has free month and check profile
						if not v.FreeMonth or v.FreeMonth <= 0 then
							if not FreeMonth then -- Don't remove time if previous month was free month
								v.TotalTime = v.TotalTime - (tSettings.iTUT*60)
								if v.TotalTime < 0 then
									if hub.isnickonline(v.CurrentNick) then
										-- Warn user?
									end
								elseif tSettings.bReset then
									v.TotalTime = 0
								end
							end
						else
							--if user has free month count down or remove
							v.FreeMonth = v.FreeMonth-1
							v.TotalTime = 0
							OnError(i.." is not checked because "..v.FreeMonthReason.." and have "..v.FreeMonth.." no free month back. (Online time: "..MinutesToTime(v.TotalTime,true)..")")
							
						end
						if v.FreeMonth ~= nil and v.FreeMonth <= 0 then
							v.FreeMonth = nil
							v.FreeMonthReason = nil
							v.FreeMonthAddBy = nil
						end
						v.Julian = os.time(os.date("!*t"))
					else
						--Show/delete user data if not reg
						tOnlineCounter[i] = nil
						OnError(i.." user data is remove because the user is deleted.")
					end
				end
				--send msg to Crews
				OnError("New Month started, all online data is checked.")
				if reloadUserList then
					hub.reloadusers()
				end
			
				--set new month
				Month = os.date("%m")
				--make check for free month
				FreeMonth = false
				if tSettings.tFreeMonth[ Month ] and tSettings.tFreeMonth[ Month ] == 1 then
					FreeMonth = true
				end
			end
			--check db if new month //Zido
			
			-- For each hubber
			for i, v in pairs(tOnlineCounter) do
            -- Online
				if hub.isnickonline(v.CurrentNick) then
					v.SessionTime = v.SessionTime + 1
					if not v.FreeMonth or v.FreeMonth <= 0 or v.TotalTime < 0 then -- Don't add time if user is safe
						if not FreeMonth or v.TotalTime < 0 then -- Don't add time during free month except if user is blocked
							if v.TotalTime < tSettings.MaxTime * 60 then
								v.TotalTime = v.TotalTime + 1
							end
						end
					end
				end
			end

		end
		
		if tSettings.SaveData and os.difftime( os.time( ) - tSettings.SaveData ) >= 10*60 then
			tSettings.SaveData = os.time()
			util.savetable( tOnlineCounter, "tOnlineCounter", tSettings.fOnlineCounter )
		end
	end
)

hub.setlistener( "onExit", { },
	function()
		-- Save
		util.savetable( tOnlineCounter, "tOnlineCounter", tSettings.fOnlineCounter )
	end
)

hub.setlistener( "onLogin", { },
	function(user)
		if not user:isbot( ) then
			-- For each hubber
			local tNick = tOnlineCounter[ user:firstnick() ]
		
			-- User already in DB
			if tNick then
				--MOD //Zido
				--remove msg about min time
				if not tNick.FreeMonth then
					-- Rank on connect bRankOnConnect
					if tSettings.bRankOnConnect then
						BuildStats(user, user:firstnick())
					end
					
					-- Warning on connect
					if tSettings.tProfiles[user:level()] and tSettings.tProfiles[user:level()] == 1 then
						-- Less than zero equals blocked
						if tNick.TotalTime < 0 then
							if tSettings.bOpWarning then
								OnError(user:nick().." is blocked because of too low uptime.")
							end
							
						-- Less than allowed
						elseif tNick.TotalTime < tSettings.iTUT*60 and tonumber(os.date("%d")) > 20 and tSettings.bWarning and not FreeMonth then
							-- Warn
							user:reply("*** Your Total Online Time Is "..MinutesToTime(tNick.TotalTime,true)..
							". If your Online Time is lower than "..tSettings.iTUT.." hours every month, your account will be blocked!", tSettings.sBot, tSettings.sBot)
						end
					end
				end
				--MOD //Zido
				
				-- Reset and save time
				tNick.SessionTime = 0
				tNick.Enter = os.date("%Y-%m-%d %H:%M:%S")
				tNick.CurrentNick = user:nick()
			else
				-- Create new entry
				tOnlineCounter[user:firstnick()] = {
					CurrentNick = user:nick(),
					Julian = os.time(os.date("!*t")),
					Enter = os.date("%Y-%m-%d %H:%M:%S"),
					SessionTime = 0,
					TotalTime = 0,
					Leave = os.date("%Y-%m-%d %H:%M:%S"),
					FreeMonth = 1,
					FreeMonthReason = "New reg",
					FreeMonthAddBy = "Bot"
				}
			end
		end
	end
)

hub.setlistener( "onLogout", { },
	function(user)
		-- Log date
		local tNick = GetOnliner(user:firstnick())
		if tNick then
			tNick.Leave = os.date("%Y-%m-%d %H:%M:%S")
		end
	end
)

hub.setlistener( "onSearch", { },
	function(user, adccmd)
		if tSettings.bSearch then
			if tSettings.tProfiles[user:level()] and tSettings.tProfiles[user:level()] == 1 then
				local tNick = tOnlineCounter[ user:firstnick() ]
				if tNick and tNick.TotalTime < 0 then
					user:reply(tSettings.sNoSearchMsg, tSettings.sBot, tSettings.sBot)
					return PROCESSED
				end
			end
		end
	end
)

local checkuser = function(user, target, adccmd)
	if tSettings.bCTM then
		if tSettings.tProfiles[user:level()] and tSettings.tProfiles[user:level()] == 1 then
			local tNick = tOnlineCounter[ user:firstnick() ]
			if tNick and tNick.TotalTime < 0 then
				user:reply(tSettings.sNoCTMMsg, tSettings.sBot, tSettings.sBot)
				return PROCESSED
			end
		end
	end
end

hub.setlistener( "onConnectToMe", { }, checkuser) 

hub.setlistener( "onRevConnectToMe", { }, checkuser) 

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )

--// public //--

return {    -- export tOnlineCounter

    tOnlineCounter = tOnlineCounter,

}

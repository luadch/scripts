--[[
	Anti Download Bot v 2.0 - LUA 5.11   [API 2]
	---------------------------------------------------
	
	2.0 - changelog by Herman
	---------------------
	Upgrade to API2 and PtokaX 0.4.x



	
	----------------------------
	Orginal Script
	------------------------------------------------------------
	Anti Download Bot v 1.0 - LUA 5.1 by Rag3Rac3r (2007-12-08)
	Written for PtokaX  0.3.6.0c and below
	Requires: Robocop Profiles, Common sense
	-------------------------------------------------------------

]]--

--------------
--[SETTINGS]--
--------------

local scriptname = "ptx_anti_dl"
local scriptversion = "2.0"

local oplevel = 60

local cmd = "nodl"
local cmd_p_add = "add"
local cmd_p_del = "del"
local cmd_p_list = "list"
local cmd_p_listblocks = "listblocks"
local cmd_p_changeblocks = "changeblocks"
local cmd_p_help = "help"


local tSettings = {
	-- The nick to send messages from
	["sBot"] = hub.getbot(), -- Uses hubsecurity nick
	-- Profiles Immune to this script, i.e. the script ignores the nick of a person IF he/she belongs to this profile
	["tImmune"] = {
		[0] = 0, -- Unreg
		[10] = 0,  -- Try-Out
		[20] = 0,  -- Reg
		[30] = 0,  -- Vip
		[40] = 0,  -- Friend
		[50] = 0,  -- Dump
		[60] = 0,  -- Operator
		[70] = 0,  -- Admin
		[80] = 1,  -- HubOwner
		[100] = 1,  --Netfounder
	},
	-- Should I be silent or notify users that they're being blocked?   (false = notify user, true = don't notify user)
	["bSilent"] = false,
	-- if bSilent = false, settings this to true will send the message to PM instead of main
	["bNotifyPM"] = false,
	-- Should I notify user upon connect that he can't DL/Search?
	["bMsgOnConnect"] = true,
	-- Send in mainchat or in PM? (you can set both to true, and really be sure the users sees it, or just choose where u want it)
	["bMsgOnConnectPM"] = true,
	["bMsgOnConnectMain"] = false,
	-- The message to send to the users
	["sMsgOnConnect"] = "Your search and download options are blocked. Clean your share with Sor.Anti.RAR.FLAC.HD.v.2.32 and after that report to [Pm_To_OPs]",
	-- Should I block CTM/RCTM (Downloads)
	["bCTM"] = true,
	-- Should I block Search?
	["bSearch"] = true,
	-- Message to send to the user when they try to search and are blocked by hub (only used if bSilent is false)
	["sNoSearchMsg"] = "Your search and download options are blocked. Clean your share with Sor.Anti.RAR.FLAC.HD.v.2.32 and after that report to [Pm_To_OPs]",
	-- Message to send to the user when they try to download and are blocked by hub (only used if bSilent is false)
	["sNoCTMMsg"] = "Your search and download options are blocked. Clean your share with Sor.Anti.RAR.FLAC.HD.v.2.32 and after that report to [Pm_To_OPs]",
	-- Send PM to all ops when user is added or removed?
	["bNotifyOps"] = true,
}

--[[      No need to change anything below this line ;)     ]]--

local utf_match = utf.match

local util_loadtable = util.loadtable
local util_savetable = util.savetable

-- File to store blocked users in
local sFilePath = "scripts/data/ptx_anti_dl_tAntiDL.tbl"
local tAntiDL = util_loadtable( sFilePath ) or {}

-- File to store blocked user history in
local sStatFilePath = "scripts/data/ptx_anti_dl_tStatAntiDL.tbl"
local tStatAntiDL = util_loadtable( sStatFilePath ) or {}

local opchat = hub.import "bot_opchat"

local hubcmd

----------
--[CODE]--
----------

--[[ The stuff required to fix so we get ordered pairs on multitype tabels :P ]]--
local cmp_multitype = function(op1, op2)
	local type1, type2 = type(op1), type(op2)
	if type1 ~= type2 then -- cmp by type
		return type1 < type2
	elseif type1 == "number" and type2 == "number"
		or type1 == "string" and type2 == "string" then
		return op1 < op2 -- cmp by default
	elseif type1 == "boolean" and type2 == "boolean" then
		return op1 == true
	else
		return tostring(op1) < tostring(op2) -- cmp by address
	end
end

local __genOrderedIndex = function(t)
	local orderedIndex = {}
	for key in pairs(t) do
		table.insert(orderedIndex, key)
	end
	table.sort(orderedIndex, cmp_multitype)
	return orderedIndex;
end

local orderedNext = function(t, state)
	local key = nil
	if state == nil then
		t.__orderedIndex = __genOrderedIndex(t)
		key = t.__orderedIndex[1]
		return key, t[key]
	end
	for i, value in pairs( t.__orderedIndex ) do
		if value == state then
			key = t.__orderedIndex[i+1]
		end
	end
	
	if key then
		return key, t[key]
	end
	
	t.__orderedIndex = nil
	return
end

local opairs = function(t)
	return orderedNext, t, nil
end

-- Check Commands here!!!
local onbmsg = function( tUser, adccmd, parameters, txt )
	local param1 = utf_match( parameters, "^(%S+)" )
	local param2 = utf_match( parameters, "^%S+%s+(%S+)" )
	local param3 = utf_match( parameters, "^%S+%s+%S+%s+(.*)" )
	local user_level = tUser:level()
	if param1 == cmd_p_add then
		if user_level >= oplevel then
			if param2 then
				local _, regnicks, regcids = hub.getregusers( )
				local tNick = regnicks[ param2 ]
				if not tNick then
					tUser:reply("The user "..param2.." is not registered with us, thus he can not be added to the list!", tSettings.sBot)
					return PROCESSED
				end
				if tAntiDL[param2] then
					tUser:reply("Ooops, the user "..param2.." is already added by "..tAntiDL[param2]["sBy"]..", and has been added to the list since "..tAntiDL[param2]["sSince"]..".", tSettings.sBot)
					return PROCESSED
				else
					-- Check if user belongs to a profile with immunity against this script
					if tSettings.tImmune[tNick.level] and tSettings.tImmune[tNick.level] == 1 then
						tUser:reply("Ooops, the user "..param2.." belongs to a profile that are Immune to this script...", tSettings.sBot)
						return PROCESSED
					end
					if param3 then
						tAntiDL[param2] = { ["sBy"] = tUser:nick(), ["sSince"] = os.date("%Y-%m-%d %H:%M:%S"), ["sReason"] = param3}
					else
						tAntiDL[param2] = { ["sBy"] = tUser:nick(), ["sSince"] = os.date("%Y-%m-%d %H:%M:%S")}
					end
					if tStatAntiDL[param2] then 
						tStatAntiDL[param2] = tStatAntiDL[param2] +1
					else
						tStatAntiDL[param2] = 1
					end
					util_savetable( tAntiDL, "tAntiDL", sFilePath )
					util_savetable( tStatAntiDL, "tStatAntiDL", sStatFilePath )
					tUser:reply(param2.." has been succesfully added to the Anti-Download list!", tSettings.sBot)
					if tSettings.bNotifyOps then
						opchat.feed(tUser:nick().." added " ..param2.. " to the Anti-Download list")
					end
				end
			else
				tUser:reply("Syntax Error, please check !nodl help", tSettings.sBot)
			end
		end
		return PROCESSED
	end
	if param1 == cmd_p_del then
		if user_level >= oplevel then
			if param2 then
				if tAntiDL[param2] then
					tAntiDL[param2] = nil
					util_savetable( tAntiDL, "tAntiDL", sFilePath )
					tAntiDL = util_loadtable( sFilePath ) or {}
					tUser:reply(param2.." has been succesfully removed from the Anti-Download list!", tSettings.sBot)
					if tSettings.bNotifyOps then
						opchat.feed(tUser:nick().." removed "..param2.." from the Anti-Download list")
					end
				else
					tUser:reply("Sorry, I don't seem to have "..param2.." in my list...", tSettings.sBot)
				end
			else
				tUser:reply("Syntax Error, please check !nodl help", tSettings.sBot)
			end
		end
		return PROCESSED
	end
	if param1 == cmd_p_list then
		if user_level >= oplevel then
			local sRet = "\r\r\n\t\t\t\tCurrent List of Users in Anti-Download list:\r\n============================================================================================================================================\r\n"
			for nick,v in opairs(tAntiDL) do
				if nick ~= nil and v.sBy ~= nil and v.sSince ~= nil then
					if v.sReason ~= nil then
						sRet = sRet..tostring(nick).." \t\t Since: "..tostring(v.sSince).." \t\t Added by: "..tostring(v.sBy).." \t\t Reason: "..tostring(v.sReason).."\r\n"
					else
						sRet = sRet..tostring(nick).." \t\t Since: "..tostring(v.sSince).." \t\t Added by: "..tostring(v.sBy).."\r\n"
					end
				end
			end
			tUser:reply(sRet, tSettings.sBot)
		end
		return PROCESSED
	end
	if param1 == cmd_p_listblocks then
		if user_level >= oplevel then
			if next(tStatAntiDL) then
				local msg = "\r\r\n\tNumber of times users have been blocked:\r\n"..string.rep("=", 45).."\r\n"
				local tCopy ={}
				-- Loop through hubbers			
				for i, v in pairs(tStatAntiDL) do
					-- Insert stats to temp table
					table.insert(tCopy, { suser = i, stimes = v } )
				end
				-- Sort by total time
				table.sort(tCopy, function(a, b) return (a.stimes > b.stimes) end)
				-- Loop through temp table
				for i, v in pairs(tCopy) do
					msg = msg..v.suser.."   \t\t\t\t"..v.stimes.." time(s)\r\n"
				end
				msg = msg..string.rep("-", 90).."\r\n"
				-- Send
				tUser:reply(msg, tSettings.sBot)
			else
				tUser:reply("Block list is currently empty!", tSettings.sBot)
			end
		end
		return PROCESSED
	end
	if param1 == cmd_p_changeblocks then
		if user_level >= oplevel then
			if param2 and tonumber(param3) then
				if tStatAntiDL[param2] then
					if tonumber(param3) == 0 then 
						tStatAntiDL[param2] = nil
						tUser:reply("You have deleted "..param2.." from the list", tSettings.sBot)
					else
						tStatAntiDL[param2] = tonumber(param3)
						tUser:reply("You have changed "..param2.."'s value", tSettings.sBot)
					end
					util_savetable( tStatAntiDL, "tStatAntiDL", sStatFilePath )
					tStatAntiDL = util_loadtable( sStatFilePath ) or {}
				else
					tUser:reply("Sorry, I don't seem to have "..param2.." in my list...", tSettings.sBot)
				end
			else
				tUser:reply("Syntax Error, please check !nodl help", tSettings.sBot)
			end
		end
		return PROCESSED
	end
	if param1 == cmd_p_help then
		if user_level >= oplevel then
			local sHelp = "\r\n"
			sHelp = sHelp.."Anti-DL list Help:\r\n==================\r\n"
			sHelp = sHelp.."!nodl add <nick>\t- Add a user to the list\r\n"
			sHelp = sHelp.."!nodl del <nick>\t- Remove a user from the list\r\n"
			sHelp = sHelp.."!nodl list\t\t- View list of Users currently in the list\r\n"
			sHelp = sHelp.."!nodl listblocks\t\t- View list of User Blocks currently in the list\r\n"
			sHelp = sHelp.."!nodl changeblocks <nick> <blocks>\t- Change number of blocks for a user\r\n"
			sHelp = sHelp.."!nodl help\t\t- This text ;)"
			tUser:reply(sHelp, tSettings.sBot)
		end
		return PROCESSED
	end
end

hub.setlistener( "onStart", { },
	function()
		hub.debug("Anti-DL v2.0 loading..")
		local ucmd = hub.import "etc_usercommands.lua"
		if ucmd then
			ucmd.add( { "* Punish *", "* Block users down and upload *", "* Add User to the list *" }, cmd, { cmd_p_add, "%[line:Complete Nick of user]", "%[line:Reason]" }, { "CT1" }, oplevel )
			ucmd.add( { "* Punish *", "* Block users down and upload *", "* Delete User from the list *" }, cmd, { cmd_p_del, "%[line:Complete Nick of user]" }, { "CT1" }, oplevel )
			ucmd.add( { "* Punish *", "* Block users down and upload *", "* Who are blocked *" }, cmd, { cmd_p_list }, { "CT1" }, oplevel )
			ucmd.add( { "* Punish *", "* Block users down and upload *", "* Number of times user blocked *" }, cmd, { cmd_p_listblocks }, { "CT1" }, oplevel )
			ucmd.add( { "* Punish *", "* Block users down and upload *", "* Change number of times user blocks *" }, cmd, { cmd_p_changeblocks, "%[line:Complete Nick of user]", "%[line:typ:New number of blocks, 0 = delete]" }, { "CT1" }, oplevel )
			ucmd.add( { "* Punish *", "* Block users down and upload *", "* Help *" }, cmd, { cmd_p_help }, { "CT1" }, oplevel )
			ucmd.add( { "* Block users down and upload *", "* Add this user to list *" }, cmd, { cmd_p_add, "%[userNI]", "%[line:Reason]" }, { "CT2" }, oplevel )
			ucmd.add( { "* Block users down and upload *", "* Delete this user from list *" }, cmd, { cmd_p_del, "%[userNI]" }, { "CT2" }, oplevel )
			ucmd.add( { "* Block users down and upload *", "* Change number of blocks *" }, cmd, { cmd_p_changeblocks, "%[userNI]", "%[line:typ:New number of blocks, 0 = delete]" }, { "CT2" }, oplevel )
		end
		hubcmd = hub.import "etc_hubcommands"
		assert( hubcmd )
		assert( hubcmd.add( cmd, onbmsg ) )
		hub.debug("Anti-DL v2.0 loaded!")
		return nil
	end
)

hub.setlistener( "onExit", { },
	function()
		util_savetable( tAntiDL, "tAntiDL", sFilePath )
		util_savetable( tStatAntiDL, "tStatAntiDL", sStatFilePath )
	end
)

hub.setlistener( "onSearch", { },
	function(tUser, tAdccmd)
		if tSettings.bSearch then
			if tAntiDL[tUser:nick()] then
				if not tSettings.bSilent then
					tUser:reply(tSettings.sNoSearchMsg, tSettings.sBot, tSettings.bNotifyPM)
					if tAntiDL[tUser:nick()].sReason then
						tUser:reply(tAntiDL[tUser:nick()].sReason, tSettings.sBot, tSettings.bNotifyPM)
					end
				end
				return PROCESSED
			end
		end
	end
)

local checkuser = function(tUser)
	if tSettings.bCTM then
		if tAntiDL[tUser:nick()] then
			if not tSettings.bSilent then
				tUser:reply(tSettings.sNoCTMMsg, tSettings.sBot, tSettings.bNotifyPM)
				if tAntiDL[tUser:nick()].sReason then
					tUser:reply(tAntiDL[tUser:nick()].sReason, tSettings.sBot, tSettings.bNotifyPM)
				end
			end
			return PROCESSED
		end
	end
end

hub.setlistener( "onConnectToMe", { }, checkuser) 

hub.setlistener( "onRevConnectToMe", { }, checkuser) 

hub.setlistener( "onLogin", { }, 
	function(tUser)
		if tSettings.bMsgOnConnect and tAntiDL[tUser:nick()] then
			tUser:reply(tSettings.sMsgOnConnect, tSettings.sBot, tSettings.bNotifyPM)
			if tAntiDL[tUser:nick()].sReason then
				tUser:reply(tAntiDL[tUser:nick()].sReason, tSettings.sBot, tSettings.bNotifyPM)
			end
		end
	end
)

--[[Do we need this?
ToArrival = function(tUser,sData)
	local _,_,sTo = sData:find("^%$To:%s+(%S+)%s+From:")
	if sTo == nil or sTo ~= tSettings.sBot then
		return false
	else
		return ChatArrival(tUser,sData)
	end
end
]]--


hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )


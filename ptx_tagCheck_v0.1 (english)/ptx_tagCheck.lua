--[[

	TagCheck 2.01 LUA 5.1x [Strict] [API 2]

	By Mutor	01/21/07
    
    Converted by Jerker

	Requested by miago

	Checks min/max slots and max hubs for specified reg prefix tags
	
	+Changes from 1.0	04/21/08
		~ Converted to Lua 5.1x strict
		~ Converted to API 2 strict
		+ Added report missing slots or hubs in MyINFO

	+Changes from 2.0	09/05/08
		+Added option to check all online users on script start
		+Added full profile table
		+Added check to UserConnected,OpConnected,RegConnected arrivals
		~OpNick option, if OpNick = "" then message sent to OpChat]

]]

local scriptname = "ptx_tagCheck"
local scriptversion = "0.1"

--Script configuration
local tSettings = {
-- Name for bot
Bot = hub.getbot( ),
--Time to ban the user, in minutes
BanTime = 10,
-- Profile(s) to check
Profiles = {
	[ 0 ] = true,    --"UNREG"
	[ 10 ] = true,   --"GUEST"
	[ 20 ] = true,   --"REG"
	[ 30 ] = false,   --"VIP"
	[ 40 ] = false,   --"SVIP"
	[ 50 ] = false,   --"SERVER"
	[ 60 ] = false,  --"OPERATOR"
	[ 70 ] = false,  --"SUPERVISOR"
	[ 80 ] = false,  --"ADMIN"
	[ 100 ] = false, --"HUBOWNER"

	},
--["Tag"] = {minslots,maxslots,maxhubs}.
--Use lower case here
Params = {
	["[0.3]"] = {1,3,15},
	["[0.5]"] = {1,3,15},
	["[0.7]"] = {1,3,15},
	["[0.8]"] = {1,3,15},
	["[1.0]"] = {1,3,15},
	["[1.5]"] = {1,3,15},
	["[2.0]"] = {1,3,15},
	["[2.5]"] = {1,3,15},
	["[3.0]"] = {1,3,15},
	["[4.0]"] = {1,3,15},
	["[4.5]"] = {1,3,15},
	["[5.0]"] = {1,3,15},
	["[5.5]"] = {2,5,15},
	["[6.0]"] = {2,5,15},
	["[7.0]"] = {2,5,15},
	["[8.0]"] = {2,5,15},
	["[9.0]"] = {2,5,15},
	["[10]"] = {2,5,15},
	["[11]"] = {5,10,15},
	["[12]"] = {5,10,15},
	["[15]"] = {5,10,15},
	["[20]"] = {5,10,15},
	["[24]"] = {5,10,15},
	["[25]"] = {5,10,15},
	["[30]"] = {5,10,15},
	["[40]"] = {5,10,15},
	["[50]"] = {5,10,15},
	["[60]"] = {5,10,15},
	["[70]"] = {5,10,15},
	["[75]"] = {5,10,15},
	["[80]"] = {5,10,15},
	["[100]"] = {5,10,15},
	["[200]"] = {10,20,15},
	["[250]"] = {10,20,15},
	["[500]"] = {10,20,15},
	["[1000]"] = {15,30,15},
	},
}

local os_date = os.date
local os_time = os.time
local utf_format = utf.format
local util_savearray = util.savearray
local hub_escapeto = hub.escapeto
local hub_escapefrom = hub.escapefrom

local bans_path = "scripts/cmd_ban/bans.tbl"
local opchat = hub.import "[-SPR-]OpChat"
local bans
local bans_path

local OnError = function(msg)
	opchat.feed(msg)
end

local TempBan = function(user, time, reason, banned)
    local bantime = time * 60
    local targetnick = user:nick( )
    local targetfirstnick = user:firstnick( )
    local botnick = "-=TagCheck=-"
    local message = utf_format( "%s was banned by %s for %s minutes because: %s", hub_escapefrom( targetnick ), botnick, time, reason )
	if not banned then	
		bans[ #bans + 1 ] = {

			nick = targetfirstnick,
			cid = user:cid( ),
			hash = user:hash( ),
			ip = user:ip( ),
			time = bantime,
			start = os_time( os_date( "*t" ) ),
			reason = reason,
			by_nick = botnick,
			by_level = 60

		}
		util_savearray( bans, bans_path )
	end
    --user:reply( message, hub_getbot )
    user:kill( "ISTA 230 " .. hub_escapeto( message ) .. " TL" .. bantime .. "\n" )

end

local IsUserBanned = function( user )
	local nick, cid, hash, ip = user:nick( ), user:cid( ), user:hash( ), user:ip( )
	local retVal = false
	for i, bantbl in ipairs( bans ) do
		if bantbl.nick == nick then
			retVal = true
			break
		elseif bantbl.cid == cid and bantbl.hash == hash then
			retVal = true
			break
		elseif bantbl.ip == ip then
			retVal = true
			break
		end
	end
	return retVal
end

local CheckUser = function(user)
	local Msg,Kick = "",false
	local j,p = user:level(),"Unregistered User"
	if j then p = cfg.get("levels")[j] or "LEVEL: "..tostring(j) end
	local _,_,tag = user:nick():find("^(%b[])[^ ]+")
	if tag then
		tag = tag:lower()
		if tSettings.Params[tag] then
			for i,v in ipairs(tSettings.Params[tag]) do
				local slots,hubs,reghubs,ophubs = user:slots( ),user:hubs( )
				if reghubs then
					if not hubs then
						hubs = reghubs
					else
						hubs = hubs + reghubs
					end
				end
				if ophubs then
					if not hubs then
						hubs = ophubs
					else
						hubs = hubs + ophubs
					end
				end
				if slots and hubs then
					if i == 2 and slots > v then
						Msg = Msg.."You have too many slots open. "..tag.."'s are required to have a "..
						"maximum of "..v.." slots open. You have "..slots.." slots."
						Kick = true
						break
					elseif i == 1 and slots < v then
						Msg = Msg.."You have too few slots open. "..tag.."'s are required to have a "..
						"minimum of "..v.." slots open. You have only "..slots.." slots."
						Kick = true
						break
					elseif i == 3 and hubs > v then
						Msg = Msg.."You are in too many hubs. "..tag.."'s are required to have a "..
						"maximum of "..v.." hub connections. You are connected to "..hubs.." hubs."
						Kick = true
						break
					end
				else
					if not slots then OnError(p.." "..user:nick().." bad MyINFO, missing a slots.") end
					if not hubs then OnError(p.." "..user:nick().." bad MyINFO, missing a hubs.") end
				end
			end
		else
			OnError(p.." "..user:nick().." is using an invalid prefix tag.")
		end
	else
		OnError(p.." "..user:nick().." is missing a prefix tag.")
	end
	if Kick then
		local nick,OpMsg = user:nick(),Msg:gsub("You have", user:nick().." has")
		OpMsg = OpMsg:gsub("You are", user:nick().." is")
		local isBanned = IsUserBanned(user)
        if not isBanned then
			OnError(OpMsg)
		end
		TempBan(user, tSettings.BanTime, Msg, isBanned)
		if not isBanned and not hub.isnickonline(nick) then
			OnError(nick.." has been removed from the hub.")
		end
		return PROCESSED
	end
end

hub.setlistener( "onStart", { },
	function()
        local ban = hub.import "cmd_ban"
        if not ban then
            error( msg_import )
        end
        bans = ban.bans
        bans_path = ban.bans_path

		for sid, user in pairs( hub.getusers( ) ) do
			if tSettings.Profiles[user:level()] then
				CheckUser(user)
			end
		end
	end
)
hub.setlistener( "onInf", { },
    function( user, cmd )
        if ( cmd:getnp "HN" or cmd:getnp "HR" or cmd:getnp "HO" or cmd:getnp "SL" ) and tSettings.Profiles[user:level()] then
            return CheckUser(user)
        end
        return nil
    end
)

hub.setlistener( "onLogin", { },
    function( user )
        if tSettings.Profiles[user:level()] then
            return CheckUser(user)
        end
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
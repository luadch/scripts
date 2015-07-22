-- Poll.Bot.v.1.3c in LUA 5.1
-- Finally a good pollbot ;-)
-- Created by TTB on 08 November 2006
-- For PtokaX 0.4.0.0 or higher since 12.06.08

-- v.1.1: 
-- [Fixed] Little bugs
-- v.1.2: 
-- [Added] Graph bars on current poll
-- [Fixed] Little bugs
-- v.1.3: 
-- [Added] Graph bars on oldpolls
-- [Added] Multiple votes for poll (#polladd edit!)
-- [Added] #pollusers - who voted already?
-- v.1.3b:
-- [Conversion] 5.02 to 5.1
-- v.1.3c: 12.06.08
-- [Conversion] Quick Convert to API2, By Madman
-- v1.3d: 26.06.08
-- [Fixed] #pollhelp, reported T.C.M
-- [Fixed] Reg don't Rightclick, reported by miago
-- [Fixed] 'SendPmToUser' (3 expected, got 2) bug, reported by miago
-- [Fixed] bug when trying to create poll, reported by miago
-- v1.3e: 29.06.08
-- [Fixed] Fixed buwg, when showing current user as created when checking #pollusers, reported by miago
-- v1.3f: 12.07.08
-- [Fixed] bug with WriteFile, files saved at wrong path
-- v1.3g: 12.07.08
-- [Fixed] SendToPmUser error in OldPoll
-- v1.3h: 21.07.08
-- [Changed] New #oldpoll layout
-- v1.4: 23.07.08
-- [Added] Option to disallow users from voteing on same answer more then once, request by dimetrius
-- [Changed] Layout of pollvotes table
--[[-- !IMPORTANT!
The new layout makes the pollvotes table invalid.
So BEFORE upgrade to 1.4, finsih your current running poll,
or all users will be able to vote again!
--]]--
-- [Removed] UserDisconnected function, it did not do anything
-- [Fixed] Bug in pollusers, due to new pollvotes
-- v1.4a: 25.07.08
-- [Fixed] Pollanswers got unsorted, thanks dimetrius for fix
-- v2.0: 15.08.08
-- [Fixed] bug in sorting poll
-- [Changed] Align of votes, thanks to fodin for code
-- [Added] FullBars option, code from fodin
-- [Added] ShowShare option, code from fodin
-- [Added] Tabel for language
-- [Changed] lanuage moved to file
-- [Changed] Path to files, now default to scripts/Poll/file
-- [Added] Commands can now be translated
-- [Added] Fully supported multi lang
-- v2.0: 12.10.08
-- [Fixed] typo in RC
-- v2.0: 27.02.09
-- [Fixed] another typo in RC
-- v3.0 14.10.14
-- Converted to Luadch by Jerker/Kungen

----------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
--------------------------------------------------------------------
--[[ 
There are many features on this bot. When a bot has been created, everyone only gets a PM. When ppl log into the hub, they will get a PM if they did not vote already. 
Just check it out... if you have special requests, post them. I always can see what I can do :-)

Your commands:

All users:
#pollhelp - Check the commands
#poll - View the current poll 
#poll <nr> - Vote when poll is active 
#pollusers - List of voted ppl
#oldpoll - List of all oldpolls 
#oldpoll <pollname> - View old poll 
Operators:
#polladd <name> <nr> <subj> - Create a new poll 
#pollclose - Close current poll, and add it to oldpolls 
#polldel - Delete current poll (it won't be added to oldpolls) 
#oldpolldel <pollname> - Delete oldpoll forever 

NOTE: All commands can be done in the main chat. Only the wizard and the #poll command can be done in PM to the bot.
]]--

--------------------------------------------------------------------
-- Settings
--------------------------------------------------------------------
local botName = "-=[.Poll.Bot.]=-"
local botDesc = "bot description"
local bot = hub.getbot( )
local prefix = "[+!#]"

-- The graphical bar on reply with the votes. Default = 30.
local lengthbar = 30

-- The users with true are the OPs and do have extra settings!
local oplevel = 60

-- Registered users
local reglevel = 20
 
-- Users can't vote more then once on the same answer
-- Set to true to activate
local NoMultiVotes = false

-- Entire graph have the same width regardless of the bar value, % of votes is shown by • dotes
local FullBars = false

-- Users can vote by just typeing nr insted of !poll nr
local NoCmdVote = false

-- Show users share in pollusers (if user online) 
local ShowShare = false

-- The Files used by this script
local polllang = "scripts/data/ptx_poll_bot_english.lang"
local pollvotes = "scripts/data/ptx_poll_bot_pollvotes.tbl" -- Holds the voters of active poll
local pollsettings = "scripts/data/ptx_poll_bot_pollsettings.tbl" -- Holds the settings of active poll
local pollold = "scripts/data/ptx_poll_bot_pollold.tbl" -- Hold old polls

local utf_match = utf.match
local util_loadtable = util.loadtable
local util_serialize = util.serialize
local io_open = io.open
local hubcmd

local tLang = util_loadtable( polllang ) or {}
--loadlua(polllang, polllang.. " for " ..botName.. "bot found, or could not be loaded")
local PollVotes = util_loadtable( pollvotes ) or {}
--loadlua(pollvotes, pollvotes.." for "..botName.." not found")
local PollSettings = util_loadtable( pollsettings ) or {}
--loadlua(pollsettings, pollsettings.." for "..botName.." not found")
local OldPolls = util_loadtable( pollold ) or {}
--loadlua(pollold, pollold.." for "..botName.." not found")

local teller = 0
local CurrentPoll ={}

local savetable = function( tbl, name, path )
    local file, err = io_open( path, "w+" )
    if file then
        file:write( "local " .. name .. "\n\n" )
        util_serialize( tbl, name, file, "" )
        file:write( "\n\nreturn " .. name )
        file:close( )
        return true
    else
        out_error( "etc_Poll.Bot.v.3.0.LUA5.1.lua: error in ", path, ": ", err, " (savetable)" )
        return false, err
    end
end

--------------------------------------------------------------------
-- Preloading
--------------------------------------------------------------------
local StringTranslate = function (Text)
	Text = string.gsub(Text, "%[bot%]", botName)
	Text = string.gsub(Text, "%[cPollAdd%]", tLang.tCmds.polladd)
	Text = string.gsub(Text, "%[cPoll%]", tLang.tCmds.poll)
	Text = string.gsub(Text, "%[cVote%]", tLang.tCmds.vote)
	Text = string.gsub(Text, "%[cOldPoll]", tLang.tCmds.oldpoll)
	Text = string.gsub(Text, "%[cPollDel]", tLang.tCmds.polldel)
	Text = string.gsub(Text, "%[cOldPollDel]", tLang.tCmds.oldpolldel)
	Text = string.gsub(Text, "%[prefix%]", prefix)
	return Text
end

local LangTranslate = function ()
	for value,text in pairs(tLang) do
		if type(text) == "table" then
			-- text was a table, there for we will get subs...
			for subvalue,subtext in pairs(text) do
				subtext = StringTranslate(tostring(subtext)) -- Transalte text
				tLang[value][subvalue] = subtext -- Change text to transleted text
			end
		else
			text = StringTranslate(tostring(text))
			tLang.value = text
		end
	end
end

--------------------------------------------------------------------
-- Help commands
--------------------------------------------------------------------
local MainInfo = ("\r\n\t--<>--------------------------------------------------------------------------------------------------------------------------------------------------------<>--"..
		"\r\n\t\t\t [ POLL Help ]\t\t\t [ POLL Help ]\r\n\t"..
		"--<>--------------------------------------------------------------------------------------------------------------------------------------------------------<>--"..
		"\r\n\t\t "..prefix..tLang.cmd.." "..tLang.tCmds.poll.."\t\t\t\t=\t"..tLang.tHelp.ViewPoll..
		"\r\n\t\t "..prefix..tLang.cmd.." "..tLang.tCmds.pollusers.."\t\t\t=\t"..tLang.tHelp.Voted..
		"\r\n\t\t "..prefix..tLang.cmd.." "..tLang.tCmds.oldpoll.."\t\t\t\t=\t"..tLang.tHelp.ListOld..
		"\r\n\t\t "..prefix..tLang.cmd.." "..tLang.tCmds.oldpoll.." <"..tLang.tHelp.Name..">\t\t=\t"..tLang.tHelp.ViewOld..
		"\r\n\t--<>--------------------------------------------------------------------------------------------------------------------------------------------------------<>--")
local OPInfo = ("\r\n\t\t "..prefix..tLang.cmd.." "..tLang.tCmds.polladd.." "..tLang.tHelp.CreateOpt.."\t=\t"..tLang.tHelp.Create..
		"\r\n\t\t "..prefix..tLang.cmd.." "..tLang.tCmds.pollclose.."\t\t\t=\t"..tLang.tHelp.Close..
		"\r\n\t\t "..prefix..tLang.cmd.." "..tLang.tCmds.polldel.."\t\t\t\t=\t"..tLang.tHelp.Del..
		"\r\n\t\t "..prefix..tLang.cmd.." "..tLang.tCmds.oldpolldel.." <"..tLang.tHelp.Name..">\t\t=\t"..tLang.tHelp.DelOld..
		"\r\n\t--<>--------------------------------------------------------------------------------------------------------------------------------------------------------<>--\r\n")

---------------------------------------------------------------------------------------------------
-- Display a graphbar. DoBar by Herodes
---------------------------------------------------------------------------------------------------
local DoBars = function( val, max, length )
	local lenght = length or 10
	local ratio = (val / ( max/length) )
	if FullBars then
		-- Made by fodin
		return "["..string.rep("•", ratio)..string.rep("--", length-ratio).."]"
	else
		return "["..string.rep("-", ratio).."¦"..string.rep(" ", length-ratio).."]"
	end
end

local ShowPollWithResult = function(curUser,data)
	local PollText = "\r\n"..string.rep("*",50).."\r\n"..tLang.Poll..": "..PollSettings["subject"].."\r\n"..string.rep("*",50).."\r\n\r\n"
	local c = tonumber(PollSettings["votes"]["n"])
	for a=1,table.maxn(PollSettings["active"]) do
		local bar = DoBars(string.format("%.0f",(100/c)*PollSettings["votes"][a]),100,lengthbar)
		PollText = PollText..a..". "..string.rep(" ",(2-string.len(a))*2+1)..PollSettings["votes"][a].." "..tLang.Votes.."\t"..bar.." ("..string.format( "%.2f",(100/c)*PollSettings["votes"][a]).."%)  "..PollSettings["active"][a].."\r\n"
	end
	PollText = PollText.."\r\n"..tLang.TotVotes..": "..PollSettings["votes"]["n"].." (100.00%)\r\n"..string.rep("*",50).."\r\n"..tLang.PollMe.Created..": "..PollSettings["currentcreator"].."\r\n"..tLang.PollMe.CreatedOn..": "..PollSettings["date"].."\r\n"..string.rep("*",50)
	curUser:reply(PollText, bot, bot)
	PollText = nil
end

local ShowPollWithNoResult = function(curUser)
	local PollText = "\r\n"..string.rep("*",50).."\r\n"..tLang.Poll..": "..PollSettings["subject"].."\r\n"..string.rep("*",50).."\r\n\r\n"
	for a=1,table.maxn(PollSettings["active"]) do
		PollText = PollText..a..". "..string.rep(" ",(2-string.len(a))*2+1)..PollSettings["active"][a].."\r\n"
	end
	PollText = PollText.."\r\n" ..tLang.PollMe.CanVote.." "..PollSettings["maxvote"].."x.\r\n"..tLang.PollMe.GiveAns.."\r\n"..string.rep("*",50).."\r\n" ..tLang.PollMe.Created.. ": "..PollSettings["currentcreator"].."\r\n"..string.rep("*",50)
	curUser:reply(PollText, bot, bot)
	PollText = nil
end

--------------------------------------------------------------------
-- Creating a Poll
--------------------------------------------------------------------
local NewPoll = function(curUser,data)
	local namepoll,votemax,questions,subject = utf_match(data,"^(%S+)%s+(%d+)%s+(%d+)%s+(.+)")
	if subject == nil or questions == nil then
		curUser:reply(tLang.Error.BadPollAdd.."\r\n"..tLang.Error.BaddPollAddEx, bot)
	else
		if namepoll == OldPolls[namepoll] then
			curUser:reply(tLang.BadPollName, bot)
		else
			local questions = tonumber(questions)
			local votemax = tonumber(votemax)
			if questions > 20 then
				curUser:reply(tLang.Plus20, bot)
			elseif questions < 2 then
				curUser:reply(tLang.More2Ans, bot)
			elseif votemax < 1 then
				curUser:reply(tLang.pplNeedVote, bot)
			elseif votemax >= questions then
				curUser:reply(tLang.ToMuchVotes, bot)
			else
				if PollSettings["current"] == nil then
					PollSettings = {}
					PollSettings["current"] = 1
					PollSettings["currentcreator"] = curUser:nick()
					PollSettings["title"] = namepoll
					PollSettings["questions"] = questions
					PollSettings["subject"] = subject
					PollSettings["maxvote"] = votemax
					PollSettings["date"] = os.date("[%X] / [%d-%m-20%y]")
					curUser:reply("---------------->>> " ..tLang.GoGandalf.. " <<<----------------", bot)
					savetable(PollSettings, "PollSettings", pollsettings)
					curUser:reply("\r\n"..string.rep("*",50).."\r\n\t"..tLang.Gandalf.Wizard.."\r\n"..string.rep("*",50).."\r\n"..tLang.Gandalf.WizKid.." = "..curUser:nick().."\r\n"..tLang.Gandalf.Name.." = "..PollSettings["title"].."\r\n"..tLang.Gandalf.Votes..": "..PollSettings["maxvote"].."\r\n"..tLang.Gandalf.PollQs..": "..PollSettings["subject"].."\r\n"..tLang.Gandalf.PollAns.." = "..PollSettings["questions"].."\r\n"..string.rep("*",50), bot, bot)
					teller = 1
					curUser:reply(tLang.Answer.." "..teller.."/"..questions..":", bot, bot)
				elseif PollSettings["current"] == 1 then
					curUser:reply(tLang.PollIsConfig.." "..PollSettings["currentcreator"], bot)
				elseif PollSettings["current"] == 2 then
					curUser:reply(tLang.CloseRunPoll, bot)
				end
			end
		end
		return true
	end
end

---------------------------------------------------------------------------------------------------
-- Poll is running... let all ppl know by mass message! :-)
---------------------------------------------------------------------------------------------------
local Poll = function(curUser,data)
	local PollText = "\r\n"..string.rep("*",50).."\r\n"..tLang.Poll..": "..PollSettings["subject"].."\r\n"..string.rep("*",50).."\r\n\r\n"
	for a=1,table.maxn(PollSettings["active"]) do
		PollText = PollText..a..". "..string.rep(" ",(2-string.len(a))*2+1)..PollSettings["active"][a].."\r\n"
	end
	PollText = PollText.."\r\n"..tLang.PollMe.CanVote.." "..PollSettings["maxvote"].."x.\r\n"..tLang.PollMe.GiveAns.."\r\n"..string.rep("*",50).."\r\n"..tLang.PollMe.Created..": "..PollSettings["currentcreator"].."\r\n"..string.rep("*",50)
	for sid,user in pairs(hub.getusers()) do
		user:reply(PollText, bot, bot)
	end
end

---------------------------------------------------------------------------------------------------
-- Clean it all up
---------------------------------------------------------------------------------------------------
local ClearActivePoll = function()
	teller = 0
	PollSettings = nil
	PollSettings = {}
	savetable(PollSettings, "PollSettings", pollsettings)
	CurrentPoll = nil
	CurrentPoll ={}
	PollVotes = nil
	PollVotes = {}
	savetable(PollVotes, "PollVotes", pollvotes)
	collectgarbage()
end

local Convert = function(curUser,data) -- This function will convert the answers from memory to the db file
	if PollSettings["current"] == 2 then
		PollSettings["active"] = {}
		PollSettings["votes"] = {}
		PollSettings["votes"]["n"] = 0
		for a,b in pairs(CurrentPoll) do
			PollSettings["active"][a] = b
			PollSettings["votes"][a] = 0
		end
		savetable(PollSettings, "PollSettings", pollsettings)
		CurrentPoll = nil
		CurrentPoll ={}
		Poll(curUser,data)
	else
		curUser:reply(tLang.Error.BadConvert, bot, bot)
		ClearActivePoll()
	end
end

local ConfigPoll = function(curUser,data)
	local tellermax = PollSettings["questions"]
	CurrentPoll[teller] = data
	teller = teller + 1
	if teller > tellermax then
		teller = 0
		PollSettings["current"] = 2
		savetable(PollSettings, "PollSettings", pollsettings)
		curUser:reply(tLang.YayNewPoll, bot, bot)
		hub.broadcast("-------->>>>>>>>>> " ..tLang.NewPoll.." <--> " ..tLang.PleaseVote.. " <<<<<<<<<<--------", bot)
		Convert(curUser,data)
	else
		curUser:reply(tLang.Answer.." "..teller.."/"..tellermax..":", bot, bot)
	end
end

local PollPM = function(curUser,data)
	local cmd = utf_match(data,"^(%S+)")
	if NoCmdVote then
		if tonumber(cmd)~=nil then 
			cmd=tLang.tCmds.vote
		end
	end
	if cmd and (string.lower(cmd) == (tLang.tCmds.vote)) then
		local cmd,answer = utf_match(data,"^(%S+)%s+(%d+)")
		if NoCmdVote then
			if cmd==nil then
				answer = utf_match(data,"^(%d+)")
			end
		end
		if PollSettings["current"] == 2 then
			if answer then
				if PollVotes[curUser:nick()] then
					if PollVotes[curUser:nick()]["n"] >= PollSettings["maxvote"] then
						curUser:reply(tLang.MaxVote.Voted.." "..PollSettings["maxvote"].." "..tLang.MaxVote.FinishIt, bot, bot)
						return true
					end
					if NoMultiVotes then
						if PollVotes[curUser:nick()][tostring(answer)] == true then
							curUser:reply(tLang.VotedAns, bot, bot)
							return true
						end
					end
				end
				answer = tonumber(answer)
				if answer > PollSettings["questions"] then
					curUser:reply(tLang.Error.Err.." "..tLang.Answer.." "..answer.." " ..tLang.Error.NoList, bot, bot)
					-- Yeah, it's splited in to 3 diffrent, I could have done 2, but why? ;p
				else
					PollSettings["votes"][answer] = PollSettings["votes"][answer] + 1
					PollSettings["votes"]["n"] = PollSettings["votes"]["n"] + 1
					savetable(PollSettings, "PollSettings", pollsettings)
					if PollVotes[curUser:nick()] then
						PollVotes[curUser:nick()][tostring(answer)] = true
						PollVotes[curUser:nick()]["n"] = PollVotes[curUser:nick()]["n"] + 1
					else
						PollVotes[curUser:nick()] = {}
						PollVotes[curUser:nick()]["n"] = 1
						PollVotes[curUser:nick()][tostring(answer)] = true
					end
					savetable(PollVotes, "PollVotes", pollvotes)
					ShowPollWithResult(curUser,data)
					if PollVotes[curUser:nick()]["n"] == PollSettings["maxvote"] then
						curUser:reply(tLang.ThanksForVote.." "..answer..". "..tLang.CheckPoll..". "..tLang.NextPoll, bot, bot)
					else
						curUser:reply(tLang.ThanksForVote.." "..answer..". "..tLang.YouHave.." "..PollSettings["maxvote"] - PollVotes[curUser:nick()]["n"].." "..tLang.VotesLeft.." "..tLang.CheckPoll, bot, bot)
					end
					--No need to inform the creator about every vote
					--Core.SendPmToNick(PollSettings["currentcreator"],bot,tLang.Voted..":  "..PollSettings["votes"]["n"].."   :)")
				end
			end
		else
			curUser:reply(tLang.NoPollActive, bot, bot)
		end
	elseif cmd and (string.lower(cmd) == (tLang.tCmds.poll)) then
		if PollSettings["current"] == 2 then
			if PollVotes[curUser:nick()] then
				ShowPollWithResult(curUser,data)
			else
				ShowPollWithNoResult(curUser,data)
			end
		else
			curUser:reply(tLang.NoPollActive, bot, bot)
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Close the active Poll
---------------------------------------------------------------------------------------------------
local ClosePoll = function(curUser,data)
	if PollSettings["current"] == 2 then
		if tonumber(PollSettings["votes"]["n"]) == 0 then
			curUser:reply(tLang.NoVoteNoOld, bot)
		else
			local Pollname = PollSettings["title"]
			OldPolls[Pollname] = {}
			OldPolls[Pollname]["subject"] = PollSettings["subject"]
			OldPolls[Pollname]["active"] = PollSettings["active"]
			OldPolls[Pollname]["votes"] = PollSettings["votes"]
			OldPolls[Pollname]["date"] = PollSettings["date"]
			OldPolls[Pollname]["currentcreator"] = PollSettings["currentcreator"]
			OldPolls[Pollname]["close"] = os.date("[%X] / [%d-%m-20%y]")
			savetable(OldPolls, "OldPolls", pollold)
			local PollText = "\r\n"..string.rep("*",50).."\r\n"..tLang.ClosedPoll..": "..PollSettings["subject"].."\r\n"..string.rep("*",50).."\r\n\r\n"
			local c = tonumber(PollSettings["votes"]["n"])
			for a=1,table.maxn(PollSettings["active"]) do
				PollText = PollText..a..". "..PollSettings["votes"][a].." ("..string.format( "%.2f",(100/c)*PollSettings["votes"][a]).."%) " ..tLang.Votes.. "  "..PollSettings["active"][a].."\r\n"
			end
			PollText = PollText.."\r\n"..tLang.TotVotes..": "..c.." (100.00%)\r\n"..string.rep("*",50).."\r\n"..tLang.PollMe.Created..": "..PollSettings["currentcreator"].."\r\n"..tLang.PollMe.CreatedOn..": "..PollSettings["date"].."\r\n"..string.rep("*",50)
			for sid, user in pairs(hub.getusers( )) do
				user:reply(PollText, bot, bot)
			end
			PollText = nil
			ClearActivePoll()
			curUser:reply(tLang.NowOld, bot)
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Show an old Poll
---------------------------------------------------------------------------------------------------
local OldPoll = function(curUser, data)
	if data == nil then
		local oTmp = ""
		local iets = nil
		for a,b in pairs(OldPolls) do
			local Date = string.gsub(OldPolls[a]["date"],"%[","")
			Date = string.gsub(Date,"%]","")
			if iets then
				iets = iets.."->["..a.." ("..Date..") ]<-\r\n"
			else
				iets = "->["..a.." ("..Date..") ]<-\r\n"
			end
		end
		if iets == nil then
			oTmp = tLang.NoOld
		else
			oTmp = tLang.BadOldPoll..":\r\n"..iets
		end
		curUser:reply(oTmp, bot)
	else
		local namepoll = utf_match(data,"^(%S+)")
		local ooTmp = ""
		if OldPolls[namepoll] then
			ooTmp = "\r\n"..string.rep("*",50).."\r\n" ..tLang.OldPoll.. ": "..OldPolls[namepoll]["subject"].."\r\n"..string.rep("*",50).."\r\n\r\n"
			local c = tonumber(OldPolls[namepoll]["votes"]["n"])
			for a=1,table.maxn(OldPolls[namepoll]["active"]) do
				local bar = DoBars(string.format("%.0f",(100/c)*OldPolls[namepoll]["votes"][a]),100,lengthbar)
				ooTmp = ooTmp..a..". "..OldPolls[namepoll]["votes"][a].." " ..tLang.Votes.. "\t"..bar.." ("..string.format( "%.2f",(100/c)*OldPolls[namepoll]["votes"][a]).."%) " ..tLang.Votes.. "  "..OldPolls[namepoll]["active"][a].."\r\n"
			end
				ooTmp = ooTmp.."\r\nTotal votes: "..c.." (100.00%)\r\n"..string.rep("*",50).."\r\nPoll created by: "..OldPolls[namepoll]["currentcreator"].."\r\nPoll created on: "..OldPolls[namepoll]["date"].."\r\nPoll closed at: "..OldPolls[namepoll]["close"].."\r\n"..string.rep("*",50)
		else
			ooTmp = tLang.OldSorry.."  '"..namepoll.."'  "..tLang.SorryBadOld
		end
		curUser:reply(ooTmp, bot, bot)
	end
	return true
end

---------------------------------------------------------------------------------------------------
-- Who voted already?
---------------------------------------------------------------------------------------------------
local PollVoters = function(curUser,data)
	if PollSettings["current"] ==  2 then
		local count = 0
		local dVoteMax = PollSettings["maxvote"]
		local dVotes = "\r\n"..string.rep("*",50).."\r\n\t"..tLang.PollVotes.."\r\n"..string.rep("*",50).."\r\n" ..tLang.Gandalf.WizKid.. " = "..PollSettings["currentcreator"].."\r\n"..tLang.Gandalf.Name.." = "..PollSettings["title"].."\r\n"..tLang.Gandalf.Votes..": "..PollSettings["maxvote"].."\r\n"..tLang.Gandalf.PollQs..": "..PollSettings["subject"].."\r\n"..tLang.Gandalf.PollAns.." = "..PollSettings["questions"].."\r\n\r\n"
		if ShowShare then
			for a,_ in pairs(PollVotes) do
				count = count + 1
				dVotes = dVotes..count.."."..string.rep(" ",(2-string.len(count))*2+1)..a
				if dVoteMax>1 then
					dVotes = dVotes.." " ..tLang.With.. " "..PollVotes[a]["n"].."/"..dVoteMax.." "..tLang.Votes
				end
				if curUser:level() >= oplevel then 
					local u = hub.isnickonline(a)
					if u ~= nil then
						dVotes = dVotes.."\t"..math.floor(u:share( )/1024/1024/1024*100)/100
					else
						dVotes = dVotes.."\t"..tLang.Offline
					end
					for i,ans in pairs(PollVotes[a]) do
						if i~="n" then
							dVotes = dVotes.."\t"..i
						end
					end
				end
				dVotes = dVotes.."\r\n"
			end
		else
			for a,_ in pairs(PollVotes) do
				count = count + 1
				dVotes = dVotes..count..". "..a.." "..tLang.With.." "..PollVotes[a]["n"].."/"..dVoteMax.." "..tLang.Votes.."\r\n"
			end
		end
		dVotes = dVotes.."\r\n"..string.rep("*",50).."\r\n"..tLang.TotVotes..": "..PollSettings["votes"]["n"].."\r\n"..tLang.TotUsers..": "..count.."\r\n"..string.rep("*",50)
		curUser:reply(dVotes, bot, bot)
	else
		curUser:reply(tLang.NoPoll, bot, bot)
	end
end

local OldPollDel = function(curUser,data)
	if data == nil then
		curUser:reply(tLang.Error.BadOldDel, bot)
	else
		local namepoll = utf_match(data,"^(%S+)")
		if OldPolls[namepoll] then
			OldPolls[namepoll] = nil
			savetable(OldPolls, "OldPolls", pollold)
			curUser:reply(tLang.DelOldPoll.. "  '"..namepoll.."'  "..tLang.OldDel, bot)
		else
			curUser:reply(tLang.Error.NonExistingOld, bot)
		end
	end
end

local onbmsg = function( tUser, adccmd, parameters, txt )
	local cmd = utf_match( parameters, "^%S+" )
	local params = utf_match( parameters, "^%S+%s(.+)" )
	local user_level = tUser:level()
	if cmd then
		if user_level >= oplevel then
			if string.lower(cmd) == (tLang.tCmds.polladd) then
				NewPoll(tUser,params)
				return PROCESSED
			elseif string.lower(cmd) == (tLang.tCmds.polldel) then
				if PollSettings["current"] then
					ClearActivePoll()
					hub.broadcast(tLang.curPollErased, bot)
				else
					tUser:reply(tLang.NoPollNoDel, bot)
				end
				return PROCESSED
			elseif string.lower(cmd) == (tLang.tCmds.pollclose) then
				if PollSettings["current"] == 2 then
					ClosePoll(tUser,params)
				else
					tUser:reply(tLang.NoPollNoClose, bot)
				end
				return PROCESSED
			elseif string.lower(cmd) == (tLang.tCmds.pollhelp) then
				tUser:reply(MainInfo..OPInfo, bot)
				return PROCESSED
			elseif string.lower(cmd) == (tLang.tCmds.oldpolldel) then
				OldPollDel(tUser,params)
				return PROCESSED
			end
		else
			if string.lower(cmd) == (tLang.tCmds.pollhelp) then
				tUser:reply(MainInfo, bot)
				return PROCESSED
			end
		end
		if string.lower(cmd) == (tLang.tCmds.poll) then
			PollPM(tUser,parameters)
			return PROCESSED
		elseif string.lower(cmd) == (tLang.tCmds.oldpoll) then
			OldPoll(tUser,params)
			return PROCESSED
		elseif string.lower(cmd) == (tLang.tCmds.pollusers) then
			PollVoters(tUser,params)
			return PROCESSED
		end
	end
end

hub.setlistener( "onPrivateMessage", { },
	function( user, targetuser, adccmd, msg )
		if targetuser:isbot() then
			if (targetuser:nick() == botName and string.find(msg, "(.*)")) then
				if PollSettings["current"] == 1 and user:nick() == PollSettings["currentcreator"] then
					ConfigPoll(user, msg)
				elseif PollSettings["current"] == 2 then
					PollPM(user, msg)
				else
					user:reply(tLang.NoPollNoVote, bot, bot)
				end
			end
		end
	end
)

hub.setlistener( "onStart", { },
	function()
		LangTranslate()
		bot = hub.regbot({ nick = botName, desc = botDesc, client = function( bot, cmd ) return true end })
		string.gmatch = (string.gmatch or string.gfind)
		local ucmd = hub.import "etc_usercommands.lua"
		if ucmd then
			---------------------------------------------------------------------------------------------------
			-- Rightclicker
			---------------------------------------------------------------------------------------------------
			ucmd.add( { tLang.tMenu.Root, tLang.tMenu.PollHelp }, tLang.cmd, { tLang.tCmds.pollhelp }, { "CT1" }, reglevel )
			ucmd.add( { tLang.tMenu.Root, tLang.tMenu.ShowPoll }, tLang.cmd, { tLang.tCmds.poll }, { "CT1" }, reglevel )
			ucmd.add( { tLang.tMenu.Root, tLang.tMenu.PollVoters }, tLang.cmd, { tLang.tCmds.pollusers }, { "CT1" }, reglevel )
			ucmd.add( { tLang.tMenu.Root, tLang.tMenu.OldPoll }, tLang.cmd, { tLang.tCmds.oldpoll }, { "CT1" }, reglevel )
			
			ucmd.add( { tLang.tMenu.Root, tLang.tMenu.AddPoll }, tLang.cmd, { tLang.tCmds.polladd, "%[line:"..tLang.tMenu.Name.."]", "%[line:"..tLang.tMenu.AddVotes.."]", "%[line:"..tLang.tMenu.AddAns.."]", "%[line:"..tLang.tMenu.AddSubject.."]" }, { "CT1" }, oplevel )
			ucmd.add( { tLang.tMenu.Root, tLang.tMenu.ClosePoll }, tLang.cmd, { tLang.tCmds.pollclose }, { "CT1" }, oplevel )
			ucmd.add( { tLang.tMenu.Root, tLang.tMenu.DelPoll }, tLang.cmd, { tLang.tCmds.polldel }, { "CT1" }, oplevel )
			ucmd.add( { tLang.tMenu.Root, tLang.tMenu.OldDelPoll }, tLang.cmd, { tLang.tCmds.oldpolldel, "%[line:"..tLang.tMenu.Name.."]" }, { "CT1" }, oplevel )
		end
		hubcmd = hub.import "etc_hubcommands"
		assert( hubcmd )
		assert( hubcmd.add( tLang.cmd, onbmsg ) )
		return nil
	end
)

--------------------------------------------------------------------
-- User connects
--------------------------------------------------------------------
hub.setlistener( "onLogin", { }, 
	function(tUser)
		if PollSettings["current"] == 2 and not PollVotes[tUser:nick()] then
			ShowPollWithNoResult(tUser)
		end
	end
)

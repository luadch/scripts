--[[

	RSSFeedWatch script for Luadch rewritten from original Ptokax script:
		FeedWatch 1.0i LUA 5.1x [Strict][API 2]
		
	RSSFeedWatch.lua
		A socket script that watches an RSS feed for changes

        - this script adds a command "rss"
        - usage: [+!#]rss feedhelp for more instructions and a list of available commands
        
		v0.03: by Night
			- Better ways to change FeedText content
			
		v0.02: by Night
			- Add RC
			- Add option to Get all feeds at once ( ex. different release category links ) 
			- Don't list commands user is not allowed to use in FeedHelp

		v0.01: by Night
            - initial version


	Dependencies:
		Luasocket http.
		Luadch comes with these already so all you need to do is:
			-Create socket folder ../lib/luasocket/lua/socket/
			-Copy all files from ../lib/luasocket/lua/ folder into ../lib/luasocket/lua/socket/
			

]]

--//--
local scriptname = "RSSFeedWatch"
local scriptversion = "0.03"
local cmd = "rss"

--// imports
local help, hubcmd

local socket = require "socket"
assert(socket,"Failed to load socket extension. Check files.")
local http = require("socket.http")
assert(http,"Failed to load http module. Check files.")

local cmd_text ="[+!#]rss "
local msg_usage = "Usage: [+!#]rss cmd, type [+!#]rss feedhelp for further instructions."
local msg_denied = "You are not allowed to use this command."

local hub_broadcast = hub.broadcast
local hub_sendtoall = hub.sendtoall
local hub_isnickonline = hub.isnickonline
local hub_loadsettings = hub.reloadcfg
local hub_import = hub.import
local hub_debug = hub.debug

local util_loadtable = util.loadtable
local util_savetable = util.savetable
local string_gsub = utf.gsub
local string_sub = utf.sub

local utf_match = utf.match
local utf_format = utf.format

local Params = {
	["name"] = "",
	["plural"] = "",
	["count"] = "",
	["feed"] = "",
	}

local ucmd_menu_help = { "RSSFeedWatch", "FeedFelp" }
local ucmd_menu_feeds = { "RSSFeedWatch", "Feeds" }
local ucmd_menu_lastfeed = { "RSSFeedWatch", "LastFeed" }
local ucmd_menu_listusers = { "RSSFeedWatch", "ListUsers" }
local ucmd_menu_listfeeds = { "RSSFeedWatch", "ListFeeds" }

local minlevel = 10 -- local min level to use rss command, each command has its own min level settings
local Bot = hub.getbot()

local Feeds = {
	[1] = {"http://feeds.bbci.co.uk/news/world/europe/rss.xml"},
	[2] = {"http://rss.cnn.com/rss/edition_world.rss"},
	[3] = {"http://yle.fi/uutiset/rss/uutiset.rss"},
	[4] = {"http://www.nytimes.com/services/xml/rss/nyt/HomePage.xml"},
	[5] = {"http://www.iltasanomat.fi/rss/uutiset.xml"},
	--[6] = {"http://media.thedailybeast.com/dailybeast/live/ext/rss/blogsandstories/rss_blogsandstories.xml"},
}
-- Assign a TAG to be used in lieu of address. Tag index should match index number in Feeds table above
local Tags = {
[1] = "BBC",
[2] = "CNN",
[3] = "YLE",
[4] = "NYTimes",
[5] = "IltaSanomat",
}
-- Always send this feed in main chat to all [0 = disable]
local ForceFeed = 0
-- Start with which feed?
local StartFeed = 1
-- Get StartFeed at script start? true/false [false = Get Feed at first timer interval]
local GetFeedAtStart = true
-- Set the socket timeout value, in seconds
local TimeOut = 5
-- Set the update interval [in minutes]
local Refresh = 1
-- Get all Feeds at once in Refresh Time
local allFeedsAtOnce = false
-- Maximum number of feeds to display
local MaxFeeds = 5
-- Maximum number of feeds to cache to file
local MaxCache = 5
--Script data path
local Path = "scripts/data/RSSFeedWatch/"
-- File to save user data to
local File = Path.."FeedUsers.tbl"
-- Truncate RSS fields to this width.
local MaxWidth = 120
-- Remove all HTML <tags> in feed fields? true/false
local TagFilter = true
-- Use simple 'title' display only true/false
local Simple = false
--Change Feed text formats here
local formatFeedText = function() 
	local FeedText
	if Simple then
		-- Simple Feed text format
		FeedText = "[ "..Params["count"].." ] New Feed"..Params["plural"].." from: "..Params["name"].."\r\n"..Params["feed"]
	else
		--Feed text format ( if not Simple enabled )
		FeedText = "\r\n\r\n\t [ "..Params["count"].." ] New Feed"..Params["plural"].." from: "..Params["name"].."\r\n\r\n"..Params["feed"]
	end
	return FeedText
end


-- Enable capture of these RSS fields
local Fields = {
	["<title>"] = true,
	["<description>"] = true,
	["<link>"] = true,
	["<author>"] = false,
	["<category>"] = false,
	["<comments>"] = false,
	["<pubDate>"] = false,
	["<guid>"] = false,
	}
-- Don't capture enabled fileds that contain these strings
local Negate = {"-MDT","TestString"}
-- Ascending list order true/false [false = descending]
local ListOrder = false
--Replace these strings in feed XML [--Comment unwanted replacements]
local Rep = {
	["%<%!%[CDATA%["] = "",
	["%]%]%>"] = "",
	["%[code *%]"] = "",
	["<img [^>]*>"] = "",
	["<p>"] = "",
	["&nbsp;"] = " ",
	["%s%s+"] = " ",
	["\160+"] = " ",
	["a href[^%w]+"] = "",
	["\t"] = " ",
	["\r\n"] = "",
	["&#091;"] = string.char(91),
	["&#093;"] = string.char(93),
	[" [ ]+"] = " ",
	["<div class=\"codeheader\">"] = "",
	["%|"] = "&#124;",
	["<summary type=\"html\">"] = "",
	["</summary>"] = "",
	}
local Order = {"feeds","listusers","listfeeds","lastfeed","feedhelp"}

--//--

--script functions
local FwCmds
local SaveFile
local GetFeed 
local ChkUsers
local ParseFeed
local secondTick = 0
local Users = util_loadtable( File ) or {}

local fileExists = function(aFile)
   local f=io.open(aFile,"r")
   if f~=nil then io.close(f) return true else return false end
end

local Decode = function(data,rev)
	local Uni = {
	["&#x2013;"] = "?",["&#x2014;"] = "?",["&#x2018;"] = "?",["&#x2019;"] = "?",["&#x201A;"] = "?",
	["&#x201C;"] = "?",["&#x201D;"] = "?",["&#x201E;"] = "?",["&#x2020;"] = "?",["&#x2021;"] = "?",
	["&#x2022;"] = "?",["&#x2026;"] = "?",["&#x2030;"] = "?",["&#x2039;"] = "?",["&#x203A;"] = "?",
	
	["&#260;"] = "A",["&#261;"] = "a",["&#280;"] = "E",["&#281;"] = "e",["&#211;"] = "?",
	["&#243;"] = "?",["&#262;"] = "C",["&#263;"] = "c",["&#321;"] = "L",["&#322;"] = "l",
	["&#323;"] = "N",["&#324;"] = "n",["&#346;"] = "S",["&#347;"] = "s",["&#377;"] = "Z",
	["&#378;"] = "z",["&#379;"] = "Z",["&#380;"] = "z",
	
	["&#x100;"] = "A",["&#x110;"] = "?",["&#x118;"] = "E",["&#x136;"] = "K",["&#x143;"] = "N",
	["&#xd3;"] = "?",["&#x15a;"] = "S",["&#x170;"] = "U",["&#x101;"] = "a",["&#x111;"] = "d",
	["&#x119;"] = "e",["&#x137;"] = "k",["&#x144;"] = "n",["&#xf3;"] = "?",["&#x15b;"] = "s",
	["&#x171;"] = "u",["&#x102;"] = "A",["&#x10e;"] = "D",["&#x11a;"] = "E",["&#x139;"] = "L",
	["&#x145;"] = "N",["&#x152;"] = "?",["&#x160;"] = "?",["&#x172;"] = "U",["&#x103;"] = "a",
	["&#x10f;"] = "d",["&#x11b;"] = "e",["&#x13a;"] = "l",["&#x146;"] = "n",["&#x153;"] = "?",
	["&#x161;"] = "?",["&#x173;"] = "u",["&#x104;"] = "A",["&#x112;"] = "E",["&#x13b;"] = "L",
	["&#x147;"] = "N",["&#x155;"] = "r",["&#x162;"] = "T",["&#x178;"] = "?",["&#x105;"] = "a",
	["&#x113;"] = "e",["&#x122;"] = "G",["&#x13c;"] = "l",["&#x148;"] = "n",["&#x156;"] = "R",
	["&#x163;"] = "t",["&#x179;"] = "Z",["&#x106;"] = "C",["&#x115;"] = "e",["&#x123;"] = "g",
	["&#x13d;"] = "L",["&#x14c;"] = "O",["&#x157;"] = "r",["&#x17a;"] = "z",["&#x107;"] = "c",
	["&#x116;"] = "E",["&#x12a;"] = "I",["&#x13e;"] = "l",["&#x14d;"] = "o",["&#x158;"] = "R",
	["&#x165;"] = "t",["&#x17b;"] = "Z",["&#x10c;"] = "C",["&#x117;"] = "e",["&#x12b;"] = "i",
	["&#x150;"] = "O",["&#x159;"] = "r",["&#x17c;"] = "z",["&#x10d;"] = "c",["&#x12e;"] = "I",
	["&#x141;"] = "L",["&#x151;"] = "o",["&#x15e;"] = "S",["&#x17d;"] = "?",["&#x12f;"] = "i",
	["&#x142;"] = "l",["&#x15f;"] = "s",["&#x17e;"] = "?",
	
	["%%C4%%80"] = "A",["%%C4%%81"] = "a",["%%C4%%82"] = "A",["%%C4%%83"] = "a",["%%C4%%84"] = "A",
	["%%C4%%85"] = "a",["%%C4%%86"] = "C",["%%C4%%87"] = "c",["%%C4%%88"] = "C",["%%C4%%89"] = "c",
	["%%C4%%8A"] = "C",["%%C4%%8B"] = "c",["%%C4%%8C"] = "C",["%%C4%%8D"] = "c",["%%C4%%8E"] = "D",
	["%%C4%%8F"] = "d",["%%C4%%90"] = "?",["%%C4%%91"] = "d",["%%C4%%92"] = "E",["%%C4%%93"] = "e",
	["%%C4%%94"] = "E",["%%C4%%95"] = "e",["%%C4%%96"] = "E",["%%C4%%97"] = "e",["%%C4%%98"] = "E",
	["%%C4%%99"] = "e",["%%C4%%9A"] = "E",["%%C4%%9B"] = "e",["%%C4%%9C"] = "G",["%%C4%%9D"] = "g",
	["%%C4%%9E"] = "G",["%%C4%%9F"] = "g",["%%C4%%A0"] = "G",["%%C4%%A1"] = "g",["%%C4%%A2"] = "G",
	["%%C4%%A3"] = "g",["%%C4%%A4"] = "H",["%%C4%%A5"] = "h",["%%C4%%A6"] = "H",["%%C4%%A7"] = "h",
	["%%C4%%A8"] = "I",["%%C4%%A9"] = "i",["%%C4%%AA"] = "I",["%%C4%%AB"] = "i",["%%C4%%AC"] = "I",
	["%%C4%%AD"] = "i",["%%C4%%AE"] = "I",["%%C4%%AF"] = "i",["%%C4%%B0"] = "I",["%%C4%%B1"] = "i",
	["%%C4%%B2"] = "?",["%%C4%%B3"] = "?",["%%C4%%B4"] = "J",["%%C4%%B5"] = "j",["%%C4%%B6"] = "K",
	["%%C4%%B7"] = "k",["%%C4%%B8"] = "?",["%%C4%%B9"] = "L",["%%C4%%BA"] = "l",["%%C4%%BB"] = "L",
	["%%C4%%BC"] = "l",["%%C4%%BD"] = "L",["%%C4%%BE"] = "l",["%%C4%%BF"] = "?",["%%C5%%80"] = "?",
	["%%C5%%81"] = "L",["%%C5%%82"] = "l",["%%C5%%83"] = "N",["%%C5%%84"] = "n",["%%C5%%85"] = "N",
	["%%C5%%86"] = "n",["%%C5%%87"] = "N",["%%C5%%88"] = "n",["%%C5%%89"] = "?",["%%C5%%8A"] = "?",
	["%%C5%%8B"] = "?",["%%C5%%8C"] = "O",["%%C5%%8D"] = "o",["%%C5%%8E"] = "O",["%%C5%%8F"] = "o",
	["%%C5%%90"] = "O",["%%C5%%91"] = "o",["%%C5%%92"] = "?",["%%C5%%93"] = "?",["%%C5%%94"] = "R",
	["%%C5%%95"] = "r",["%%C5%%96"] = "R",["%%C5%%97"] = "r",["%%C5%%98"] = "R",["%%C5%%99"] = "r",
	["%%C5%%9A"] = "S",["%%C5%%9B"] = "s",["%%C5%%9C"] = "S",["%%C5%%9D"] = "s",["%%C5%%9E"] = "S",
	["%%C5%%9F"] = "s",["%%C5%%A0"] = "?",["%%C5%%A1"] = "?",["%%C5%%A2"] = "T",["%%C5%%A3"] = "t",
	["%%C5%%A4"] = "T",["%%C5%%A5"] = "t",["%%C5%%A6"] = "T",["%%C5%%A7"] = "t",["%%C5%%A8"] = "U",
	["%%C5%%A9"] = "u",["%%C5%%AA"] = "U",["%%C5%%AB"] = "u",["%%C5%%AC"] = "U",["%%C5%%AD"] = "u",
	["%%C5%%AE"] = "U",["%%C5%%AF"] = "u",["%%C5%%B0"] = "U",["%%C5%%B1"] = "u",["%%C5%%B2"] = "U",
	["%%C5%%B3"] = "u",["%%C5%%B4"] = "W",["%%C5%%B5"] = "w",["%%C5%%B6"] = "Y",["%%C5%%B7"] = "y",
	["%%C5%%B8"] = "?",["%%C5%%B9"] = "Z",["%%C5%%BA"] = "z",["%%C5%%BB"] = "Z",["%%C5%%BC"] = "z",
	["%%C5%%BD"] = "?",["%%C5%%BE"] = "?",
	}
	local Asc = {
	[34]="&quot;",[38]="&amp;",[39]="&#39;",[60]="&lt;",[62]="&gt;",[94]="&circ;",[126]="&tilde;",[127]="&#127;",
	[128]="&euro;",[130]="&sbquo;",[131]="&fnof;",[132]="&bdquo;",[133]="&hellip;",[134]="&dagger;",[135]="&Dagger;",
	[136]="&circ;",[137]="&permil;",[138]="&Scaron;",[139]="&lsaquo;",[140]="&OElig;",[142]="&#381;",[145]="&lsquo;",
	[146]="&rsquo;",[147]="&ldquo;",[148]="&rdquo;",[149]="&bull;",[150]="&ndash;",[151]="&mdash;",[152]="&tilde;",
	[153]="&trade;",[154]="&scaron;",[155]="&rsaquo;",[156]="&oelig;",[157]="&#356;",[158]="&#382;",[159]="&Yuml;",
	[160]="&nbsp;",[161]="&#711;",[162]="&#728;",[163]="&#321;",[164]="&curren;",[165]="&#260;",[166]="&brvbar;",
	[167]="&sect;",[168]="&uml;",[169]="&copy;",[170]="&#350;",[171]="&laquo;",[172]="&not;",[173]="&shy;",
	[174]="&reg;",[175]="&#379;",[176]="&deg;",[177]="&plusmn;",[178]="&sup2;",[179]="&#322;",[180]="&acute;",
	[181]="&micro;",[182]="&para;",[183]="&middot;",[184]="&cedil;",[185]="&#261;",[186]="&#351;",[187]="&raquo;",
	[188]="&#317;",[189]="&#733;",[190]="&#318;",[191]="&#380;",[192]="&#340;",[193]="&Aacute;",[194]="&Acirc;",
	[195]="&#258;",[196]="&Auml;",[197]="&#313;",[198]="&#262;",[199]="&Ccedil;",[200]="&#268;",[201]="&Eacute;",
	[202]="&#280;",[203]="&Euml;",[204]="&#282;",[205]="&Iacute;",[206]="&Icirc;",[207]="&#270;",[208]="&#272;",
	[209]="&#323;",[210]="&#327;",[211]="&Oacute;",[212]="&Ocirc;",[213]="&#336;",[214]="&Ouml;",[215]="&times;",
	[216]="&#344;",[217]="&#366;",[218]="&Uacute;",[219]="&#368;",[220]="&Uuml;",[221]="&Yacute;",[222]="&#354;",
	[223]="&szlig;",[224]="&agrave;",[225]="&aacute;",[226]="&acirc;",[227]="&#259;",[228]="&auml;",[229]="&#314;",
	[230]="&#263;",[231]="&ccedil;",[232]="&#269;",[233]="&eacute;",[234]="&#281;",[235]="&euml;",[236]="&#283;",
	[237]="&iacute;",[238]="&icirc;",[239]="&#271;",[240]="&#273;",[241]="&#324;",[242]="&#328;",[243]="&oacute;",
	[244]="&ocirc;",[245]="&#337;",[246]="&ouml;",[247]="&divide;",[248]="&#345;",[249]="&#367;",[250]="&uacute;",
	[251]="&#369;",[252]="&uuml;",[253]="&yacute;",[254]="&#355;",[255]="&#729;",
	}
	
	for i,v in pairs(Uni) do if rev then data = string_gsub(data,v,i) else data = string_gsub(data,i,v) end end
	for i,v in pairs(Asc) do
		local c = string.char(i)
		if rev then data = string_gsub(data, c,v) else data = string_gsub(data,tostring(v),c) end
	end

	return data
end

ParseFeed = function(xml,n)
	local s 
	local New = { }
	for i,v in pairs(Rep) do xml = string_gsub(xml,i,v) end
	for item in string.gmatch(xml, "<item>(.-)</item>") do
		item = string_gsub(item,"[\r\n]","")
		item = string_gsub(item, "%<[%w ]+%/%>","%1 </>")
		local t = {}
		for field,val in string.gmatch(item, "(%b<>)(.-)%<%/") do
			local s = ""
			if Fields[field:lower()] then
				field = string_gsub(field:lower(),"[<>]","")..":"
				if TagFilter then 
					val = string_gsub(val,"%b<>","") 
				end
				s = s.." "..string.format("%-20.13s",field).."\t"
				if val:len() > MaxWidth then 
					s = s..string_sub(val,1,MaxWidth).."..." 
				else 
					s = s..val.."" 
				end
			end
			if s:len() > 0 then table.insert(t,s) end
		end
		local ChkFld = function(s)
			if next(Negate) then
				for i,v in ipairs(Negate) do
					if s:find(v,1,true) then return false end
				end
			end
			return true
		end
		if next(t) and ChkFld(t[1]) then table.insert(New,t) end
	end
	if next(New) then
		if ListOrder then
			local Tab = {}
			for n = 1, #New do table.insert(Tab,1,New[n]) end
			New = Tab
		end
		local reply,cnt = "",0
		while #New > MaxCache do table.remove(New) end
		local Old = util_loadtable(Feeds[n][2])
		for key,val in ipairs(New) do
			local bool = true
			if Old and next(Old) then
				for i,v in ipairs(Old) do if v[2] == val[2] then bool = false break end end
			end
			if bool then
				cnt = cnt + 1
				if cnt <= MaxFeeds then
					if Simple then
						reply = reply..tostring(key)..". "..string_gsub(val[1],"title%:[^%S]+","")
					else
						for i,v in ipairs(val) do reply = reply.."\t"..v.."\n" end
					end
					reply = reply.."\n"
				end
			end
		end
		if reply:len() > 0 then
			local plural = ""
			if cnt > 1 then plural = "s" end
			SaveFile(Feeds[n][2],New,"Old")
			if Old then Old = nil end
			Params["name"] = Feeds[n][3]
			Params["count"] = tostring(cnt)
			Params["plural"] = plural
			Params["feed"] = reply
	
			local txt = formatFeedText()
			return txt
		end
		if Old then Old = nil end
	end
end

GetFeed = function(n)
	local st = socket.gettime()
	n = math.min(n,#Feeds)
	http.TIMEOUT = TimeOut
	local s,fd,sz,hd = "",http.request(Feeds[n][1])
	if fd and sz then
		local td,plural = socket.gettime()-st,"of a second."
		if td > 1 then plural = "seconds." end
		local time = string.format("%.2f "..plural,td)
		local msg_ = ParseFeed(Decode(fd),n)

		if msg_ and msg_:len() > 0 then
			if not Simple then msg_ = msg_.."\t\t\tProcessed In: "..time.."\n\n" end
			if ForceFeed > 0 and n == ForceFeed then
				hub_broadcast(msg_, Bot)
			else
				for i,v in ipairs(Users) do
					local user = hub_isnickonline(v[1])
					if user and v[3] then
						if v[2] == "p" then
							user:reply(msg_, Bot, Bot)
						elseif v[2] == "m" then
							user:reply(msg_, Bot)
						end
					end
				end
			end
		end
	end
end

ChkUsers = function(n)
	for i,v in ipairs(Users) do 
		if n:lower() == v[1]:lower() then 
			return i 
		end 
	end
end

FwCmds = {
	feeds = {function(user,data,cmd2)
		if user then
			local choice = data
			if choice then
				local t = {["on"] = true,["off"] = {true,false},["m"] = "main chat",["p"] = "private message"}
				if t[choice] then
					local b,save = ChkUsers(user:firstnick())
					local tab = {["true"] = "enabled",["false"] = "disabled"}
					if not b then
						local channel = "p"
						if choice == "m" then
							channel = "m"
						end
						table.insert(Users,{user:firstnick(),channel,true})
						save = true
						b = #Users
					else
						if choice == "on" then
							if Users[b][3] then
								return user:nick()..", feeds are already enabled for you and will be sent in "..t[Users[b][2]]
							else
								Users[b][3] = t[choice]
								save = true
							end
						elseif choice == "off" then
							if not Users[b][3] then
								return user:nick()..", feeds are already disabled for you and will be sent in "..t[Users[b][2]].." when enabled."
							else
								Users[b][3] = t[choice][2]
								save = true
							end
						else
							if Users[b][2] == choice then
								return user:nick()..", feeds are already set for "..t[choice].." and are curretly "..tab[tostring(Users[b][3])]
							else
								Users[b][2] = choice
								save = true
							end
						end
					end
					if save then 
						SaveFile(File,Users,"Users") 
					end
					return "Feeds are currently "..tab[tostring(Users[b][3])].." current message type: "..t[Users[b][2]]
				else
					return "**Error in selection. Usage: "..cmd_text..cmd2.." <on/off/p/m>"
				end
			else
				return "Error in selection. Usage: "..cmd_text..cmd2.." <on/off/p/m>"
			end
		else
			return "Set your RSS feed option",
			" %[line:on=enabled, off= disabled, m=main, p=pm]",
			" %[line:on=enabled, off= disabled, m=main, p=pm]"
		end
	end,
	{ level = 10 } --min level to use this command
	},
	lastfeed = {function(user,data,cmd2)
		if not data then
			return "Usage: [+!#]rss lastfeed <Feed number>"
		end
		local n = data
		if n then
			n = tonumber(n)
		end
		if not n then
			return "Error! ' "..data.." ' is not a valid feed number."
		end
		
		if n and n > 0 then
			if Feeds[n] then
				local Old = util_loadtable(Feeds[n][2])
				if Old and next(Old) then
					local reply,plural,cnt = "","s",#Old
					if cnt == 1 then plural = "" end
					for key,val in ipairs(Old) do
						for i,v in ipairs(val) do reply = reply.."\t"..v.."\n" end
						reply = reply.."\n"
					end
					if reply ~= "" then
						return "\n\n\t[ "..tostring(cnt).." ] Cached feed"..
						plural.." from: "..Feeds[n][1].."\n\n"..reply.."\n"
					end
				else
					return "There are no cached feeds at this time."
				end
			else
				return "Error! "..tostring(n).." is not a valid feed number."
			end
		else
			return "Error! "..tostring(n).." is not a valid feed number."
		end
	end,
	{ level = 10 } --min level to use this command
	},
	listfeeds = {function(user,data,cmd2)
		if user then
			if next(Feeds) then
				local reply = ""
				for i,v in ipairs(Feeds) do
					reply = reply.."\t"..string.format("[%-2s]    ",i)..v[1].."\n"
				end
				if reply ~= "" then
					return "Listing enabled feeds:\n\n"..reply
				end
			else
				return "Error, There are no feeds set in script."
			end
		else
			return "List Enabled Feeds","",""
		end
	end,
	{ level = 10 } --min level to use this command
	},
	listusers = {function(user,data,cmd2)
		if user then
			local r = "?"
			local reply,t,c = "\n\n\t"..scriptname.." Active Users\n\n\t"..r:rep(50).."\r\n"..
			"\tNickname\t\tMessage Type\tStatus\r\n\t"..r:rep(50).."\r\n",{},""
			local tab = {["true"] = "enabled",["false"] = "disabled",
			["m"] = "main chat      ",["p"] = "private message"}
			for i,v in ipairs(Users) do
				table.insert(t,"\t"..string.format("%-30s",v[1]).."\t"..
				tab[v[2]].."\t"..tab[tostring(v[3])].."\r\n")
			end
			table.sort(t, function(a,b)return a < b end)
			c = table.concat(t,"")
			if c:len() > 0 then return reply..c.."\n\t"..r:rep(50).."\r\n\r\n" end
		else
			return "List Active Feed Users","",""
		end
	end,
	{ level = 10 } --min level to use this command
	},
	feedhelp = {function(user,data,cmd2)
		if user then
			local reply,t,c = "\n\n\t"..scriptname.." Command Help\n\n\tCommand"..
			"\t\tDescription\r\n\t"..string.rep("?",40).."\r\n",{},""
			for i,v in ipairs(Order) do
				local desc,args = FwCmds[v][1]()
				if user:level() >= FwCmds[v][2]["level"] then
					table.insert(t,"\t"..cmd_text..string.format("%-15s",v).."\t"..desc.."\r\n")
				end
			end
			if not t then
				return msg_denied
			end
			table.sort(t, function(a,b)return a < b end)
			for i,v in ipairs(t) do
				c = c..v
			end
			if c:len() > 0 then
				return reply..c.."\n\t"..string.rep("?",40).."\r\n\r\n"
			end
		else
			return scriptname.." Help","",""
		end
	end,
	{ level = 10 } --min level to use this command
	}
}

SaveFile = function(fileN,table, tablename )
	util_savetable(table, tablename, fileN)
end

local oncmdRSS = function( user, command, parameters )
    local user_level = user:level()
	if user_level < minlevel then
		user:reply( msg_denied, Bot )
		return PROCESSED
	end

	local subCmd = utf_match( parameters, "^(%S+)" )
    local data = utf_match( parameters, "^%a+ (%S+)" )
	
	if subCmd and FwCmds[subCmd] then
		if user:level() >= FwCmds[subCmd][2]["level"] then
			local msg = FwCmds[subCmd][1](user,data,subCmd)
			if msg and msg:len() > 0 then
				user:reply(msg, Bot )
			end
		else
			user:reply( msg_denied, Bot )
			return PROCESSED
		end
	else
		user:reply(msg_usage, Bot )
		return PROCESSED
	end
	
    return PROCESSED
end

hub.setlistener( "onTimer", {},
    function()
		secondTick = secondTick+1
		if secondTick >= (Refresh*60) then
			secondTick = 0
			if allFeedsAtOnce then
				for n,v in ipairs(Feeds) do
					GetFeed(n)
				end
			else
				if StartFeed > #Feeds then StartFeed = 1 end
				GetFeed(StartFeed)
				StartFeed = StartFeed + 1
			end
		end
	return nil
	end
)

hub.setlistener( "onStart", { },
    function( )
	MaxFeeds,Refresh,StartFeed = math.min(MaxFeeds,MaxCache),math.max(Refresh,2),math.min(StartFeed,#Feeds)
	TimeOut = math.min(TimeOut,60)

	for i,v in ipairs(Feeds) do
		local host = Tags[i] or Feeds[i][1]:gsub("^[hftp:]+[/]+",""):gsub("/.*$","") or "unavailable"
		table.insert(Feeds[i],Path..Feeds[i][1]:gsub("^[hftp:]+[/]+",""):gsub("[%c%p]","_")..".dat")
		if host and host ~= "" then table.insert(Feeds[i],host) end
	end
	for n,v in ipairs(Feeds) do
		if not fileExists(v[2]) then
			local Old = {}
			SaveFile(v[2],Old,"Old")
		end
	end
	local ucmd = hub.import "etc_usercommands"    -- add usercommand
        if ucmd then
			ucmd.add( ucmd_menu_help, cmd, {"feedhelp" }, { "CT1" }, FwCmds["feedhelp"][2]["level"] )
			ucmd.add( ucmd_menu_feeds, cmd, {"feeds", "%[line: on/off/m/p]" }, { "CT1" }, FwCmds["feeds"][2]["level"] )
			ucmd.add( ucmd_menu_lastfeed, cmd, {"lastfeed", "%[line: Feed Number ]" }, { "CT1" }, FwCmds["lastfeed"][2]["level"] )
			ucmd.add( ucmd_menu_listusers, cmd, {"listusers" }, { "CT1" }, FwCmds["listusers"][2]["level"] )
			ucmd.add( ucmd_menu_listfeeds, cmd, {"listfeeds" }, { "CT1" }, FwCmds["listfeeds"][2]["level"] )
        end
	
	hubcmd = hub_import( "etc_hubcommands" )    -- add hubcommand
    assert( hubcmd )
    assert( hubcmd.add( cmd, oncmdRSS ) )

	if GetFeedAtStart then 
		if allFeedsAtOnce then
			for n,v in ipairs(Feeds) do
				GetFeed(n)
			end
		else
			GetFeed(StartFeed) 
		end
	end
    return nil
    end
)

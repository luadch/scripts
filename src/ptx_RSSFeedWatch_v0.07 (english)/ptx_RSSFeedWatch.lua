--[[

	RSSFeedWatch script for Luadch rewritten from original Ptokax script:
		FeedWatch 1.0i LUA 5.1x [Strict][API 2]
		
	RSSFeedWatch.lua
		A socket script that watches an RSS feed for changes

		- this script adds a command "rss"
		- usage: [+!#]rss feedhelp for more instructions and a list of available commands

		v0.07: by Jerker
			- Added msgToPM option to send messages from commands to PM (true) or main (false)
			  when user hasn't selected channel, otherwise messages are sent to where user selected
			  Error messages are still sent to main
			- Converting non UTF-8 feeds to UTF-8
			- Don't truncate links
			- New labels for feed fields with tab count for formatting output
			- Added RC to Add and Delete feeds and to toggle ForceFeed setting

		v0.06: by Jerker
			- Added support for atom feeds
			- Added support for ssl
		
		v0.05: by Night
			- Fix a problem with using nick prefix script
			- Fix a typo in FeedHelp

		v0.04: by Night
			- Change the ForceFeed option to allow enabling multiple forced feeds
			- Add ForceFeedPM option to send forced feeds in PM
		
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

		Luasec https.
		Luadch comes with these already so all you need to do is:
			-Create ssl folder ../lib/luasec/lua/ssl/
			-Copy all files from ../lib/luasec/lua/ folder into ../lib/luasec/lua/ssl/
		
		slaxml.lua
			-Copy folder slaxml to ../lib/

]]

--//--
local scriptname = "RSSFeedWatch"
local scriptversion = "0.07"
local cmd = "rss"

--// imports
local help, ucmd, hubcmd

local socket = require "socket"
assert(socket,"Failed to load socket extension. Check files.")
local http = require("socket.http")
assert(http,"Failed to load http module. Check files.")
local https = require("ssl.https")
assert(https,"Failed to load https module. Check files.")

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
local utf_gsub = utf.gsub
local utf_sub = utf.sub
local utf_find = utf.find
local utf_len = utf.len
local utf_match = utf.match
local utf_format = utf.format
local string_rep = string.rep
local string_char = string.char
local push, pop, table_sort = table.insert, table.remove, table.sort
local delete = os.remove

local Params = {
	["name"] = "",
	["plural"] = "",
	["count"] = "",
	["feed"] = "",
	}

local ucmd_menu_help = { "RSSFeedWatch", "FeedHelp" }
local ucmd_menu_feeds = { "RSSFeedWatch", "Feeds" }
local ucmd_menu_lastfeed = { "RSSFeedWatch", "LastFeed" }
local ucmd_menu_listusers = { "RSSFeedWatch", "ListUsers" }
local ucmd_menu_listfeeds = { "RSSFeedWatch", "ListFeeds" }
local ucmd_menu_addfeed = { "RSSFeedWatch", "AddFeed" }
local ucmd_menu_forcefeed = { "RSSFeedWatch", "Toggle ForceFeed" }
local ucmd_menu_deletefeed = { "RSSFeedWatch", "DeleteFeed" }

local minlevel = 10 -- local min level to use rss command, each command has its own min level settings
local Bot = hub.getbot()

-- Send Forced Feed in PM
local ForceFeedPM = false
-- Start with which feed?
local StartFeed = 1
-- Get StartFeed at script start? true/false [false = Get Feed at first timer interval]
local GetFeedAtStart = true
-- Set the socket timeout value, in seconds
local TimeOut = 5
-- Set the update interval [in minutes]
local Refresh = 10
-- Get all Feeds at once in Refresh Time
local allFeedsAtOnce = false
-- Maximum number of feeds to display
local MaxFeeds = 5
-- Maximum number of feeds to cache to file
local MaxCache = 5
--Script data path
local Path = "scripts/data/RSSFeedWatch/"
-- File to save user data to
local UserFile = Path.."FeedUsers.tbl"
-- File to save feeds data to
local FeedsFile = Path.."Feeds.tbl"
-- Truncate RSS fields, except links, to this width.
local MaxWidth = 120
-- Remove all HTML <tags> in feed fields? true/false
local TagFilter = true
-- Use simple 'title' display only true/false
local Simple = false
-- Messages from command in PM
local msgToPM = true

local Feeds = util_loadtable( FeedsFile ) or { }
--[[{
	{ url="http://feeds.bbci.co.uk/news/world/europe/rss.xml", tag="BBC", force=false },
	{ url="http://rss.cnn.com/rss/edition_world.rss", tag="CNN", force=false },
	{ url="http://yle.fi/uutiset/rss/uutiset.rss", tag="YLE", force=false },
	{ url="http://www.nytimes.com/services/xml/rss/nyt/HomePage.xml", tag="NYTimes", force=false },
	{ url="https://github.com/luadch/luadch/releases.atom", tag="Luadch", force=false },
}--]]

-- Body style
local Body = [[


=== FeedWatch =======================================================================================
%s
======================================================================================= FeedWatch ===
  ]]

local encoding = "UTF-8"

-- Change Feed text formats here
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
-- name = field name in feel
-- label = label on screen
-- tabs = number of tabs between label and text
-- show = show the field
local RssFields = {
	[1] = {name="title", label="Title", tabs=2, show=true, },
	[2] = {name="link", label="Link", tabs=2, show=true, },
	[3] = {name="description", label="Desc", tabs=2, show=true, },
	[4] = {name="author", label="Auth", tabs=2, show=false, },
	[5] = {name="category", label="Cat", tabs=2, show=false, },
	[6] = {name="pubdate", label="Publ", tabs=2, show=true, },
	[7] = {name="guid", label="Id", tabs=2, show=false, },
	[8] = {name="comments", label="Comments", tabs=1, show=false, },
	}
-- Enable capture of these Atom fields
-- name = field name in feel
-- label = label on screen
-- tabs = number of tabs between label and text
-- show = show the field
-- specialCase = if text is in attribute or child field
--   source = source of text, "attr" = attribute, "kids" = child field
--   name = name of field or attribute
local AtomFields = {
	[1] = {name="title", label="Title", tabs=2, show=true, },
	[2] = {name="link", label="Link", tabs=2, show=true, specialCase={ source = "attr", name = "href"}, },
	[3] = {name="summary", label="Desc", tabs=2, show=true, },
	[4] = {name="author", label="Auth", tabs=2, show=false, specialCase={ source = "kids", name = "name"}, },
	[5] = {name="category", label="Cat", tabs=2, show=false, specialCase={ source = "attr", name = "term"}, },
	[6] = {name="published", label="Publ", tabs=2, show=true, },
	[7] = {name="id", label="Id", tabs=2, show=false, },
	}
-- Don't capture enabled fileds that contain these strings
local Negate = {"-MDT","TestString"}
-- Ascending list order true/false [false = descending]
local ListOrder = false

local Order = {"feeds","listusers","listfeeds","lastfeed","addfeed","forcefeed","delfeed","feedhelp"}

local Rep = {
	["<img [^>]->"] = "",
	["</?p>"] = "",
	["%s%s+"] = " ",
	["\160+"] = " ",
	["<a href.->(.-)</a>"] = function(x) return x end,
	["\t"] = " ",
	["\r\n"] = "",
	["<br.-/>"] = "",
	}

--//--

-- script functions
local FwCmds
local SaveFile
local SaveFeed
local GetFeed
local ChkUsers

local ParseFeed
local CreateXML
local FindElement
local FindAttibute
local GetEncoding

local secondTick = 0
local Users = util_loadtable( UserFile ) or {}

local fileExists = function(aFile)
   local f=io.open(aFile,"r")
   if f~=nil then io.close(f) return true else return false end
end

local ToUtf8 = function(data, enc)

	local Latin1 = {
		[128]="€",[130]="‚",[131]="ƒ",[132]="„",[133]="…",[134]="†",[135]="‡",
		[136]="ˆ",[137]="‰",[138]="Š",[139]="‹",[140]="Œ",[142]="Ž",[145]="‘",
		[146]="’",[147]="“",[148]="”",[149]="•",[150]="–",[151]="—",[152]="~",
		[153]="™",[154]="š",[155]="›",[156]="œ",[158]="ž",[159]="Ÿ",[160]=" ",
		[161]="¡",[162]="¢",[163]="£",[164]="¤",[165]="¥",[166]="¦",[167]="§",
		[168]="¨",[169]="©",[170]="ª",[171]="«",[172]="¬",[173]="­",[174]="®",
		[175]="¯",[176]="°",[177]="±",[178]="²",[179]="³",[180]="´",[181]="µ",
		[182]="¶",[183]="·",[184]="¸",[185]="¹",[186]="º",[187]="»",[188]="¼",
		[189]="½",[190]="¾",[191]="¿",[192]="À",[193]="Á",[194]="Â",[195]="Ã",
		[196]="Ä",[197]="Å",[198]="Æ",[199]="Ç",[200]="È",[201]="É",[202]="Ê",
		[203]="Ë",[204]="Ì",[205]="Í",[206]="Î",[207]="Ï",[208]="Ð",[209]="Ñ",
		[210]="Ò",[211]="Ó",[212]="Ô",[213]="Õ",[214]="Ö",[215]="×",[216]="Ø",
		[217]="Ù",[218]="Ú",[219]="Û",[220]="Ü",[221]="Ý",[222]="Þ",[223]="ß",
		[224]="à",[225]="á",[226]="â",[227]="ã",[228]="ä",[229]="å",[230]="æ",
		[231]="ç",[232]="è",[233]="é",[234]="ê",[235]="ë",[236]="ì",[237]="í",
		[238]="î",[239]="ï",[240]="ð",[241]="ñ",[242]="ò",[243]="ó",[244]="ô",
		[245]="õ",[246]="ö",[247]="÷",[248]="ø",[249]="ù",[250]="ú",[251]="û",
		[252]="ü",[253]="ý",[254]="þ",[255]="ÿ",
	}
	
	if enc ~= "UTF-8" then
		--convert to UTF-8
		for i,v in pairs(Latin1) do
			local c = string_char(i)
			data = utf_gsub(data, c, v)
		end
	end
	
	return data
end

local Decode = function(data)
	
	local Html = {
	["&quot;"] = "\"", ["&amp;"] = "&", ["&lt;"] = "<", ["&gt;"] = ">", ["&euro;"] = "€",
	["&sbquo;"] = "‚", ["&fnof;"] = "ƒ", ["&bdquo;"] = "„", ["&hellip;"] = "…", ["&dagger;"] = "†",
	["&Dagger;"] = "‡", ["&circ;"] = "ˆ", ["&permil;"] = "‰", ["&Scaron;"] = "Š", ["&lsaquo;"] = "‹",
	["&OElig;"] = "Œ", ["&lsquo;"] = "‘", ["&rsquo;"] = "’", ["&ldquo;"] = "“", ["&rdquo;"] = "”",
	["&bull;"] = "•", ["&ndash;"] = "–", ["&mdash;"] = "—", ["&tilde;"] = "~", ["&trade;"] = "™",
	["&scaron;"] = "š", ["&rsaquo;"] = "›", ["&oelig;"] = "œ", ["&Yuml;"] = "Ÿ", ["&nbsp;"] = " ",
	["&iexcl;"] = "¡", ["&cent;"] = "¢", ["&pound;"] = "£", ["&curren;"] = "¤", ["&yen;"] = "¥",
	["&brvbar;"] = "¦", ["&sect;"] = "§", ["&uml;"] = "¨", ["&copy;"] = "©", ["&ordf;"] = "ª",
	["&laquo;"] = "«", ["&not;"] = "¬", ["&shy;"] = "­", ["&reg;"] = "®", ["&macr;"] = "¯", 
	["&deg;"] = "°", ["&plusmn;"] = "±", ["&sup2;"] = "²", ["&sup3;"] = "³", ["&acute;"] = "´",
	["&micro;"] = "µ", ["&para;"] = "¶", ["&middot;"] = "·", ["&cedil;"] = "¸", ["&sup1;"] = "¹",
	["&ordm;"] = "º", ["&raquo;"] = "»", ["&frac14;"] = "¼", ["&frac12;"] = "½", ["&frac34;"] = "¾",
	["&iquest;"] = "¿", ["&Agrave;"] = "À", ["&Aacute;"] = "Á", ["&Acirc;"] = "Â", ["&Atilde;"] = "Ã",
	["&Auml;"] = "Ä", ["&Aring;"] = "Å", ["&AElig;"] = "Æ", ["&Ccedil;"] = "Ç", ["&Egrave;"] = "È",
	["&Eacute;"] = "É", ["&Ecirc;"] = "Ê", ["&Euml;"] = "Ë", ["&Igrave;"] = "Ì", ["&Iacute;"] = "Í",
	["&Icirc;"] = "Î", ["&Iuml;"] = "Ï", ["&ETH;"] = "Ð", ["&Ntilde;"] = "Ñ", ["&Ograve;"] = "Ò",
	["&Oacute;"] = "Ó", ["&Ocirc;"] = "Ô", ["&Otilde;"] = "Õ", ["&Ouml;"] = "Ö", ["&times;"] = "×",
	["&Oslash;"] = "Ø", ["&Ugrave;"] = "Ù", ["&Uacute;"] = "Ú", ["&Ucirc;"] = "Û", ["&Uuml;"] = "Ü",
	["&Yacute;"] = "Ý", ["&THORN;"] = "Þ", ["&szlig;"] = "ß", ["&agrave;"] = "à", ["&aacute;"] = "á",
	["&acirc;"] = "â", ["&atilde;"] = "ã", ["&auml;"] = "ä", ["&aring;"] = "å", ["&aelig;"] = "æ",
	["&ccedil;"] = "ç", ["&egrave;"] = "è", ["&eacute;"] = "é", ["&ecirc;"] = "ê", ["&euml;"] = "ë",
	["&igrave;"] = "ì", ["&iacute;"] = "í", ["&icirc;"] = "î", ["&iuml;"] = "ï", ["&eth;"] = "ð",
	["&ntilde;"] = "ñ", ["&ograve;"] = "ò", ["&oacute;"] = "ó", ["&ocirc;"] = "ô", ["&otilde;"] = "õ",
	["&ouml;"] = "ö", ["&divide;"] = "÷", ["&oslash;"] = "ø", ["&ugrave;"] = "ù", ["&uacute;"] = "ú",
	["&ucirc;"] = "û", ["&uuml;"] = "ü", ["&yacute;"] = "ý", ["&thorn;"] = "þ", ["&yuml;"] = "ÿ",
	}

	for i,v in pairs(Html) do
		data = utf_gsub(data,i,v)
	end

	return data
end

CreateXML = function(xml)
	local SLAXML = require 'slaxml'
	local stack = {}
	local doc = { type="document", name="#doc" }
	local current = doc
	push(stack,doc)
	local builder = SLAXML:parser{
		startElement = function(name,nsURI)
			local el = { type="element", name=name, nsURI=nsURI }
			if current==doc then
				if doc.root then error(utf_format("Encountered element '%s' when the document already has a root '%s' element",name,doc.root.name)) end
				doc.root = el
			end
			if not current.kids then current.kids = { } end
			push(current.kids,el)
			current = el
			push(stack,el)
		end,
		attribute = function(name,value,nsURI)
			if not current or current.type~="element" then error(utf_format("Encountered an attribute %s=%s but I wasn't inside an element",name,value)) end
			local attr = {type='attribute',name=name,nsURI=nsURI,value=value}
			if not current.attr then current.attr = { } end
			push(current.attr,attr)
		end,
		closeElement = function(name)
			if current.name~=name or current.type~="element" then error(utf_format("Received a close element notification for '%s' but was inside a '%s' %s",name,current.name,current.type)) end
			pop(stack)
			current = stack[#stack]
		end,
		text = function(value)
			if current and current.type~='document' then
				if current.type~="element" then error(utf_format("Received a text notification '%s' but was inside a %s",value,current.type)) end
				value = utf_gsub(value, "^[\n%s]-", "")
				value = utf_gsub(value, "[\n%s]-$", "")
				if value ~= "" then
					current.value=value
				end
			end
		end
	}
	builder:parse(xml,{ simple=true })
	return doc
end

FindElement = function(element, name, specialCase)
	if element.kids then
		for k,v in pairs(element.kids) do
			if v.name and v.name == name then
				if specialCase then
					if specialCase.source == "attr" then
						return FindAttibute(v, specialCase.name)
					elseif specialCase.source == "kids" then
						return FindElement(v, specialCase.name)
					end
				else
					if v.value then
						return v.value
					end
				end
			end
		end
	end
end

FindAttibute = function(element, name)
	if element.attr then
		for k,v in pairs(element.attr) do
			if v.name and v.name == name then
				return v.value
			end
		end
	end
end

ParseFeed = function(xml,n,typeOfFeed)
	local New = { }
	local doc = CreateXML(xml)
	local base = {}
	local elementName
	local parseFields = {}
	for k,v in pairs(doc.root.kids) do
		if v.name == "channel" then --rss
			base = v
			elementName = "item"
			parseFields = RssFields
			break
		elseif v.name == "entry" then --atom
			base = doc.root
			elementName = "entry"
			parseFields = AtomFields
			break
		end
	end
	if not elementName then
		return
	end
	for k,v in pairs(base.kids) do
		local t = {}
		if v.name == elementName then
			for key,tField in ipairs(parseFields) do
				local s = ""
				if tField.show then
					local val = FindElement(v, tField.name, tField.specialCase)
					if val then
						val = Decode(val)
						for i,v in pairs(Rep) do val = utf_gsub(val,i,v) end
						if TagFilter then 
							val = utf_gsub(val,"%b<>","") 
						end
						s = s.." "..tField.label..":"..string_rep("\t",tField.tabs)
						if utf_len(val) > MaxWidth and tField.name:lower() ~= "link" then
							s = s..utf_sub(val,1,MaxWidth).."..."
						else
							s = s..val..""
						end
					end
					if utf_len(s) > 0 then push(t,s) end
				end
			end
		end
		local ChkFld = function(s)
			if next(Negate) then
				for i,v in ipairs(Negate) do
					if utf_find(s,v,1,true) then return false end
				end
			end
			return true
		end
		if next(t) and ChkFld(t[1]) then push(New,t) end
	end
	if next(New) then
		if ListOrder then
			local Tab = {}
			for i = 1, #New do push(Tab,1,New[i]) end
			New = Tab
		end
		local reply,cnt = "",0
		while #New > MaxCache do pop(New) end
		local Old = util_loadtable(Feeds[n].filepath)
		for key,val in ipairs(New) do
			local bool = true
			if Old and next(Old) then
				for i,v in ipairs(Old) do if v[2] == val[2] then bool = false break end end
			end
			if bool then
				cnt = cnt + 1
				if cnt <= MaxFeeds then
					if Simple then
						reply = reply..tostring(key)..". "..utf_gsub(val[1],parseFields[1].label.."%:[^%S]+","")
					else
						for i,v in ipairs(val) do reply = reply.."\t".. utf_gsub(v, "\n+", " " ) .. "\n" end
					end
					reply = reply.."\n"
				end
			end
		end
		if utf_len(reply) > 0 then
			local plural = ""
			if cnt > 1 then plural = "s" end
			SaveFile(Feeds[n].filepath,New,"Old")
			if Old then Old = nil end
			Params["name"] = Feeds[n].host
			Params["count"] = tostring(cnt)
			Params["plural"] = plural
			Params["feed"] = reply


			local txt = formatFeedText()
			return txt
		end
		if Old then Old = nil end
	end
end

GetEncoding = function(xml)
	local temp = utf_match(xml, "^<%?xml%s.-encoding=\"(.-)\".->")
	if temp and utf_len(temp) > 0 then
		return temp:upper()
	else
		return "UTF-8" --UTF-8 is default encoding for XML
	end
end

GetFeed = function(n)
	local st = socket.gettime()
	n = math.min(n,#Feeds)
	local s,fd,sz,hd
	if utf_sub(Feeds[n].url, 1, 5):lower() == "https" then
		--Not possible to set TIMEOUT for HTTPS, yet...
		--https.TIMEOUT = TimeOut
		s,fd,sz,hd = "",https.request(Feeds[n].url)
	else
		http.TIMEOUT = TimeOut
		s,fd,sz,hd = "",http.request(Feeds[n].url)
	end
	if fd and sz then
		local msg_
		encoding = GetEncoding(fd)
		msg_ = ParseFeed(ToUtf8(fd, encoding), n, Feeds[n].feedtype)
		local td,plural = socket.gettime()-st,"of a second."
		if td > 1 then plural = "seconds." end
		local time = utf_format("%.2f "..plural,td)

		if msg_ and utf_len(msg_) > 0 then
			if not Simple then msg_ = msg_.."\t Processed In: "..time.."\n\n" end
			if Feeds[n].force then
				if ForceFeedPM then
					hub_broadcast(utf_format( Body, msg_ ), Bot, Bot)
				else
					hub_broadcast(utf_format( Body, msg_ ), Bot)
				end
			else
				for i,v in ipairs(Users) do
					local user = hub_isnickonline(v[1])
					if user and v[3] then
						if v[2] == "p" then
							user:reply(utf_format( Body, msg_ ), Bot, Bot)
						elseif v[2] == "m" then
							user:reply(utf_format( Body, msg_ ), Bot)

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
					local b,save = ChkUsers(user:nick())
					local tab = {["true"] = "enabled",["false"] = "disabled"}
					if not b then
						if choice == "off" then
							return user:nick()..", feeds are already disabled for you.", false
						end
						local channel = "p"
						if choice == "m" then
							channel = "m"

						end
						push(Users,{user:nick(),channel,true})
						save = true
						b = #Users
					else
						if choice == "on" then
							if Users[b][3] then
								return user:nick()..", feeds are already enabled for you and will be sent in "..t[Users[b][2]], false
							else
								Users[b][3] = t[choice]
								save = true

							end
						elseif choice == "off" then
							if not Users[b][3] then
								return user:nick()..", feeds are already disabled for you and will be sent in "..t[Users[b][2]].." when enabled.", false
							else
								Users[b][3] = t[choice][2]
								save = true

							end
						else
							if Users[b][2] == choice then
								return user:nick()..", feeds are already set for "..t[choice].." and are curretly "..tab[tostring(Users[b][3])], false
							else
								Users[b][2] = choice
								save = true


							end
						end
					end
					if save then
						SaveFile(UserFile,Users,"Users")
					end
					return "Feeds are currently "..tab[tostring(Users[b][3])].." current message type: "..t[Users[b][2]], false
				else
					return "**Error in selection. Usage: "..cmd_text..cmd2.." <on/off/p/m>", false
				end
			else
				return "Error in selection. Usage: "..cmd_text..cmd2.." <on/off/p/m>", false
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
        if not user then
            return "Show Last feeds of <Feed number>","",""
        end
		if not data then
			return "Usage: [+!#]rss lastfeed <Feed number>", false
		end
		local n = data
		if n then
			n = tonumber(n)
		end
		if not n then
			return "Error! ' "..data.." ' is not a valid feed number.", false
		end

		if n and n > 0 then
			if Feeds[n] then
				local Old = util_loadtable(Feeds[n].filepath)
				if Old and next(Old) then
					local reply,plural,cnt = "","s",#Old
					if cnt == 1 then plural = "" end
					for key,val in ipairs(Old) do
						for i,v in ipairs(val) do reply = reply.."\t"..v.."\n" end
						reply = reply.."\n"
					end
					if reply ~= "" then
						local PM = msgToPM
						local u = ChkUsers(user:nick())
						if u and Users[u][2] then
							if Users[u][2] == "p" then
								PM = true
							elseif Users[u][2] == "m" then
								PM = false
							end
						end
						return "\n\n\t[ "..tostring(cnt).." ] Cached feed"..
						plural.." from: "..Feeds[n].url.."\n\n"..reply.."\n", PM
					end
				else
					return "There are no cached feeds at this time.", false
				end
			else
				return "Error! "..tostring(n).." is not a valid feed number.", false
			end
		else
			return "Error! "..tostring(n).." is not a valid feed number.", false
		end
	end,
	{ level = 10 } --min level to use this command
	},
	listfeeds = {function(user,data,cmd2)
		if user then
			if next(Feeds) then
				local reply = ""
				for i,v in ipairs(Feeds) do
					reply = reply.."\t"..utf_format("[%-2s]    ",i)..v.url.."\n"
				end
				if reply ~= "" then
					local PM = msgToPM
					local u = ChkUsers(user:nick())
					if u and Users[u][2] then
						if Users[u][2] == "p" then
							PM = true
						elseif Users[u][2] == "m" then
							PM = false
						end
					end
					return "Listing enabled feeds:\n\n"..reply, PM
				end
			else
				return "Error, There are no feeds set in script.", false
			end
		else
			return "List Enabled Feeds","",""
		end
	end,
	{ level = 10 } --min level to use this command
	},
	listusers = {function(user,data,cmd2)
		if user then
			local r = "-"
			local reply,t,c = "\n\n\t"..scriptname.." Active Users\n\n\t"..string_rep(r,50).."\r\n"..
			"\tNickname\t\tMessage Type\tStatus\r\n\t"..string_rep(r,50).."\r\n",{},""
			local tab = {["true"] = "enabled",["false"] = "disabled",
			["m"] = "main chat      ",["p"] = "private message"}
			for i,v in ipairs(Users) do
				push(t,"\t"..utf_format("%-30s",v[1]).."\t"..
				tab[v[2]].."\t"..tab[tostring(v[3])].."\r\n")
			end
			table_sort(t, function(a,b)return a < b end)
			c = table.concat(t,"")
			if utf_len(c) > 0 then
				local PM = msgToPM
				local u = ChkUsers(user:nick())
				if u and Users[u][2] then
					if Users[u][2] == "p" then
						PM = true
					elseif Users[u][2] == "m" then
						PM = false
					end
				end
				return reply..c.."\n\t"..string_rep(r,50).."\r\n\r\n", PM
			end
		else
			return "List Active Feed Users","",""
		end
	end,
	{ level = 10 } --min level to use this command
	},
	feedhelp = {function(user,data,cmd2)
		if user then
			local reply,t,c = "\n\n\t"..scriptname.." Command Help\n\n\t"..utf_format("%-22s","Command")..
			"\tDescription\r\n\t"..string_rep("-",50).."\r\n",{},""
			for i,v in ipairs(Order) do
				local desc,args = FwCmds[v][1]()
				if user:level() >= FwCmds[v][2]["level"] then
					push(t,"\t"..utf_format("%-22s",cmd_text..v).."\t"..desc.."\r\n")
				end
			end
			if not t then
				return msg_denied, false
			end
			table_sort(t, function(a,b)return a < b end)
			for i,v in ipairs(t) do
				c = c..v
			end
			if utf_len(c) > 0 then
				local PM = msgToPM
				local u = ChkUsers(user:nick())
				if u and Users[u][2] then
					if Users[u][2] == "p" then
						PM = true
					elseif Users[u][2] == "m" then
						PM = false
					end
				end
				return reply..c.."\n\t"..string_rep("-",50).."\r\n\r\n", PM
			end
		else
			return scriptname.." Help","",""
		end
	end,
	{ level = 10 } --min level to use this command

	},
	addfeed = {function(user,data,cmd2,data2)
		if user then
			if (not data) or (not data2) then
				return "Usage: [+!#]rss addfeed <Url> <Tag>", false
			end
			for i,v in ipairs(Feeds) do
				if v.url == data then
					return "Feed with url "..data.." already exists."
				end
				if v.tag == data2 then
					return "Feed with tag "..data2.." already exists."
				end
			end
			local host = data2 or utf_gsub(utf_gsub(data, "^[hftps:]+[/]+", ""), "/.*$", "") or "unavailable"
			local newFeed = { url=data, tag=data2, force=false, filepath = Path..utf_gsub(utf_gsub(data, "^[hftps:]+[/]+", ""), "[%c%p]", "_")..".tbl" }
			if host and host ~= "" then newFeed.host = host end
			push(Feeds, newFeed)
			SaveFeed()
			if not fileExists(newFeed.filepath) then
				local Old = {}
				SaveFile(newFeed.filepath,Old,"Old")
			end
			return "New feed added."
		else
			return "Add new RSS feed <Url> <Tag>",
			"",
			""
		end
	end,
	{ level = 60 } --min level to use this command

	},
	forcefeed = {function(user,data,cmd2)
		if user then
			if not data then
				return "Usage: [+!#]rss forcefeed <Feed number>", false
			end
			local n = data
			if n then
				n = tonumber(n)
			end
			if not n then
				return "Error! ' "..data.." ' is not a valid feed number.", false
			end

			if n and n > 0 then
				if Feeds[n] then
					local reply
					if Feeds[n].force then
						Feeds[n].force = false
						reply = "ForceFeed is now disabled for "..Feeds[n].tag.." ("..tostring(n)..")."
					else
						Feeds[n].force = true
						reply = "ForceFeed is now enabled for "..Feeds[n].tag.." ("..tostring(n)..")."
					end
					SaveFeed()
					return reply
				else
					return "Error! "..tostring(n).." is not a valid feed number.", false
				end
			else
				return "Error! "..tostring(n).." is not a valid feed number.", false
			end
		else
			return "Toggle force feed on <Feed number>",
			"",
			""
		end
	end,
	{ level = 60 } --min level to use this command

	},
	delfeed = {function(user,data,cmd2)
		if user then
			if not data then
				return "Usage: [+!#]rss delfeed <Feed number>", false
			end
			local n = data
			if n then
				n = tonumber(n)
			end
			if not n then
				return "Error! ' "..data.." ' is not a valid feed number.", false
			end

			if n and n > 0 then
				if Feeds[n] then
					local del = pop(Feeds, n)
					SaveFeed()
					if del and del.filepath and fileExists(del.filepath) then
						delete(del.filepath)
					end
					return del.tag.." ("..tostring(n)..") is now deleted."
				else
					return "Error! "..tostring(n).." is not a valid feed number.", false
				end
			else
				return "Error! "..tostring(n).." is not a valid feed number.", false
			end
		else
			return "Delete feed <Feed number>",
			"",
			""
		end
	end,
	{ level = 60 } --min level to use this command

	},
}

SaveFile = function(fileN,table, tablename )
	util_savetable(table, tablename, fileN)
end

SaveFeed = function()
	local tmp = {}
	for i,v in ipairs(Feeds) do
		push(tmp, { url=v.url, tag=v.tag, force=v.force })
	end
	SaveFile(FeedsFile,tmp,"Feeds")
end

local oncmdRSS = function( user, command, parameters )
	local user_level = user:level()
	if user_level < minlevel then
		user:reply( msg_denied, Bot )
		return PROCESSED
	end

	local subCmd = utf_match( parameters, "^(%S+)" )
	local data = utf_match( parameters, "^%a+ (%S+)" )
	local data2 = utf_match( parameters, "^%a+ %S+%s(%S+)" )

	if subCmd and FwCmds[subCmd] then
		if user:level() >= FwCmds[subCmd][2]["level"] then
			local msg, PM = FwCmds[subCmd][1](user,data,subCmd,data2)
			if msg and utf_len(msg) > 0 then
				if PM then
					user:reply(msg, Bot, Bot )
				else
					user:reply(msg, Bot )
				end
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
		if secondTick >= Refresh*60 then
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
		local host = Feeds[i].tag or utf_gsub(utf_gsub(Feeds[i].url, "^[hftps:]+[/]+", ""), "/.*$", "") or "unavailable"
		Feeds[i].filepath = Path..utf_gsub(utf_gsub(Feeds[i].url, "^[hftps:]+[/]+", ""), "[%c%p]", "_")..".tbl"
		if host and host ~= "" then Feeds[i].host = host end
	end
	for n,v in ipairs(Feeds) do
		if not fileExists(v.filepath) then
			local Old = {}
			SaveFile(v.filepath,Old,"Old")
		end
	end
	ucmd = hub.import "etc_usercommands"    -- add usercommand
	if ucmd then
		ucmd.add( ucmd_menu_help, cmd, {"feedhelp" }, { "CT1" }, FwCmds["feedhelp"][2]["level"] )
		ucmd.add( ucmd_menu_feeds, cmd, {"feeds", "%[line: on/off/m/p]" }, { "CT1" }, FwCmds["feeds"][2]["level"] )
		ucmd.add( ucmd_menu_lastfeed, cmd, {"lastfeed", "%[line: Feed Number ]" }, { "CT1" }, FwCmds["lastfeed"][2]["level"] )
		ucmd.add( ucmd_menu_listusers, cmd, {"listusers" }, { "CT1" }, FwCmds["listusers"][2]["level"] )
		ucmd.add( ucmd_menu_listfeeds, cmd, {"listfeeds" }, { "CT1" }, FwCmds["listfeeds"][2]["level"] )
		ucmd.add( ucmd_menu_addfeed, cmd, {"addfeed", "%[line: Url ]", "%[line: Tag ]" }, { "CT1" }, FwCmds["addfeed"][2]["level"] )
		ucmd.add( ucmd_menu_forcefeed, cmd, {"forcefeed", "%[line: Feed Number ]" }, { "CT1" }, FwCmds["forcefeed"][2]["level"] )
		ucmd.add( ucmd_menu_deletefeed, cmd, {"delfeed", "%[line: Feed Number ]" }, { "CT1" }, FwCmds["delfeed"][2]["level"] )
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

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
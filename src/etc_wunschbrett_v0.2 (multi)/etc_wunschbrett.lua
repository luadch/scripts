--[[
    "etc_wunschbrett.lua" by Motnahp
		Enables you to post your request to a list where everyone can look in and see if there are 
		items added.
    v0.2
        - added date to tbl to see actuality
        - added timer to broadcast that items are added
	v0.1 
		- adds commands add, show and delete
		- adds help
		- adds ucmd 

]]--

--[[ Settings ]]-- 

-- nicht Editieren -- do not edit --

local scriptname = "etc_wunschbrett_v0.2"

-- cmd --
local cmd = "wish"

-- parameters --
local prm1 = "add"
local prm2 = "show"
local prm3 = "delete"

local hubcmd
local hub_bot = hub.getbot()
local utf_match = utf.match
local utf_format = utf.format
local util_savearray = util.savearray
local table_remove = table.remove
local os_date = os.date
local os_difftime = os.difftime
local os_time = os.time
local start_time = os.time()

--local tabel and storage path -- 
local wunsch_path = "scripts/etc_wunschbrett/t_wunschbrett.tbl"
local t_wunschbrett = util.loadtable( wunsch_path ) or { }


-- load lang file
local lang, err = cfg.loadlanguage(cfg.get"language", scriptname); err = err and hub.debug(err)

-- functions --
local addrequest
local showrequests
local deleterequest
local amount

-->> nachfolgende Settings sind editierbar -->> you may edit the following settings -->>

-- permissions --
local min_level = 20

-- help --
local help_title = lang.help_title or "Wish_list"
local help_usage = lang.help_usage or "[+!#]wish [add|show|delete]"
local help_desc = lang.help_desc or "Allows you to [ add a request | show all requests | delete a request ]."

-- error msgs --
local help_err = lang.help_err or "You are not allowed to use this command."
local help_err_wrong_id = lang.help_err_wrong_id or "\n\t\t You have entered one or more wrong parameters, try one of those: \n\n\t\t %s \n\t\t %s "
local noitem = lang.noitem or "No request entered"
local nonumber = lang.nonumber or "No number entered"

-- msgs --
local addrequestmsg = lang.addrequestmsg or  "%s was added to wishlist"
local showrequestmsg = lang.showrequestmsg or  "\nThe Requests: "
local deletemsg = lang.deletemsg or  "%s was deletet from wishlist"
local amountmsg = lang.amountmsg or "[[Wishes]]--> %s items have been added to the wishlist, go and check them out"


-- ucmd menu --
local ucmd_menu_add = lang.ucmd_menu_add or { "Generel", "Wishes", "add" }
local ucmd_menu_show = lang.ucmd_menu_show or { "Generel", "Wishes", "show" }
local ucmd_menu_delete = lang.ucmd_menu_delete or { "Generel", "Wishes", "delete" }
local ucmd_what = lang.ucmd_what or "Enter your request:"
local ucmd_which = lang.ucmd_who or "Enter the request number:"

local by = lang.by or "added by"

-- others --
local hour = 60*60 -- 
local delay = 12 -- enter the amount of hours to send the info how many items are added ( depends on the variable hour)

--<< ende des editierbaren Teils --<< end of editable settings --<<
delay = delay * hour
--[[   Code   ]]--     

local onbmsg = function( user, adccmd, parameters)
	local local_prms = parameters.." "
	local user_level = user:level( )
	if user_level < min_level then 
		user:reply( help_err, hub_bot ) 
		return PROCESSED
	else
	    local id, item = utf_match( local_prms, "^(%S+) (.*)")	

		if id == prm1 then	-- add
			user:reply( addrequest( user, item ), hub_bot )
			return PROCESSED
		end
    	if id == prm2 then -- show
			user:reply( showrequests( ), hub_bot )
			return PROCESSED
		end		
		if id == prm3 then -- delete
			user:reply( deleterequest( item ), hub_bot )
			return PROCESSED
		end
		user:reply( utf_format( help_err_wrong_id, help_usage, help_desc ), hub_bot )	-- if no id hittes
		return PROCESSED
	end
end




hub.setlistener("onTimer", {},  --> Bei PtokaX = function OnTimer()
	function()
		if os_difftime( os_time() - start_time ) >= delay then
			hub.broadcast( amount( ), hub_bot )			
			start_time = os_time()
		end 	
		return nil
	end
) 

hub.setlistener( "onStart", { },
    function( )
        local help = hub.import "cmd_help"
        if help then
            help.reg( help_title, help_usage, help_desc, min_level )    -- reg help
        end
        local ucmd = hub.import "etc_usercommands"    -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu_add, cmd, { prm1,  "%[line:" .. ucmd_what .. "]" } , { "CT3" }, min_level )
            ucmd.add( ucmd_menu_show, cmd, { prm2} , { "CT3" }, min_level )
            ucmd.add( ucmd_menu_delete, cmd, { prm3,  "%[line:" .. ucmd_which .. "]" } , { "CT3" }, min_level )
        end
        hubcmd = hub.import "etc_hubcommands"    -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

-- functions --

addrequest = function ( user, item )
    local msg
    if item then
		t_wunschbrett[ #t_wunschbrett + 1 ] = {
			user_nick = user:nick( ),
            request = item,
            date = os_date( "%d.%m.%y" )
            }
        msg = utf_format( addrequestmsg, item )
		util_savearray( t_wunschbrett, wunsch_path )

    else
        msg = noitem
    end
	return msg 
end

showrequests = function (  ) 
	local msg = showrequestmsg
		
	for i, wishtbl in ipairs( t_wunschbrett ) do
		msg = msg.."\n["..i.."] [ "..( tostring( wishtbl.date ) or "n.a." ).." ] "..by..": "..wishtbl.user_nick.."\t - "..wishtbl.request
	end
	return msg
end

deleterequest = function ( number )
    local msg
    if number then
		local place = tonumber( number ) 
		local text = t_wunschbrett[place].request
        msg = utf_format ( deletemsg, text )
        -- msg = utf_format ( deletemsg, number )
        table_remove( t_wunschbrett, number )
		util_savearray( t_wunschbrett, wunsch_path )
    else
        msg = nonumber
    end
	return msg
end

amount = function ( )
    return utf_format( amountmsg, tostring( #t_wunschbrett ) )
end

hub.debug( "** Loaded " .. scriptname .. ".lua **" )

--[[   End    ]]--      
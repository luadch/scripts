--[[
    "etc_blackboard.lua" by Motnahp
    
    v0.2
        - adds parameter deleteinfo <number>
        - added userinformations of the OP who added a info 
	v0.1
		- adds command blackboard with parameters <addinfo> <showusers> <showinfo> 
		- adds help
		- adds ucmd 

]]--

--[[ Settings ]]-- 

-- nicht Editieren -- do not edit --

local scriptname = "etc_blackboard"
local version = "_v0.2"

-- cmd --
local cmd = "blackboard"

-- parameters --
local prm1 = "addinfo"
local prm2 = "showusers"
local prm3 = "showinfo"
-- local prm4 = "comment"
local prm5 = "deleteinfo"

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
local hub_issidonline = hub.issidonline

--local tabel and storage path -- 
local list_path = "scripts/etc_blackboard/t_blackboard.tbl"
local t_list = util.loadtable( list_path ) or { }
local nicklist_path = "scripts/etc_blackboard/t_blackboardnicks.tbl"
local t_nicklist = util.loadtable( nicklist_path ) or { }


-- load lang file
local lang, err = cfg.loadlanguage(cfg.get"language", scriptname); err = err and hub.debug(err)

-- functions --
local adduserinfo
local showusers
local showinfo
local deleteinfo

-->> nachfolgende Settings sind editierbar -->> you may edit the following settings -->>

-- permissions --
local min_level = 60

-- help --
local help_title = lang.help_title or "Blackboard"
local help_usage = lang.help_usage or "[+!#]blackboard [addinfo <userSID> <info> |showusers all|showinfo <userSID>| deleteinfo <id>]"
local help_desc = lang.help_desc or "Allows you to [ add info about user| shows all users with infos added | shows all infos of a user| allows you to delete a info]."

-- error msgs --
local help_err = lang.help_err or "You are not allowed to use this command."
local help_err_wrong_id = lang.help_err_wrong_id or "\n\t\t You have entered one or more wrong parameters, try one of those: \n\n\t\t %s \n\t\t %s "

-- msgs --
local addinfomsg = lang.addinfomsg or  "%s was added to blackboard, reason: %s"
local showusersmsg = lang.showusersmsg or "\nAll Users in blackboard: "
local showinfomsg = lang.showinfomsg or "\n All infos of User %s: "
local noinfos = lang.noinfos or "No infos available"
local nonenty = lang.noentry or "No entry with this ID"
local deleteinfomsg = lang.deleteinfomsg or  "Info: %s of User: %s was deletet from blackboard"

-- ucmd menu --
local ucmd_menu_addinfo = lang.ucmd_menu_addinfo or { "Hub", "Blackboard", "add info" }
local ucmd_menu_showusers = lang.ucmd_menu_showusers or { "Hub", "Blackboard", "show users" }
local ucmd_menu_showinfo = lang.ucmd_menu_showinfo or { "Hub", "Blackboard", "show infos" }
local ucmd_menu_deleteinfo = lang.ucmd_menu_deleteinfo or { "Hub", "Blackboard", "delete info" }

local ucmd_what = lang.ucmd_what or "Enter your info: "
local ucmd_info = lang.ucmd_info or "Enter your comment: "
-- local ucmd_which_user = lang.ucmd_which_user or "Enter the User number: "
local ucmd_which_info = lang.ucmd_which_info or "Enter the Info number: "

-- others --

--<< ende des editierbaren Teils --<< end of editable settings --<<

--[[   Code   ]]--     

local onbmsg = function( user, adccmd, parameters)
	local local_prms = parameters.." "
	local user_level = user:level( )
	if user_level < min_level then 
		user:reply( help_err, hub_bot ) 
		return PROCESSED
	else
	    local id, target, data = utf_match( local_prms, "^(%S+) (%S+) (.*)")
        target = hub_issidonline( target )

		if id == prm1 then	-- addinfo
			user:reply( adduserinfo( user, target, data ), hub_bot )
			return PROCESSED
		end
    	if id == prm2 then -- showusers
			user:reply( showusers( ), hub_bot )
			return PROCESSED
		end		
		if id == prm3 then -- showinfo
			user:reply( showinfo( target ), hub_bot )
			return PROCESSED
		end	
		if id == prm5 then -- deleteinfo
			user:reply( deleteinfo( target ), hub_bot )
			return PROCESSED
		end	
		user:reply( utf_format( help_err_wrong_id, help_usage, help_desc ), hub_bot )	-- if no id hittes
		return PROCESSED
	end
end

hub.setlistener( "onStart", { },
    function( )
        local help = hub.import "cmd_help"
        if help then
            help.reg( help_title, help_usage, help_desc, min_level )    -- reg help
        end
        local ucmd = hub.import "etc_usercommands"    -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu_addinfo, cmd, { prm1, "%[userSID]", "%[line:" .. ucmd_what .. "]" --[[, "%[line:" .. ucmd_info .. "]"]] } , { "CT2" }, min_level )
            ucmd.add( ucmd_menu_showusers, cmd, { prm2 , "all"} , { "CT1" }, min_level )
            ucmd.add( ucmd_menu_showinfo, cmd, { prm3, "%[userSID]" } , { "CT2" }, min_level )
            ucmd.add( ucmd_menu_deleteinfo, cmd, { prm5, "%[line:" .. ucmd_which_info .. "]" } , { "CT1" }, min_level )

        end
        hubcmd = hub.import "etc_hubcommands"    -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

-- functions --

adduserinfo = function ( user, target, item)
	local msg
    local targetnick = target:nick()
    t_list[ #t_list + 1 ] = {
        nick = targetnick,
        firstnick = target:firstnick(),
        date = os_date( "%d.%m.%y" ),
        by = user:nick(),
        info = item,
        }
    local inlist = false
    for i = 1, #t_nicklist, 1 do
        if t_nicklist[i].nick == targetnick then
           inlist = true 
           break
        end
    end
    if not inlist then
        t_nicklist[ #t_nicklist + 1 ] = { 
            nick = targetnick,
            firstnick = target:firstnick(),
            }
    end
    util_savearray( t_list, list_path )
    util_savearray( t_nicklist, nicklist_path )
    
    msg = utf_format( addinfomsg, targetnick, item)
	return msg
end


showusers = function ( )
	local msg = showusersmsg
    
    for i = 1, #t_nicklist, 1 do
        msg = msg.."\n["..i.."] "..t_nicklist[i].nick
	end
	return msg
end

showinfo = function ( target )
	local msg 
    local output = false
    local targetnick = target:nick()
    msg = utf_format ( showinfomsg, targetnick)
    for i = 1, #t_list, 1 do    
		if t_list[i].nick == targetnick then
            msg = msg .. "\n[" .. i .. "] [" .. t_list[i].date .. "] - " .. t_list[i].info .. " - " .. t_list[i].by
            output = true
		end
	end
    if not output then
        msg = msg .. noinfos
    end
	return msg
end

deleteinfo = function ( target )
    local msg 
    local item = tonumber( target)
    local nick, info 
    if #t_list >= item then
        nick = t_list[item].nick
        info = t_list[item].info
        msg = utf_format( deleteinfomsg, info, nick )
        table.remove( t_list, item )
        local moreinfos = false
        for i = 1, #t_list, 1 do
            if t_list[i].nick == nick then
                moreinfos = true
                break
            end
        end
        if not moreinfos then
            for i = 1, #t_nicklist, 1 do
                if t_list[i].nick == nick then
                    table.remove( t_nicklist, i )
                end
            end
        end
        util_savearray( t_list, list_path )
        util_savearray( t_nicklist, nicklist_path )       
    else
        msg = noentry
    end
    return msg
end

hub.debug( "** Loaded "..scriptname..version..".lua **" )

--[[   End    ]]--      
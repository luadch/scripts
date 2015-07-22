--[[

    ptx_freshstuff.lua

    based on the ptokax script freshstuff3_4.2 by bastya_elvtars


    v0.1 converted by blastbeat

        - this famous script was originally written by bastya_elvtars for ptokax with lua 5.0 and is licensed under GPL
        - changes:
              - the "categories.dat" has to return a table now ( because global vars are disabled in luadch )
              - updated to lua 5.1.1 ( maybe i missed some things )
        - notes:
              - this port should be considered as BETA
              - you have to save the lua file in unicode without signature when using non ansi chars inside the file ( for correct display )


    v0.2 modded by pulsar

        - cleaning code
        - added some categories
        - optimized output style

]]--



--// do not touch this lines

setmetatable( getfenv( 1 ), nil )

local fs_path = "scripts/ptx_freshstuff/"
local FreshStuff
local Bot

local scriptname = "ptx_freshstuff"
local scriptversion = "0.2"

FreshStuff = { Commands = {}, Levels = {}, AllStuff = {}, NewestStuff = {}, TopAdders = {} }


--// Settings

Bot = {
        name = hub.getbot(),
        email=" ",
        desc=" ",
    }

FreshStuff = {
    ProfilesUsed= 2, --> 2 for Luadch
    Commands = {

        Add = "addrel",
        Show = "releases",
        Delete = "delrel",
        ReLoad = "reloadrel",
        Search = "searchrel",
        AddCatgry = "addcat",
        DelCatgry = "delcat",
        ShowCtgrs = "showcats",
        Prune = "prunerel",
        TopAdders = "topadders",
        Help = "relhelp",

    },
    Levels = {

        Add=1, --> adding
        Show=1, --> showing all
        Delete=5, --> deleting
        ReLoad=5, --> reload
        Search=1, --> search
        AddCatgry=7, --> add category
        DelCatgry=7, --> delete category
        ShowCtgrs=1, --> show categories
        Prune=6, --> prune (delete old)
        TopAdders=1, --> top release adders
        Help=1, --> Guess what! :P

    },
    MaxItemAge=360, --> IN DAYS
    TopAddersCount=10, --> shows top-adders on command, this is the number how many it should show
    ShowOnEntry = 2, --> Show latest stuff on entry 1=PM, 2=mainchat, 0=no
    MaxNew = 16, --> Max stuff shown on newalbums/entry (notice: real entrys + 1)
    WhenAndWhatToShow={ --> Timed release announcing. You can specify a category name, or "all" or "new"

        ["04:01"]="new",
        ["12:00"]="new",
        ["15:00"]="new",
        ["18:00"]="new",
        ["21:00"]="new",
        ["00:00"]="new",

    }
  }

local ucmd_menu = "Releases" --> Rightclick Menu


--// Code

FreshStuff.AllStuff = {}; FreshStuff.NewestStuff = {}; FreshStuff.TopAdders = {}
local rightclick, commandtable, rctosend = {}, {}, {}

FreshStuff.Timer=0

Bot.version = "FreshStuff3 4.2 beta (bastya_elvtars)"

hub.setlistener( "onStart", { },
    function( p )

        userlevels = { --> Luadch default profiles

           [100]=9,
           [80]=9,
           [70]=7,
           [60]=6,
           [50]=5,
           [40]=4,
           [30]=3,
           [20]=2,
           [10]=1,
           [0]=1

        }

        if loadfile( fs_path .. "categories.dat" ) then
            FreshStuff.Types = dofile( fs_path .. "categories.dat" )
        else
            error( "Das Kategorie File ist fehlerhaft oder nicht vorhanden!" )
        end

        RegCmd( "relhelp", help, {}, 1, "\t\t\t\t\t\tZeigt den Text den du gesucht hast." )
        FreshStuff.ReloadRel()

        local ucmd = hub.import "etc_usercommands"
        
        if ucmd then

            ucmd.add({ucmd_menu,"Filme","SD","eintragen"},FreshStuff.Commands.Add,{"Filme_SD","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Filme","SD","anzeigen"},FreshStuff.Commands.Show,{"Filme_SD"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Filme","DVD","eintragen"},FreshStuff.Commands.Add,{"Filme_DVD","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Filme","DVD","anzeigen"},FreshStuff.Commands.Show,{"Filme_DVD"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Filme","720p","eintragen"},FreshStuff.Commands.Add,{"Filme_720p","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Filme","720p","anzeigen"},FreshStuff.Commands.Show,{"Filme_720p"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Filme","1080p","eintragen"},FreshStuff.Commands.Add,{"Filme_1080p","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Filme","1080p","anzeigen"},FreshStuff.Commands.Show,{"Filme_1080p"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Filme","COMPLETE.BLURAY","eintragen"},FreshStuff.Commands.Add,{"Filme_COMPLETE.BLURAY","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Filme","COMPLETE.BLURAY","anzeigen"},FreshStuff.Commands.Show,{"Filme_COMPLETE.BLURAY"}, { "CT1" },20)

            -----------------------------------------------------------------------------------------
            
            ucmd.add({ucmd_menu,"Serien","SD","eintragen"},FreshStuff.Commands.Add,{"Serien_SD","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Serien","SD","anzeigen"},FreshStuff.Commands.Show,{"Serien_SD"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Serien","DVD","eintragen"},FreshStuff.Commands.Add,{"Serien_DVD","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Serien","DVD","anzeigen"},FreshStuff.Commands.Show,{"Serien_DVD"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Serien","720p","eintragen"},FreshStuff.Commands.Add,{"Serien_720p","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Serien","720p","anzeigen"},FreshStuff.Commands.Show,{"Serien_720p"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Serien","1080p","eintragen"},FreshStuff.Commands.Add,{"Serien_1080p","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Serien","1080p","anzeigen"},FreshStuff.Commands.Show,{"Serien_1080p"}, { "CT1" },20)
            
            ucmd.add({ucmd_menu,"Serien","COMPLETE.BLURAY","eintragen"},FreshStuff.Commands.Add,{"Serien_COMPLETE.BLURAY","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Serien","COMPLETE.BLURAY","anzeigen"},FreshStuff.Commands.Show,{"Serien_COMPLETE.BLURAY"}, { "CT1" },20)

            -----------------------------------------------------------------------------------------

            ucmd.add({ucmd_menu,"Dokus","SD","eintragen"},FreshStuff.Commands.Add,{"Dokus_SD","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Dokus","SD","anzeigen"},FreshStuff.Commands.Show,{"Dokus_SD"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Dokus","DVD","eintragen"},FreshStuff.Commands.Add,{"Dokus_DVD","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Dokus","DVD","anzeigen"},FreshStuff.Commands.Show,{"Dokus_DVD"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Dokus","720p","eintragen"},FreshStuff.Commands.Add,{"Dokus_720p","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Dokus","720p","anzeigen"},FreshStuff.Commands.Show,{"Dokus_720p"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Dokus","1080p","eintragen"},FreshStuff.Commands.Add,{"Dokus_1080p","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Dokus","1080p","anzeigen"},FreshStuff.Commands.Show,{"Dokus_1080p"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Dokus","COMPLETE.BLURAY","eintragen"},FreshStuff.Commands.Add,{"Dokus_COMPLETE.BLURAY","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Dokus","COMPLETE.BLURAY","anzeigen"},FreshStuff.Commands.Show,{"Dokus_COMPLETE.BLURAY"}, { "CT1" },20)
            
            -----------------------------------------------------------------------------------------

            ucmd.add({ucmd_menu,"Musik","MP3","eintragen"},FreshStuff.Commands.Add,{"Musik_MP3","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Musik","MP3","anzeigen"},FreshStuff.Commands.Show,{"Musik_MP3"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Musik","FLAC","eintragen"},FreshStuff.Commands.Add,{"Musik_FLAC","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Musik","FLAC","anzeigen"},FreshStuff.Commands.Show,{"Musik_FLAC"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Musik","MViD","eintragen"},FreshStuff.Commands.Add,{"Musik_MViD","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Musik","MViD","anzeigen"},FreshStuff.Commands.Show,{"Musik_MViD"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Musik","MDVDR","eintragen"},FreshStuff.Commands.Add,{"Musik_MDVDR","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Musik","MDVDR","anzeigen"},FreshStuff.Commands.Show,{"Musik_MDVDR"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Musik","MBluRay","720p","eintragen"},FreshStuff.Commands.Add,{"Musik_MBluRay_720p","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Musik","MBluRay","720p","anzeigen"},FreshStuff.Commands.Show,{"Musik_MBluRay_720p"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Musik","MBluRay","1080p","eintragen"},FreshStuff.Commands.Add,{"Musik_MBluRay_1080p","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Musik","MBluRay","1080p","anzeigen"},FreshStuff.Commands.Show,{"Musik_MBluRay_1080p"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Musik","MBluRay","COMPLETE.BLURAY","eintragen"},FreshStuff.Commands.Add,{"Musik_MBluRay_COMPLETE.BLURAY","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Musik","MBluRay","COMPLETE.BLURAY","anzeigen"},FreshStuff.Commands.Show,{"Musik_MBluRay_COMPLETE.BLURAY"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Musik","AUDiOBOOKS","eintragen"},FreshStuff.Commands.Add,{"Musik_AUDiOBOOKS","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Musik","AUDiOBOOKS","anzeigen"},FreshStuff.Commands.Show,{"Musik_AUDiOBOOKS"}, { "CT1" },20)

            -----------------------------------------------------------------------------------------

            ucmd.add({ucmd_menu,"Software","PC","eintragen"},FreshStuff.Commands.Add,{"Software_PC","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Software","PC","anzeigen"},FreshStuff.Commands.Show,{"Software_PC"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Software","ANDROiD","eintragen"},FreshStuff.Commands.Add,{"Software_ANDROiD","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Software","ANDROiD","anzeigen"},FreshStuff.Commands.Show,{"Software_ANDROiD"}, { "CT1" },20)
            
            ucmd.add({ucmd_menu,"Software","MacOSX","eintragen"},FreshStuff.Commands.Add,{"Software_MacOSX","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Software","MacOSX","anzeigen"},FreshStuff.Commands.Show,{"Software_MacOSX"}, { "CT1" },20)
            
            ucmd.add({ucmd_menu,"Software","iOS","eintragen"},FreshStuff.Commands.Add,{"Software_iOS","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Software","iOS","anzeigen"},FreshStuff.Commands.Show,{"Software_iOS"}, { "CT1" },20)
            
            ucmd.add({ucmd_menu,"Software","Luadch","Hubsoft","eintragen"},FreshStuff.Commands.Add,{"Software_Luadch_Hubsoft","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Software","Luadch","Hubsoft","anzeigen"},FreshStuff.Commands.Show,{"Software_Luadch_Hubsoft"}, { "CT1" },20)
            
            ucmd.add({ucmd_menu,"Software","Luadch","Skripts","eintragen"},FreshStuff.Commands.Add,{"Software_Luadch_Skripts","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Software","Luadch","Skripts","anzeigen"},FreshStuff.Commands.Show,{"Software_Luadch_Skripts"}, { "CT1" },20)
            
            -----------------------------------------------------------------------------------------

            ucmd.add({ucmd_menu,"Spiele","PC","eintragen"},FreshStuff.Commands.Add,{"Spiele_PC","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Spiele","PC","anzeigen"},FreshStuff.Commands.Show,{"Spiele_PC"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Spiele","XBOX","eintragen"},FreshStuff.Commands.Add,{"Spiele_XBOX","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Spiele","XBOX","anzeigen"},FreshStuff.Commands.Show,{"Spiele_XBOX"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Spiele","XBOX360","eintragen"},FreshStuff.Commands.Add,{"Spiele_XBOX360","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Spiele","XBOX360","anzeigen"},FreshStuff.Commands.Show,{"Spiele_XBOX360"}, { "CT1" },20)
            
            ucmd.add({ucmd_menu,"Spiele","XBOXONE","eintragen"},FreshStuff.Commands.Add,{"Spiele_XBOXONE","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Spiele","XBOXONE","anzeigen"},FreshStuff.Commands.Show,{"Spiele_XBOXONE"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Spiele","PS2","eintragen"},FreshStuff.Commands.Add,{"Spiele_PS2","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Spiele","PS2","anzeigen"},FreshStuff.Commands.Show,{"Spiele_PS2"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Spiele","PS3","eintragen"},FreshStuff.Commands.Add,{"Spiele_PS3","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Spiele","PS3","anzeigen"},FreshStuff.Commands.Show,{"Spiele_PS3"}, { "CT1" },20)
            
            ucmd.add({ucmd_menu,"Spiele","PS4","eintragen"},FreshStuff.Commands.Add,{"Spiele_PS4","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Spiele","PS4","anzeigen"},FreshStuff.Commands.Show,{"Spiele_PS4"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Spiele","PSP","eintragen"},FreshStuff.Commands.Add,{"Spiele_PSP","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Spiele","PSP","anzeigen"},FreshStuff.Commands.Show,{"Spiele_PSP"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Spiele","Wii","eintragen"},FreshStuff.Commands.Add,{"Spiele_Wii","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Spiele","Wii","anzeigen"},FreshStuff.Commands.Show,{"Spiele_Wii"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"Spiele","NDS","eintragen"},FreshStuff.Commands.Add,{"Spiele_NDS","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Spiele","NDS","anzeigen"},FreshStuff.Commands.Show,{"Spiele_NDS"}, { "CT1" },20)

            -----------------------------------------------------------------------------------------

            ucmd.add({ucmd_menu,"eBooks","eintragen"},FreshStuff.Commands.Add,{"eBooks","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"eBooks","anzeigen"},FreshStuff.Commands.Show,{"eBooks"}, { "CT1" },20)

            -----------------------------------------------------------------------------------------

            ucmd.add({ucmd_menu,"XXX","SD","eintragen"},FreshStuff.Commands.Add,{"XXX_SD","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"XXX","SD","anzeigen"},FreshStuff.Commands.Show,{"XXX_SD"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"XXX","DVD","eintragen"},FreshStuff.Commands.Add,{"XXX_DVD","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"XXX","DVD","anzeigen"},FreshStuff.Commands.Show,{"XXX_DVD"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"XXX","720p","eintragen"},FreshStuff.Commands.Add,{"XXX_720p","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"XXX","720p","anzeigen"},FreshStuff.Commands.Show,{"XXX_720p"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"XXX","1080p","eintragen"},FreshStuff.Commands.Add,{"XXX_1080p","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"XXX","1080p","anzeigen"},FreshStuff.Commands.Show,{"XXX_1080p"}, { "CT1" },20)

            ucmd.add({ucmd_menu,"XXX","COMPLETE.BLURAY","eintragen"},FreshStuff.Commands.Add,{"XXX_COMPLETE.BLURAY","%[line:Name:]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"XXX","COMPLETE.BLURAY","anzeigen"},FreshStuff.Commands.Show,{"XXX_COMPLETE.BLURAY"}, { "CT1" },20)
            
            -----------------------------------------------------------------------------------------

            ucmd.add({ucmd_menu,"----------"}," ",{}, { "CT1" },20)

            -----------------------------------------------------------------------------------------

            ucmd.add({ucmd_menu,"Xtra","Zeige die Top Releaser"},FreshStuff.Commands.TopAdders,{}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Xtra","Suche ein Release"},FreshStuff.Commands.Search,{"%[line:Was?]"}, { "CT1" },20)
            ucmd.add({ucmd_menu,"Xtra","Lösche ein Release"},FreshStuff.Commands.Delete,{"%[line:ID Nummer(n):]"},  { "CT1" },70)
            ucmd.add({ucmd_menu,"Xtra","Releasedatenbank neu laden"},FreshStuff.Commands.ReLoad,{}, { "CT1" },70)
            ucmd.add({ucmd_menu,"Xtra","Lösche alte Releases"},FreshStuff.Commands.Prune,{"%[line:Max. Alter in Tagen (Enter=defaults to "..FreshStuff.MaxItemAge.."):]"}, { "CT1" },100)

            CreateRightClicks()

        end
    end
)

hub.setlistener( "onBroadcast", { },
    function( user, adccmd, txt )
        local cmd, parameters = utf.match( txt, "^[+!#](%a+) ?(.*)" )
        if commandtable[ cmd ] then
            parsecmds( user, txt, "MAIN", string.lower( cmd ) )
            return PROCESSED
        end
    end
)

hub.setlistener( "onLogin", { },
    function( user )
        if FreshStuff.Count > 0 then
            if FreshStuff.ShowOnEntry ~= 0 then
                if FreshStuff.ShowOnEntry== 1 then
                    SendTxt( user, "PM", Bot.name, FreshStuff.MsgNew )
                else
                    SendTxt( user, "MAIN", Bot.name, FreshStuff.MsgNew )
                end
            end
        end
    end
)

local start = os.time( )
hub.setlistener( "onTimer", { },
    function( )
        if os.difftime( os.time( ) - start ) >= 60 then
            if FreshStuff.WhenAndWhatToShow[ os.date( "%H:%M" ) ] then
                if FreshStuff.Types[ FreshStuff.WhenAndWhatToShow[ os.date( "%H:%M" ) ] ] then
                    hub.broadcast( FreshStuff.ShowRelType( FreshStuff.WhenAndWhatToShow[ os.date( "%H:%M" ) ] ), Bot.name )
                else
                    if FreshStuff.WhenAndWhatToShow[ os.date( "%H:%M" ) ] == "new" then
                        hub.broadcast( FreshStuff.MsgNew, Bot.name )
                    elseif FreshStuff.WhenAndWhatToShow[ os.date( "%H:%M" ) ] == "all" then
                        hub.broadcast( FreshStuff.MsgAll, Bot.name )
                    else
                    
                    end
                end
            end
            FreshStuff.Timer = 0
            start = os.time( )
        end
        return nil
    end
)

function parsecmds( user, data, env, cmd, bot )
    local whoto = Bot.name
    if commandtable[ cmd ] then
        if commandtable[ cmd ][ "level" ] ~= 0 then
            if userlevels[ user:level() ] >= commandtable[ cmd ][ "level" ] then
                commandtable[ cmd ][ "func" ]( user, data, env, unpack( commandtable[ cmd ][ "parms" ] ) )
            else
                SendTxt( user, env, bot, "Du bist nicht berechtigt diesen Befehl zu benutzen." )
            end
        else
            SendTxt( user, env, bot, "Der Befehl ist deaktiviert. Kontaktiere den Hubowner wenn du ihn wieder nutzen willst." )
        end
    end
end

function RegCmd( cmnd, func, parms, level, help)
    commandtable[ cmnd ] = { [ "func" ] = func, [ "parms" ] = parms, [ "level" ] = level, [ "help" ] = help }
end

function SendTxt( user, env, bot, text )
    if env == "main" then
        user:reply( text, bot, bot )
    else
        user:reply( text, bot )
    end
end

function help( user, data, env )
    local count = 0
    local hlptbl = {}
    local hlp = "\nAusführbare Befehle für dich sind:\n=================================================================================================================================\n"
    for a,b in pairs( commandtable ) do
        if b[ "level" ] ~= 0 then
            if userlevels[ user:level() ] >= b[ "level" ] then
                count = count + 1
                table.insert( hlptbl, "!" .. a .. " " .. b[ "help" ] )
            end
        end
    end
    table.sort( hlptbl )
    hlp = hlp .. table.concat( hlptbl, "\n" ) .. "\n\nAlle " .. count .. " Befehle können entweder im Main oder in PM ausgeführt werden, die verfügbaren Prefixe sind:" ..
    " ! # + - ?\r\n=================================================================================================================================" .. Bot.version
    user:reply( hlp, Bot.name, Bot.name )
end

function FreshStuff.ShowCrap( user, data, env )
    if FreshStuff.Count < 1 then SendTxt( user, env, Bot.name, "Keine Releases im Moment, versuche es später noch einmal." ) return end
    local _, _, cat = string.find( data, "%S+%s+(%S+)" )
    local _, _, latest = string.find( data, "%S+%s+(%d+)" )
    if not cat then
        user:reply( FreshStuff.MsgAll, Bot.name, Bot.name )
    else
        if cat == "new" then
            user:reply( FreshStuff.MsgNew, Bot.name, Bot.name )
        elseif FreshStuff.Types[ cat ] then
            if latest then
                user:reply( FreshStuff.ShowRelNum( cat, latest ), Bot.name, Bot.name )
            else
                user:reply( FreshStuff.ShowRelType( cat ), Bot.name, Bot.name )
            end
        else
            SendTxt( user, env, Bot.name, "No such type." )
        end
    end
end

function FreshStuff.AddCrap( user, data, env )
    local _, _, cat, tune = string.find( data, "%S+%s+(%S+)%s+(.+)" )
    if cat then
        if FreshStuff.Types[ cat ] then
            if string.find( tune, "$", 1, true ) then
                SendTxt( user, env, Bot.name, "Der Release Name darf keine Dollar Zeichen beinhalten ($)!" )
                return
            end
            if FreshStuff.Count > 0 then
                for i = 1, FreshStuff.Count do
                    local ct, who, when, title = unpack( FreshStuff.AllStuff[ i ] )
                    if title == tune then
                        SendTxt( user, env, Bot.name, "Das Release wurde schon hinzugefügt in der Kategorie " .. FreshStuff.Types[ ct ] .. "." )
                        return
                    end
                end
            end
            SendTxt( user, env, Bot.name, tune .. " wurde zu den Releases hinzugefügt als " .. cat )
            hub.broadcast( user:nick() .. " fügte zu der Kategorie " .. cat .. " hinzu: " .. tune, Bot.name )
            FreshStuff.Count = FreshStuff.Count + 1
            FreshStuff.AllStuff[ FreshStuff.Count ] = { cat, user:nick(), os.date( "%m/%d/%Y" ), tune }
            FreshStuff.SaveRel()
            FreshStuff.ReloadRel()
        else
            SendTxt( user, env, Bot.name, "Unbekannte Kategorie: " .. cat )
        end
    else
        SendTxt( user, env, Bot.name, "Woher soll ich wissen was ich hinzufügen soll, wenn du mir das nicht erzählst!!" )
    end
end

function FreshStuff.OpenRel()
    FreshStuff.AllStuff,FreshStuff.NewestStuff = nil, nil
    collectgarbage(); io.flush()
    FreshStuff.AllStuff,FreshStuff.NewestStuff = {}, {}
    FreshStuff.Count,FreshStuff.Count2 = 0, 0
    local f = io.open( fs_path .. "releases.dat", "r" )
    if f then
        for line in f:lines() do
            local _, _, cat, who, when, title = string.find( line, "(.+)$(.+)$(.+)$(.+)" )
            if cat then
                if not FreshStuff.TopAdders[ who ] then FreshStuff.TopAdders[ who ] = 1 else FreshStuff.TopAdders[ who ] = FreshStuff.TopAdders[ who ] + 1 end
                if string.find( when,"%d+/%d+/0%d" ) then
                    local _, _, m, d, y = string.find( when, "(%d+)/(%d+)/(0%d)" )
                    when = m .. "/" .. d .. "/" .. "20" .. y
                end
                FreshStuff.Count = FreshStuff.Count + 1
                FreshStuff.AllStuff[ FreshStuff.Count ] = { cat, who, when, title }
            else
                error( "Releases file is corrupt, failed to load all items." )
            end
        end
        f:close()
    end
    if FreshStuff.Count > FreshStuff.MaxNew then
        local tmp = FreshStuff.Count - FreshStuff.MaxNew + 1
        FreshStuff.Count2 = FreshStuff.Count - FreshStuff.MaxNew + 1
        for i = tmp, FreshStuff.Count do
            FreshStuff.Count2 = FreshStuff.Count2 + 1
            if FreshStuff.AllStuff[ FreshStuff.Count2 ] then
                FreshStuff.NewestStuff[ FreshStuff.Count2 ] = FreshStuff.AllStuff[ FreshStuff.Count2 ]
            end
        end
    else
        for i = 1, FreshStuff.Count do
            FreshStuff.Count2 = FreshStuff.Count2 + 1
            if FreshStuff.AllStuff[ i ] then
                FreshStuff.NewestStuff[ FreshStuff.Count2 ] = FreshStuff.AllStuff[ i ]
            end
        end
    end
end

function FreshStuff.ShowRel( tab )
    local Msg = "\n"
    local cat, who, when, title
    local tmptbl = {}
    local cunt = 0
    if tab == FreshStuff.NewestStuff then
        if FreshStuff.Count2 == 0 then
            FreshStuff.MsgNew = "\n\n" .. " --------- Die aktuellsten Releases -------- \n\n  Keine Releases in der Datenbank\n\n --------- Die aktuellsten Releases -------- \n\n"
        else
            for i = 1, FreshStuff.Count2 do
                if FreshStuff.NewestStuff[ i ] then
                    cat, who, when, title = unpack( FreshStuff.NewestStuff[ i ] )
                    if title then
                        if FreshStuff.Types[ cat ] then cat = FreshStuff.Types[ cat ] end
                        if not tmptbl[ cat ] then tmptbl[ cat ] = {} end
                        table.insert( tmptbl[ cat ], Msg .. "Nr: " .. i .. "\t|   " .. when .. "   |   " .. title .. "   |   von: " .. who .. "" )
                        cunt = cunt + 1
                    end
                end
            end
        end
        for a, b in pairs( tmptbl ) do
            Msg = Msg .. "\n" .. a .. "\n" .. string.rep( "¯", 10 ) .. "" .. table.concat( b ) .. "\n"
        end
        local new = FreshStuff.MaxNew if cunt < FreshStuff.MaxNew then new = cunt end
        FreshStuff.MsgNew = "\n" .. "\n=====================================================================================================================\n" ..
                                    "\t\t\t\t\t       DIE  " .. FreshStuff.MaxNew - 1 .. "  NEUESTEN RELEASES\n" ..
                                    "\t\t\t\t\t   ==============================" ..
                                    Msg ..
                                    "\n=====================================================================================================================\n"
    else
        if FreshStuff.Count == 0 then
            FreshStuff.MsgAll = "\n\n" .. " --------- Alle Releases -------- \n\n  Keine Releases in der Datenbank\n\n --------- Alle Releases -------- \n\n"
        else
            FreshStuff.MsgHelp = "  use " .. FreshStuff.Commands.Show .. " <new>"
            for a,b in pairs( FreshStuff.Types ) do
                FreshStuff.MsgHelp = FreshStuff.MsgHelp .. "/" .. a
            end
            FreshStuff.MsgHelp = FreshStuff.MsgHelp .. "> um nur die ausgewählten Kategorien zu sehen"
            for i = 1, FreshStuff.Count do
                if FreshStuff.AllStuff[ i ] then
                    cat, who, when, title = unpack( FreshStuff.AllStuff[ i ] )
                    if title then
                        if FreshStuff.Types[ cat ] then cat = FreshStuff.Types[ cat ] end
                        if not tmptbl[ cat ] then tmptbl[ cat ] = {} end
                        table.insert( tmptbl[ cat ], Msg .. "Nr: " .. i .. "\t" .. title .. " " )
                    end
                end
            end
            for a,b in pairs ( tmptbl ) do
                Msg = Msg .. "\n" .. a .. "\n" .. string.rep( "-", 33 ) .. "\n" .. table.concat( b ) .. "\n"
            end
            FreshStuff.MsgAll = "\n\n" .. " --------- Alle Releases -------- " .. Msg .. "\n --------- Alle Releases -------- \n" .. FreshStuff.MsgHelp .. "\n"
        end
    end
end

function FreshStuff.ShowRelType( what )
    local cat, who, when, title
    local Msg, MsgType, tmp = "\n", nil, 0
    if FreshStuff.Count == 0 then
        MsgType = "\n\n" .. " --------- Alles von: " .. FreshStuff.Types[ what ] ..
                            " -------- \n\n  Kein " .. string.lower( FreshStuff.Types[ what ] ) ..
                            " im Moment\n\n --------- Alles von: " .. FreshStuff.Types[ what ] .. " -------- \n\n"
    else
        for i = 1, FreshStuff.Count do
            cat, who, when, title = unpack( FreshStuff.AllStuff[ i ] )
            if cat == what then
                tmp = tmp + 1
                Msg = Msg .. "Nr: " .. i .. "\t ->    " .. title .. "  ->  gepostet von  " .. who .. "  am  [" .. when .. "]\n"
            end
        end
        if tmp == 0 then
            MsgType = "\n\n" .. " --------- Alles von: " .. FreshStuff.Types[ what ] .. " -------- \n\n  Kein " .. string.lower( FreshStuff.Types[ what ] ) ..
                                " im Moment\n\n --------- Alles von: " .. FreshStuff.Types[ what ] .. " -------- \n\n"
        else
            MsgType = "\n\n" .. " --------- Alles von: " .. FreshStuff.Types[ what ] .. " -------- \n" .. 
                                Msg .. "\n --------- Alles von: " .. FreshStuff.Types[ what ] .. " -------- \n\n"
        end
    end
    return MsgType
end

function FreshStuff.ShowRelNum( what, num )
    num = tonumber( num )
    local Msg = "\n"
    local cunt = 0
    local target = FreshStuff.Count - num
    local cat, who, when, title
    if num > FreshStuff.Count then target = 1 end
    for i = FreshStuff.Count, target, -1 do
        if FreshStuff.AllStuff[ i ] then
            cat, who, when, title = unpack( FreshStuff.AllStuff[ i ] )
            Msg = Msg.."Nr: " .. i .. "\t" .. title .. " // (Added by " .. who .. " at " .. when .. ")\n"
            cunt = cunt + 1
        else
            break
        end
    end
    if cunt < num then num = cunt end
    local MsgType = "\n\n" .. " --------- Die aktuellsten " .. num .. " " .. FreshStuff.Types[ what ] .. " -------- \n\n" ..
                              Msg .. "\n\n --------- Die aktuellsten " .. num .. " " .. FreshStuff.Types[ what ] .. " -------- \n\n"
    return MsgType
end

function FreshStuff.DelCrap( user, data, env )
    local _, _, what = string.find( data, "%S+%s+(.+)" )
    if what then
        local cnt, x = 0, os.clock()
        local tmp = {}
        for w in string.gmatch( what, "(%d+)" ) do
            table.insert( tmp, tonumber( w ) )
        end
        table.sort( tmp )
        for k = table.getn( tmp ), 1, -1 do
            local n = tmp[ k ]
            if FreshStuff.AllStuff[ n ] then
                SendTxt( user, env, Bot.name, FreshStuff.AllStuff[ n ][ 4 ] .. " wurde gelöscht." )
                FreshStuff.AllStuff[ n ] = nil
                cnt = cnt + 1
            else
                SendTxt( user, env, Bot.name, "Release mit der Nummer " .. wht .. " wurde in der Datenbank nicht gefunden." )
            end
        end
        if cnt > 0 then
            FreshStuff.SaveRel()
            FreshStuff.ReloadRel()
            SendTxt( user, env, Bot.name, "Das Löschen von " .. cnt .. " Release(s) dauerte " .. os.clock() - x .. " Sekunden." )
        end
    else
        SendTxt( user, env, Bot.name, "Woher soll ich wissen was ich löschen soll, wenn du mir das nicht erzählst!." )
    end
end

function FreshStuff.SaveRel()
    local f = io.open( fs_path .. "releases.dat", "w+" )
    for i = 1, FreshStuff.Count do
        if FreshStuff.AllStuff[ i ] then
            f:write( table.concat( FreshStuff.AllStuff[ i ], "$" ) .. "\n" )
        end
    end
    f:flush()
    f:close()
end

function FreshStuff.ReloadRel( user, data, env )
    local x = os.clock()
    FreshStuff.OpenRel()
    FreshStuff.ShowRel( FreshStuff.NewestStuff )
    FreshStuff.ShowRel( FreshStuff.AllStuff )
    if user then SendTxt( user, env, Bot.name, "Releases reloaded, dauerte " .. os.clock() - x .. " Sekunden." ) end
end

function FreshStuff.SearchRel( user, data, env )
    local _, _, what = string.find( data, "%S+%s+(.+)" )
    if what then
        local res, rest = 0, {}
        local msg = "\n---------- Du suchtest nach \"" .. what .. "\". Das Resultat: ----------\n\n"
        for a,b in pairs( FreshStuff.AllStuff ) do
            if string.find( string.lower( b[ 4 ] ), string.lower( what ), 1, true ) then
                table.insert( rest, { b[ 1 ], b[ 2 ], b[ 3 ], b[ 4 ] } )
            end
        end
        if table.getn( rest ) ~= 0 then
            for i = 1, table.getn( rest ) do
                local type, who, when, title = unpack( rest[ i ] )
                res = res + 1
                msg = msg .."ID: " .. i .. "\t" .. title .. "\n"
            end
            msg = msg .. string.rep( "-", 20 ) .. "\n" .. res .. " Resultate."
        else
            msg = msg .. "\nSearch string " .. what .. " wurde in der Datenbank nicht gefunden."
        end
        user:reply( msg, Bot.name, Bot.name )
    else
        SendTxt( user, env, Bot.name, "Woher soll ich wissen was ich suchen soll, wenn du mir das nicht erzählst!|" )
    end
end

function FreshStuff.AddCatgry( user, data, env )
    local _, _, what1, what2 = string.find( data, "%S+%s+(%S+)%s+(.+)" )
    if what1 then
        if string.find( what1, "$", 1, true ) then SendTxt( user, env, Bot.name, "Das Dollar Zeichen ist nicht erlaubt." ) return 1 end
        if not FreshStuff.Types[ what1 ] then
            FreshStuff.Types[ what1 ] = what2
            FreshStuff.SaveCt()
            SendTxt( user, env, Bot.name, "Die Kategorie " .. what1 .. " wurde erfolgreich hinzugefügt." )
        else
            if FreshStuff.Types[ what1 ] == what2 then
                SendTxt( user, env, Bot.name, "Die Kategorie " .. what1 .. " existiert bereits." )
            else
                FreshStuff.Types[ what1 ] = what2
                FreshStuff.SaveCt()
                SendTxt( user, env, Bot.name, "Die Kategorie " .. what1 .. " wurde erfolgreich geändert." )
            end
        end
    else
        SendTxt( user, env, Bot.name, "Category should be added properly: +" .. FreshStuff.Commands.AddCatgry .. " <category_name> <displayed_name>" )
    end
end

function FreshStuff.DelCatgry( user, data, env)
    local _, _, what = string.find( data, "%S+%s+(%S+)")
    if what then
        if not FreshStuff.Types[ what ] then
            SendTxt( user, env, Bot.name, "Die Kategorie " .. what .. " existiert nicht." )
        else
            FreshStuff.Types[ what ] = nil
            FreshStuff.SaveCt()
            SendTxt( user, env, Bot.name, "Die Kategorie " .. what .. " wurde erfolgreich gelöscht." )
        end
    else
        SendTxt( user, env, Bot.name, "Category should be deleted properly: +" .. FreshStuff.Commands.DelCatgry .. " <category_name>" )
    end
end

function FreshStuff.ShowCatgries( user, data, env )
    local msg = "\n======================\nVerfügbare Kategorien:\n======================\n"
    for a, b in pairs( FreshStuff.Types ) do
        msg = msg .. "\n" .. a
    end
    user:reply( msg, Bot.name, Bot.name )
end

function FreshStuff.SaveCt()
    local f = io.open( fs_path .. "categories.dat", "w+" )
    f:write( "return {\n" )
    for a,b in pairs( FreshStuff.Types ) do
        f:write( "[\"" .. a .. "\"]=\"" .. b .. "\",\n" )
    end
    f:write( "}" )
    f:close()
end

function FreshStuff.PruneRel( user, data, env )
    local _, _, days = string.find( data, "%S+%s+(%d+)" )
    days = days or FreshStuff.MaxItemAge
    local cnt = 0
    local x = os.clock()
    hub.broadcast( "Release-löscher Prozess gestarted, alle Releases älter als " .. days .. " Tage werden von der Datenbank gelöscht.", Bot.name )
    local now = JulianDate( SplitTimeString( os.date( "%m/%d/%Y" .. " 00:00:00" ) ) )
    local oldest = days * 1440
    for i = FreshStuff.Count, 1, -1 do
        local old = JulianDate( SplitTimeString( FreshStuff.AllStuff[ i ][ 3 ] .. " 00:00:00" ) )
        local diff = now - old
        local hours, mins = math.floor( diff ) * 24 + math.floor( frac( diff ) * 24 ), math.floor( frac( frac( diff ) * 24 ) * 60 )
        local tempus = hours * 60 + mins
        if tempus > oldest then
            FreshStuff.AllStuff[ i ] = nil
            cnt = cnt + 1
        end
    end
    hub.broadcast( FreshStuff.Count .. " Releases durchsucht und " .. cnt .. " entfernt.", Bot.name )
    if cnt ~= 0 then
        FreshStuff.SaveRel()
        FreshStuff.ReloadRel()
    end
end

function FreshStuff.ShowTopAdders( user, data, env )
    local tmp, numtbl, msg = {}, {}, "\nDie Top " .. FreshStuff.TopAddersCount .. " Releasers sind:\n" .. string.rep( "-", 33 ) .. "\n"
    for a,b in pairs( FreshStuff.TopAdders ) do
        table.insert( numtbl, b )
        tmp[ b ] = tmp[ b ] or {}
        table.insert( tmp[ b ], a )
    end
    table.sort( numtbl )
    local e
    if table.getn( numtbl ) <= FreshStuff.TopAddersCount then e = 1 else e = table.getn( numtbl ) - FreshStuff.TopAddersCount end
    for k = table.getn( numtbl ), e, -1 do
        for n, c in pairs( tmp[ numtbl[ k ] ] ) do
            msg = msg .. c .. ": " .. numtbl[ k ] .."\n"
        end
    end
    user:reply( msg, Bot.name, Bot.name )
end

function SplitTimeString( TimeString )
    -- Splits a time format to components, originally written by RabidWombat.
    -- Supports 2 time formats: MM/DD/YYYY HH:MM and YYYY. MM. DD. HH:MM
    local D, M, Y, HR, MN, SC
    if string.find( TimeString, "/" ) then
        _, _, M, D, Y, HR, MN, SC = string.find( TimeString, "(%d+)/(%d+)/(%d+)%s+(%d+):(%d+):(%d+)" )
    else
        _, _, Y, M, D, HR, MN, SC = string.find( TimeString, "([^.]+).([^.]+).([^.]+). ([^:]+).([^:]+).(%S+)" )
    end
    D = tonumber( D )
    M = tonumber( M )
    Y = tonumber( Y )
    HR = tonumber( HR )
    assert( HR < 24 )
    MN = tonumber( MN )
    assert( MN < 60 )
    SC = tonumber( SC )
    assert( SC < 60 )
    return D, M, Y, HR, MN, SC
end

function JulianDate( DAY, MONTH, YEAR, HOUR, MINUTE, SECOND ) -- Written by RabidWombat.
    -- HOUR is 24hr format.
    local jy, ja, jm;
    assert( YEAR ~= 0 );
    assert( YEAR ~= 1582 or MONTH ~= 10 or DAY < 4 or DAY > 15 );
    --The dates 5 through 14 October, 1582, do not exist in the Gregorian system!
    if( YEAR < 0 ) then
        YEAR = YEAR + 1;
    end
    if( MONTH > 2 ) then
        jy = YEAR;
        jm = MONTH + 1;
    else
        jy = YEAR - 1;
        jm = MONTH + 13;
    end
    local intgr = math.floor( math.floor( 365.25 * jy ) + math.floor( 30.6001 * jm ) + DAY + 1720995 );
    --check for switch to Gregorian calendar
    local gregcal = 15 + 31 * ( 10 + 12 * 1582 );
    if( DAY + 31 * ( MONTH + 12 * YEAR ) >= gregcal ) then
        ja = math.floor( 0.01 * jy );
        intgr = intgr + 2 - ja + math.floor( 0.25 * ja );
    end
    --correct for half-day offset
    local dayfrac = HOUR / 24 - 0.5;
    if( dayfrac < 0.0 ) then
        dayfrac = dayfrac + 1.0;
        intgr = intgr - 1;
    end
    --now set the fraction of a day
    local frac = dayfrac + ( MINUTE + SECOND / 60.0 ) / 60.0 / 24.0;
    --round to nearest second
    local jd0 = ( intgr + frac ) * 100000;
    local jd  = math.floor( jd0 );
    if( jd0 - jd > 0.5 ) then jd = jd + 1 end
    return jd / 100000;
end

function frac( num ) -- returns fraction of a number (RabidWombat)
    return num - math.floor( num );
end

function CreateRightClicks()
    for idx,_ in pairs( userlevels ) do
        rctosend[ idx ] = rctosend[ idx ] or {}
        for a,b in pairs( rightclick ) do
            if userlevels[ idx ] >= b then
                table.insert( rctosend[ idx ], a )
            end
        end
        for _,arr in pairs( rctosend ) do
            table.sort( arr )
        end
    end
end

RegCmd(FreshStuff.Commands.Add,FreshStuff.AddCrap,{},FreshStuff.Levels.Add,"<type> <name>\t\t\t\tFügt ein Release der gegebenen Kategorie hinzu.")
RegCmd(FreshStuff.Commands.Show,FreshStuff.ShowCrap,{},FreshStuff.Levels.Show,"<type>\t\t\t\t\tZeigt ein Release der gegebenen Kategorie, wenn keine Kategorie angegeben wird dann wird alles gezeigt.")
RegCmd(FreshStuff.Commands.Delete,FreshStuff.DelCrap,{},FreshStuff.Levels.Delete,"<ID>\t\t\t\t\tLöscht Releases der gegebenen ID, oder löscht mehrere wenn : 1,5,33,6789")
RegCmd(FreshStuff.Commands.ReLoad,FreshStuff.ReloadRel,{},FreshStuff.Levels.ReLoad,"\t\t\t\t\t\tLadet die Release Datenbank neu.")
RegCmd(FreshStuff.Commands.Search,FreshStuff.SearchRel,{},FreshStuff.Levels.Search,"<string>\t\t\t\t\tSuche nach Releases NAMES containing the given string.")
RegCmd(FreshStuff.Commands.AddCatgry,FreshStuff.AddCatgry,{},FreshStuff.Levels.AddCatgry,"<new_cat> <displayed_name>\t\t\tErstellt eine neue Kategorie.")
RegCmd(FreshStuff.Commands.DelCatgry,FreshStuff.DelCatgry,{},FreshStuff.Levels.DelCatgry,"<cat>\t\t\t\t\tLöscht die gegebene Kategorie...")
RegCmd(FreshStuff.Commands.ShowCtgrs,FreshStuff.ShowCatgries,{},FreshStuff.Levels.ShowCtgrs,"\t\t\t\t\tZeigt alle vorhandenen Kategorien.")
RegCmd(FreshStuff.Commands.Prune,FreshStuff.PruneRel,{},FreshStuff.Levels.Prune,"<days>\t\t\t\t\tLöscht alle Releases die älter sind als n Tage, bei keiner angegebenen Option, löscht es die eine die älter ist als "..FreshStuff.MaxItemAge.." Tage.")
RegCmd(FreshStuff.Commands.TopAdders,FreshStuff.ShowTopAdders,{},FreshStuff.Levels.TopAdders,"<number>\t\t\t\tZeigt die n TopReleaser (bei keiner Option werden die Top 5 angezeigt).")

--// End
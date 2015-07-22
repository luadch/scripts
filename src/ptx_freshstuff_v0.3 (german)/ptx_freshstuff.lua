--[[

    ptx_freshstuff.lua converted by blastbeat

        based on the ptokax script freshstuff3_4.2 by bastya_elvtars

        v0.3: by pulsar

            - change path to "../scripts/data/"
            - rename "categories.dat" to "ptx_freshstuff_categories.dat"
            - rename "releases.dat" to "ptx_freshstuff_releases.dat"
            - cleaning code, make it more readable for other customizers
            - remove unused functions
            - limit output amount of releases to show at the same time, new limit is FreshStuff.MaxShow
            - added 4k categories for: Movies, TV, Dokus, XXX

        v0.2: by pulsar

            - cleaning code
            - added some categories
            - optimized output style

        v0.1: by blastbeat

            - this famous script was originally written by bastya_elvtars for ptokax with lua 5.0 and is licensed under GPL
            - changes:
                  - the "categories.dat" has to return a table now ( because global vars are disabled in luadch )
                  - updated to lua 5.1.1 ( maybe i missed some things )
            - notes:
                  - this port should be considered as BETA
                  - you have to save the lua file in unicode without signature when using non ansi chars inside the file ( for correct display )

]]--



--// do not touch this lines

setmetatable( getfenv( 1 ), nil )

local fs_path = "scripts/data/"
local FreshStuff, Bot

local scriptname = "ptx_freshstuff"
local scriptversion = "0.3"

FreshStuff = { Commands = {}, Levels = {}, AllStuff = {}, NewestStuff = {}, TopAdders = {} }


--// Settings

local userlevels = {

   [100] = 100, --> HUBOWNER
   [80] = 80, --> ADMIN
   [70] = 70, --> SUPERVISOR
   [60] = 60, --> OPERATOR
   [50] = 50, --> SERVER
   [40] = 40, --> SVIP
   [30] = 30, --> VIP
   [20] = 20, --> REG
   [10] = 10, --> GUEST
   [0] = 0, --> UNREG

}

local minlevel = 10 --> minlevel to use this script
local oplevel = 60 --> minlevel to use OPERATOR commands
local masterlevel = 100 --> minlevel to use HUBOWNER commands

Bot = {
        name = hub.getbot(),
        email = " ",
        desc = " ",
    }

FreshStuff = {

    Commands = {

        Add = "addrel",
        Show = "releases",
        Delete = "delrel",
        ReLoad = "reloadrel",
        Search = "searchrel",
        Prune = "prunerel",
        TopAdders = "topadders",
        Help = "relhelp",
    },

    Levels = {

        Add = 10, --> adding
        Show = 10, --> showing all
        Delete = 60, --> deleting
        ReLoad = 60, --> reload
        Search = 10, --> search
        Prune = 100, --> prune (delete old)
        TopAdders = 10, --> top release adders
        Help = 10, --> guess what! :)
    },

    MaxItemAge = 360, --> IN DAYS
    TopAddersCount = 10, --> shows top-adders on command, this is the number how many it should show
    ShowOnEntry = 2, --> Show latest stuff on entry 1=PM, 2=mainchat, 0=no
    MaxNew = 51, --> Max stuff shown on newalbums/entry (notice: real entrys + 1)
    MaxShow = 300, --> Max stuff shown at the same time
    WhenAndWhatToShow = { --> Timed release announcing. You can specify a category name, or "all" or "new"

        ["12:00"] = "new",
        ["18:00"] = "new",
    },
  }

local ucmd_menu = "Releases" --> Rightclick Menu
local ucmd_add = "eintragen"
local ucmd_show = "anzeigen"
local ucmd_show_newest_01 = "Zeige die "
local ucmd_show_newest_02 = " neuesten Releases"
local ucmd_show_top_releaser = "Zeige die Top Releaser"
local ucmd_search_release = "Suche ein Release"
local ucmd_delete_release = "Lösche ein Release"
local ucmd_reload_db = "Datenbank neu laden"
local ucmd_prune_01 = "Lösche ältere Releases"
local ucmd_prune_02 = "Max. Alter in Tagen (leer=defaults to "

local msg_error_01 = "Die Kategorie Datei ist fehlerhaft oder existiert nicht."
local msg_error_02 = "Die Releases Datei ist fehlerhaft oder existiert nicht."
local msg_error_03 = "Befehl unvollständig."

local msg_denied = "Du bist nicht befugt diesen Befehl zu nutzen."
local msg_disabled = "Dieser Befehl ist deaktiviert."

local msg_empty_db = "Es befinden sich keine Releases in der Datenbank."
local msg_missing_cat = "Fehlerhafte Eingabe."

local msg_add_crap_01 = "Dollarzeichen ($) in Releasenamen sind nicht erlaubt."
local msg_add_crap_02 = "Es befindet sich bereits ein Release mit diesem Namen in der Kategorie: "
local msg_add_crap_03 = " wurde hinzugefügt als: "
local msg_add_crap_04 = " hat in der Kategorie ["
local msg_add_crap_05 = "] das folgende Release hinzugefügt: "
local msg_add_crap_06 = "Unbekannte Kategorie: "
local msg_add_crap_07 = "Ich hab keine Ahnung was du von mir willst :)"

local msg_del_crap_01 = " wurde gelöscht."
local msg_del_crap_02 = "Das Release mit der Nummer ["
local msg_del_crap_03 = "] wurde aus der Datenbank gelöscht."
local msg_del_crap_04 = "Anzahl der gelöschten Releases: "
local msg_del_crap_05 = "   |   benötigte Zeit in Sekunden: "

local msg_reload_rel_01 = "Releasedatenbank neu geladen, benötigte Zeit in Sekunden: "
local msg_search_rel_01 = [[


======================================================================================

Suche nach: %s

Gefunden: %s

%s
======================================================================================
  ]]

local msg_search_rel_02 = "Dein Suchstring wurde in der Datenbank nicht gefunden."

local msg_showrel_01 = "Keine Releases in der Datenbank gefunden."
local msg_showrel_02 = "von: "
local msg_showrel_03 = "Nr: "
local msg_showrel_04 = "\t|   "
local msg_showrel_05 = "   |   "
local msg_showrel_06 = "¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯"
local msg_showrel_07 = [[


===========================================================================================================================================
                                                                                                                DIE  %s  NEUESTEN  RELEASES
%s
===========================================================================================================================================
  ]]

local msg_show_cat_01 = [[


===========================================================================================================================================
                                                                                                       DIE  NEUESTEN  %s  RELEASES

No Releases from this category found.

===========================================================================================================================================
  ]]

local msg_show_cat_02 = [[


===========================================================================================================================================
                                                                                                       DIE   %s  NEUESTEN  %s  RELEASES

%s
===========================================================================================================================================
  ]]

local msg_prune = [[


=============================================================================
Release-Lösch-Prozess gestartet, alle Releases älter als  %s  Tage werden gelöscht.
Ergebnis:  %s  Releases durchsucht und  %s  gelöscht.
=============================================================================
  ]]
  
local msg_top_adders = [[


=========================================

Die Top  %s  Releasers sind:

%s
=========================================
  ]]
  
  
--// Code

FreshStuff.AllStuff = {}; FreshStuff.NewestStuff = {}; FreshStuff.TopAdders = {}
local rightclick, commandtable, rctosend = {}, {}, {}
FreshStuff.Timer = 0

hub.setlistener( "onStart", { },
    function( p )
        if loadfile( fs_path .. "ptx_freshstuff_categories.dat" ) then
            FreshStuff.Types = dofile( fs_path .. "ptx_freshstuff_categories.dat" )
        else
            error( msg_error_01 )
        end
        FreshStuff.ReloadRel()

        local ucmd = hub.import( "etc_usercommands" )

        if ucmd then
            local newest = FreshStuff.MaxNew - 1

            -------------------------------------------------------------------------------------------------------------------------

            ucmd.add( { ucmd_menu, ucmd_show_newest_01 .. newest .. ucmd_show_newest_02 }, FreshStuff.Commands.Show,{ "new" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"━━━━━━━━━━━━━━━━" }, " ", {}, { "CT1" }, minlevel )

            -------------------------------------------------------------------------------------------------------------------------

            ucmd.add( { ucmd_menu,"Filme","SD",ucmd_add }, FreshStuff.Commands.Add, { "Filme_SD", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Filme","SD",ucmd_show }, FreshStuff.Commands.Show, { "Filme_SD"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Filme","DVD",ucmd_add }, FreshStuff.Commands.Add, { "Filme_DVD", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Filme","DVD",ucmd_show }, FreshStuff.Commands.Show, { "Filme_DVD"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Filme","720p",ucmd_add }, FreshStuff.Commands.Add, { "Filme_720p", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Filme","720p",ucmd_show }, FreshStuff.Commands.Show, { "Filme_720p"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Filme","1080p",ucmd_add }, FreshStuff.Commands.Add, { "Filme_1080p", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Filme","1080p",ucmd_show }, FreshStuff.Commands.Show, { "Filme_1080p"}, { "CT1" }, minlevel )
            
            ucmd.add( { ucmd_menu,"Filme","4k",ucmd_add }, FreshStuff.Commands.Add, { "Filme_4k", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Filme","4k",ucmd_show }, FreshStuff.Commands.Show, { "Filme_4k"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Filme","COMPLETE.BLURAY",ucmd_add }, FreshStuff.Commands.Add, { "Filme_COMPLETE.BLURAY", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Filme","COMPLETE.BLURAY",ucmd_show }, FreshStuff.Commands.Show, { "Filme_COMPLETE.BLURAY"}, { "CT1" }, minlevel )

            -------------------------------------------------------------------------------------------------------------------------

            ucmd.add( { ucmd_menu,"Serien","SD",ucmd_add }, FreshStuff.Commands.Add, { "Serien_SD", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Serien","SD",ucmd_show }, FreshStuff.Commands.Show, { "Serien_SD"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Serien","DVD",ucmd_add }, FreshStuff.Commands.Add, { "Serien_DVD", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Serien","DVD",ucmd_show }, FreshStuff.Commands.Show, { "Serien_DVD"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Serien","720p",ucmd_add }, FreshStuff.Commands.Add, { "Serien_720p", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Serien","720p",ucmd_show }, FreshStuff.Commands.Show, { "Serien_720p"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Serien","1080p",ucmd_add }, FreshStuff.Commands.Add, { "Serien_1080p", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Serien","1080p",ucmd_show }, FreshStuff.Commands.Show, { "Serien_1080p"}, { "CT1" }, minlevel )
            
            ucmd.add( { ucmd_menu,"Serien","4k",ucmd_add }, FreshStuff.Commands.Add, { "Serien_4k", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Serien","4k",ucmd_show }, FreshStuff.Commands.Show, { "Serien_4k"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Serien","COMPLETE.BLURAY",ucmd_add }, FreshStuff.Commands.Add, { "Serien_COMPLETE.BLURAY", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Serien","COMPLETE.BLURAY",ucmd_show }, FreshStuff.Commands.Show, { "Serien_COMPLETE.BLURAY"}, { "CT1" }, minlevel )

            -------------------------------------------------------------------------------------------------------------------------

            ucmd.add( { ucmd_menu,"Dokus","SD",ucmd_add }, FreshStuff.Commands.Add, { "Dokus_SD", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Dokus","SD",ucmd_show }, FreshStuff.Commands.Show, { "Dokus_SD"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Dokus","DVD",ucmd_add }, FreshStuff.Commands.Add, { "Dokus_DVD", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Dokus","DVD",ucmd_show }, FreshStuff.Commands.Show, { "Dokus_DVD"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Dokus","720p",ucmd_add }, FreshStuff.Commands.Add, { "Dokus_720p", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Dokus","720p",ucmd_show }, FreshStuff.Commands.Show, { "Dokus_720p"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Dokus","1080p",ucmd_add }, FreshStuff.Commands.Add, { "Dokus_1080p", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Dokus","1080p",ucmd_show }, FreshStuff.Commands.Show, { "Dokus_1080p"}, { "CT1" }, minlevel )
            
            ucmd.add( { ucmd_menu,"Dokus","4k",ucmd_add }, FreshStuff.Commands.Add, { "Dokus_4k", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Dokus","4k",ucmd_show }, FreshStuff.Commands.Show, { "Dokus_4k"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Dokus","COMPLETE.BLURAY",ucmd_add }, FreshStuff.Commands.Add, { "Dokus_COMPLETE.BLURAY", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Dokus","COMPLETE.BLURAY",ucmd_show }, FreshStuff.Commands.Show, { "Dokus_COMPLETE.BLURAY"}, { "CT1" }, minlevel )

            -------------------------------------------------------------------------------------------------------------------------

            ucmd.add( { ucmd_menu,"Musik","MP3",ucmd_add }, FreshStuff.Commands.Add, { "Musik_MP3", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Musik","MP3",ucmd_show }, FreshStuff.Commands.Show, { "Musik_MP3"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Musik","FLAC",ucmd_add }, FreshStuff.Commands.Add, { "Musik_FLAC", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Musik","FLAC",ucmd_show }, FreshStuff.Commands.Show, { "Musik_FLAC"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Musik","MViD",ucmd_add }, FreshStuff.Commands.Add, { "Musik_MViD", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Musik","MViD",ucmd_show }, FreshStuff.Commands.Show, { "Musik_MViD"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Musik","MDVDR",ucmd_add }, FreshStuff.Commands.Add, { "Musik_MDVDR", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Musik","MDVDR",ucmd_show }, FreshStuff.Commands.Show, { "Musik_MDVDR"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Musik","MBluRay","720p",ucmd_add }, FreshStuff.Commands.Add, { "Musik_MBluRay_720p", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Musik","MBluRay","720p",ucmd_show }, FreshStuff.Commands.Show, { "Musik_MBluRay_720p"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Musik","MBluRay","1080p",ucmd_add }, FreshStuff.Commands.Add, { "Musik_MBluRay_1080p", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Musik","MBluRay","1080p",ucmd_show }, FreshStuff.Commands.Show, { "Musik_MBluRay_1080p"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Musik","MBluRay","COMPLETE.BLURAY",ucmd_add }, FreshStuff.Commands.Add, { "Musik_MBluRay_COMPLETE.BLURAY", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Musik","MBluRay","COMPLETE.BLURAY",ucmd_show }, FreshStuff.Commands.Show, { "Musik_MBluRay_COMPLETE.BLURAY"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Musik","AUDiOBOOKS",ucmd_add }, FreshStuff.Commands.Add, { "Musik_AUDiOBOOKS", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Musik","AUDiOBOOKS",ucmd_show }, FreshStuff.Commands.Show, { "Musik_AUDiOBOOKS"}, { "CT1" }, minlevel )

            -------------------------------------------------------------------------------------------------------------------------

            ucmd.add( { ucmd_menu,"Software","PC",ucmd_add }, FreshStuff.Commands.Add, { "Software_PC", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Software","PC",ucmd_show }, FreshStuff.Commands.Show, { "Software_PC"}, { "CT1" }, minlevel )
            
            ucmd.add( { ucmd_menu,"Software","Linux",ucmd_add }, FreshStuff.Commands.Add, { "Software_Linux", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Software","Linux",ucmd_show }, FreshStuff.Commands.Show, { "Software_Linux"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Software","ANDROiD",ucmd_add }, FreshStuff.Commands.Add, { "Software_ANDROiD", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Software","ANDROiD",ucmd_show }, FreshStuff.Commands.Show, { "Software_ANDROiD"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Software","MacOSX",ucmd_add }, FreshStuff.Commands.Add, { "Software_MacOSX", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Software","MacOSX",ucmd_show }, FreshStuff.Commands.Show, { "Software_MacOSX"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Software","iOS",ucmd_add }, FreshStuff.Commands.Add, { "Software_iOS", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Software","iOS",ucmd_show }, FreshStuff.Commands.Show, { "Software_iOS"}, { "CT1" }, minlevel )

            -------------------------------------------------------------------------------------------------------------------------

            ucmd.add( { ucmd_menu,"Games","PC",ucmd_add }, FreshStuff.Commands.Add, { "Spiele_PC", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Games","PC",ucmd_show }, FreshStuff.Commands.Show, { "Spiele_PC"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Games","XBOX",ucmd_add }, FreshStuff.Commands.Add, { "Spiele_XBOX", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Games","XBOX",ucmd_show }, FreshStuff.Commands.Show, { "Spiele_XBOX"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Games","XBOX360",ucmd_add }, FreshStuff.Commands.Add, { "Spiele_XBOX360", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Games","XBOX360",ucmd_show }, FreshStuff.Commands.Show, { "Spiele_XBOX360"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Games","XBOXONE",ucmd_add }, FreshStuff.Commands.Add, { "Spiele_XBOXONE", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Games","XBOXONE",ucmd_show }, FreshStuff.Commands.Show, { "Spiele_XBOXONE"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Games","PS2",ucmd_add }, FreshStuff.Commands.Add, { "Spiele_PS2", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Games","PS2",ucmd_show }, FreshStuff.Commands.Show, { "Spiele_PS2"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Games","PS3",ucmd_add }, FreshStuff.Commands.Add, { "Spiele_PS3", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Games","PS3",ucmd_show }, FreshStuff.Commands.Show, { "Spiele_PS3"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Games","PS4",ucmd_add }, FreshStuff.Commands.Add, { "Spiele_PS4", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Games","PS4",ucmd_show }, FreshStuff.Commands.Show, { "Spiele_PS4"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Games","PSP",ucmd_add }, FreshStuff.Commands.Add, { "Spiele_PSP", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Games","PSP",ucmd_show }, FreshStuff.Commands.Show, { "Spiele_PSP"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Games","Wii",ucmd_add }, FreshStuff.Commands.Add, { "Spiele_Wii", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Games","Wii",ucmd_show }, FreshStuff.Commands.Show, { "Spiele_Wii"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"Games","NDS",ucmd_add }, FreshStuff.Commands.Add, { "Spiele_NDS", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Games","NDS",ucmd_show }, FreshStuff.Commands.Show, { "Spiele_NDS"}, { "CT1" }, minlevel )

            -------------------------------------------------------------------------------------------------------------------------

            ucmd.add( { ucmd_menu,"eBooks",ucmd_add }, FreshStuff.Commands.Add, { "eBooks", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"eBooks",ucmd_show }, FreshStuff.Commands.Show, { "eBooks"}, { "CT1" }, minlevel )

            -------------------------------------------------------------------------------------------------------------------------

            ucmd.add( { ucmd_menu,"XXX","SD",ucmd_add }, FreshStuff.Commands.Add, { "XXX_SD", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"XXX","SD",ucmd_show }, FreshStuff.Commands.Show, { "XXX_SD"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"XXX","DVD",ucmd_add }, FreshStuff.Commands.Add, { "XXX_DVD", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"XXX","DVD",ucmd_show }, FreshStuff.Commands.Show, { "XXX_DVD"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"XXX","720p",ucmd_add }, FreshStuff.Commands.Add, { "XXX_720p", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"XXX","720p",ucmd_show }, FreshStuff.Commands.Show, { "XXX_720p"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"XXX","1080p",ucmd_add }, FreshStuff.Commands.Add, { "XXX_1080p", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"XXX","1080p",ucmd_show }, FreshStuff.Commands.Show, { "XXX_1080p"}, { "CT1" }, minlevel )
            
            ucmd.add( { ucmd_menu,"XXX","4k",ucmd_add }, FreshStuff.Commands.Add, { "XXX_4k", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"XXX","4k",ucmd_show }, FreshStuff.Commands.Show, { "XXX_4k"}, { "CT1" }, minlevel )

            ucmd.add( { ucmd_menu,"XXX","COMPLETE.BLURAY",ucmd_add }, FreshStuff.Commands.Add, { "XXX_COMPLETE.BLURAY", "%[line:Name:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"XXX","COMPLETE.BLURAY",ucmd_show }, FreshStuff.Commands.Show, { "XXX_COMPLETE.BLURAY"}, { "CT1" }, minlevel )

            -------------------------------------------------------------------------------------------------------------------------

            ucmd.add( { ucmd_menu,"━━━━━━━━━━━━━━━━ " }, " ", {}, { "CT1" }, minlevel )

            -------------------------------------------------------------------------------------------------------------------------

            ucmd.add( { ucmd_menu,"Menu",ucmd_show_top_releaser }, FreshStuff.Commands.TopAdders,{}, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Menu",ucmd_search_release }, FreshStuff.Commands.Search,{"%[line:]" }, { "CT1" }, minlevel )
            ucmd.add( { ucmd_menu,"Menu",ucmd_delete_release }, FreshStuff.Commands.Delete,{"%[line:ID Nr.:]"},  { "CT1" },oplevel)
            ucmd.add( { ucmd_menu,"Menu",ucmd_reload_db }, FreshStuff.Commands.ReLoad,{}, { "CT1" },oplevel)
            ucmd.add( { ucmd_menu,"Menu",ucmd_prune_01 }, FreshStuff.Commands.Prune,{"%[line:" .. ucmd_prune_02 .. FreshStuff.MaxItemAge .. ")]" }, { "CT1" }, masterlevel )

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
                if FreshStuff.ShowOnEntry == 1 then
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
                SendTxt( user, env, bot, msg_denied )
            end
        else
            SendTxt( user, env, bot, msg_disabled )
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

function FreshStuff.ShowCrap( user, data, env )
    if FreshStuff.Count < 1 then SendTxt( user, env, Bot.name, msg_empty_db ) return end
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
            SendTxt( user, env, Bot.name, msg_missing_cat )
        end
    end
end

function FreshStuff.AddCrap( user, data, env )
    local _, _, cat, tune = string.find( data, "%S+%s+(%S+)%s+(.+)" )
    if cat then
        if FreshStuff.Types[ cat ] then
            if string.find( tune, "$", 1, true ) then
                SendTxt( user, env, Bot.name, msg_add_crap_01 )
                return
            end
            if FreshStuff.Count > 0 then
                for i = 1, FreshStuff.Count do
                    local ct, who, when, title = unpack( FreshStuff.AllStuff[ i ] )
                    if title == tune then
                        SendTxt( user, env, Bot.name, msg_add_crap_02 .. FreshStuff.Types[ ct ] .. "." )
                        return
                    end
                end
            end
            SendTxt( user, env, Bot.name, tune .. msg_add_crap_03 .. cat )
            hub.broadcast( user:nick() .. msg_add_crap_04 .. cat .. msg_add_crap_05 .. tune, Bot.name )
            FreshStuff.Count = FreshStuff.Count + 1
            FreshStuff.AllStuff[ FreshStuff.Count ] = { cat, user:nick(), os.date( "%m/%d/%Y" ), tune }
            FreshStuff.SaveRel()
            FreshStuff.ReloadRel()
        else
            SendTxt( user, env, Bot.name, msg_add_crap_06 .. cat )
        end
    else
        SendTxt( user, env, Bot.name, msg_add_crap_07 )
    end
end

function FreshStuff.OpenRel()
    FreshStuff.AllStuff,FreshStuff.NewestStuff = nil, nil
    collectgarbage(); io.flush()
    FreshStuff.AllStuff,FreshStuff.NewestStuff = {}, {}
    FreshStuff.Count,FreshStuff.Count2 = 0, 0
    local f = io.open( fs_path .. "ptx_freshstuff_releases.dat", "r" )
    if f then
        for line in f:lines() do
            local _, _, cat, who, when, title = string.find( line, "(.+)$(.+)$(.+)$(.+)" )
            if cat then
                if not FreshStuff.TopAdders[ who ] then
                    FreshStuff.TopAdders[ who ] = 1
                else
                    FreshStuff.TopAdders[ who ] = FreshStuff.TopAdders[ who ] + 1
                end
                if string.find( when,"%d+/%d+/0%d" ) then
                    local _, _, m, d, y = string.find( when, "(%d+)/(%d+)/(0%d)" )
                    when = m .. "/" .. d .. "/" .. Y
                end
                FreshStuff.Count = FreshStuff.Count + 1
                FreshStuff.AllStuff[ FreshStuff.Count ] = { cat, who, when, title }
            else
                error( msg_error_02 )
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
            FreshStuff.MsgNew = msg_empty_db
        else
            for i = 1, FreshStuff.Count2 do
                if FreshStuff.NewestStuff[ i ] then
                    cat, who, when, title = unpack( FreshStuff.NewestStuff[ i ] )
                    if title then
                        if FreshStuff.Types[ cat ] then cat = FreshStuff.Types[ cat ] end
                        if not tmptbl[ cat ] then tmptbl[ cat ] = {} end
                        table.insert( tmptbl[ cat ], Msg .. msg_showrel_03 .. i .. msg_showrel_04 .. when .. msg_showrel_05 .. title .. msg_showrel_05 .. msg_showrel_02 .. who .. "" )
                        cunt = cunt + 1
                    end
                end
            end
        end
        for a, b in pairs( tmptbl ) do
            Msg = Msg .. "\n" .. a .. "\n" .. msg_showrel_06 .. "" .. table.concat( b ) .. "\n"
        end
        local new = FreshStuff.MaxNew
        local newest = FreshStuff.MaxNew - 1
        if cunt < FreshStuff.MaxNew then
            new = cunt
            newest = cunt
        end

        FreshStuff.MsgNew = utf.format( msg_showrel_07, newest, Msg )
    else
        FreshStuff.MsgAll = msg_error_03
    end
end

function FreshStuff.ShowRelType( what )
    local num = FreshStuff.MaxShow
    local Msg = "\n"
    local cunt = 0
    local target = FreshStuff.Count - num
    local cat, who, when, title
    if num > FreshStuff.Count then target = 1 end
    local i = FreshStuff.Count
    while cunt < num do
        if FreshStuff.AllStuff[ i ] then
            cat, who, when, title = unpack( FreshStuff.AllStuff[ i ] )
            if cat == what then
                Msg = Msg .. msg_showrel_03 .. i .. msg_showrel_04 .. when .. msg_showrel_05 .. title .. msg_showrel_05 .. msg_showrel_02 .. who .. "\n"
                cunt = cunt + 1
            end
            i = i - 1
        else
            break
        end
    end
    if cunt < num then num = cunt end
    if cunt == 0 then
        MsgType = utf.format( msg_show_cat_01, FreshStuff.Types[ what ] )
    else
        MsgType = utf.format( msg_show_cat_02, num, FreshStuff.Types[ what ], Msg )
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

            if cat == what then
                Msg = Msg .. msg_showrel_03 .. i .. msg_showrel_04 .. when .. msg_showrel_05 .. title .. msg_showrel_05 .. msg_showrel_02 .. who .. "\n"
                cunt = cunt + 1
            end

        else
            break
        end
    end
    if cunt < num then num = cunt end
    local MsgType = "\n\n" .. " --------- The actually " .. num .. " " .. FreshStuff.Types[ what ] .. " -------- \n\n" ..
                              Msg .. "\n\n --------- The actually " .. num .. " " .. FreshStuff.Types[ what ] .. " -------- \n\n"
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
                SendTxt( user, env, Bot.name, FreshStuff.AllStuff[ n ][ 4 ] .. msg_del_crap_01 )
                FreshStuff.AllStuff[ n ] = nil
                cnt = cnt + 1
            else
                SendTxt( user, env, Bot.name, msg_del_crap_02 .. wht .. msg_del_crap_03 )
            end
        end
        if cnt > 0 then
            FreshStuff.SaveRel()
            FreshStuff.ReloadRel()
            SendTxt( user, env, Bot.name, msg_del_crap_04 .. cnt .. msg_del_crap_05 .. os.clock() - x )
        end
    else
        SendTxt( user, env, Bot.name, msg_add_crap_07 )
    end
end

function FreshStuff.SaveRel()
    local f = io.open( fs_path .. "ptx_freshstuff_releases.dat", "w+" )
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
    if user then SendTxt( user, env, Bot.name, msg_reload_rel_01 .. os.clock() - x ) end
end

function FreshStuff.SearchRel( user, data, env )
    local _, _, what = string.find( data, "%S+%s+(.+)" )
    if what then
        local res, rest = 0, {}
        local msg, msg_out = "", ""
        for a,b in pairs( FreshStuff.AllStuff ) do
            if string.find( string.lower( b[ 4 ] ), string.lower( what ), 1, true ) then
                table.insert( rest, { b[ 1 ], b[ 2 ], b[ 3 ], b[ 4 ] } )
            end
        end
        if table.getn( rest ) ~= 0 then
            for i = 1, table.getn( rest ) do
                local type, who, when, title = unpack( rest[ i ] )
                res = res + 1
                msg = msg .. msg_showrel_03 .. i .. "\t" .. title .. "\n"
            end
            msg_out = utf.format( msg_search_rel_01, what, res, msg )
        else
            msg_out = utf.format( msg_search_rel_01, what, res, msg_search_rel_02 )
        end
        user:reply( msg_out, Bot.name, Bot.name )
    else
        SendTxt( user, env, Bot.name, msg_add_crap_07 )
    end
end

function FreshStuff.SaveCt()
    local f = io.open( fs_path .. "ptx_freshstuff_categories.dat", "w+" )
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
    local msg_out = utf.format( msg_prune, days, FreshStuff.Count, cnt )
    hub.broadcast( msg_out, Bot.name )
    if cnt ~= 0 then
        FreshStuff.SaveRel()
        FreshStuff.ReloadRel()
    end
end

function FreshStuff.ShowTopAdders( user, data, env )
    local tmp, numtbl, msg, count = {}, {}, "", 0
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
            count = count + 1
        end
    end
    if count < FreshStuff.TopAddersCount then
        FreshStuff.TopAddersCount = count
    end
    local msg_out = utf.format( msg_top_adders, FreshStuff.TopAddersCount, msg )
    user:reply( msg_out, Bot.name, Bot.name )
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

RegCmd( FreshStuff.Commands.Add, FreshStuff.AddCrap, {}, FreshStuff.Levels.Add, " " )
RegCmd( FreshStuff.Commands.Show, FreshStuff.ShowCrap, {}, FreshStuff.Levels.Show, " " )
RegCmd( FreshStuff.Commands.Delete, FreshStuff.DelCrap, {}, FreshStuff.Levels.Delete, " " )
RegCmd( FreshStuff.Commands.ReLoad, FreshStuff.ReloadRel, {}, FreshStuff.Levels.ReLoad, " " )
RegCmd( FreshStuff.Commands.Search, FreshStuff.SearchRel, {}, FreshStuff.Levels.Search, " " )
RegCmd( FreshStuff.Commands.Prune, FreshStuff.PruneRel, {}, FreshStuff.Levels.Prune,  " " )
RegCmd( FreshStuff.Commands.TopAdders, FreshStuff.ShowTopAdders, {}, FreshStuff.Levels.TopAdders, " " )

--// End
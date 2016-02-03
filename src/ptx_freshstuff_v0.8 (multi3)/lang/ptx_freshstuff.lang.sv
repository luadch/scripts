return {

own_botdesc_rel = "Releases: ",
own_botdesc_cat = "Kategorier: ",
own_botdesc_sep = "  |  ",

ucmd_menu = "Releases",
ucmd_add = "lägg till",
ucmd_show = "visa",
ucmd_show_newest_01 = "Visa de ",
ucmd_show_newest_02 = " nyaste releaserna",
ucmd_show_top_releaser = "Visa Topp-releasers",
ucmd_search_release = "Sök efter en release",
ucmd_delete_release = "Ta bort en release",
ucmd_reload_db = "Ladda om databasen",
ucmd_prune_01 = "Ta bort äldre releaser",
ucmd_prune_02 = "Max antal dagar (tom=standard ",
ucmd_help = "Visa hjälp",
ucmd_optout = "Av",
ucmd_optin = "På",

msg_error_01 = "Kategorifilen saknas eller så är den trasig.",
msg_error_02 = "Release-filen saknas eller så är den trasig.",
msg_error_03 = "Kommandot är ofullständigt.",
msg_error_04 = "Hitta inte releasen.",

msg_denied = "Du har inte tillåtelse att använda detta kommando.",
msg_disabled = "Detta kommando är inaktiverat.",

msg_empty_db = "Det finns inga Releaser i databasen.",
msg_missing_cat = "Denna typen finns inte.",

msg_add_crap_01 = "Dollartecken ($) får inte användas i release-namnet.",
msg_add_crap_02 = "Det finns redan en release med detta namnet i en annan kategori: ",
msg_add_crap_03 = " har lagt till som: ",
msg_add_crap_04 = " har lagt till i kategorin [",
msg_add_crap_05 = "] följande release: ",
msg_add_crap_06 = "Okänd kategori: ",
msg_add_crap_07 = "Jag förstår inte vad du menar :)",

msg_del_crap_01 = " har tagits bort.",
msg_del_crap_02 = "Release med nummer [",
msg_del_crap_03 = "] har tagits bort från databasen.",
msg_del_crap_04 = "Antal borttagna releaser: ",
msg_del_crap_05 = "   |   Tiden det tog i sekunder var: ",

msg_reload_rel_01 = "Releaser laddades om och tiden det tog i sekunder var: ",
msg_search_rel_01 = [[


======================================================================================

Söker efter: %s

Hittade: %s  |  Lista över de först %s releaserna:

%s
======================================================================================
  ]],

msg_search_rel_02 = "Det gick inte att hitta det du sökte i databasen.",

msg_showrel_01 = "Hittade inga releaser i databasen.",
msg_showrel_02 = "av: ",
msg_showrel_03 = "Nr: ",
msg_showrel_04 = "\t|   ",
msg_showrel_05 = "   |   ",
msg_showrel_06 = "¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯",
msg_showrel_07 = [[


===========================================================================================================================================
                                                                                                                DE  %s  NYASTE RELEASERNA
%s
===========================================================================================================================================
  ]],

msg_show_cat_01 = [[


===========================================================================================================================================
                                                                                                       DE  %s  NYASTE RELEASERNA

Hittade inga releaser från denna kategori.

===========================================================================================================================================
  ]],

msg_show_cat_02 = [[


===========================================================================================================================================
                                                                                                       DE  %s  NYASTE RELEASERNA

%s
===========================================================================================================================================
  ]],

msg_prune = [[


=============================================================================
Ta bort releaser startad, alla releaser äldre än  %s  dagar har tagits bort från databasen.
Resultat:  %s  releaser hittades och  %s  borttagna.
=============================================================================
  ]],

msg_top_adders = [[


=========================================

De  %s  som lagt till flest releaser är:

%s
=========================================
  ]],

msg_help = [[


=============================================================================

    [+!#]addrel <KATEGORI> <RELEASE-NAMN>
    [+!#]releases <KATEGORI>
    [+!#]delrel <RELEASE-NUMMER-ID>
    [+!#]reloadrel
    [+!#]searchrel <SÖKSTRÄNG>
    [+!#]prunerel [<MAXIMAL-RELEASE-ÅLDER>]
    [+!#]topadders
    [+!#]relhelp
    [+!#]announcerel <RIKTIGA-DUMP-ANVÄNDARNAMNET> <KATEGORI> <RELEASE-NAMN>
	[+!#]reloff
	[+!#]relon

=============================================================================
  ]],

msg_optout = "Releaser är avstängda",
msg_already_optout = "Du har redan stängt av releaser",
msg_optin = "Releaser är påslagna",
msg_already_optin = "Du har redan slagit på releaser",

}
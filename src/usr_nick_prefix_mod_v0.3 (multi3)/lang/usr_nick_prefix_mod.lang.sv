return {

    help_title = "usr_nick_prefix_mod.lua",
    help_usage = "[+!#]nickprefix add <ANVÄNDARNAMN> <PREFIX>  /  [+!#]nickprefix del <ANVÄNDARNAMN>",
    help_desc = "Detta skript lägger till ett prefix på användarnamnet",

    msg_denied = "Du har inte behörighet att använda detta kommando.",
    msg_god = "Du har inte behörighet att lägga till/ändra prefixet på denna användaren.",
    msg_isbot = "Användaren är en bot.",
    msg_notonline = "Användaren är frånkopplad.",
    msg_notfound = "Hittade inget prefix.",
    msg_forbidden = "Prefixet innehåller ej tillåtna tecken eller mellanslag.",
    msg_usage = "Användning: [+!#]nickprefix add <ANVÄNDARNAMN> <PREFIX>  /  [+!#]nickprefix del <ANVÄNDARNAMN>",

    msg_prefix_add = "%s  har lagt till ett prefix på användaren: %s  prefix: %s",
    msg_prefix_change = "%s  ändrade prefixet på användaren: %s  nytt prefix: %s",
    msg_prefix_remove = "%s  tog bort prefixet på användaren: %s",

    ucmd_menu_ct2_1 = { "Användarprefix", "lägg till//ändra" },
    ucmd_menu_ct2_2 = { "Användarprefix", "ta bort" },
    ucmd_prefix = "Nytt användarprefix:",

}
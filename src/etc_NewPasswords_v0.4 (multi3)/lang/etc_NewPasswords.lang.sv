return {

    help_title = "etc_NewPasswords.lua",
    help_usage = "[+!#]newpw true|false",
    help_desc = "Skapar ett nytt lösenord för användaren vid inloggningen",
    msg_denied = "Du har inte behörighet att använda detta kommando.",
    msg_usage = "Användning: [+!#]newpw true|false",
    msg_disconnect = "Du har kopplats från eftersom du har fått ett nytt lösenord. Lägg till ditt nya lösenord till dina favorithubbar och logga in igen.",
    msg_report = "Följande användare har fått ett nytt automatiskt slumpmässigt lösenord och har nu blivit frånkopplad: %s",
    msg_target = [[


=== NYTT LÖSENORD TILL DIG =====================================

     Hej %s, du har fått ett nytt lösenord. Använd det att logga in med från och med nu!
     Ditt nya lösenord är:  %s

     Du kommer att kopplas från nu!

===================================== NYTT LÖSENORD TILL DIG ===
  ]],

    msg_users_true = [[


=== NYA LÖSENORD =====================================

Användare som bytat lösenord:

%s
===================================== NYA LÖSENORD ===
  ]],

    msg_users_false = [[


=== NYA LÖSENORD =====================================

Användare som inte bytat lösenord:

%s
===================================== NYA LÖSENORD ===
  ]],

    ucmd_menu_ct1_1 = { "Hubb", "etc", "NyttLösenord", "visa användare med nya lösenord" },
    ucmd_menu_ct1_2 = { "Hubb", "etc", "NyttLösenord", "visa användare med gamla lösenord" },

}
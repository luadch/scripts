--[[ 

    freshstuff3_4.2@luadch_v0.08_german_v0.1.lua by blastbeat
    
    - this famous script was originally written by bastya_elvtars for ptokax with lua 5.0 and is licensed under GPL
    - some functions arent ported to luadch yet ( timer, usercommands, creation of folder and .dat file )
    - changes: 
      - the "categories.dat" has to return a table now ( because global vars are disabled in luadch )
      - updated to lua 5.1.1 ( maybe i missed some things )
    - notes:
      - this port should be considered as BETA
      - you have to save the lua file in unicode without signature when using non ansi chars inside the file ( for correct display )
    - TODO: import op chat

]]--

--!
setmetatable( getfenv( 1 ), nil )

--! some new settings

local fs_path = "scripts/ptx_freshstuff/" 
local FreshStuff
local Bot

--!

FreshStuff={Commands={},Levels={},AllStuff = {},NewestStuff = {},TopAdders={}} -- do not touch this line

--<SettingsStart>
Bot = {
        --! name=frmHub:GetHubBotName(),
        name=hub.getbot( ), --!
        email=" ",
        desc=" ",
      }

---------------------------------------------------------------------------------------------------------------------------------------------------------



FreshStuff={
    ProfilesUsed= 2,         -- 0 for lawmaker/terminator (standard), 1 for robocop, 2 for INFINITY
    Commands={
      Add="addrel",         -- Add a new release
      Show="releases",         -- This command shows the stuff, syntax : +albums with options new/game/warez/music/movie
      Delete="delrel",         -- This command deletes an entry, syntax : +delalbum THESTUFF2DELETE
      ReLoad="reloadrel",     -- This command reloads the txt file. syntax : +reloadalbums (this command is needed if you manualy edit the text file)
      Search="searchrel",     -- This is for searching inside releases.
      AddCatgry="addcat",     -- For adding a category
      DelCatgry="delcat",     -- For deleting a category
      ShowCtgrs="showcats",     -- For showing categories
      Prune="prunerel",     -- Pruning releases (removing old entries)
      TopAdders="topadders",     -- Showing top adders
      Help="relhelp",         -- Guess what! :P
    },                 -- No prefix for commands! It is automatically added. (<--- multiple prefixes)
    Levels={
      Add=1,         -- adding
      Show=1,         -- showing all
      Delete=5,       -- deleting
      ReLoad=5,       -- reload
      Search=1,     -- search
      AddCatgry=7,     -- add category
      DelCatgry=7,     -- delete category
      ShowCtgrs=1,     -- show categories
      Prune=6,         -- prune (delete old)
      TopAdders=1,     -- top release adders
      Help=1,         -- Guess what! :P
    }, -- You set the userlevels according to... you know what :P
    MaxItemAge=360, --IN DAYS
    TopAddersCount=10, -- shows top-adders on command, this is the number how many it should show
    ShowOnEntry = 2, -- Show latest stuff on entry 1=PM, 2=mainchat, 0=no
    MaxNew = 16, -- Max stuff shown on newalbums/entry
    WhenAndWhatToShow={ 
      ["04:01"]="new",
      ["12:00"]="new",
      ["15:00"]="new",
      ["18:00"]="new",
      ["21:00"]="new",
      ["00:00"]="new",
    }-- Timed release announcing. You can specify a category name, or "all" or "new"
  }


--<SettingsEnd> 
-- ====================================================================================
-- please do not edit below =========================================================== 
-- ====================================================================================


FreshStuff.AllStuff = {}; FreshStuff.NewestStuff = {}; FreshStuff.TopAdders={}
local rightclick,commandtable,rctosend={},{},{}

FreshStuff.Timer=0

Bot.version="FreshStuff3 4.2 beta (bastya_elvtars)"

hub.setlistener( "onStart", { },                                     
    function( p )
    --[[ --! function Main()
      if FreshStuff.ProfilesUsed==0 or FreshStuff.ProfilesUsed~=2 or FreshStuff.ProfilesUsed~=3 then
        userlevels={[0]=7, [1]=6, [2]=5, [3]=4, [4]=3, [5]=2, [6]=1, [7]=1, [8]=1, [9]=1, [-1]=1} --
      elseif FreshStuff.ProfilesUsed==2 then
        userlevels={[0]=7, [1]=6, [2]=5, [3]=4, [4]=3, [5]=2, [6]=1, [7]=1, [8]=1, [9]=1, [-1]=1} ---- Profile
      else
        userlevels={[0]=7, [1]=6, [2]=5, [3]=4, [4]=3, [5]=2, [6]=1, [7]=1, [8]=1, [9]=1, [-1]=1} --
      end
    ]]
      userlevels={[100]=7, [80]=6, [60]=5, [40]=4, [30]=3, [20]=2, [10]=1, [0]=1} --! luadch default profiles
      --! frmHub:RegBot(Bot.name,1,Bot.desc,Bot.email)
      --! if loadfile("freshstuff/categories.dat") then
      if loadfile(fs_path.."categories.dat") then --!      
        --! dofile("freshstuff/categories.dat")
        FreshStuff.Types = dofile(fs_path.."categories.dat") --!        
      else
    --[=[ --!      FreshStuff.Types={
              ["rarCD"]="rarCD",
              ["rarDVD"]="rarDVD",
              ["Software"]="Software",
              ["Audio"]="Audio",
              ["Reportage"]="Reportage",
              ["Spiel"]="Spiel",
              ["Serie"]="Serie",
            }
        os.execute("md \""..frmHub:GetPtokaXLocation().."/scripts/freshstuff\"")
        SendToOps(Bot.name,"Das Kategorie File ist fehlerhaft oder nicht vorhanden! Erstelle eine neue...")
        SendToOps(Bot.name,"Wenn das das erste mal ist das du das Skript startest, oder neu installiert hast, bitte kopiere releases.dat in das Verzeichnis Namens  freshstuff (befindet sich in der scripts Mappe, und starte die Skripts neu. Danke!")
        local f=io.open("freshstuff/categories.dat","w+")
        f:write(
      [[FreshStuff.Types={
    ["rarCD"]="rarCD",
    ["rarDVD"]="rarDVD",
    ["Software"]="Software",
    ["Audio"]="Audio",
    ["Reportage"]="Reportage",
    ["Spiel"]="Spiel",
    ["Serie"]="Serie",
      }]])
        f:close()
    ]=]
      error("Das Kategorie File ist fehlerhaft oder nicht vorhanden!") --!
      end
      RegCmd("relhelp",help,{},1,"\t\t\t\t\t\tZeigt den Text den du gesucht hast.")
    --[[ --!    for a,b in pairs(FreshStuff.Types) do
        RegRC(FreshStuff.Levels.Add,"1 1","Releases\\eintragen\\"..b,"!"..FreshStuff.Commands.Add.." "..a.." %[line:Name:]")
        RegRC(FreshStuff.Levels.Show,"1 1","Releases\\anzeigen\\"..b.."","!"..FreshStuff.Commands.Show.." "..a)
        RegRC(FreshStuff.Levels.Help,"1 1","Releases\\sonstiges\\Hilfe","!"..FreshStuff.Commands.Help)
      end
      CreateRightClicks()
    ]]
      FreshStuff.ReloadRel()
      --! SetTimer(60000)
      --! StartTimer()
      
      
        local ucmd = hub.import "etc_usercommands"    -- add usercommand
        if ucmd then
ucmd.add({"Releases","sonstiges","Zeige Kategorien"},FreshStuff.Commands.ShowCtgrs, {}, { "CT1" },  FreshStuff.Levels.ShowCtgrs)
ucmd.add({"Releases","sonstiges","Lösche ein Release"},FreshStuff.Commands.Delete,{"%[line:ID Nummer(n):]"},  { "CT1" }, FreshStuff.Levels.Delete)
ucmd.add({"Releases","sonstiges","Releasedatenbank neu laden"},FreshStuff.Commands.ReLoad,{}, { "CT1" },FreshStuff.Levels.ReLoad)
ucmd.add({"Releases","sonstiges","Suche Release"},FreshStuff.Commands.Search,{"%[line:Was?]"}, { "CT1" },FreshStuff.Levels.Search)
ucmd.add({"Releases","sonstiges","Erstelle eine Kategorie"},FreshStuff.Commands.AddCatgry,{"%[line:Kategorie Name:]","%[line:Angezeigter Name:]"}, { "CT1" },FreshStuff.Levels.AddCatgry)
ucmd.add({"Releases","sonstiges","Lösche eine Kategorie"},FreshStuff.Commands.DelCatgry,{"%[line:Kategorie Name:]"}, { "CT1" },FreshStuff.Levels.DelCatgry)
ucmd.add({"Releases","sonstiges","Lösche alte Releases"},FreshStuff.Commands.Prune,{"%[line:Max. Alter in Tagen (Enter=defaults to "..FreshStuff.MaxItemAge.."):]"}, { "CT1" },FreshStuff.Levels.Prune)
ucmd.add({"Releases","sonstiges","Zeige die Top Releaser"},FreshStuff.Commands.TopAdders,{"%[line:Anzahl der TopReleaser (Enter defaults to 5):]"}, { "CT1" },FreshStuff.Levels.TopAdders)
ucmd.add({"Releases","sonstiges","Hilfe"},FreshStuff.Commands.Help,{}, { "CT1" },FreshStuff.Levels.Help)
       for a,b in pairs(FreshStuff.Types) do
ucmd.add({"Releases","eintragen",b},FreshStuff.Commands.Add,{a,"%[line:Name:]"}, { "CT1" },FreshStuff.Levels.Add)
ucmd.add({"Releases","anzeigen",b},FreshStuff.Commands.Show,{a}, { "CT1" },FreshStuff.Levels.Show)


      end
      CreateRightClicks()
 

        end



    end
)

hub.setlistener( "onBroadcast", { },                                     
    function( user, adccmd, txt )
    --[[ --! function ChatArrival(user,data)
      data=string.sub(data,1,string.len(data)-1)
      local _,_,cmd=string.find(data,"%b<>%s+[%!%+%#%?%-](%S+)")
    ]]
      local cmd, parameters = utf.match( txt, "^[+!#](%a+) ?(.*)" ) --!    
      if commandtable[cmd] then
        parsecmds(user,txt,"MAIN",string.lower(cmd))
        --! return 1
        return PROCESSED --!        
      end
    end
)

--[[ --! function ToArrival(user,data)
  data=string.sub(data,1,string.len(data)-1)
  local _,_,whoto,cmd = string.find(data,"$To:%s+(%S+)%s+From:%s+%S+%s+$%b<>%s+[%!%+%#%?%-](%S+)")
  if commandtable[cmd] then
    parsecmds(user,data,"PM",string.lower(cmd),whoto)
    return 1
  end
end
]]

hub.setlistener( "onLogin", { },
    function( user )
    --[[ --! function NewUserConnected(user)
      if  user.bUserCommand then -- if login is successful, and usercommands can be sent
        user:SendData(table.concat(rctosend[user.iProfile],"|"))
      end
    ]]
      if FreshStuff.Count > 0 then
        if FreshStuff.ShowOnEntry ~=0 then
          if FreshStuff.ShowOnEntry==1 then
            SendTxt(user,"PM",Bot.name, FreshStuff.MsgNew)
          else
            SendTxt(user,"MAIN",Bot.name, FreshStuff.MsgNew)
          end
        end
      end
    end
)

--[=[ --! function OnTimer()
  if FreshStuff.WhenAndWhatToShow[os.date("%H:%M")] then
    if FreshStuff.Types[FreshStuff.WhenAndWhatToShow[os.date("%H:%M")]] then
      SendToAll(Bot.name, FreshStuff.ShowRelType(FreshStuff.WhenAndWhatToShow[os.date("%H:%M")]))
    else
      if FreshStuff.WhenAndWhatToShow[os.date("%H:%M")]=="new" then
        SendToAll(Bot.name, FreshStuff.MsgNew)
      elseif FreshStuff.WhenAndWhatToShow[os.date("%H:%M")]=="all" then
        SendToAll(Bot.name, FreshStuff.MsgAll)
    else
        SendToOps(Bot.name,"Irgend so ein Mongo hat was in meine liste gepostet, von dem ich noch nie was gehört habe. :-)")
      end
    end
  end
  FreshStuff.Timer=0
end
]=]

--!
local start = os.time( )
hub.setlistener( "onTimer", { },
    function( )
        if os.difftime( os.time( ) - start ) >= 60 then
              if FreshStuff.WhenAndWhatToShow[os.date("%H:%M")] then
                if FreshStuff.Types[FreshStuff.WhenAndWhatToShow[os.date("%H:%M")]] then
                  --!SendToAll(Bot.name, FreshStuff.ShowRelType(FreshStuff.WhenAndWhatToShow[os.date("%H:%M")]))
                  hub.broadcast(FreshStuff.ShowRelType(FreshStuff.WhenAndWhatToShow[os.date("%H:%M")]),Bot.name)
                else
                  if FreshStuff.WhenAndWhatToShow[os.date("%H:%M")]=="new" then
                    --!SendToAll(Bot.name, FreshStuff.MsgNew)
                    hub.broadcast(FreshStuff.MsgNew, Bot.name)
                  elseif FreshStuff.WhenAndWhatToShow[os.date("%H:%M")]=="all" then
                    --!SendToAll(Bot.name, FreshStuff.MsgAll)
                    hub.broadcast(FreshStuff.MsgAll, Bot.name)
                else
                    --!SendToOps(Bot.name,"Irgend so ein Mongo hat was in meine liste gepostet, von dem ich noch nie was gehört habe. :-)")
                  end
                end
              end
              FreshStuff.Timer=0
            start = os.time( )
        end
        return nil
    end
)

--! OpConnected=NewUserConnected
--! OpDisconnected=UserDisconnected

function parsecmds(user,data,env,cmd,bot)
  --! whoto=whoto or Bot.name
  local whoto=Bot.name --!  
  if commandtable[cmd] then -- if it exists
    if commandtable[cmd]["level"]~=0 then -- and enabled
      --! if userlevels[user.iProfile] >= commandtable[cmd]["level"] then -- and user has enough rights
      if userlevels[user:level( )] >= commandtable[cmd]["level"] then --!  
        commandtable[cmd]["func"](user,data,env,unpack(commandtable[cmd]["parms"])) -- user,data,env and more params afterwards
      else
        SendTxt(user,env,bot,"Du bist nicht berechtigt diesen Befehl zu benutzen.")
      end
    else
      SendTxt(user,env,bot,"Der Befehl ist deaktiviert. Kontaktiere den Hubowner wenn du ihn wieder nutzen willst.")
    end
  end
end

function RegCmd(cmnd,func,parms,level,help) -- regs a command, parsed on ToArrival and ChatArrival
  commandtable[cmnd]={["func"]=func,["parms"]=parms,["level"]=level,["help"]=help}
end

--[[ --! function RegRC(level,context,name,command,PM)
  if level==0 then return 1 end
  if not PM then
    rightclick["$UserCommand "..context.." "..name.."$<%[mynick]> "..command.."&#124;"]=level
--     SendToAll(command)
  else
    rightclick["$UserCommand "..context.." "..name.."$$To: "..Bot.name.." From: %[mynick] $<%[mynick]> "..command.."&#124;"]=level
  end
end
]]

function SendTxt(user,env,bot,text) -- sends message according to environment (main or pm)
  if env=="main" then
    --! user:SendPM(bot,text)
    user:reply( text, bot, bot ) --!    
  else
    --! user:SendData(bot,text)
    user:reply( text, bot ) --!    
  end
end

function help(user,data,env)
  local count=0
  local hlptbl={}
  local hlp="\r\nAusführbare Befehle für dich sind:\r\n=================================================================================================================================\r\n"
  --! for a,b in commandtable do
  for a,b in pairs(commandtable) do --!  
    if b["level"]~=0 then
      --! if userlevels[user.iProfile] >= b["level"] then
      if userlevels[user:level()] >= b["level"] then --!      
        count=count+1
        table.insert(hlptbl,"!"..a.." "..b["help"])
      end
    end
  end
  table.sort(hlptbl)
  hlp=hlp..table.concat(hlptbl,"\r\n").."\r\n\r\nAlle "..count.." Befehle können entweder im Main oder in PM ausgeführt werden, die verfügbaren Prefixe sind:"..
  " ! # + - ?\r\n================================================================================================================================="..Bot.version
  --! user:SendPM(Bot.name,hlp)
  user:reply( hlp, Bot.name, Bot.name ) --!  
end

function FreshStuff.ShowCrap(user,data,env)
  if FreshStuff.Count < 1 then SendTxt(user,env,Bot.name,"Keine Releases im Moment, versuche es später noch einmal.") return end
  --! local _,_,cat= string.find(data, "%b<>%s+%S+%s+(%S+)")
  local _,_,cat= string.find(data, "%S+%s+(%S+)") --!  
  --! local _,_,latest=string.find(data, "%b<>%s+%S+%s+%S+%s+(%d+)")
  local _,_,latest=string.find(data, "%S+%s+(%d+)") --! 
  if not cat then
    --! user:SendPM(Bot.name, FreshStuff.MsgAll)
    user:reply( FreshStuff.MsgAll, Bot.name, Bot.name ) --!  
  else
    if cat == "new" then
      --! user:SendPM(Bot.name, FreshStuff.MsgNew)
      user:reply( FreshStuff.MsgNew, Bot.name, Bot.name ) --!        
    elseif FreshStuff.Types[cat] then
      if latest then
        --! user:SendPM(Bot.name,FreshStuff.ShowRelNum(cat,latest))
        user:reply( FreshStuff.ShowRelNum(cat,latest), Bot.name, Bot.name ) --!           
      else
        --! user:SendPM(Bot.name, FreshStuff.ShowRelType(cat))
        user:reply( FreshStuff.ShowRelType(cat), Bot.name, Bot.name ) --!        
      end
    else
      SendTxt(user,env,Bot.name,"No such type.")
    end
  end
end

function FreshStuff.AddCrap (user,data,env)
  --! local _,_,cat,tune= string.find(data, "%b<>%s+%S+%s+(%S+)%s+(.+)")
  local _,_,cat,tune= string.find(data, "%S+%s+(%S+)%s+(.+)") --! 
  if cat then
    if FreshStuff.Types[cat] then
      if string.find(tune,"$",1,true) then SendTxt(user,env,Bot.name, "Der Release Name darf keine Dollar Zeichen beinhalten ($)!") return end
      if FreshStuff.Count > 0 then
        for i=1, FreshStuff.Count do
          local ct,who,when,title=unpack(FreshStuff.AllStuff[i])
          if title==tune then SendTxt(user,env,Bot.name, "Das Release wurde schon hinzugefügt in der Kategorie "..FreshStuff.Types[ct]..".") return end
        end
      end
      SendTxt(user,env,Bot.name, tune.." wurde zu den Releases hinzugefügt als "..cat)
      --! SendToAll(Bot.name, user.sName.." fügte zu der Kategorie "..cat.." hinzu: "..tune)
      hub.broadcast( user:nick( ).." fügte zu der Kategorie "..cat.." hinzu: "..tune, Bot.name ) --!
      FreshStuff.Count = FreshStuff.Count + 1
      FreshStuff.AllStuff[FreshStuff.Count]={cat,user:nick(),os.date("%m/%d/%Y"),tune}
      FreshStuff.SaveRel()
      FreshStuff.ReloadRel()
    else 
      SendTxt(user,env,Bot.name, "Unbekannte Kategorie: "..cat)
    end
  else
    SendTxt(user,env,Bot.name, "Woher soll ich wissen was ich hinzufügen soll, wenn du mir das nicht erzählst!!")
  end
end

function FreshStuff.OpenRel()
  FreshStuff.AllStuff,FreshStuff.NewestStuff = nil,nil
  collectgarbage(); io.flush()
  FreshStuff.AllStuff,FreshStuff.NewestStuff = {},{}
  FreshStuff.Count,FreshStuff.Count2 = 0,0
  --! local f=io.open("freshstuff/releases.dat","r")
  local f=io.open(fs_path.."releases.dat","r") --!  
  if f then
    for line in f:lines() do
      local _,_,cat,who,when,title=string.find(line, "(.+)$(.+)$(.+)$(.+)")
      if cat then
    if not FreshStuff.TopAdders[who] then FreshStuff.TopAdders[who]=1 else FreshStuff.TopAdders[who]=FreshStuff.TopAdders[who]+1 end
    if string.find(when,"%d+/%d+/0%d") then -- compatibility with old file format
      local _,_,m,d,y=string.find(when,"(%d+)/(%d+)/(0%d)")
      when=m.."/"..d.."/".."20"..y
    end
        FreshStuff.Count = FreshStuff.Count +1
    FreshStuff.AllStuff[FreshStuff.Count]={cat,who,when,title}
      else
    --! SendToOps(Bot.name, "Releases file is corrupt, failed to load all items.")
    error("Releases file is corrupt, failed to load all items.") --!
      end
    end
    f:close()
  end
  if FreshStuff.Count > FreshStuff.MaxNew then
    local tmp = FreshStuff.Count - FreshStuff.MaxNew + 1
    FreshStuff.Count2=FreshStuff.Count - FreshStuff.MaxNew + 1
    for i = tmp, FreshStuff.Count do
      FreshStuff.Count2=FreshStuff.Count2 + 1
      if FreshStuff.AllStuff[FreshStuff.Count2] then
    FreshStuff.NewestStuff[FreshStuff.Count2]=FreshStuff.AllStuff[FreshStuff.Count2]
      end
    end
  else
    for i=1, FreshStuff.Count do
      FreshStuff.Count2 = FreshStuff.Count2 + 1
      if FreshStuff.AllStuff[i] then
    FreshStuff.NewestStuff[FreshStuff.Count2]=FreshStuff.AllStuff[i]
      end
    end
  end
end

function FreshStuff.ShowRel(tab)
  local Msg = "\r\n"
  local cat,who,when,title
  local tmptbl={}
  local cunt=0
  if tab == FreshStuff.NewestStuff then
    if FreshStuff.Count2 == 0 then
      FreshStuff.MsgNew = "\r\n\r\n".." --------- Die aktuellsten Releases -------- \r\n\r\n  Keine Releases in der Datenbank\r\n\r\n --------- Die aktuellsten Releases -------- \r\n\r\n"
    else
      for i=1, FreshStuff.Count2 do
    if FreshStuff.NewestStuff[i] then
      cat,who,when,title=unpack(FreshStuff.NewestStuff[i])
      if title then
        if FreshStuff.Types[cat] then cat=FreshStuff.Types[cat] end
        if not tmptbl[cat] then tmptbl[cat]={} end
        table.insert(tmptbl[cat],Msg.."Nr: "..i.."\t ->    "..title.." ")
            cunt=cunt+1
      end
    end
      end
    end
    for a,b in pairs (tmptbl) do  
      Msg=Msg.."\r\n"..a.."\r\n"..string.rep("¯",10)..""..table.concat(b).."\r\n"
    end

    local new=FreshStuff.MaxNew if cunt < FreshStuff.MaxNew then new=cunt end
    FreshStuff.MsgNew = "\r\n".."++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\r\n                                                           DIE  15  NEUESTEN RELEASES\r\n                                                         ++++++++++++++++++++++++++++"..Msg.."\++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\r\n"

  else
    if FreshStuff.Count == 0 then
      FreshStuff.MsgAll = "\r\n\r\r\n".." --------- Alle Releases -------- \r\n\r\n  Keine Releases in der Datenbank\r\n\r\n --------- Alle Releases -------- \r\n\r\n"
    else
      FreshStuff.MsgHelp  = "  use "..FreshStuff.Commands.Show.." <new>"
      --! for a,b in FreshStuff.Types do
      for a,b in pairs(FreshStuff.Types) do --!      
    FreshStuff.MsgHelp  = FreshStuff.MsgHelp .."/"..a
      end
      FreshStuff.MsgHelp  = FreshStuff.MsgHelp .."> um nur die ausgewählten Kategorien zu sehen"
      for i=1, FreshStuff.Count do
    if FreshStuff.AllStuff[i] then
      cat,who,when,title=unpack(FreshStuff.AllStuff[i])
      if title then
        if FreshStuff.Types[cat] then cat=FreshStuff.Types[cat] end
        if not tmptbl[cat] then tmptbl[cat]={} end
        table.insert(tmptbl[cat],Msg.."Nr: "..i.."\t"..title.." ")
      end
    end
      end
      for a,b in pairs (tmptbl) do
    Msg=Msg.."\r\n"..a.."\r\n"..string.rep("-",33).."\r\n"..table.concat(b).."\r\n"
      end      
      FreshStuff.MsgAll = "\r\n\r\r\n".." --------- Alle Releases -------- "..Msg.."\r\n --------- Alle Releases -------- \r\n"..FreshStuff.MsgHelp .."\r\n"
    end
  end
end

function FreshStuff.ShowRelType(what)
  local cat,who,when,title
  local Msg,MsgType,tmp = "\r\n",nil,0
  if FreshStuff.Count == 0 then
    MsgType = "\r\n\r\n".." --------- Alles von: "..FreshStuff.Types[what].." -------- \r\n\r\n  Kein "..string.lower(FreshStuff.Types[what]).." im Moment\r\n\r\n --------- Alles von: "..FreshStuff.Types[what].." -------- \r\n\r\n"
  else
    for i=1, FreshStuff.Count do
      cat,who,when,title=unpack(FreshStuff.AllStuff[i])
      if cat == what then
    tmp = tmp + 1
    Msg = Msg.."Nr: "..i.."\t ->    "..title.."  ->  gepostet von  "..who.."  am  ["..when.."]\r\n"
      end
    end
    if tmp == 0 then
      MsgType = "\r\n\r\n".." --------- Alles von: "..FreshStuff.Types[what].." -------- \r\n\r\n  Kein "..string.lower(FreshStuff.Types[what]).." im Moment\r\n\r\n --------- Alles von: "..FreshStuff.Types[what].." -------- \r\n\r\n"
    else
      MsgType= "\r\n\r\n".." --------- Alles von: "..FreshStuff.Types[what].." -------- \r\n"..Msg.."\r\n --------- Alles von: "..FreshStuff.Types[what].." -------- \r\n\r\n"
    end
  end
  return MsgType
end

function FreshStuff.ShowRelNum(what,num) -- to show numbers of categories
  num=tonumber(num)
  local Msg="\r\n"
  local cunt=0
  local target=FreshStuff.Count-num
  local cat,who,when,title
  if num > FreshStuff.Count then target=1 end
  for i=FreshStuff.Count,target,-1 do
    if FreshStuff.AllStuff[i] then
      cat,who,when,title=unpack(FreshStuff.AllStuff[i])
      Msg = Msg.."Nr: "..i.."\t"..title.." // (Added by "..who.." at "..when..")\r\n"
      cunt=cunt+1
    else
      break
    end
  end
  if cunt < num then num=cunt end
  local MsgType = "\r\n\r\n".." --------- Die aktuellsten "..num.." "..FreshStuff.Types[what].." -------- \r\n\r\n"..Msg.."\r\n\r\n --------- Die aktuellsten "..num.." "..FreshStuff.Types[what].." -------- \r\n\r\n"
  return MsgType
end
  
function FreshStuff.DelCrap(user, data,env)
  --! local _,_,what=string.find(data,"%b<>%s+%S+%s+(.+)")
  local _,_,what=string.find(data,"%S+%s+(.+)") --!  
  if what then
    local cnt,x=0,os.clock()
    local tmp={}
    --! for w in string.gfind(what,"(%d+)") do
    for w in string.gmatch(what,"(%d+)") do --!    
      table.insert(tmp,tonumber(w))
    end
    table.sort(tmp)
    for k=table.getn(tmp),1,-1 do
      local n=tmp[k]
      if FreshStuff.AllStuff[n] then
    SendTxt(user,env,Bot.name, FreshStuff.AllStuff[n][4].." wurde gelöscht.")
    FreshStuff.AllStuff[n]=nil
    cnt=cnt+1
      else
    SendTxt(user,env,Bot.name, "Release mit der Nummer "..wht.." wurde in der Datenbank nicht gefunden.")
      end
    end
    if cnt>0 then
      FreshStuff.SaveRel()
      FreshStuff.ReloadRel()
      SendTxt(user,env,Bot.name, "Das Löschen von "..cnt.." Release(s) dauerte "..os.clock()-x.." Sekunden.")
    end
  else
    SendTxt(user,env,Bot.name, "Woher soll ich wissen was ich löschen soll, wenn du mir das nicht erzählst!.")
  end
end

function FreshStuff.SaveRel()
  --! local f= io.open("freshstuff/releases.dat","w+")
  local f= io.open(fs_path.."releases.dat","w+") --"  
  for i=1,FreshStuff.Count do
    if FreshStuff.AllStuff[i] then
      f:write(table.concat(FreshStuff.AllStuff[i],"$").."\n")
    end
  end
  f:flush()
  f:close()
end

function FreshStuff.ReloadRel(user,data,env)
  local x=os.clock()
  FreshStuff.OpenRel()
  FreshStuff.ShowRel(FreshStuff.NewestStuff)
  FreshStuff.ShowRel(FreshStuff.AllStuff)
  if user then SendTxt(user,env,Bot.name,"Releases reloaded, dauerte "..os.clock()-x.." Sekunden.") end
end

function FreshStuff.SearchRel(user,data,env)
  --! local _,_,what=string.find(data,"%b<>%s+%S+%s+(.+)")
  local _,_,what=string.find(data,"%S+%s+(.+)") --!  
  if what then
    local res,rest=0,{}
    local msg="\r\n---------- Du suchtest nach \""..what.."\". Das Resultat: ----------\r\n\r\n"
    --! for a,b in FreshStuff.AllStuff do
    for a,b in pairs(FreshStuff.AllStuff) do --!    
      if string.find(string.lower(b[4]),string.lower(what),1,true) then
    table.insert(rest,{b[1],b[2],b[3],b[4]})
      end
    end
    if table.getn(rest)~=0 then
      for i=1,table.getn(rest) do
    local type,who,when,title=unpack(rest[i])
    res= res + 1
    msg = msg.."ID: "..i.."\t"..title.." \r\n"
      end
      msg=msg..string.rep("-",20).."\r\n"..res.." Resultate."
    else
      msg=msg.."\r\nSearch string "..what.." wurde in der Datenbank nicht gefunden."
    end
    --! user:SendPM(Bot.name,msg)
    user:reply( msg, Bot.name, Bot.name ) --!        
  else
    SendTxt(user,env,Bot.name, "Woher soll ich wissen was ich suchen soll, wenn du mir das nicht erzählst!|")
  end
end






function FreshStuff.AddCatgry(user,data,env)
  --! local _,_,what1,what2=string.find(data,"%b<>%s+%S+%s+(%S+)%s+(.+)")
  local _,_,what1,what2=string.find(data,"%S+%s+(%S+)%s+(.+)") --!  
  if what1 then
    if string.find(what1,"$",1,true) then SendTxt(user,env,Bot.name, "Das Dollar Zeichen ist nicht erlaubt.") return 1 end
    if not FreshStuff.Types[what1] then
      FreshStuff.Types[what1]=what2
      FreshStuff.SaveCt()
      SendTxt(user,env,Bot.name,"Die Kategorie "..what1.." wurde erfolgreich hinzugefügt.")
    else
      if FreshStuff.Types[what1]==what2 then
    SendTxt(user,env,Bot.name,"Die Kategorie "..what1.." existiert bereits.")
      else
    FreshStuff.Types[what1]=what2
    FreshStuff.SaveCt()
    SendTxt(user,env,Bot.name,"Die Kategorie "..what1.." wurde erfolgreich geändert.")
      end
    end
  else
    SendTxt(user,env,Bot.name,"Category should be added properly: +"..FreshStuff.Commands.AddCatgry.." <category_name> <displayed_name>")
  end
end






function FreshStuff.DelCatgry(user,data,env)
  --! local _,_,what=string.find(data,"%b<>%s+%S+%s+(%S+)")
  local _,_,what=string.find(data,"%S+%s+(%S+)") --!  
  if what then
    if not FreshStuff.Types[what] then
      SendTxt(user,env,Bot.name,"Die Kategorie "..what.." existiert nicht.")
    else
      FreshStuff.Types[what]=nil
      FreshStuff.SaveCt()
      SendTxt(user,env,Bot.name,"Die Kategorie "..what.." wurde erfolgreich gelöscht.")
    end
  else
    SendTxt(user,env,Bot.name,"Category should be deleted properly: +"..FreshStuff.Commands.DelCatgry.." <category_name>")
  end
end






function FreshStuff.ShowCatgries(user,data,env)
  local msg="\r\n======================\r\nVerfügbare Kategorien:\r\n======================\r\n"
  --! for a,b in FreshStuff.Types do
  for a,b in pairs(FreshStuff.Types) do --!
    msg=msg.."\r\n"..a
  end
  --! user:SendPM(Bot.name,msg)
  user:reply( msg, Bot.name, Bot.name )    --!
end

function FreshStuff.SaveCt()
  --! local f=io.open("freshstuff/categories.dat","w+")
  local f=io.open(fs_path.."categories.dat","w+") --!  
  --! f:write("FreshStuff.Types={\n")
  f:write("return {\n") --!  
  --! for a,b in FreshStuff.Types do
  for a,b in pairs(FreshStuff.Types) do --!
    f:write("[\""..a.."\"]=\""..b.."\",\n")
  end
  f:write("}")
  f:close()
end






function FreshStuff.PruneRel(user,data,env)
  --! local _,_,days=string.find(data,"%b<>%s+%S+%s+(%d+)")
  local _,_,days=string.find(data,"%S+%s+(%d+)") --!  
  days=days or FreshStuff.MaxItemAge
  local cnt=0
  local x=os.clock()
  --! SendToAll(Bot.name,"Release-löscher Prozess gestarted, alle Releases älter als "..days.." Tage werden von der Datenbank gelöscht.")
  hub.broadcast( "Release-löscher Prozess gestarted, alle Releases älter als "..days.." Tage werden von der Datenbank gelöscht.", Bot.name ) --!  
  local now=JulianDate(SplitTimeString(os.date("%m/%d/%Y".." 00:00:00")))
  local oldest=days*1440
  for i=FreshStuff.Count,1,-1 do
    local old=JulianDate(SplitTimeString(FreshStuff.AllStuff[i][3].." 00:00:00"))
    local diff=now-old
    local hours, mins= math.floor(diff) * 24 + math.floor(frac(diff) * 24), math.floor(frac(frac(diff)*24)*60)
    local tempus=hours*60+mins
    if tempus > oldest then
      FreshStuff.AllStuff[i]=nil
      cnt=cnt+1
    end
  end
  --! SendToAll(Bot.name,FreshStuff.Count.." Releases durchsucht und "..cnt.." entfernt.")
  hub.broadcast( FreshStuff.Count.." Releases durchsucht und "..cnt.." entfernt.", Bot.name ) --! 
  if cnt ~=0 then
    FreshStuff.SaveRel()
    FreshStuff.ReloadRel()
  end
end

function FreshStuff.ShowTopAdders(user,data,env)
  local tmp,numtbl,msg={},{},"\r\nDie Top "..FreshStuff.TopAddersCount.." Releasers sind:\r\n"..string.rep("-",33).."\r\n"
  --! for a,b in FreshStuff.TopAdders do
  for a,b in pairs(FreshStuff.TopAdders) do --!  
    table.insert(numtbl,b)
    tmp[b] = tmp[b] or {}
    table.insert(tmp[b],a)
  end
  table.sort(numtbl)
  local e
  if table.getn(numtbl) <= FreshStuff.TopAddersCount then e=1 else e=table.getn(numtbl)-FreshStuff.TopAddersCount end
  for k=table.getn(numtbl),e,-1 do
    --! for n,c in tmp[numtbl[k]] do
    for n,c in pairs(tmp[numtbl[k]]) do --!    
      msg=msg..c..": "..numtbl[k].."\r\n"
    end
  end
  --! user:SendPM(Bot.name,msg)
  user:reply( msg, Bot.name, Bot.name )      
end

function SplitTimeString(TimeString) 
-- Splits a time format to components, originally written by RabidWombat.
-- Supports 2 time formats: MM/DD/YYYY HH:MM and YYYY. MM. DD. HH:MM
  local D,M,Y,HR,MN,SC
  if string.find(TimeString,"/") then
    _,_,M,D,Y,HR,MN,SC=string.find(TimeString,"(%d+)/(%d+)/(%d+)%s+(%d+):(%d+):(%d+)")
  else
    _,_,Y,M,D,HR,MN,SC = string.find(TimeString, "([^.]+).([^.]+).([^.]+). ([^:]+).([^:]+).(%S+)")
  end
  D = tonumber(D)
  M = tonumber(M)
  Y = tonumber(Y)
  HR = tonumber(HR)
  assert(HR < 24)
  MN = tonumber(MN)
  assert(MN < 60)
  SC = tonumber(SC)
  assert(SC < 60)
  return D,M,Y,HR,MN,SC
end

function JulianDate(DAY, MONTH, YEAR, HOUR, MINUTE, SECOND) -- Written by RabidWombat.
-- HOUR is 24hr format.
  local jy, ja, jm;
  assert(YEAR ~= 0);
  assert(YEAR ~= 1582 or MONTH ~= 10 or DAY < 4 or DAY > 15);
  --The dates 5 through 14 October, 1582, do not exist in the Gregorian system!
  if(YEAR < 0 ) then
    YEAR = YEAR + 1;
  end
  if( MONTH > 2) then 
    jy = YEAR;
    jm = MONTH + 1;
  else
    jy = YEAR - 1;
    jm = MONTH + 13;
  end
  local intgr = math.floor( math.floor(365.25*jy) + math.floor(30.6001*jm) + DAY + 1720995 );
  --check for switch to Gregorian calendar
  local gregcal = 15 + 31*( 10 + 12*1582 );
  if(DAY + 31*(MONTH + 12*YEAR) >= gregcal ) then
    ja = math.floor(0.01*jy);
    intgr = intgr + 2 - ja + math.floor(0.25*ja);
  end
  --correct for half-day offset
  local dayfrac = HOUR / 24 - 0.5;
  if( dayfrac < 0.0 ) then
    dayfrac = dayfrac + 1.0;
    intgr = intgr - 1;
  end
  --now set the fraction of a day
  local frac = dayfrac + (MINUTE + SECOND/60.0)/60.0/24.0;
  --round to nearest second
  local jd0 = (intgr + frac)*100000;
  local  jd  = math.floor(jd0);
  if( jd0 - jd > 0.5 ) then jd = jd + 1 end
  return jd/100000;
end

function frac(num) -- returns fraction of a number (RabidWombat)
  return num - math.floor(num);
end

function CreateRightClicks()
  --! for idx,_ in userlevels do -- usual profiles
  for idx,_ in pairs(userlevels) do --!  
    rctosend[idx]=rctosend[idx] or {} -- create if not exist (but this is not SQL :-P)
    for a,b in pairs(rightclick) do -- run thru the rightclick table
      if userlevels[idx] >= b then -- if user is allowed to use
        table.insert(rctosend[idx],a) -- then put to the array
      end
    end
    for _,arr in pairs(rctosend) do -- and we alphabetize (sometimes eyecandy is also necessary)
      table.sort(arr) -- sort the array
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
--[[ --! RegRC(FreshStuff.Levels.ShowCtgrs,"1 1","Releases\\sonstiges\\Zeige Kategorien","!"..FreshStuff.Commands.ShowCtgrs)
RegRC(FreshStuff.Levels.Delete,"1 1","Releases\\sonstiges\\Lösche ein Release","!"..FreshStuff.Commands.Delete.." %[line:ID Nummer(n):]")
RegRC(FreshStuff.Levels.ReLoad,"1 1","Releases\\sonstiges\\Releasedatenbank neu laden","!"..FreshStuff.Commands.ReLoad)
RegRC(FreshStuff.Levels.Search,"1 1","Releases\\sonstiges\\Suche Release","!"..FreshStuff.Commands.Search.." %[line:Was?]")
RegRC(FreshStuff.Levels.AddCatgry,"1 1","Releases\\sonstiges\\Erstelle eine Kategorie","!"..FreshStuff.Commands.AddCatgry.." %[line:Kategorie Name:] %[line:Angezeigter Name:]")
RegRC(FreshStuff.Levels.DelCatgry,"1 1","Releases\\sonstiges\\Lösche eine Kategorie","!"..FreshStuff.Commands.DelCatgry.." %[line:Kategorie Name:]")
RegRC(FreshStuff.Levels.Prune,"1 1","Releases\\sonstiges\\Lösche alte Releases","!"..FreshStuff.Commands.Prune.." %[line:Max. Alter in Tagen (Enter=defaults to "..FreshStuff.MaxItemAge.."):]")
RegRC(FreshStuff.Levels.TopAdders,"1 1","Releases\\sonstiges\\Zeige die Top Releaser","!"..FreshStuff.Commands.TopAdders.." %[line:Anzahl der TopReleaser (Enter defaults to 5):]")
]]
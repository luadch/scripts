--[[

	etc_hubportier_0.1 by pulsar

		Version: Luadch 0.08
			- Das Script sendet eine Willkommens-/Abschiedsnachricht an die User

]]--



--[SETTINGS]

local scriptname = "etc_hubportier"

local PortierLogin = {	--> Nachricht die beim Login an alle User geschickt wird

		[ 0 ] = "ist wieder da...",  --> UNREG
		[ 10 ] = "ist wieder da...",  --> GUEST
		[ 20 ] = "ist wieder da...",  --> REG
		[ 30 ] = "ist wieder da...",  --> VIP
		[ 40 ] = "ist wieder da...",  --> SVIP
		[ 60 ] = "ist wieder da...",  --> OPERATOR
		[ 80 ] = "ist wieder da...",  --> ADMIN
		[ 100 ] = "ist wieder da...",  --> HUBOWNER
}

local PortierLogout = {	--> Nachricht die beim Logout an alle User geschickt wird

		[ 0 ] = "verkrümelt sich jetzt...",  --> UNREG
		[ 10 ] = "verkrümelt sich jetzt...",  --> GUEST
		[ 20 ] = "verkrümelt sich jetzt...",  --> REG
		[ 30 ] = "verkrümelt sich jetzt...",  --> VIP
		[ 40 ] = "verkrümelt sich jetzt...",  --> SVIP
		[ 60 ] = "verkrümelt sich jetzt...",  --> OPERATOR
		[ 80 ] = "verkrümelt sich jetzt...",  --> ADMIN
		[ 100 ] = "verkrümelt sich jetzt...",  --> HUBOWNER
}

local PortierUserLogin = {	--> Nachricht die beim Login an den User selbst geschickt wird

		[ 0 ] = "schön das du wieder hier bist...",  --> UNREG
		[ 10 ] = "schön das du wieder hier bist...",  --> GAST
		[ 20 ] = "schön das du wieder hier bist...",  --> REG
		[ 30 ] = "schön das du wieder hier bist...",  --> VIP
		[ 40 ] = "schön das du wieder hier bist...",  --> SVIP
		[ 60 ] = "schön das du wieder hier bist...",  --> OPERATOR
		[ 80 ] = "schön das du wieder hier bist...",  --> ADMIN
		[ 100 ] = "schön das du wieder hier bist...",  --> HUBOWNER
}


--[CODE]

local seperator = "  "
hub.setlistener("onLogin", {},
    function(user)
        hub.debug("1")
        local nick = user:nick()
        local level = user:level()
        local levelname = cfg.get("levels")[user:level()] or "Unreg"
        local txt = PortierLogin[level]
        local txt2 = PortierUserLogin[level]
        hub.broadcast(levelname..seperator..nick..seperator..txt, hub.getbot())
        user:reply(levelname..seperator..nick..seperator..txt2, hub.getbot())
    end
)

hub.setlistener("onLogout", {},
    function(user)
        local nick = user:nick()
        local level = user:level()
        local levelname = cfg.get("levels")[user:level()] or "Unreg"
        local txt3 = PortierLogout[level]
        hub.broadcast(levelname..seperator..nick..seperator..txt3, hub.getbot())
    end
)

hub.debug("** Loaded "..scriptname..".lua **")

--[END]
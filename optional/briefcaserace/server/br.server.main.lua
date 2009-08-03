root = getRootElement()
runningMap = false
teams = {} -- used for team game, the participating teams
settings =	{	limit = 1000, weather = 0, teams = false, hide = true, reset = 300, gamespeed = 1, ff = true, autobalance = true, teamskins = {},
				weapons = {[1] = 1, [22] = 200, [17] = 4, [29] = 250},
				cam = {x = 1468.88, y = -919.25, z = 100.15, lx = 1468.39, ly = -918.42, lz = 99.88, roll = 0, fov = 70}
			}
local readyPlayers = {}

addEvent("onPlayerReady", true)
addEvent("onPlayerBriefcaseHit", true)
addEvent("onPlayerObjectiveHit", true)

addEventHandler("onResourceStart", getResourceRootElement(getThisResource()),
function (resource)

	local resourceRoot = getResourceRootElement(resource)
	
	addEventHandler( "onGamemodeMapStart", root,		onGamemodeMapStart_brmain)

	addEventHandler( "onResourceStart", root,			onResourceStart_brmain)
	addEventHandler( "onResourceStop", resourceRoot,	onResourceStop_brmain)
end
)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- GAME SETUP --
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- assumes the previous gamemode must be stopped before the next one is started

function onGamemodeMapStart_brmain(resource)
--outputServerLog(tostring(resource))
	if (runningMap) then
		outputConsole("Briefcase Race: The old game mode must be stopped before a new one is started. Stop the old one and then start a new one.")
		outputServerLog("Briefcase Race: The old game mode must be stopped before a new one is started. Stop the old one and then start a new one.")
--		outputConsole(getResourceName(runningMap) .. " map changed to " .. getResourceName(resource) .. " map. Ignoring settings. To use new settings, restart the game mode.")
--		removeEventHandler("onResourceStop", runningMap, onGamemodeMapStop_brmain)
--		runningMap = resource
--		addEventHandler("onResourceStop", resource, onGamemodeMapStop_brmain)
	else
		outputConsole("Briefcase Race: " .. getResourceName(resource) .. " map started. Starting game.")
		outputServerLog("Briefcase Race: " .. getResourceName(resource) .. " map started. Starting game.")
		-- get settings
		readSettingsFile(resource)
		-- get the teams that currently exist
		if (settings.teams) then
			teams = getElementsByType("team")
			if (#teams < 2) then
				outputConsole("Briefcase Race: Error: Teams enabled in settings but not enough teams exist! Fix this map or try a different one.")
				outputServerLog("Briefcase Race: Error: Teams enabled in settings but not enough teams exist! Fix this map or try a different one.")
				return
			else
				-- set friendly fire
				for i,v in ipairs(teams) do
					setTeamFriendlyFire(v, settings.ff)
				end
			end
		end
		-- set weather
		--setWeather(settings.weather)
		setTimer(setWeather, 1000, 1, settings.weather)
		-- set game speed
		setGameSpeed(settings.gamespeed)
		runningMap = resource
		addEventHandler("onResourceStop", getResourceRootElement(resource), onGamemodeMapStop_brmain)
		-- start the game
		startGame()
	end
end

function onGamemodeMapStop_brmain(resource)
	outputConsole("Briefcase Race: " .. getResourceName(resource) .. " map stopped. Stopping game.")
	outputServerLog("Briefcase Race: " .. getResourceName(resource) .. " map stopped. Stopping game.")
	removeEventHandler("onResourceStop", getResourceRootElement(resource), onGamemodeMapStop_brmain)
	runningMap = false
	teams = {}
	settings =	{	limit = 1000, teams = true, hide = true, reset = 300, gamespeed = 1, ff = true, teamskins = {},
					weapons = {[1] = 1, [22] = 200, [17] = 4, [29] = 250},
					cam = {x = 1468.88, y = -919.25, z = 100.15, lx = 1468.39, ly = -918.42, lz = 99.88, roll = 0, fov = 70}
				}
	-- end the game
	endGame()
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SCOREBOARD MANAGEMENT --
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- adds 'points' column to scoreboard
function onResourceStart_brmain ( resource )
	if ( resource == getThisResource () ) then
		-- add points column to scoreboard if it's already loaded
		local scoreboardResource = getResourceFromName ( "scoreboard" )
		if ( scoreboardResource and getResourceState ( scoreboardResource ) == "running" ) then
		    setTimer ( call, 5000, 1, scoreboardResource, "addScoreboardColumn", "points" )
		    outputDebugString ( "Scoreboard already started: Adding points column in 5 seconds..." )
		end
	elseif ( resource == getResourceFromName ( "scoreboard" ) ) then
		-- add points column to scoreboard if it just already loaded
	    setTimer ( call, 5000, 1, scoreboardResource, "addScoreboardColumn", "points" )
		outputDebugString ( "Scoreboard just started: Adding points column in 5 seconds..." )
	end
end

-- removes 'points' column from scoreboard
function onResourceStop_brmain ( resource )
	local scoreboardResource = getResourceFromName ( "scoreboard" )
	call ( scoreboardResource, "removeScoreboardColumn", "points" )
end


-- show/hide scoreboard for all players
function forceScoreboardForAllPlayers ( status )
	local scoreboardResource = getResourceFromName ( "scoreboard" )
	if ( scoreboardResource and getResourceState ( scoreboardResource ) == "running" ) then
		for i,v in ipairs ( getElementsByType ( "player" ) ) do
	    	call ( scoreboardResource, "setPlayerScoreboardForced", v, status )
		end
		return true
	else
	    return false
	end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TEAM/PLAYER FUNCTIONS --
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function getValidTeams()
	return teams
end

function isPlayerOnValidTeam(player)
	local team = getPlayerTeam(player)
	if (team) then
		for i,v in ipairs(teams) do
			if (v == team) then
				return true
			end
		end
		return false
	else
		return false
	end
end

function isTeamValid(team)
	for i,v in ipairs(teams) do
		if (v == team) then
			return true
		end
	end
	return false
end

function addReadyPlayer(player)
	table.insert(readyPlayers, player)
end

function isPlayerReady(player)
	local ready = false
	for i,v in ipairs(readyPlayers) do
		if (v == player) then
			ready = true
			break
		end
	end
	return ready
end

function removeReadyPlayer(player)
	local index = false
	for i,v in ipairs(readyPlayers) do
		if (v == player) then
			index = i
			break
		end
	end
	if (index) then
		table.remove(readyPlayers, index)
	end
end

function getReadyPlayers()
	return readyPlayers
--[[	-- generate array of ready players
	if (not settings.teams) then
		return getElementsByType("player")
	else
		local playerTable = {}
		for i,team in ipairs(getElementsByType("team")) do
			if (isTeamValid(team)) then
				for j,player in ipairs(getPlayersInTeam(team)) do
					table.insert(playerTable, player)
				end
			end
		end
		return playerTable
	end]]
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- XML FUNCTIONS --
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function readSettingsFile(resource)
	local settingsRoot = xmlLoadFile(":" .. getResourceName(resource) .. "/settings.xml")
	--local settingsRoot = xmlLoadFile("settings.xml", resource)
	--local settingsRoot = getResourceConfig(resource, "settings.xml")
	if (not settingsRoot) then
		outputDebugString("Could not read settings.xml file from gamemode.. using default settings.")
	else
		-- get point limit
		local node, val
		node = xmlFindChild(settingsRoot, "pointlimit", 0)
		if (node) then
			val = xmlNodeGetValue(node)
			if (val and tonumber(val)) then
				settings.limit = tonumber(val)
				outputDebugString("pointlimit read from settings.xml " .. val)
			end
		end
		-- get weather
		node = xmlFindChild(settingsRoot, "weather", 0)
		if (node) then
			val = xmlNodeGetValue(node)
			if (val and tonumber(val)) then
				settings.weather = tonumber(val)
				outputDebugString("weather read from settings.xml " .. val)
			end
		end
		-- get team game
		node = xmlFindChild(settingsRoot, "teamgame", 0)
		if (node) then
			val = xmlNodeGetValue(node)
			if (val and tonumber(val)) then
				if (val == "0") then
					settings.teams = false
					outputDebugString("teamgame read from settings.xml " .. val)
				elseif (val == "1") then
					settings.teams = true
					outputDebugString("teamgame read from settings.xml " .. val)
				end
			end
		end
		-- get hide objective
		node = xmlFindChild(settingsRoot, "hideobj", 0)
		if (node) then
			val = xmlNodeGetValue(node)
			if (val and tonumber(val)) then
				if (val == "0") then
					settings.hide = false
					outputDebugString("hideobj read from settings.xml " .. val)
				elseif (val == "1") then
					settings.hide = true
					outputDebugString("hideobj read from settings.xml " .. val)
				end
			end
		end
		-- get idle time
		node = xmlFindChild(settingsRoot, "idletime", 0)
		if (node) then
			val = xmlNodeGetValue(node)
			if (val and tonumber(val)) then
				settings.reset = tonumber(val)
				outputDebugString("idletime read from settings.xml: " .. val)
			end
		end
		-- get game speed
		node = xmlFindChild(settingsRoot, "gamespeed", 0)
		if (node) then
			val = xmlNodeGetValue(node)
			if (val and tonumber(val) and tonumber(val) <= 10 and tonumber(val) > 0) then
				settings.gamespeed = tonumber(val)
				outputDebugString("gamespeed read from settings.xml: " .. val)
			end
		end
		-- get friendly fire
		node = xmlFindChild(settingsRoot, "ff", 0)
		if (node) then
			val = xmlNodeGetValue(node)
			if (val and tonumber(val)) then
				if (val == "0") then
					settings.ff = false
					outputDebugString("ff read from settings.xml " .. val)
				elseif (val == "1") then
					settings.ff = true
					outputDebugString("ff read from settings.xml " .. val)
				end
			end
		end
		-- get autobalance
		node = xmlFindChild(settingsRoot, "autobalance", 0)
		if (node) then
			val = xmlNodeGetValue(node)
			if (val and tonumber(val)) then
				if (val == "0") then
					settings.autobalance = false
					outputDebugString("autobalance read from settings.xml " .. val)
				elseif (val == "1") then
					settings.autobalance = true
					outputDebugString("autobalance read from settings.xml " .. val)
				end
			end
		end
		-- get team skins
		node = xmlFindChild(settingsRoot, "teamskins", 0)
		if (node) then
			settings.teamskins = {}
			local children = xmlNodeGetChildren(node)
			if (children) then
				for i,v in ipairs(children) do
					local teamName = xmlNodeGetAttribute(v, "team")
					if (teamName) then
						settings.teamskins[teamName] = {}
						local skins = xmlNodeGetValue(v)
						local index = 1
						local curSkin = gettok(skins, index, string.byte(','))
						while (curSkin) do
							-- process current skin
							curSkin = tonumber(curSkin)
							if (curSkin) then
								table.insert(settings.teamskins[teamName], curSkin)
							end
							-- get the next skin
							index = index + 1
							curSkin = gettok(skins, index, string.byte(','))
						end
						outputDebugString("skins read from settings.xml from team " .. teamName .. ": " .. skins)
					end
				end
			end
		end
		-- get spawn weapons
		node = xmlFindChild(settingsRoot, "weapons", 0)
		if (node) then
			settings.weapons = {}
			local children = xmlNodeGetChildren(node)
			if (children) then
				for i,v in ipairs(children) do
					local id = xmlNodeGetAttribute(v, "id")
					local ammo = xmlNodeGetAttribute(v, "ammo")
					id = tonumber(id)
					ammo = tonumber(ammo)
					if (id and ammo) then
						settings.weapons[id] = ammo
						outputDebugString("weapon read from settings.xml: " .. id .. ":" .. ammo)
					end
				end
			end
		end
		-- get idle cam position
		node = xmlFindChild(settingsRoot, "idlecam", 0)
		if (node) then
			local x = xmlNodeGetAttribute(node, "x")
			local y = xmlNodeGetAttribute(node, "y")
			local z = xmlNodeGetAttribute(node, "z")
			local lx = xmlNodeGetAttribute(node, "lx")
			local ly = xmlNodeGetAttribute(node, "ly")
			local lz = xmlNodeGetAttribute(node, "lz")
			local roll = xmlNodeGetAttribute(node, "roll")
			local fov = xmlNodeGetAttribute(node, "fov")
			if (x and y and z and lx and ly and lz and roll and fov and
				tonumber(x) and tonumber(y) and tonumber(z) and tonumber(lx) and tonumber(ly) and tonumber(lz) and tonumber(roll) and tonumber(fov)) then
				settings.cam.x = x
				settings.cam.y = y
				settings.cam.z = z
				settings.cam.lx = lx
				settings.cam.ly = ly
				settings.cam.lz = lz
				settings.cam.roll = roll
				settings.cam.fov = fov
			end
		end
		xmlUnloadFile(settingsRoot)
	end
end
local RunConsoleCommand = RunConsoleCommand;
local tonumber = tonumber;
local tostring = tostring;
local CurTime = CurTime;
local Entity = Entity;
local unpack = unpack;
local table = table;
local pairs = pairs;
local concommand = concommand;
local timer = timer;
local ents = ents;
local hook = hook;
local math = math;
local pcall = pcall;
local ErrorNoHalt = ErrorNoHalt;
local DeriveGamemode = DeriveGamemode;
local util = util
local net = net
local player = player
activeRound = activeRound
rounds = rounds or -1
roundEnd = roundEnd or 0

MAP_LOADED = MAP_LOADED or false

local allowedteams = {
	[TEAM_SPECIAL] = true,
	[TEAM_SCI] = true,
}

local allowedroles = {
	[role.SECURITY_Chief] = true,
	[role.SECURITY_Sergeant] = true,
	[role.MTF_Com] = true,
	[role.MTF_HOF] = true,
	[role.SECURITY_IMVSOLDIER] = true,
	[role.MTF_Left] = true,
	[role.Dispatcher] = true,
	[role.MTF_Specialist] = true,
	[role.MTF_Engi] = true,
}

local blockedroles = {
	[role.SCI_Cleaner] = true
}

function UIUSelectTargets()

	local plys = player.GetAll()

	local numcount = 0

	for i, v in RandomPairs(plys) do

		if (allowedteams[v:GTeam()] and !blockedroles[v:GetRoleName()]) or allowedroles[v:GetRoleName()]  then

			numcount = numcount + 1

			--v:BreachGive("item_special_document")

		end

		if numcount >= 3 then break end

	end

end

function RestartGame()

	for i, v in pairs(player.GetAll()) do
		BREACH.AdminLogSystem:LogPlayer(v)
	end

	timer.Simple(1, function()

		RunConsoleCommand("_restart")

	end)

	--[[
	for _, v in ipairs(GetActivePlayers()) do
		v:RXSENDNotify("Перезагружаем сервер...")
	end

	timer.Simple(0.4, function()
		
		local t_struct = {
			failed = function( err ) MsgC( Color(255,0,0), "HTTP error: " .. err ) end,
			url = "https://admin1911.cloudns.cl/other/api/restart.php?=gameserver23658D99BBpgff",
			method = "POST",
			type = "application/json",
			header = {
				["User-Agent"] = "ShakyPoggers_Restart_SystemQWRBQWKRBKQWORBKQWOOKBR"
			},
			body = "",
			success = function(code, body) end
		}

		reqwest(t_struct)

		for _, ply in pairs(player.GetAll()) do
			ply:Kick("Server shutting down.")
		end

		timer.Simple(1.5, function()
			RunConsoleCommand("_restart")
		end)

	end)]]

end

function CleanUp()
	if BREACH.GRUEscape then BREACH.GRUEscape.Reset() end
	game.CleanUpMap( false, { "env_fire", "phys_bone_follower", "entityflame", "_firesmoke", "light" }, function() end)

	timer.Destroy("PreparingTime")
	timer.Destroy("RoundTime")
	timer.Destroy("PostTime")
	timer.Destroy("GateOpen")
	timer.Destroy("PlayerInfo")
	timer.Destroy("NTFEnterTime")
	timer.Destroy("NTFEnterTime2")
	timer.Destroy("NTFEnterTime3")
	timer.Destroy("PunishEnd")
	timer.Destroy("GateExplode")
	timer.Destroy("SCP173Open")
	timer.Destroy("PerformRandomIntercomAnnouncement")
	timer.Destroy("LZDecont")
	timer.Destroy("LZDecont_Anounce1")
	timer.Destroy("LZDecont_Anounce2")
	timer.Destroy("LZDecont_Music")
	timer.Destroy("AnnounceAboutDetonation")
	timer.Destroy("AnnounceAboutDetonation2")
	timer.Destroy("AnnounceAboutDetonation3")

	SPAWN_SCP_RANDOM_COPY = nil

	if timer.Exists("InfiniteEscapes") == false then
		timer.Create("InfiniteEscapes", 1, 0, InfiniteEscapes)
	end

	local plys = player.GetAll()

	for i = 1, #plys do
		local ply = plys[i]
		ply.SelectedSCPAlready = nil
	end

	BroadcastLua("if CL_BLOOD_POOL_ITERATION == nil then CL_BLOOD_POOL_ITERATION = 1 end CL_BLOOD_POOL_ITERATION = CL_BLOOD_POOL_ITERATION + 1")
	game.GetWorld():StopParticles()
	Recontain106Used = false
	OMEGAEnabled = false
	OMEGADoors = false
	nextgateaopen = 0
	spawnedntfs = 0
	roundstats = {
		descaped = 0,
		rescaped = 0,
		sescaped = 0,
		dcaptured = 0,
		rescorted = 0,
		deaths = 0,
		teleported = 0,
		snapped = 0,
		zombies = 0,
		secretf = false
	}
	inUse = false
end
--concommand.Add("CleanUp_Breach", CleanUp)

function CleanUpPlayers()
	for k,v in pairs(player.GetAll()) do
		v:SetModelScale( 1 )
		v:SetCrouchedWalkSpeed(0.6)
		v.mblur = false
		player_manager.SetPlayerClass( v, "class_breach" )
		player_manager.RunClass( v, "SetupDataTables" )
		v:Freeze(false)
		v.MaxUses = nil
		v.blinkedby173 = false
		v.scp173allow = false
		v.scp1471stacks = 1
		v.usedeyedrops = false
		v.isescaping = false
		v:SendLua( "CamEnable = false" )
	end
	net.Start("Effect")
		net.WriteBool( false )
	net.Broadcast()
	net.Start("957Effect")
		net.WriteBool( false )
	net.Broadcast()
end

function RoundTypeUpdate()
	activeRound = nil
	local chance = math.random(0, 100)

	if chance > 10 then --chance > 8
		activeRound = ROUNDS.normal
	else
		local spec_chance = math.random(0, 2)
		if spec_chance == 0 and SPAWN_NAZI_1 and SPAWN_USA_1 and MINIEVENTPROP then
			-- Only select ww2tdm if map supports it
			activeRound = ROUNDS.ww2tdm
		else
			-- hl2tdm is not defined, fallback to normal
			activeRound = ROUNDS.normal
		end
	end

	if forceround then
		activeRound = ROUNDS[forceround]
		forceround = nil
	end

	-- Safety check: if activeRound is still nil, fallback to normal
	if !activeRound then
		activeRound = ROUNDS.normal
	end

	SetGlobalString("RoundName", activeRound.name)
end



function Breach_EndRound(reason)
	if BREACH.GRUEscape then BREACH.GRUEscape.Reset() end
	net.Start("New_SHAKYROUNDSTAT")	
		net.WriteString(reason)
		net.WriteFloat(GetPostTime())
	net.Broadcast()
	postround = false
	postround = true
	if activeRound and activeRound.postround then
		activeRound.postround()
	end
	roundEnd = 0
	timer.Create("PostTime", GetPostTime(), 1, function()
		print( "restarting round" )
		RoundRestart()
	end)
end

util.AddNetworkString("PrepClient")

function TEST()
	--DiscordWebHookMessage("REDACTED_LEGACY_WEBHOOK", {
	--		content = "Рестарт",
	--	})
end

function RoundRestart(forceStart)
    if BREACH.GRUEscape then BREACH.GRUEscape.Reset() end
    -- GRU objectives belong to a round, not to the map lifetime.
    for i = 1, 3 do SetGlobalInt("TASKS_GRU_" .. i, 0) end
    GRU_Objective = nil
    if BREACH.Nu7 then BREACH.Nu7.ResetRoundState() end
	for k, v in ipairs(player.GetAll()) do
		v.ArenaParticipant = false
	end
	if GetGlobalInt("RoundUntilRestart", 15) <= 0 then
		hook.Run("BreachLog_GameRestart")
		RestartGame()
		--DiscordWebHookMessage("REDACTED_LEGACY_WEBHOOK", {
		--	content = "Рестарт",
		--})
		return
	end
	net.Start("PrepClient")
	net.Broadcast()
	print("round: clients prepared")
	BroadcastStopMusic()
	timer.Simple(1, function()
	SetGlobalBool("EnoughPlayersCountDown", false)

	if #GetActivePlayers() < GetMinimumPlayers() and !DEBUG_TESTIC and not forceStart then

		for _, v in ipairs(GetActivePlayers()) do
			if v:GTeam() != TEAM_SPEC then
				v:SetupNormal()
				v:SetSpectator()
			end
			v:RXSENDNotify("l:not_enough_players")
		end
		CleanUp()
		EvacuationEnd()
		EvacuationWarheadEnd()
		LZLockDownEnd()
		gamestarted = false
		preparing = false
		postround = false
		activeRound = nil

		BroadcastLua("activeRound = nil preparing = false gamestarted = false postround = false")

		return
	end

	if !MAP_LOADED then
		error( "Map config is not loaded!" )
	end

	print("round: starting")

	SetGlobalInt("RoundUntilRestart", GetGlobalInt("RoundUntilRestart", 15) - 1)

	if #GetActivePlayers() >= 30 then SetGlobalBool("BigRound", true) else SetGlobalBool("BigRound", false) end

	local restrts = GetGlobalInt("RoundUntilRestart", 15)

	--DiscordWebHookMessage("REDACTED_LEGACY_WEBHOOK", {
	--	content = restrts.." раундов до рестарта.\nВремя раунда: "..string.NiceTime_Full_Rus( GetRoundTime() ),
	--})
	
	hook.Run("BreachLog_RoundStart", GetGlobalInt("RoundUntilRestart", 15))

	BREACH.AdminLogs.Logs_Data.CurRound = BREACH.AdminLogs.Logs_Data.CurRound + 1

	LZLockDownEnd()
	EvacuationEnd()
	EvacuationWarheadEnd()
	Radio_RandomizeChannels()
	CleanUp()
	print("round: map cleaned")
	CleanUpPlayers()
	print("round: players cleaned")
	preparing = true
	postround = false
	activeRound = nil
	if #GetActivePlayers() < MINPLAYERS and not forceStart then WinCheck() end
	RoundTypeUpdate()
	SetupCollide()
	SetupAdmins( player.GetAll() )
	activeRound.setup()
	print( "round: setup end" )	
	net.Start("UpdateRoundType")
		net.WriteString(activeRound.name)
	net.Broadcast()
	activeRound.init()	
	print( "round: int end / preparation start" )	
	gamestarted = true
	BroadcastLua('gamestarted = true')
	print("round: gamestarted")
	net.Start("PrepStart")
		net.WriteInt(forceStart and 0 or GetPrepTime(), 8)
	net.Broadcast()
	UseAll()
	DestroyAll()
	-- timer.Destroy("PostTime") -- Removed: Already destroyed in CleanUp() at line 313
	hook.Run( "BreachPreround" )
	timer.Create("PreparingTime", forceStart and 0.1 or GetPrepTime(), 1, function()
		for k,v in pairs(player.GetAll()) do
			v:Freeze(false)
		end
		preparing = false
		postround = false		
		activeRound.roundstart()
		net.Start("RoundStart")
			net.WriteInt(GetRoundTime(), 12)
		net.Broadcast()
		print("round: started")
		roundEnd = CurTime() + GetRoundTime() + 3
		hook.Run( "BreachRound" )

		
		timer.Create("RoundTime", GetRoundTime(), 1, function()
			postround = false
			postround = true
			for k,v in pairs(player.GetAll()) do
				v:Freeze(false)
				if v:GTeam() == TEAM_ARENA then
					v.ArenaParticipant = false
					v:SetupNormal()
					v:SetSpectator()
				end
			end
			print( "post init: good" )
			activeRound.postround()
			--GiveExp()	
			print( "post functions: good" )
			print( "round: post" )
			if activeRound.name == "Containment Breach" then --custom rounds
			net.Start("New_SHAKYROUNDSTAT")	
			    net.WriteString("l:roundend_alphawarhead")
				net.WriteFloat(GetPostTime())
			net.Broadcast()
			net.Start("PostStart")
				net.WriteInt(GetPostTime(), 6)
				net.WriteInt(1, 4)
			net.Broadcast()
			end
			print( "data broadcast: good" )
			roundEnd = 0
			timer.Destroy("PunishEnd")
			hook.Run( "BreachPostround" )
			timer.Create("PostTime", GetPostTime(), 1, function()
				print( "restarting round" )
				RoundRestart()
			end)	
		end)
		
		hook.Run("BreachRoundTimerCreated")
	end)
	end)
end

function GetAlivePlayers()
	local tab = GetActivePlayers()
	local _t = {}
	for i = 1, #tab do
		local v = tab[i]
		if !v:Alive() or v:GTeam() == TEAM_SPEC or v:Health() <= 0 then continue end
		_t[#_t + 1] = v
	end
	return _t
end

-- GRU evacuation lifecycle. Rewards below retain the existing server rules;
-- the removed givekarmaforescape call belonged to an absent legacy subsystem.
BREACH.GRUEscape = BREACH.GRUEscape or {}
local gruEscapes = {}
local gruEscapeReceipts = {}

function BREACH.GRUEscape.Cancel(ply)
	local state = gruEscapes[ply]
	if not state then return end
	gruEscapes[ply] = nil
	timer.Remove(state.timerName)
	if not IsValid(ply) then return end
	-- A replacement life owns its own flags. Normal role changes cancel before
	-- incrementing RXActionGeneration; this also guards unexpected late calls.
	if ply.RXActionGeneration ~= state.generation then return end
	ply.isescaping = false
	ply:Freeze(state.frozen)
	if not state.god then ply:GodDisable() end
	ply.canblink = state.canblink
end

function BREACH.GRUEscape.Reset()
	for ply in pairs(gruEscapes) do BREACH.GRUEscape.Cancel(ply) end
	timer.Remove("PerformEscapeAnim_GRU")
end

hook.Add("PlayerDisconnected", "RXGRUEscape", function(ply)
	BREACH.GRUEscape.Cancel(ply)
	gruEscapeReceipts[ply] = nil
end)
hook.Add("PlayerDeath", "RXGRUEscape", BREACH.GRUEscape.Cancel)
hook.Add("PlayerSilentDeath", "RXGRUEscape", BREACH.GRUEscape.Cancel)

local function beginGRUEscape(ply)
	if gruEscapes[ply] or ply.isescaping or postround or preparing then return false end
	local receipt = gruEscapeReceipts[ply]
	if receipt and receipt.generation == ply.RXActionGeneration then return false end
	local heli
	for _, ent in ipairs(ents.FindByClass("gru_heli")) do
		if IsValid(ent) and IsValid(ent.at4e) and not ent.Blownup and not ent.Evacuating then
			heli = ent
			break
		end
	end
	if not heli or (ply:GTeam() == TEAM_GRU and not GetGlobalBool("Evacuation")) then return false end

	local state = {
		timerName = "EscapeWait" .. ply:SteamID64(), generation = ply.RXActionGeneration,
		team = ply:GTeam(), role = ply:GetRoleName(), frozen = ply:IsFrozen(),
		god = ply:HasGodMode(), canblink = ply.canblink
	}
	gruEscapes[ply] = state
	-- Keep the receipt through cancellation: a round reset has a short delay
	-- before it replaces player lives. That window must not grant rewards twice.
	gruEscapeReceipts[ply] = state
	ply.isescaping = true
	ply:GodEnable()
	ply:Freeze(true)
	ply.canblink = false
	timer.Create(state.timerName, 2, 1, function()
		if gruEscapes[ply] ~= state then return end
		if not IsValid(ply) or not ply:Alive() or ply:Health() <= 0
			or ply.RXActionGeneration ~= state.generation or ply:GTeam() ~= state.team
			or ply:GetRoleName() ~= state.role or not ply.isescaping or postround or preparing then
			BREACH.GRUEscape.Cancel(ply)
			return
		end
		BREACH.GRUEscape.Cancel(ply)
		ply:SetupNormal()
		ply:SetSpectator()
		WinCheck()
	end)

	if ply:GTeam() ~= TEAM_GRU then
		SetGlobalInt("TASKS_GRU_2", GetGlobalInt("TASKS_GRU_2") + 1)
	else
		if GetGlobalInt("TASKS_GRU_1") == 5 then ply:AddToStatistics("l:uiu_obj_bonus", 1000) end
		if GetGlobalInt("TASKS_GRU_2") >= 3 then ply:AddToStatistics("l:uiu_obj_bonus", 1000) end
		if GetGlobalInt("TASKS_GRU_3") >= 3 then ply:AddToStatistics("l:uiu_obj_bonus", 1000) end
	end
	net.Start("Ending_HUD")
	net.WriteString("l:ending_escaped_site19_got_captured")
	net.Send(ply)
	ply:CompleteAchievement("escape")
	ply:CompleteAchievement("escapehand")
	ply:AddToStatistics("l:escaped", 800)
	if ply:HasWeapon("item_cheemer") then ply:AddToStatistics("l:cheemer_rescue", 100) end
	ply:LevelBar()
	return true
end

function InfiniteEscapes()
	if !BREACH.PeopleCanEscape then return end

	local plys = GetAlivePlayers()
	for i = 1, #plys do
		local v = plys[i]

		if v:GTeam() == TEAM_SPEC then continue end
		if !v:Alive() then continue end
		if v:Health() <= 0 then continue end
		if v.isescaping then continue end

		if v:GetPos():WithinAABox(Vector(-2135.845703, 4767.522461, 1440.664429), Vector(-1835.034912, 5305.313477, 1658.326904)) then
			if v:CanEscapeChaosRadio() then
					--v:AddFrags(5)
				v:GodEnable()
				v:SetNoDraw(true)
				v:Freeze(true)
				net.Start("StartCIScene")
				net.Send(v)
				v.isescaping = true
				timer.Create("EscapeWait" .. v:SteamID64(), 8, 1, function()
					net.Start("Ending_HUD")
						net.WriteString("l:ending_captured_by_unknown")
					net.Send(v)
					v:AddToStatistics("l:escaped", 1000)
					if v:HasWeapon("item_cheemer") then
						v:AddToStatistics("l:cheemer_rescue", 1000)
					end
					v:CompleteAchievement("escape")
					v:LevelBar()
					v:Freeze(false)
					v:GodDisable()
					v:CompleteAchievement("chaosradio")
					v:SetupNormal()
					v:SetSpectator()
					WinCheck()
					v.isescaping = false
				end)
			end
		elseif v:GetPos():WithinAABox(Vector(-7679.626465, -727.644836, 1889.328735), Vector(-8088.857422, -886.812866, 1685.490723)) then
			local exptoget = 100 * v:GetNLevel()

			v:GodEnable()
			v:Freeze(true)
			v.canblink = false
			v.isescaping = true

			timer.Create("EscapeWait" .. v:SteamID64(), 2, 1, function()
						
				v:Freeze(false)
				v:GodDisable()
				v:SetupNormal()
				v:SetSpectator()
						
				WinCheck()
				v.isescaping = false
			end)
			net.Start("Ending_HUD")
				net.WriteString("l:ending_escaped_site19_got_captured")
			net.Send(v)
			v:CompleteAchievement("escape")
			v:CompleteAchievement("escapehand")
			v:AddToStatistics("l:escaped", 800)
			if v:HasWeapon("item_cheemer") then
				v:AddToStatistics("l:cheemer_rescue", 1000)
			end
			v:LevelBar()
		elseif v:GetPos():WithinAABox(Vector(-6979.750488, -893.080811, 1668.085327), Vector(-7044.459961, -998.905945, 1924.017090)) then

			local rtime = timer.TimeLeft("RoundTime")

			v:GodEnable()
			v:Freeze(true)
			v.canblink = false
			v.isescaping = true
			timer.Create("EscapeWait" .. v:SteamID64(), 2, 1, function()
				v:Freeze(false)
				v:GodDisable()
				v:SetupNormal()
				v:SetSpectator()
				WinCheck()
				v.isescaping = false
			end)
			if v:GTeam() == TEAM_USA then
				if v:GetRoleName() != role.SCI_SpyUSA then
					if Monitors_Activated and Monitors_Activated >= 5 then
						net.Start("Ending_HUD")
							net.WriteString("l:ending_mission_complete")
						net.Send(v)
						v:CompleteAchievement("fbiescape")
						v:AddToStatistics("l:escaped", 600)
					else
						net.Start("Ending_HUD")
							net.WriteString("l:ending_mission_failed")
						net.Send(v)
						v:AddToStatistics("l:escaped", 200)
					end
				else
					if v.TempValues.FBIHackedTerminal then
						net.Start("Ending_HUD")
							net.WriteString("l:ending_mission_complete")
						net.Send(v)
						v:AddToStatistics("l:escaped", 1000)
					else
						net.Start("Ending_HUD")
							net.WriteString("l:ending_mission_failed")
						net.Send(v)
						v:AddToStatistics("l:escaped", 100)
					end
				end
			else
				net.Start("Ending_HUD")
					net.WriteString("l:ending_escaped_site19")
				net.Send(v)
				v:AddToStatistics("l:escaped", 200)
			end
			if v:HasWeapon("item_cheemer") then
				v:AddToStatistics("l:cheemer_rescue", 1000)
			end

			v:CompleteAchievement("escape")
			v:CompleteAchievement("beglec")
			if !timer.Exists("RoundTime") or timer.TimeLeft("RoundTime") <= 5 then
				v:CompleteAchievement("runbitch")
			end
			v:LevelBar()
		elseif v:GetPos():WithinAABox(Vector(-15027.241211, 3324.958008, -15499.637695), Vector(-14578.889648, 3665.833252, -15751.149414)) then

			if v:CanEscapeO5() then

				local rtime = timer.TimeLeft("RoundTime")

				v:GodEnable()
				v:Freeze(true)
				v.canblink = false
				v.isescaping = true

				timer.Create("EscapeWait" .. v:SteamID64(), 2, 1, function()
					v:Freeze(false)
					v:GodDisable()
					v:SetupNormal()
					v:SetSpectator()
					v.isescaping = false
				end)

				net.Start("Ending_HUD")
					net.WriteString("l:ending_o5")
				net.Send(v)

				v:CompleteAchievement("monorail")
				v:CompleteAchievement("escape")

				v:AddToStatistics("l:escaped", 1000)
				if v:HasWeapon("item_cheemer") then
					v:AddToStatistics("l:cheemer_rescue", 1000)
				end
				v:LevelBar()

			end

		elseif v:GetPos():WithinAABox(Vector(-7251.340332, 2135.789307, 2002), Vector(-7121.389160, 2256.855469, 2238)) then
			beginGRUEscape(v)

		elseif v:GetPos():WithinAABox(Vector(-7383.785645, 13929.800781, 2325.235352), Vector(-6826.424805, 15381.131836, 1937.054810)) then
			
			if v:CanEscapeCar() && v:InVehicle() then
				v.canblink = false
				v.isescaping = true
				local vehicle = v:GetVehicle()
				for i, ply in pairs(player.GetAll()) do
					if ply:InVehicle() then
						local myvehicle = ply:GetVehicle()
						ply:ExitVehicle()
						if ply:CanEscapeCar() then
							ply:SetupNormal()
							ply:SetSpectator()
							v:CompleteAchievement("escape")
							net.Start("Ending_HUD")
								net.WriteString("l:ending_car")
							net.Send(ply)
							ply:CompleteAchievement("car")
							ply:AddToStatistics("l:escaped", 1600)
							ply:LevelBar()
						end
						timer.Simple(0.2, function() if IsValid(myvehicle) then myvehicle:Remove() end end)
					end
				end
			end

		end

	end

end
timer.Create("InfiniteEscapes", 1, 0, InfiniteEscapes)
--[[
concommand.Add("br_enable_escapes", function()

	InfiniteEscapes()

end)
--]]

function WinCheck()
	if postround then return end
	if !activeRound then return end
	activeRound.endcheck()
	if roundEnd > 0 and roundEnd < CurTime() then
		roundEnd = 0
	--	endround = true
	--	why = "game ran out of time limit"
		print( "Something went wrong! Error code: 100" )
		print( debug.traceback() )
	end
	/*if #GetActivePlayers() < 2 then 
		endround = true
		why = " there are not enough players"
		gamestarted = false
		BroadcastLua( "gamestarted = false" )
	end*/
	if endround then
		print("Ending round because " .. why)
		PrintMessage(HUD_PRINTCONSOLE, "Ending round because " .. why)
		StopRound()
		timer.Destroy("RoundTime")
		preparing = false
		postround = true

		// send infos
		--[[
		net.Start("EndRoundStats")	
		    net.WriteString("Containment Breach has been ended")
		    net.WriteFloat(18)
	    net.Broadcast()]]

	    net.Start("New_SHAKYROUNDSTAT")
		    net.WriteString("l:roundend_cbended")
		    net.WriteFloat(GetPostTime())
	    net.Broadcast()
		
		net.Start("PostStart")
			net.WriteInt(GetPostTime(), 6)
			net.WriteInt(2, 4)
		net.Broadcast()
		activeRound.postround()	
		--GiveExp()
		endround = false
		--print( debug.traceback() )  
		hook.Run( "BreachPostround" )
		timer.Create("PostTime", GetPostTime(), 1, function()
			RoundRestart()
		end)
	end
end

function StopRound()
	timer.Stop("PreparingTime")
	timer.Stop("RoundTime")
	timer.Stop("PostTime")
	timer.Stop("GateOpen")
	timer.Stop("PlayerInfo")
end

timer.Create("WinCheckTimer", 5, 0, function()
	if postround == false and preparing == false then
		WinCheck()
	end
end)

--[[
timer.Create("EXPTimer", 180, 0, function()
	for k,v in pairs(player.GetAll()) do
		if IsValid(v) and v.AddExp != nil then
			v:AddExp(200, true)
		end
	end
end)
--]]

function SetupCollide()
	local fent = ents.GetAll()
	for k, v in pairs( fent ) do
		if v and v:GetClass() == "func_door" or v:GetClass() == "prop_dynamic" then
			if v:GetClass() == "prop_dynamic" then
				local ennt = ents.FindInSphere( v:GetPos(), 5 )
				local neardors = false
				for k, v in pairs( ennt ) do
					if v:GetClass() == "func_door" then
						neardors = true
						break
					end
				end
				if !neardors then 
					v.ignorecollide106 = false
					continue
				end
			end

			local changed
			for _, pos in pairs( DOOR_RESTRICT106 ) do
				if v:GetPos():Distance( pos ) < 100 then
					v.ignorecollide106 = false
					changed = true
					break
				end
			end
			
			if !changed then
				v.ignorecollide106 = true
			end
		end
	end
end

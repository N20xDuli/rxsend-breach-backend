-- Player-class methods are entity-local and must exist before gameplay hooks run.
BREACH = BREACH or {}
local dataFields = {"RoleName", "Namesurvivor", "NEXP", "NLevel", "NGTeam", "MaxSlots", "SpecialMax", "PenaltyAmount", "SpecialCD", "StaminaScale", "Energized", "Boosted", "Adrenaline", "Female", "InDimension", "Crouching"}

function BREACH.HasPlayerDataTables(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    for _, name in ipairs(dataFields) do
        if not isfunction(ply["Get" .. name]) or not isfunction(ply["Set" .. name]) then return false end
    end
    return true
end

function BREACH.EnsurePlayerDataTables(ply)
    if BREACH.HasPlayerDataTables(ply) then return true end
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    -- Clients must wait for the authoritative class id; never assign it locally.
    if player_manager.GetPlayerClass(ply) ~= "class_breach" then return false end
    local ok, err = pcall(player_manager.RunClass, ply, "SetupDataTables")
    if not ok and (ply.RXDataTableErrorAt or 0) <= CurTime() then
        ply.RXDataTableErrorAt = CurTime() + 5
        ErrorNoHaltWithStack("[RX PlayerData] SetupDataTables failed: " .. tostring(err) .. "\n")
    end
    return ok and BREACH.HasPlayerDataTables(ply)
end

local RunConsoleCommand = RunConsoleCommand;
local FindMetaTable = FindMetaTable;
local CurTime = CurTime;
local pairs = pairs;
local string = string;
local table = table;
local timer = timer;
local hook = hook;
local math = math;
local pcall = pcall;
local unpack = unpack;
local tonumber = tonumber;
local tostring = tostring;
local ents = ents;
local ErrorNoHalt = ErrorNoHalt;
local DeriveGamemode = DeriveGamemode;
local util = util
local net = net
local player = player

local mply = FindMetaTable("Player")

DEFINE_BASECLASS( "player_default" )

local templevel = 0 -- set 0 to disable

local bonuslevel = 0

local PLAYER = {}

function PLAYER:SetupDataTables()

	if self._datatableapplied and BREACH.HasPlayerDataTables(self.Player) then return end
	local applyDefaults = not self._datatableapplied

	local check = SysTime()
	
	self.Player:NetworkVar( "String", 0, "RoleName" )
	self.Player:NetworkVar( "String", 1, "Namesurvivor")
	self.Player:NetworkVar( "Int", 0, "NEXP" )
	self.Player:NetworkVar( "Int", 1, "NLevel" )
	self.Player:NetworkVar( "Int", 2, "NGTeam" )
	self.Player:NetworkVar( "Int", 3, "MaxSlots" )
	self.Player:NetworkVar( "Int", 4, "SpecialMax" )
    self.Player:NetworkVar( "Int", 5, "PenaltyAmount" )
	self.Player:NetworkVar( "Float", 0, "SpecialCD" )
	self.Player:NetworkVar( "Float", 1, "StaminaScale" )
	self.Player:NetworkVar( "Bool", 0, "Energized" )
	self.Player:NetworkVar( "Bool", 1, "Boosted" )
	self.Player:NetworkVar( "Bool", 2, "Adrenaline" )
	self.Player:NetworkVar( "Bool", 3, "Female" )
	self.Player:NetworkVar( "Bool", 4, "InDimension")
	self.Player:NetworkVar( "Bool", 5, "Crouching")

	-- Mark success only after every accessor has been registered.
	self._datatableapplied = true
	if not applyDefaults then return end

	print(SysTime() - check, " Spent on networkvaring..")
	
	if SERVER then
		print("Setting up datatables for " .. self.Player:Nick())
		self.Player:SetRoleName("Spectator")
		self.Player:SetNamesurvivor( "" )

		print("setting up data")

		self.Player:SetNGTeam(TEAM_SPEC or 26)
		self.Player:SetSpecialCD( 0 )
		self.Player:SetInDimension( false )
		self.Player:SetAdrenaline( false )
		self.Player:SetEnergized( false )
		self.Player:SetBoosted( false )
		self.Player:SetMaxSlots( 8 )
		self.Player:SetFemale( false )
		self.Player:SetCrouching( false )
		self.Player:SetSpecialMax( 0 )
		self.Player:SetStaminaScale(1.0)

		-- LoadPlayer gives bots/dummies in-memory defaults without a database account.
		BREACH.DataBaseSystem:LoadPlayer(self.Player, function()

			print("[RXSEND MYSQLOO] Data for " .. self.Player:Nick() .." has been set successfuly!")

		end)

	end
end

function CheckPlayerData( player, name )
	local pd = player:GetPData( name, 0 )
	if pd == "nil" then
		print( "Damaged playerdata found..." )
		player:RemovePData( name )
		player:SetPData( name, 1 )
	end
end

player_manager.RegisterClass( "class_breach", PLAYER, "player_default" )
if CLIENT then
    local function ensureAllPlayers()
        for _, ply in ipairs(player.GetAll()) do BREACH.EnsurePlayerDataTables(ply) end
    end
    -- ULib priority -2 runs before ordinary hooks and does not override their return values.
    hook.Add("Think", "RXPlayerDataReady", ensureAllPlayers, -2)
    hook.Add("HUDPaint", "RXPlayerDataReady", ensureAllPlayers, -2)
    hook.Add("CreateMove", "RXPlayerDataReady", function()
        BREACH.EnsurePlayerDataTables(LocalPlayer())
    end, -2)
    hook.Add("SetupMove", "RXPlayerDataReady", function(ply)
        BREACH.EnsurePlayerDataTables(ply)
    end, -2)
    hook.Add("NetworkEntityCreated", "RXPlayerDataReady", function(ent)
        if ent:IsPlayer() then BREACH.EnsurePlayerDataTables(ent) end
    end)
    hook.Add("InitPostEntity", "RXPlayerDataReady", ensureAllPlayers)
end

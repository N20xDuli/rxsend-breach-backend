BREACH = BREACH || {}
BREACH.DataBaseSystem = BREACH.DataBaseSystem || {}

BREACH.DataBaseSystem.cachedQueries = BREACH.DataBaseSystem.cachedQueries || {}

local storage = include("rxsend/database.lua")

local mply = FindMetaTable("Player")

BREACH.DataBaseSystem.PDATASWAP = {
	["breach_level"] = "level",
	["DonatedLevels"] = "donatedlevels",
	["elo"] = "elo",
}

BR_DATATYPE_NUM = 0
BR_DATATYPE_STRING = 1
BR_DATATYPE_BOOL = 2

local data_list = {
	
	["level"] = {
		default = 1,
		type = BR_DATATYPE_NUM,
	},

	["donatedlevels"] = {
		type = BR_DATATYPE_NUM,
		default = 0
	},

	["exp"] = {
		default = 0,
		type = BR_DATATYPE_NUM,
	},

	["firsttime"] = {
		type = BR_DATATYPE_NUM,
	},
	
	["lastname"] = {
		type = BR_DATATYPE_STRING,
	},

	["playtime"] = {
		type = BR_DATATYPE_NUM
	},

	["premium"] = {
		type = BR_DATATYPE_NUM,
		default = 0,
	},

	["adminka"] = {
		type = BR_DATATYPE_NUM,
		default = 0,
	},

}

local function temporaryPlayer(ply)
    return ply:IsBot() or ply.BreachAdminDummy == true
end

local function initializeDefaults(ply)
    if ply.StoredData then return end
    ply.StoredData = {}
    for name, definition in pairs(data_list) do
        ply.StoredData[name] = definition.default
    end
end

local function persistentID(sid64)
    -- Bots and unauthenticated clients return "0" and have no shared account.
    return isstring(sid64) and #sid64 == 17 and sid64:match("^%d+$") ~= nil
end

local function onConnected()

	timer.Remove("RXPlayerDatabaseReconnect")

	local query = BREACH.DataBaseSystem:GetDatabase():query("CREATE TABLE IF NOT EXISTS player_data (id TEXT, dataname TEXT, value varchar(255))")

	query:start()
	--breachachievements' doesn't exist (INSERT INTO breachachievements ( owner, achivid, count
	local query = BREACH.DataBaseSystem:GetDatabase():query("CREATE TABLE IF NOT EXISTS breachachievements (owner TEXT, achivid TEXT, count varchar(255))")

	query:start()

end

function DataBaseSystemConnect()

	if BREACH.DataBaseSystem.databaseObject then return BREACH.DataBaseSystem.databaseObject end

	BREACH.DataBaseSystem.databaseObject = storage.Connect("players")

	BREACH.DataBaseSystem.databaseObject.onConnectionFailed = function(db, msg)
        ErrorNoHalt("[RXSend] Player database connection failed; retrying in 5 seconds.\n")
        timer.Create("RXPlayerDatabaseReconnect", 5, 1, function()
            if BREACH.DataBaseSystem.databaseObject == db then db:connect() end
        end)
    end

    BREACH.DataBaseSystem.databaseObject.onConnected = onConnected

    BREACH.DataBaseSystem.databaseObject:connect()
    return BREACH.DataBaseSystem.databaseObject

end

function BREACH.DataBaseSystem:Connect()

	return DataBaseSystemConnect()

end

hook.Add("InitPostEntity", "CreateDataTable", function()

	BREACH.DataBaseSystem:Connect()


end)

-- A missed map-ready hook must not prevent player initialization.
function BREACH.DataBaseSystem:GetDatabase()
    return self.databaseObject or self:Connect()
end

timer.Simple(0, function() BREACH.DataBaseSystem:GetDatabase() end)

function BREACH.DataBaseSystem:GetData(sid64, dataname, default, callback, onerror)

    if not persistentID(sid64) then
        if callback then timer.Simple(0, function() callback(default) end) end
        return
    end

	local query = BREACH.DataBaseSystem:GetDatabase():query("SELECT * from player_data WHERE id = "..sql.SQLStr(sid64).." AND dataname = "..sql.SQLStr(dataname).." LIMIT 1")

	query.onSuccess = function(_, data)
		if callback then
			local toreturn = default

			if #data > 0 then
				toreturn = data[1].value
			end

			callback(toreturn)
		end
	end

	query.onError = onerror

	query:start()

end

function BREACH.DataBaseSystem:GetPlayerData(sid64, callback)

    if not persistentID(sid64) then
        if callback then timer.Simple(0, function() callback({}) end) end
        return
    end

	local query = BREACH.DataBaseSystem:GetDatabase():query("SELECT * from player_data WHERE id = "..sql.SQLStr(sid64))

	query.onSuccess = function(_, data)
		callback(data)
	end

	query.onError = onerror

	query:start()

end

function BREACH.DataBaseSystem:UpdateData(sid64, dataname, value, add)

    if not persistentID(sid64) then return false end

	local query = BREACH.DataBaseSystem:GetDatabase():query("SELECT value from player_data WHERE id = "..sql.SQLStr(sid64).." AND dataname = "..sql.SQLStr(dataname).." LIMIT 1")

	query.onSuccess = function(_, data)

		local isdefault

		if data_list and data_list[dataname] then
			isdefault = (data_list and data_list[dataname].default != nil and ( data_list[dataname].type == BR_DATATYPE_NUM and data_list[dataname].default == value ))
		end
		local addvalue

		local setvalue = value

		if #data > 0 then

			if isdefault then

				addvalue = BREACH.DataBaseSystem:GetDatabase():query("DELETE FROM player_data WHERE id = "..sql.SQLStr(sid64).." AND dataname = "..sql.SQLStr(dataname))

			else

				if add then
					addvalue = BREACH.DataBaseSystem:GetDatabase():query("UPDATE player_data SET value = value + "..sql.SQLStr(setvalue).." WHERE id = "..sql.SQLStr(sid64).." AND dataname = "..sql.SQLStr(dataname))
				else
					addvalue = BREACH.DataBaseSystem:GetDatabase():query("UPDATE player_data SET value = "..sql.SQLStr(setvalue).." WHERE id = "..sql.SQLStr(sid64).." AND dataname = "..sql.SQLStr(dataname))
				end

			end

		else

			if !isdefault then

				addvalue = BREACH.DataBaseSystem:GetDatabase():query("INSERT INTO player_data VALUES("..sql.SQLStr(sid64)..", "..sql.SQLStr(dataname)..", "..sql.SQLStr(value)..")")

			end

		end

		if addvalue then

			addvalue.onSuccess = function()

				local ply = player.GetBySteamID64(sid64)

				if IsValid(ply) then

					if add and ply.StoredData[dataname] then

						ply.StoredData[dataname] = ply.StoredData[dataname] + setvalue

					else

						ply.StoredData[dataname] = setvalue

					end

				end

			end

			addvalue:start()

		end
	end

	query:start()

end

function BREACH.DataBaseSystem:RemoveData(sid64, dataname)

    if not persistentID(sid64) then return false end

	local query = BREACH.DataBaseSystem:GetDatabase():query("DELETE FROM player_data WHERE id = "..sql.SQLStr(sid64).." AND dataname = "..sql.SQLStr(dataname))

	query:start()

end

function mply:RemoveBreachData(dataname)
	if temporaryPlayer(self) then
		initializeDefaults(self)
		self.StoredData[dataname] = data_list[dataname] and data_list[dataname].default or nil
		return
	end
	BREACH.DataBaseSystem:RemoveData(self:SteamID64(), dataname)
end

function mply:GetBreachData(dataname)
	if temporaryPlayer(self) then initializeDefaults(self) end
	if !self.StoredData then
		BREACH.DataBaseSystem:LoadPlayer(self)
		return
	else
		local val = self.StoredData[dataname]

		if !val and data_list[dataname] then
			val = data_list[dataname].default
		end
		return val
	end
end

function mply:SetBreachData(dataname, value, add)
	if temporaryPlayer(self) then
		initializeDefaults(self)
		if add then value = (tonumber(self.StoredData[dataname]) or 0) + (tonumber(value) or 0) end
		self.StoredData[dataname] = value
		return
	end
	BREACH.DataBaseSystem:UpdateData(self:SteamID64(), dataname, value, add)
end

function mply:AddBreachData(dataname, amount)
	self:SetBreachData(dataname, amount, true)
end

function BREACH.DataBaseSystem:LoadValuesToPlayer(ply)

	ply:SetNLevel(ply:GetBreachData("level"))
	ply:SetPenaltyAmount(temporaryPlayer(ply) and 0 or tonumber(ply:GetPData("breach_penalty", 0)))
	ply:SetNEXP(ply:GetBreachData("exp"))

end

function BREACH.DataBaseSystem:LoadPlayer(ply, onload)

	if !IsValid(ply) or !ply:IsPlayer() then return false end
	if temporaryPlayer(ply) then
		initializeDefaults(ply)
		self:LoadValuesToPlayer(ply)
		if onload then onload() end
		return true
	end

	if !ply.StoredData then

		ply.StoredData = {}

		for i, v in pairs(data_list) do
			ply.StoredData[i] = v.default
		end

		self:GetPlayerData(ply:SteamID64(), function(data)

			-- The query can finish after the player has disconnected.
			if !IsValid(ply) or !istable(ply.StoredData) then return end

			for _, v in pairs(data) do

				local val = v.value

				if data_list[v.dataname] then
					if data_list[v.dataname].type == BR_DATATYPE_NUM then
						val = tonumber(val)
					elseif data_list[v.dataname].type == BR_DATATYPE_BOOL then
						val = tobool(val)
					end
				end

				ply.StoredData[v.dataname] = val

			end

			BREACH.DataBaseSystem:LoadValuesToPlayer(ply)

			if onload then onload() end

		end)

	else

		BREACH.DataBaseSystem:LoadValuesToPlayer(ply)

		if onload then onload() end

	end

end

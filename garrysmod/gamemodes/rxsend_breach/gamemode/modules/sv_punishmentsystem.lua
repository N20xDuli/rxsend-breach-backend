include("rxsend/punishments.lua")

function TESTICSUPRA()

	local query = BREACH.DataBaseSystem.databaseObject:query("SELECT * FROM player_data WHERE dataname = "..sql.SQLStr("premium"))

	query.onSuccess = function(_, data) print(#data) end

	query:start()

end
--
BREACH.DataList = {}

-- Steam ID conversion is provided by the steam_functions autorun dependency.
-- Do not replace it here: unauthenticated players and bots have no account ID.

local datattotrasnfer = {
	["prefix_activated"] = "prefix_activated",
	["rainbow_prefix_activated"] = "rainbow_prefix_activated",
}

function GETDATA()


	for dataname, tovalue in pairs(datattotrasnfer) do

		local txt = "["..dataname.."]"

		for i, v in pairs(sql.Query("SELECT * FROM playerpdata")) do

			if v.infoid:EndsWith(txt) and !v.infoid:StartWith("-") then

				BREACH.DataBaseSystem:UpdateData(util.SteamID64From32(string.sub(v.infoid, 0, #v.infoid-#txt)), tovalue, v.value)

			end


		end

	end
end

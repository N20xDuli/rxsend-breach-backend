include( "shared.lua" )

local function groupHasAccess( group, access )
	for k, v in pairs( ULib.ucl.groups[group].allow ) do
		if v == access then
			return true, group, ""
		elseif k == access then
			return true, group, v
		end
	end
	return false, ""
end

local function checkInheritedAccess( group, access )
	if ULib.ucl.groups[group] then
		local foundAccess, fromGroup, restrictionString = groupHasAccess( group, access )
		if foundAccess then
			return foundAccess, group, restrictionString
		else
			return checkInheritedAccess( ULib.ucl.groups[group].inherit_from, access )
		end
	else
		return false, "", ""
	end
end
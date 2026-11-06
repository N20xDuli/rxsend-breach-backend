BREACH = BREACH or {}

-- Role names are internal identifiers from sh_module.lua, independent of language.
BREACH.HighOfficialRoles = {
    [role.Dispatcher] = true, -- O4 command dispatcher
    [role.MTF_HOF] = true, -- Facility director
    [role.MTF_Com] = true, -- Security director
    [role.SCI_Head] = true, -- Head of personnel
    [role.MTF_Security] = true, -- Internal security agent
    [role.SECURITY_Chief] = true, -- Security department captain
}

-- Security department lieutenant and O4 await confirmed role definitions.
-- MTF_Left is an MTF lieutenant, not a security department lieutenant.
function BREACH.IsHighOfficial(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply.GetRoleName then
        return false
    end

    return BREACH.HighOfficialRoles[ply:GetRoleName()] == true
end

-- Receiving and proximity voice do not depend on this transmission permission.
function BREACH.CanRadioTransmit(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    local teamID = ply:GTeam()
    if teamID == TEAM_SPEC or teamID == TEAM_SCP then return false end
    local nu7 = BREACH.Nu7
    if not nu7 or not nu7.IsFoundationTeam then return false end
    if not nu7.IsFoundationTeam(teamID) then return true end
    return teamID == TEAM_NTF or teamID == TEAM_NU7 or teamID == TEAM_ALPHA9 or BREACH.IsHighOfficial(ply)
end

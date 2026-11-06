BREACH = BREACH or {}
-- The server owns the full presentation window, including the legacy scene.
function BREACH.BeginSupportEntry(ply, teamID)
    local durations = {[TEAM_NU7]=20,[TEAM_NTF]=20,[TEAM_GRU]=20,[TEAM_CHAOS]=20,
        [TEAM_USA]=20,[TEAM_GOC]=20,[TEAM_DZ]=20,[TEAM_COTSK]=20,[TEAM_QRT]=8}
    local duration = durations[teamID]
    if not duration then return end
    ply.RXEntryCardEnds = CurTime() + duration
    ply:SetNWFloat("RXDeploymentEnds", ply.RXEntryCardEnds)
end
function BREACH.QueueSupportScene(players, duration, callback)
    local delay = 0
    local identities = {}
    for _, ply in ipairs(players) do
        if IsValid(ply) and ply:Alive() and ply:GTeam() ~= TEAM_SPEC then
            delay = math.max(delay, (ply.RXEntryCardEnds or 0) - CurTime())
            identities[ply] = {team=ply:GTeam(),role=ply:GetRoleName()}
        end
    end
    if delay <= 0 then return false end
    for ply in pairs(identities) do
        ply:SetNWFloat("RXDeploymentEnds", CurTime()+delay+0.05+duration)
    end
    timer.Simple(delay+0.05, function()
        local ready = {}
        for ply, identity in pairs(identities) do
            if IsValid(ply) and ply:Alive() and ply:GTeam()==identity.team and ply:GetRoleName()==identity.role then
                ready[#ready+1]=ply
            end
        end
        if #ready > 0 then callback(ready) end
    end)
    return true
end
function BREACH.OfferSupportSelection(ply)
    if not IsValid(ply) or not ply:IsPremium() or ply:GTeam()==TEAM_SPEC or string.lower(ply:GetRoleName()):find("spy") then return end
    local teamID, roleName = ply:GTeam(), ply:GetRoleName()
    ply.RXSelectionToken = (ply.RXSelectionToken or 0)+1
    local token=ply.RXSelectionToken
    ply.CanSwitchRole=false
    ply:SetNWFloat("RXSelectionEnds",0)
    local function ready()
        if not IsValid(ply) or not ply:Alive() or ply:GTeam()~=teamID or ply:GetRoleName()~=roleName or ply.RXSelectionToken~=token then return end
        if CurTime()<ply:GetNWFloat("RXDeploymentEnds",0) or IsValid(ply:GetNWEntity("NTF1Entity")) then
            timer.Simple(0.25,ready)
            return
        end
        ply.CanSwitchRole=true
        ply:SetNWFloat("RXSelectionEnds",CurTime()+45)
        ply:bSendLua("Select_Supp_Menu(LocalPlayer():GTeam())")
        timer.Simple(45,function()
            if IsValid(ply) and ply.RXSelectionToken==token then ply.CanSwitchRole=false end
        end)
    end
    ready()
end

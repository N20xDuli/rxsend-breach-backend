BREACH = BREACH or {}
function BREACH.BeginDeploymentIntro(duration, preview, teamID)
    if BREACH.RoundUI and BREACH.RoundUI.EndDeployment then
        BREACH.RoundUI.EndDeployment("new-deployment")
    end
    if BREACH.RoleInfo then BREACH.RoleInfo.Close() end
    if GAMEMODE and GAMEMODE.ScoreboardHide then GAMEMODE:ScoreboardHide() end
    local now = RealTime()
    BREACH.DeploymentIntro = {ends = now + duration, graceUntil = now + 2,
        preview = preview == true, team = teamID}
end
local function cancelDeployment(reason)
    if BREACH.RoundUI and BREACH.RoundUI.EndDeployment then
        BREACH.RoundUI.EndDeployment(reason)
    else
        BREACH.DeploymentIntro=nil
    end
end
function BREACH.IsDeploymentIntroActive()
    local state = BREACH.DeploymentIntro
    if postround or (BREACH.RoundUI and BREACH.RoundUI.HasResults and BREACH.RoundUI.HasResults()) then
        if state then cancelDeployment("results") end
        return false
    end
    local ply=LocalPlayer()
    local legacy=IsValid(ply) and ply:Alive() and ply:GTeam()~=TEAM_SPEC and ply:GetNWFloat("RXDeploymentEnds",0)>CurTime()
    if not state then return legacy end
    local now = RealTime()
    if now >= state.ends then BREACH.DeploymentIntro = nil return legacy end
    if state.preview or now <= state.graceUntil then return true end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() or ply:GTeam() ~= state.team then
        cancelDeployment("player-changed")
        return false
    end
    -- Role/team replication can arrive after the intro message; bind after the grace period.
    local currentRole = ply:GetRoleName()
    if state.role == nil then state.role = currentRole end
    if currentRole ~= state.role then cancelDeployment("role-changed") return false end
    return true
end
hook.Add("HUDShouldDraw", "BreachDeploymentHideHUD", function(name)
    -- CHudGMod owns HUDPaint itself, including deployment overlays.
    if name ~= "CHudGMod" and name ~= "CHudChat" and BREACH.IsDeploymentIntroActive() then return false end
end)
hook.Add("Think", "BreachDeploymentHidePanels", function()
    -- The combat visibility hook owns SCP ability panels once its API is loaded.
    local hud=BREACH.CombatHUD
    if hud and hud.SCPAbilityHUDVisible then return end
    if IsValid(BREACH.Abilities) then BREACH.Abilities:SetVisible(not BREACH.IsDeploymentIntroActive()) end
end)

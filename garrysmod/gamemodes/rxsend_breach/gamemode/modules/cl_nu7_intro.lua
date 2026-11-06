BREACH.Nu7 = BREACH.Nu7 or {}
local intro
local duration = 20
local icon = Material("nextoren/gui/roles_icon/nu7_intro_badge.png", "smooth")

hook.Add("RXRoundUIReset","RXNu7DeploymentReset",function() intro=nil end)

function BREACH.Nu7.StartIntro(roleName, preview)
    BREACH.BeginDeploymentIntro(duration, preview, TEAM_NU7)
    intro = {started=RealTime(), roleName=roleName, preview=preview == true}
    BREACH.Music:Play(BR_MUSIC_SPAWN_NU7)
    if IsValid(BREACH_DESC_LOGO) then BREACH_DESC_LOGO:Remove() end
    if IsValid(BREACH_DESC_PANEL) then BREACH_DESC_PANEL:Remove() end
end

net.Receive("NU7_DeploymentIntro", function()
    BREACH.Nu7.StartIntro(net.ReadString())
end)

concommand.Add("nu7_intro_preview", function()
    BREACH.Nu7.StartIntro(role.NU7_Commander, true)
end)

hook.Add("PostDrawHUD", "Nu7_DeploymentOverlay", function()
    if not intro then return end
    local elapsed = RealTime() - intro.started
    local client = LocalPlayer()
    local live=IsValid(client) and client:Alive() and client.GTeam and client:GTeam()==TEAM_NU7
    if not intro.preview and elapsed>2 and (not live or
        (intro.roleSynced and intro.roleId~=client:GetRoleName())) then
        if BREACH.RoundUI and BREACH.RoundUI.EndDeployment then
            BREACH.RoundUI.EndDeployment("role-changed")
        else intro=nil end
        return
    end
    if not intro.preview and not intro.roleSynced and elapsed>2 and live then
        intro.roleId=client:GetRoleName()
        intro.roleName=intro.roleId
        intro.roleSynced=true
    end
    if elapsed>=duration then
        local completed=not intro.preview
        intro=nil
        if completed then DrawNewRoleDesc() end
        return
    end
    if BREACH.RoundUI and BREACH.RoundUI.DrawDeployment then
        BREACH.RoundUI.DrawDeployment({title="落锤特遣大队",faction="机动特遣队",
            roleName=GetLangRole and GetLangRole(intro.roleName) or intro.roleName,
            name=IsValid(client) and client:GetNamesurvivor() or "",tasks=BREACH.Nu7.Objectives or {},
            elapsed=elapsed,duration=duration,preview=intro.preview,icon=icon})
    end
end)

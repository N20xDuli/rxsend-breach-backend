BREACH.Goc = BREACH.Goc or {}
local intro
local duration = 20
local emblem = Material("nextoren/gui/roles_icon/goc.png", "smooth")

local function entryTasks(ply, preview, agents)
    if not preview and IsValid(ply) and ply:GTeam()==TEAM_GOC and BREACH.RoleInfo and BREACH.RoleInfo.Snapshot then
        local snapshot=BREACH.RoleInfo.Snapshot(ply)
        if not snapshot.observer and #snapshot.tasks>0 then return snapshot.tasks end
    end
    return {"撤离前引爆阿尔法核弹头"}
end
hook.Add("RXRoundUIReset","RXGocDeploymentReset",function() intro=nil end)

function BREACH.Goc.StartIntro(preview)
    BREACH.BeginDeploymentIntro(duration, preview, TEAM_GOC)
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if not preview then ply:ConCommand("stopsound") end
    local roleName = preview and role.Goc_Commander or ply:GetRoleName()
    intro = {started=RealTime(), preview=preview==true,
        roleName=GetLangRole and GetLangRole(roleName) or roleName,
        name=ply:GetNamesurvivor() or "",tasks=entryTasks(ply,preview,nil)}
    if IsValid(ply.Faction_intro) then ply.Faction_intro:Remove() end
    if IsValid(BREACH_DESC_LOGO) then BREACH_DESC_LOGO:Remove() end
    if IsValid(BREACH_DESC_PANEL) then BREACH_DESC_PANEL:Remove() end
    BREACH.Music:Play(BR_MUSIC_SPAWN_GOC)
end
concommand.Add("goc_intro_preview", function() BREACH.Goc.StartIntro(true) end)

hook.Add("PostDrawHUD", "GocDeploymentEntry", function()
    if not intro then return end
    local t = RealTime()-intro.started
    local ply = LocalPlayer()
    local liveGoc = IsValid(ply) and ply:Alive() and ply:GTeam()==TEAM_GOC
    if not intro.preview and t > 2 and (not liveGoc or
        (intro.roleSynced and intro.roleId~=ply:GetRoleName())) then
        if BREACH.RoundUI and BREACH.RoundUI.EndDeployment then
            BREACH.RoundUI.EndDeployment("role-changed")
        else intro=nil end
        return
    end
    if not intro.preview and not intro.roleSynced and t > 2 and liveGoc then
        local roleName = ply:GetRoleName()
        intro.roleId = roleName
        intro.roleName = GetLangRole and GetLangRole(roleName) or roleName
        intro.name = ply:GetNamesurvivor() or ""
        intro.tasks = entryTasks(ply,false,intro.agents)
        intro.roleSynced = true
    end
    if t >= duration then
        local preview = intro.preview
        intro = nil
        if not preview and liveGoc then
            net.Start("ProceedUnfreezeSUP")
            net.SendToServer()
            DrawNewRoleDesc()
            FadeMusic(15)
        end
        return
    end
    if BREACH.RoundUI and BREACH.RoundUI.DrawDeployment then
        BREACH.RoundUI.DrawDeployment({title="全球超自然联盟",
            roleName=(intro.preview or intro.roleSynced) and intro.roleName or "",name=intro.name,
            tasks=(intro.preview or intro.roleSynced) and intro.tasks or {},elapsed=t,duration=duration,
            preview=intro.preview,icon=emblem})
    end
end)

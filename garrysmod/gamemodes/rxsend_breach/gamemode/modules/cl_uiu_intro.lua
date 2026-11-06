BREACH.Uiu = BREACH.Uiu or {}
local intro
local duration = 20
local emblem = Material("nextoren/gui/roles_icon/fbi.png", "smooth")

local function entryTasks(ply, preview, agents)
    if not preview and IsValid(ply) and ply:GTeam()==TEAM_USA and BREACH.RoleInfo and BREACH.RoleInfo.Snapshot then
        local snapshot=BREACH.RoleInfo.Snapshot(ply)
        if not snapshot.observer and #snapshot.tasks>0 then return snapshot.tasks end
    end
    return agents and {"黑入设施系统", "刺杀设施主管获取密令", "窃取设施资料，封锁设施"} or {"黑入设施系统", "窃取设施资料，封锁设施"}
end
hook.Add("RXRoundUIReset","RXUiuDeploymentReset",function() intro=nil end)

function BREACH.Uiu.StartIntro(preview, agents)
    BREACH.BeginDeploymentIntro(duration, preview, TEAM_USA)
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if not preview then ply:ConCommand("stopsound") end
    local roleName = preview and (agents and role.UIU_Agent_Commander or role.UIU_Commander) or ply:GetRoleName()
    intro = {started=RealTime(), preview=preview==true, agents=agents==true,
        roleName=GetLangRole and GetLangRole(roleName) or roleName,
        name=ply:GetNamesurvivor() or "",tasks=entryTasks(ply,preview,agents)}
    if IsValid(ply.Faction_intro) then ply.Faction_intro:Remove() end
    if IsValid(BREACH_DESC_LOGO) then BREACH_DESC_LOGO:Remove() end
    if IsValid(BREACH_DESC_PANEL) then BREACH_DESC_PANEL:Remove() end
    BREACH.Music:Play(agents and BR_MUSIC_SPAWN_FBI_AGENTS or BR_MUSIC_SPAWN_FBI)
end
concommand.Add("uiu_intro_preview", function(_,_,args)
    BREACH.Uiu.StartIntro(true,args and (args[1]=="agents" or args[1]=="agent"))
end)

hook.Add("PostDrawHUD", "UiuDeploymentEntry", function()
    if not intro then return end
    local t = RealTime()-intro.started
    local ply = LocalPlayer()
    local liveGoc = IsValid(ply) and ply:Alive() and ply:GTeam()==TEAM_USA
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
        BREACH.RoundUI.DrawDeployment({title="特异事故处",faction="联邦调查局",
            roleName=(intro.preview or intro.roleSynced) and intro.roleName or "",name=intro.name,
            tasks=(intro.preview or intro.roleSynced) and intro.tasks or {},elapsed=t,duration=duration,
            preview=intro.preview,icon=emblem})
    end
end)

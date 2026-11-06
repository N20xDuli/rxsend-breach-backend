BREACH.SupportIntro = BREACH.SupportIntro or {}
local entry
local configs = {
    sh={team=TEAM_DZ, code="蛇之手", title="蛇之手", caption="蛇之手 / 入场",
        icon="dz", rgb={88,213,175}, task="l:tasks_sh", role=role.DZ_Commander,
        music=BR_MUSIC_SPAWN_DZ, duration=20, unfreeze=true},
    qrt={team=TEAM_QRT, code="QRT", title="快速反应部队", faction="基金会", caption="快速反应部队 / 部署",
        icon="obr", rgb={106,151,235}, task="保护并遵循安全主管的命令", role=role.QRT_Commander,
        music=BR_MUSIC_SPAWN_OBR, duration=8},
    scarlet={team=TEAM_COTSK, code="COTSK", title="猩红之子", caption="猩红之子",
        icon="scarlet", rgb={210,60,75}, task="l:tasks_cotsk", role=role.Cult_Commander,
        music=BR_MUSIC_SPAWN_CULT, duration=20, unfreeze=true},
    gru={team=TEAM_GRU, code="GRU", title="格鲁乌 P 部门", caption="格鲁乌 / P 部门",
        icon="gru", rgb={177,185,113}, task="l:tasks_gru", role=role.GRU_Commander, duration=20},
    ntf={team=TEAM_NTF, code="EPSILON-11", title="九尾狐", faction="机动特遣队", caption="机动特遣队 / 九尾狐",
        icon="ntf", rgb={100,178,245}, task="l:tasks_ntf", role=role.NTF_Commander,
        music=BR_MUSIC_SPAWN_NTF, duration=20, unfreeze=true},
    ci={team=TEAM_CHAOS, code="CI", title="混沌分裂者", caption="混沌分裂者",
        icon="chaos", rgb={99,205,120}, task="l:tasks_ci", role="CI Commander",
        music=BR_MUSIC_SPAWN_CHAOS, duration=20},
    osn={team=TEAM_OSN,title="特种任务小队",icon="obr",task="l:tasks_osn",role=role.OSN_Commander,
        music=BR_MUSIC_SPAWN_OBR,duration=20,preserveSounds=true,fadeMusic=false},
    guard={team=TEAM_GUARD,title="机动特遣队",faction="基金会",icon="mtf",task="l:tasks_evacuate_personnel_and_terminate_enemies",role=role.MTF_Guard,
        music=BR_MUSIC_SPAWN_MOG,duration=20,preserveSounds=true,fadeMusic=false}
}
for _,cfg in pairs(configs) do cfg.material=Material("nextoren/gui/roles_icon/"..cfg.icon..".png","smooth") end
local function entryTasks(cfg, ply, preview)
    if not preview and IsValid(ply) and ply:GTeam()==cfg.team and BREACH.RoleInfo and BREACH.RoleInfo.Snapshot then
        local snapshot=BREACH.RoleInfo.Snapshot(ply)
        if not snapshot.observer and #snapshot.tasks>0 then return snapshot.tasks end
    end
    return {BREACH.TranslateString(cfg.task)}
end
local entryTimers={"GuardBrief","GuardImpact","GuardLights","GuardReady"}
local function releaseGuard(entryState,switchWeapon)
    if not entryState or entryState.key~="guard" or entryState.preview then return end
    local ply=entryState.player
    hook.Remove("HUDShouldDraw","MTF_HIDEHUD")
    if not IsValid(ply) then return end
    ply.cantopeninventory=nil
    if switchWeapon and ply:Alive() and ply:GTeam()==TEAM_GUARD then
        for _,weapon in ipairs(ply:GetWeapons()) do
            if not weapon:GetClass():find("nade") and weapon:GetClass():StartWith("cw_") then
                ply.DoWeaponSwitch=weapon
                break
            end
        end
    end
end
local function clearEntry()
    for _,suffix in ipairs(entryTimers) do timer.Remove("RXSupportIntro"..suffix) end
    releaseGuard(entry,false)
    if entry and entry.key=="gru" and not entry.preview and IsValid(entry.player) then
        entry.player.NoAutoMusic=entry.oldNoAutoMusic
        entry.player.cantSeeNames=entry.oldCantSeeNames
    end
    entry=nil
end
local function entryTimer(suffix,delay,callback)
    local state=entry
    timer.Create("RXSupportIntro"..suffix,delay,1,function()
        if entry~=state or postround or (BREACH.RoundUI and BREACH.RoundUI.HasResults()) then return end
        local ply=state.player
        if not state.preview and RealTime()-state.started>2 and
            (not IsValid(ply) or not ply:Alive() or ply:GTeam()~=state.cfg.team or
                (state.roleSynced and ply:GetRoleName()~=state.roleId)) then return end
        callback(state)
    end)
end
hook.Add("RXRoundUIReset","RXSupportDeploymentReset",clearEntry)
function BREACH.SupportIntro.Start(key,preview)
    local cfg=configs[key]
    local ply=LocalPlayer()
    if not cfg or not IsValid(ply) then return end
    clearEntry()
    local roleName=preview and cfg.role or ply:GetRoleName()
    BREACH.BeginDeploymentIntro(cfg.duration, preview, cfg.team)
    entry={key=key,cfg=cfg,started=RealTime(),preview=preview==true,player=ply,
        roleName=GetLangRole and GetLangRole(roleName) or roleName,name=ply:GetNamesurvivor() or "",
        tasks=entryTasks(cfg,ply,preview)}
    if IsValid(ply.Faction_intro) then ply.Faction_intro:Remove() end
    if IsValid(BREACH_DESC_LOGO) then BREACH_DESC_LOGO:Remove() end
    if IsValid(BREACH_DESC_PANEL) then BREACH_DESC_PANEL:Remove() end
    if not preview and not cfg.preserveSounds then ply:ConCommand("stopsound") end
    if key=="gru" then
        if not preview then
            entry.oldNoAutoMusic=ply.NoAutoMusic
            entry.oldCantSeeNames=ply.cantSeeNames
            ply.NoAutoMusic=true
            ply.cantSeeNames=true
        end
        surface.PlaySound("nextoren/new_gru.wav")
    else
        if cfg.music then BREACH.Music:Play(cfg.music) end
        if key=="scarlet" then surface.PlaySound("nextoren/cultist_time_travel.ogg") end
        if key=="sh" then surface.PlaySound("nextoren/others/interdimension_travel.wav") end
    end
    if key=="guard" then
        entryTimer("GuardBrief",7,function() surface.PlaySound("nextoren/start_round/start_round_mtf.mp3") end)
        entryTimer("GuardImpact",9.3,function()
            util.ScreenShake(Vector(0,0,0),35,15,3,150)
            surface.PlaySound("nextoren/others/horror/horror_14.ogg")
        end)
        entryTimer("GuardLights",10,function(state)
            if not state.preview then BREACH.Round.GeneratorsActivated=false end
        end)
        entryTimer("GuardReady",18,function(state) releaseGuard(state,true) end)
    end
end
for _,key in ipairs({"scarlet","gru","ntf","ci","sh","qrt","osn","guard"}) do
    local factionKey=key
    concommand.Add(key.."_intro_preview",function() BREACH.SupportIntro.Start(factionKey,true) end)
end

hook.Add("PostDrawHUD","SupportDeploymentEntry",function()
    if not entry then return end
    local cfg=entry.cfg
    local t=RealTime()-entry.started
    local ply=LocalPlayer()
    local live=IsValid(ply) and ply:Alive() and ply:GTeam()==cfg.team
    if not entry.preview and t > 2 and (not live or
        (entry.roleSynced and entry.roleId~=ply:GetRoleName())) then
        if BREACH.RoundUI and BREACH.RoundUI.EndDeployment then
            BREACH.RoundUI.EndDeployment("role-changed")
        else clearEntry() end
        return
    end
    if not entry.preview and not entry.roleSynced and t > 2 and live then
        local roleName = ply:GetRoleName()
        entry.roleId = roleName
        entry.roleName = GetLangRole and GetLangRole(roleName) or roleName
        entry.name = ply:GetNamesurvivor() or ""
        entry.tasks = entryTasks(cfg,ply,false)
        entry.roleSynced = true
    end
    if t>=cfg.duration then
        local preview=entry.preview
        clearEntry()
        if not preview and live then
            if cfg.unfreeze then net.Start("ProceedUnfreezeSUP");net.SendToServer() end
            DrawNewRoleDesc()
            if cfg.music and cfg.fadeMusic~=false then FadeMusic(10) end
        end
        return
    end
    if BREACH.RoundUI and BREACH.RoundUI.DrawDeployment then
        BREACH.RoundUI.DrawDeployment({title=cfg.title,faction=cfg.faction,
            roleName=(entry.preview or entry.roleSynced) and entry.roleName or "",
            name=entry.name,tasks=(entry.preview or entry.roleSynced) and entry.tasks or {},elapsed=t,duration=cfg.duration,
            preview=entry.preview,icon=cfg.material})
    end
end)

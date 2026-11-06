-- Presentation only: the existing server death scene and spectator controls remain authoritative.
BREACH = BREACH or {}
BREACH.RoundUI = BREACH.RoundUI or {}
local R = BREACH.RoundUI
local C = {bg=Color(17,19,20,242), line=Color(63,68,67), text=Color(224,227,220),
    muted=Color(155,163,158), accent=Color(161,178,148),
    deathText=Color(232,235,229),deathMuted=Color(173,181,177),deathHint=Color(214,221,211)}
local F = {title="RXDeathTitle",body="RXDeathBody",small="RXDeathSmall",
    hero="RXDeathHero",identity="RXDeathIdentity",hint="RXDeathHint"}
local deathWash=Material("vgui/gradient-l","smooth")
R.HasObserverFeedback = true

function R.DeathLayout(width,height)
    width,height=width or ScrW(),height or ScrH()
    local s=math.Clamp(math.min(width/1920,height/1080),.7,1.25)
    local ds=math.Clamp(math.min(width/1920,height/1080),.65,1.4)
    local margin=36*s
    return {s=s,deathScale=ds,washW=math.min(width,900*ds),
        death={x=92*ds,y=height-410*ds,w=math.min(610*ds,width-188*ds),h=220*ds},
        observer={x=margin,y=height-margin-170*s,w=math.min(480*s,width-margin*2),h=170*s}}
end

local function fonts()
    local s=R.DeathLayout().s
    for name,size in pairs({title=28,body=18,small=14}) do
        surface.CreateFont(F[name],{font="Microsoft YaHei",size=math.Round(size*s),
            weight=name=="title" and 600 or 500,antialias=true,extended=true})
    end
    for name,size in pairs({hero=52,identity=20,hint=16}) do
        surface.CreateFont(F[name],{font="Microsoft YaHei",size=math.Round(size*R.DeathLayout().deathScale),
            weight=name=="hero" and 700 or 500,antialias=true,extended=true})
    end
end
fonts()

local function text(value,font,x,y,color)
    draw.SimpleText(tostring(value or ""),F[font],x,y,color or C.text,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
end

local function fit(value,font,width)
    value=utf8.force(tostring(value or ""))
    surface.SetFont(F[font])
    if surface.GetTextSize(value)<=width then return value end
    for i=utf8.len(value)-1,1,-1 do
        local short=utf8.sub(value,1,i).."…"
        if surface.GetTextSize(short)<=width then return short end
    end
    return "…"
end

local function binding(command)
    if BREACH.RoleInfo and BREACH.RoleInfo.Binding then return BREACH.RoleInfo.Binding(command) end
    local key=input.LookupBinding(command)
    if not key then return "未绑定" end
    return ({mouse1="鼠标左键",mouse2="鼠标右键",space="空格"})[key] or string.upper(key)
end

local function blocked(ply)
    if not IsValid(ply) or disablehud or preparing or postround or gui.IsGameUIVisible() then return true end
    if R.HasResults and R.HasResults() then return true end
    if ply.ShowMainMenu or ply.CameraEnabled or ply.IntroBlackOut then return true end
    if BREACH.RoleInfo and BREACH.RoleInfo.IsOpen and BREACH.RoleInfo.IsOpen() then return true end
    if BREACH.ReportUI and IsValid(BREACH.ReportUI.Panel) then return true end
    if LOUNGE_CHAT and LOUNGE_CHAT.ChatboxOpen then return true end
    if GAMEMODE.ShowScoreboard or (IsValid(INTRO_PANEL) and INTRO_PANEL:IsVisible()) then return true end
    if BREACH.IsDeploymentIntroActive and BREACH.IsDeploymentIntroActive() then return true end
    if BREACH.IsNu7TerminalOpen and BREACH.IsNu7TerminalOpen() then return true end
    if IsEQVisible and IsEQVisible() then return true end
    if IsRoleMenuVisible and IsRoleMenuVisible() then return true end
    local screenshot=GetConVar("breach_config_screenshot_mode")
    return screenshot and screenshot:GetBool()
end

local function translated(value)
    value=tostring(value or "")
    local catalog=BREACH.Localization and BREACH.Localization.Catalog()
    value=catalog and isstring(catalog[value]) and catalog[value] or
        (BREACH.TranslateString and BREACH.TranslateString(value) or value)
    value=string.Trim(value)
    return string.find(value,"l:",1,true)==1 and "" or value
end

local function identityLines(value,width)
    local lines,line={},""
    surface.SetFont(F.identity)
    value=utf8.force(tostring(value or ""))
    for i=1,utf8.len(value) do
        local char=utf8.sub(value,i,i)
        if line~="" and surface.GetTextSize(line..char)>width then
            lines[#lines+1],line=line,char
        else line=line..char end
    end
    if line~="" then lines[#lines+1]=line end
    if #lines>2 then lines[2]=fit(lines[2].."…","identity",width) end
    return lines
end

-- Kept separate from drawing so transitions can be checked without changing a player.
function R.DeathPhase(state,now,observer,alive)
    if not state or observer or now>=state.expires or (alive and now>state.started+1) then return nil end
    return now<state.displayAt and "pending" or "death"
end

function R.DeathFeedbackVisible()
    local ply=LocalPlayer()
    return IsValid(ply) and not blocked(ply) and
        R.DeathPhase(R.DeathState,CurTime(),ply:GTeam()==TEAM_SPEC,ply:Alive())=="death"
end

function R.ClearDeathFeedback()
    if IsValid(R.DeathPanel) then R.DeathPanel:Remove() end
    R.DeathPanel,R.DeathState=nil,nil
end

function R.BeginDeathFeedback()
    R.ClearDeathFeedback()
    local ply=LocalPlayer()
    if not IsValid(ply) or ply:GTeam()==TEAM_ARENA or preparing or postround then return end
    local now=CurTime()
    local roleId,teamId=ply:GetRoleName(),ply:GTeam()
    local roleName=translated(GetLangRole and GetLangRole(roleId) or roleId)
    local faction=translated(gteams and gteams.GetName and gteams.GetName(teamId))
    local identity=roleName
    if faction~="" then identity=faction..(roleName~="" and " · "..roleName or "") end
    -- Eight seconds is the duration of the existing Death_Scene server transition.
    -- It is used only to retire this visual; no countdown or respawn promise is shown.
    R.DeathState={started=now,displayAt=now+2,expires=now+8,roleId=roleId,teamId=teamId,
        faction=faction,roleName=roleName,identity=identity,status="已阵亡"}
    if BREACH.RoleInfo and BREACH.RoleInfo.Close then BREACH.RoleInfo.Close() end
    if GAMEMODE.ShowScoreboard then GAMEMODE:ScoreboardHide() end
    if IsValid(BREACH_DESC_PANEL) then BREACH_DESC_PANEL:Remove() end
    local panel=vgui.Create("DPanel")
    R.DeathPanel=panel
    panel:SetMouseInputEnabled(false)
    panel:SetKeyboardInputEnabled(false)
    panel:SetPos(0,0)
    panel:SetSize(ScrW(),ScrH())
    panel.Paint=function(self,w,h)
        local state=R.DeathState
        if not state or CurTime()<state.displayAt or blocked(LocalPlayer()) then return end
        local layout=R.DeathLayout()
        local s,content=layout.deathScale,layout.death
        local x,y=content.x,content.y
        surface.SetMaterial(deathWash)
        surface.SetDrawColor(4,7,8,170)
        surface.DrawTexturedRect(0,0,layout.washW,h)
        -- This panel owns the final transition, so removing it cannot purge a
        -- new role's independent ScreenFade effect after an early respawn.
        local fade=math.Clamp((CurTime()-(state.expires-.6))/.5,0,1)
        if fade>0 then surface.SetDrawColor(0,0,0,255*fade) surface.DrawRect(0,0,w,h) end
        local function label(value,font,xx,yy,color)
            text(value,font,xx,yy+2*s,Color(0,0,0,190))
            text(value,font,xx,yy,color)
        end
        label(fit(state.status,"hero",content.w),"hero",x,y,C.deathText)
        local lines=identityLines(state.identity,content.w)
        for i=1,math.min(#lines,2) do
            label(lines[i],"identity",x+2*s,y+(76+(i-1)*28)*s,C.deathMuted)
        end
        local extra=math.max(0,math.min(#lines,2)-1)*28*s
        surface.SetDrawColor(214,221,211,140)
        surface.DrawRect(x+2*s,y+129*s+extra,56*s,math.max(1,s))
        label("即将进入观战","hint",x+2*s,y+154*s+extra,C.deathHint)
    end
end

function R.ShowDeathFeedback(message)
    -- Ignore an old delayed callback after preparation/respawn already cleared the visual.
    if not R.DeathState then return true end
    R.DeathState.displayAt=math.max(R.DeathState.displayAt,CurTime())
    if isstring(message) and message~="" then
        R.DeathState.status=BREACH.TranslateString and BREACH.TranslateString(message) or message
    end
    return true
end

function R.ObserverSnapshot(ply)
    if not IsValid(ply) or not ply.GTeam or ply:GTeam()~=TEAM_SPEC or not ply:Alive() then return nil end
    local mode=ply:GetObserverMode()
    local following=mode==OBS_MODE_IN_EYE or mode==OBS_MODE_CHASE
    local state={mode=mode,following=following,modeLabel=mode==OBS_MODE_IN_EYE and "第一人称观战"
        or mode==OBS_MODE_CHASE and "跟随观战" or "自由观战"}
    local target=following and ply:GetObserverTarget() or nil
    if IsValid(target) and target:IsPlayer() and target~=ply and target:Alive()
        and target:Health()>0 and target:GTeam()~=TEAM_SPEC then
        -- These are the same target name/health fields the old spectator panel exposed.
        -- Never infer faction, role, equipment or killer from the observed entity.
        state.name=target:Nick()
        state.health=math.max(0,target:Health())
        state.maxHealth=math.max(1,target:GetMaxHealth())
    end
    state.modeKey=binding("+reload")
    if following then
        state.previousKey=binding("+attack")
        state.nextKey=binding("+attack2")
    end
    return state
end

hook.Add("Think","RXRoundDeathFeedbackState",function()
    if not R.DeathState then return end
    local ply=LocalPlayer()
    local observer=IsValid(ply) and ply:GTeam()==TEAM_SPEC
    local active=IsValid(ply) and ply:Alive() and ply:Health()>0 and not observer
    local changed=IsValid(ply) and CurTime()>R.DeathState.started+1 and
        (ply:GTeam()~=R.DeathState.teamId or ply:GetRoleName()~=R.DeathState.roleId)
    if not IsValid(ply) or preparing or postround or changed or
        not R.DeathPhase(R.DeathState,CurTime(),observer,active) then
        R.ClearDeathFeedback()
    end
end)

hook.Add("HUDPaint","RXRoundObserverFeedback",function()
    local ply=LocalPlayer()
    if R.DeathState or blocked(ply) or ply.BlackScreen then return end
    local state=R.ObserverSnapshot(ply)
    if not state then return end
    local layout=R.DeathLayout()
    local box,s=layout.observer,layout.s
    local x,y,w=box.x,box.y,box.w
    surface.SetDrawColor(C.bg) surface.DrawRect(x,y,w,box.h)
    surface.SetDrawColor(C.accent) surface.DrawRect(x,y,3*s,box.h)
    text(state.modeLabel,"small",x+20*s,y+16*s,C.accent)
    text(fit(state.name or (state.following and "正在切换观察目标" or "自由镜头"),"body",w-40*s),
        "body",x+20*s,y+42*s,C.text)
    if state.health then
        text("生命  "..state.health.." / "..state.maxHealth,"small",x+20*s,y+72*s,C.muted)
        local barX,barW=x+w*.53,w*.47-20*s
        surface.SetDrawColor(C.line) surface.DrawRect(barX,y+80*s,barW,3*s)
        surface.SetDrawColor(C.accent)
        surface.DrawRect(barX,y+80*s,barW*math.Clamp(state.health/state.maxHealth,0,1),3*s)
    else
        text(gamestarted and "本回合仍在进行" or "等待新回合开始","small",x+20*s,y+72*s,C.muted)
    end
    surface.SetDrawColor(C.line) surface.DrawRect(x+20*s,y+101*s,w-40*s,1)
    text(fit(state.modeKey.."  切换视角","small",w-40*s),"small",x+20*s,y+113*s,C.text)
    if state.following then
        local controls=state.previousKey.."  上一目标     "..state.nextKey.."  下一目标"
        text(fit(controls,"small",w-40*s),"small",x+20*s,y+140*s,C.muted)
    end
end)

hook.Add("OnScreenSizeChanged","RXRoundDeathFeedbackResize",function()
    fonts()
    if IsValid(R.DeathPanel) then
        R.DeathPanel:SetPos(0,0)
        R.DeathPanel:SetSize(ScrW(),ScrH())
    end
end)

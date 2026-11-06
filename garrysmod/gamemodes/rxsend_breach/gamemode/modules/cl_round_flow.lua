-- Presentation only: phase, event and deployment data come from the existing game.
BREACH = BREACH or {}
BREACH.RoundUI = BREACH.RoundUI or {}
local R = BREACH.RoundUI
local C = {bg=Color(17,19,20,245), panel=Color(23,26,27), line=Color(63,68,67),
    text=Color(224,227,220), muted=Color(155,163,158), accent=Color(161,178,148), warning=Color(208,171,112)}
R.FlowColors = C
R.Events = R.Events or {}

function R.FlowLayout(width,height)
    width,height=width or ScrW(),height or ScrH()
    local s=math.Clamp(math.min(width/1920,height/1080),.65,1.4)
    return {s=s,margin=32*s,phaseW=math.min(420*s,width-64*s),phaseH=58*s,
        eventW=math.min(370*s,width-64*s),eventY=156*s,
        deployW=math.min(610*s,width-188*s),deployH=math.min(450*s,height-100*s)}
end
local function fonts()
    local s=R.FlowLayout().s
    for name,size in pairs({Title=32,Heading=23,Body=18,Small=14,Number=40,Phase=26,
        DeployTitle=52,DeployRole=27,DeployBody=20,DeploySmall=16}) do
        surface.CreateFont("RXRound"..name,{font="Microsoft YaHei",size=math.Round(size*s),
            weight=name=="Title" and 600 or 500,antialias=true,extended=true})
    end
end
fonts()
hook.Add("OnScreenSizeChanged","RXRoundFlowFonts",fonts)

function R.FlowText(value)
    value=tostring(value or "")
    local catalog=BREACH.Localization and BREACH.Localization.Catalog()
    if catalog and isstring(catalog[value]) then return catalog[value] end
    return BREACH.TranslateString and BREACH.TranslateString(value) or value
end
function R.FlowWrap(value,font,width)
    local text=utf8.force(tostring(value or ""))
    local lines,line={},""
    surface.SetFont(font)
    for i=1,utf8.len(text) do
        local char=utf8.sub(text,i,i)
        if char=="\n" then lines[#lines+1],line=line,""
        elseif line~="" and surface.GetTextSize(line..char)>width then lines[#lines+1],line=line,char
        else line=line..char end
    end
    if line~="" then lines[#lines+1]=line end
    return lines
end
local function text(value,font,x,y,color,align)
    draw.SimpleText(value,"RXRound"..font,x,y,color or C.text,align or TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
end
local function rect(x,y,w,h,color)
    surface.SetDrawColor(color) surface.DrawRect(x,y,w,h)
end
local function lines(value,font,x,y,width,color,maxLines)
    local wrapped=R.FlowWrap(value,"RXRound"..font,width)
    local spacing=(font=="Small" and 22 or 28)*R.FlowLayout().s
    for i=1,math.min(#wrapped,maxLines or #wrapped) do
        local line=wrapped[i]
        if maxLines and i==maxLines and #wrapped>maxLines then
            line=utf8.sub(line,1,math.max(0,utf8.len(line)-1)).."…"
        end
        text(line,font,x,y+(i-1)*spacing,color)
    end
    return math.min(#wrapped,maxLines or #wrapped)*spacing
end

function R.FlowBlocked()
    local p=LocalPlayer()
    if not IsValid(p) or disablehud or p.ShowMainMenu or playing or gui.IsGameUIVisible() then return true end
    local screenshot=GetConVar("breach_config_screenshot_mode")
    if screenshot and screenshot:GetBool() then return true end
    if IsValid(INTRO_PANEL) and INTRO_PANEL:IsVisible() then return true end
    if BREACH.RoleInfo and BREACH.RoleInfo.IsOpen() then return true end
    if BREACH.ReportUI and IsValid(BREACH.ReportUI.Panel) then return true end
    if GAMEMODE.ShowScoreboard or (IsEQVisible and IsEQVisible()) or (IsRoleMenuVisible and IsRoleMenuVisible()) then return true end
    if BREACH.IsNu7TerminalOpen and BREACH.IsNu7TerminalOpen() then return true end
    if BREACH.IsDeploymentIntroActive and BREACH.IsDeploymentIntroActive() then return true end
    return false
end

function R.Notify(message,kind,duration)
    local parts={}
    if not istable(message) then message={message} end
    for _,v in ipairs(message) do
        if isstring(v) or isnumber(v) then parts[#parts+1]=R.FlowText(v) end
    end
    local value=string.Trim(table.concat(parts,""))
    if value=="" then return end
    local now=RealTime()
    kind=kind or "info"
    for _,entry in ipairs(R.Events) do
        if entry.text==value and entry.kind==kind and entry.ends>now then
            entry.ends=now+math.Clamp(tonumber(duration) or 7,2,15)
            return entry
        end
    end
    local entry={text=value,kind=kind,ends=now+math.Clamp(tonumber(duration) or 7,2,15)}
    R.Events[#R.Events+1]=entry
    while #R.Events>4 do table.remove(R.Events,1) end
    return entry
end

-- Cancel presentation only; the server still owns movement and unfreeze timing.
function R.EndDeployment(reason)
    BREACH.DeploymentIntro=nil
    hook.Run("RXRoundUIReset",reason or "deployment-ended")
end

function R.ClearTransient(reason)
    R.Events={}
    timer.Remove("RXRoundResultMusic")
    timer.Remove("RXRoundResultFade")
    R.StartNoticeUntil=nil
    R.Generation=(R.Generation or 0)+1
    if R.ClearResults then R.ClearResults() end
    if R.ClearDeathFeedback then R.ClearDeathFeedback() end
    if BREACH.RoleInfo then
        BREACH.RoleInfo.Close()
        if IsValid(BREACH_DESC_PANEL) then BREACH_DESC_PANEL:Remove() end
    end
    if IsValid(MVP_MENU) then MVP_MENU:Remove() end
    hook.Remove("HUDPaint","BottomMessage")
    timer.Remove("SetBottomMessage")
    shoulddrawescape=nil
    R.EndDeployment(reason)
end

function R.BeginPhase(phase,seconds)
    if phase=="postround" then R.EndDeployment("postround") end
    if phase=="preparing" or phase=="active" then
        R.Events={}
        if R.ClearResults then R.ClearResults() end
        if R.ClearDeathFeedback then R.ClearDeathFeedback() end
    end
    R.Phase=phase
    R.PhaseEnds=CurTime()+math.max(0,tonumber(seconds) or 0)
    if phase=="active" then R.StartNoticeUntil=RealTime()+2.5 end
end

function R.PhaseSnapshot()
    if postround or (R.HasResults and R.HasResults()) then return nil end
    if preparing then
        return {kind="preparing",title="回合开始",detail="",
            remaining=math.max(0,math.ceil(tonumber(cltime) or 0))}
    end
    if gamestarted~=true then
        local ready=GetGlobalInt("RXRoundReadyPlayers",0)
        local required=GetGlobalInt("RXRoundMinimumPlayers",0)
        local count=required>0 and ("已就绪 "..ready.." 人 · 需要 "..required.." 人") or ""
        if GetGlobalBool("EnoughPlayersCountDown",false) then
            return {kind="countdown",title="即将开局",detail="",
                remaining=math.max(0,math.ceil(GetGlobalInt("EnoughPlayersCountDownStart",CurTime())-CurTime()))}
        end
        return {kind="waiting",title="等待玩家",detail=count}
    end
    if (R.StartNoticeUntil or 0)>RealTime() then
        return {kind="active",title="回合开始",detail=""}
    end
end

-- The existing timer visibility rule still applies; ordinary phase feedback
-- yields to the nuclear countdown without making it visible to other roles.
function R.NuclearTimerVisible()
    if preparing or postround or (R.HasResults and R.HasResults()) then return false end
    local p=LocalPlayer()
    return GetGlobalBool("NukeTime",false) and IsValid(p)
        and (p:GTeam()==TEAM_SPEC or p:GTeam()==TEAM_ARENA or GetGlobalBool("AliveCanSeeRoundTime",false))
end

function R.DrawPhase(phase)
    local s=R.FlowLayout().s
    local x,y=ScrW()/2,36*s
    local alpha=phase.kind=="active" and math.Clamp(((R.StartNoticeUntil or 0)-RealTime())/.4,0,1) or 1
    local title=phase.title
    if phase.remaining then title=title.."  "..string.ToMinutesSeconds(phase.remaining) end
    -- Text and a soft shadow leave the map visible, matching the approved
    -- round-feedback direction without another fixed status card.
    draw.SimpleText(title,"RXRoundPhase",x,y+2*s,Color(0,0,0,220*alpha),TEXT_ALIGN_CENTER)
    draw.SimpleText(title,"RXRoundPhase",x,y,Color(C.text.r,C.text.g,C.text.b,255*alpha),TEXT_ALIGN_CENTER)
    if phase.detail and phase.detail~="" then
        draw.SimpleText(phase.detail,"RXRoundSmall",x,y+36*s,Color(0,0,0,220),TEXT_ALIGN_CENTER)
        draw.SimpleText(phase.detail,"RXRoundSmall",x,y+34*s,C.text,TEXT_ALIGN_CENTER)
    end
end

function R.ShowEscape(index,elapsed)
    local info=clang and clang.escapemessages and clang.escapemessages[index]
    if not info then return end
    local detail=string.Replace(info.txt or "","{t}",string.ToMinutesSeconds(math.max(0,tonumber(elapsed) or 0)))
    R.Notify({info.main or "撤离完成","\n",detail,"\n",info.txt2 or ""},"escape",12)
end

function R.DeploymentLayout(width,height)
    width,height=width or ScrW(),height or ScrH()
    local l=R.FlowLayout(width,height)
    return {s=l.s,x=94*l.s,y=height/2-216*l.s,textW=l.deployW,w=l.deployW,h=l.deployH}
end

local deploymentWash=Material("vgui/gradient-l","smooth")
function R.DeploymentBlocked()
    local p=LocalPlayer()
    if not IsValid(p) or disablehud or p.ShowMainMenu or playing or gui.IsGameUIVisible() then return true end
    if postround or (R.HasResults and R.HasResults()) then return true end
    local screenshot=GetConVar("breach_config_screenshot_mode")
    if screenshot and screenshot:GetBool() then return true end
    if IsValid(INTRO_PANEL) and INTRO_PANEL:IsVisible() then return true end
    if BREACH.ReportUI and IsValid(BREACH.ReportUI.Panel) then return true end
    if GAMEMODE.ShowScoreboard or (IsEQVisible and IsEQVisible()) or (IsRoleMenuVisible and IsRoleMenuVisible()) then return true end
    if BREACH.RoleInfo and BREACH.RoleInfo.IsOpen() then return true end
    if BREACH.IsNu7TerminalOpen and BREACH.IsNu7TerminalOpen() then return true end
    return false
end

-- The server has already assigned this player. This is their own entry brief,
-- not a promise of respawn for spectators watching a support notification.
function R.DrawDeployment(info)
    if R.DeploymentBlocked() then return end
    local l=R.DeploymentLayout()
    local s,x,y=l.s,l.x,l.y
    local duration=math.max(1,tonumber(info.duration) or 20)
    local elapsed=math.Clamp(tonumber(info.elapsed) or 0,0,duration)
    local alpha=math.Clamp(elapsed/.65,0,1)*math.Clamp((duration-elapsed)/.8,0,1)
    local function ink(c) return Color(c.r,c.g,c.b,c.a*alpha) end
    local function label(value,font,xx,yy,color)
        draw.SimpleText(value,"RXRound"..font,xx,yy+2*s,Color(0,0,0,190*alpha))
        text(value,font,xx,yy,ink(color or C.text))
    end
    local function paragraph(value,font,xx,yy,width,spacing,limit,color)
        local wrapped=R.FlowWrap(R.FlowText(value),"RXRound"..font,width)
        for i=1,math.min(#wrapped,limit) do
            local line=wrapped[i]
            if i==limit and #wrapped>limit then line=utf8.sub(line,1,math.max(0,utf8.len(line)-1)).."…" end
            label(line,font,xx,yy+(i-1)*spacing*s,color)
        end
        return math.min(#wrapped,limit)*spacing*s
    end
    surface.SetMaterial(deploymentWash)
    surface.SetDrawColor(4,7,8,235*alpha)
    surface.DrawTexturedRect(0,0,math.min(ScrW(),850*s),ScrH())
    local titleX=x
    if info.icon and not info.icon:IsError() then
        surface.SetMaterial(info.icon) surface.SetDrawColor(230,233,223,230*alpha)
        surface.DrawTexturedRect(x-14*s,y,66*s,66*s)
        titleX=x+68*s
    end
    local faction=R.FlowText(info.faction or "")
    if faction~="" and faction~=R.FlowText(info.title) then
        label(faction,"DeploySmall",titleX+4*s,y+5*s,C.muted)
    end
    local titleHeight=paragraph(info.title or "增援部队","DeployTitle",titleX,y+35*s,
        l.textW-(titleX-x),60,2,C.text)
    local roleY=y+math.max(130*s,35*s+titleHeight+28*s)
    local roleHeight=paragraph(info.roleName or "","DeployRole",x,roleY,l.textW,34,2,C.accent)
    local taskY=roleY+math.max(34*s,roleHeight)+46*s
    rect(x,taskY-26*s,280*s,math.max(1,s),ink(Color(214,217,202,85)))
    local used=0
    for _,task in ipairs(info.tasks or {}) do
        if used>=3 then break end
        local height=paragraph(task,"DeployBody",x,taskY,l.textW,28,3-used,C.text)
        used=used+math.Round(height/(28*s))
        taskY=taskY+height+8*s
    end
    -- F1 is blocked during the entry animation; make the availability explicit.
    local key=BREACH.RoleInfo and BREACH.RoleInfo.InfoKey() or "F1"
    label("部署后按 "..key.." 查看角色","DeploySmall",x,taskY+12*s,C.muted)
    if info.preview then label("界面预览","DeploySmall",x,ScrH()-54*s,C.muted) end
end

hook.Add("Think","RXRoundFlowLifecycle",function()
    if R.WasGameStarted==true and gamestarted==false then R.ClearTransient("waiting") end
    R.WasGameStarted=gamestarted
    for i=#R.Events,1,-1 do if R.Events[i].ends<=RealTime() then table.remove(R.Events,i) end end
end)

hook.Add("HUDPaint","RXRoundFlow",function()
    if R.FlowBlocked() then return end
    local p=LocalPlayer()
    if p.BlackScreen or p.IntroBlackOut or p.CameraEnabled then return end
    local l=R.FlowLayout()
    local s=l.s
    local phase=R.PhaseSnapshot()
    if phase and not R.NuclearTimerVisible() then R.DrawPhase(phase) end
    if postround or (R.HasResults and R.HasResults()) then return end
    if R.DeathFeedbackVisible and R.DeathFeedbackVisible() then return end
    local x,y=ScrW()-l.margin-l.eventW,l.eventY
    if IsValid(R.ExperiencePanel) then x=l.margin end
    for i=math.max(1,#R.Events-2),#R.Events do
        local e=R.Events[i]
        local body=R.FlowWrap(e.text,"RXRoundBody",l.eventW-36*s)
        local height=(48+math.min(4,#body)*28)*s
        local color=e.kind=="warning" and C.warning or C.accent
        rect(x,y,l.eventW,height,C.bg)
        rect(x,y,2*s,height,color)
        text(e.kind=="warning" and "警告" or e.kind=="escape" and "撤离" or "通知","Small",x+18*s,y+12*s,color)
        lines(e.text,"Body",x+18*s,y+40*s,l.eventW-36*s,C.text,4)
        y=y+height+8*s
    end
end)

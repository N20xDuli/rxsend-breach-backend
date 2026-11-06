-- Presentation only: all outcomes, ranking rows and experience come from the server.
BREACH = BREACH or {}
BREACH.RoundUI = BREACH.RoundUI or {}
local R = BREACH.RoundUI
local C = {line=Color(214,217,202,100), shadow=Color(0,0,0,220),
    text=Color(237,236,224), muted=Color(174,178,173), accent=Color(183,194,164),
    negative=Color(208,135,125)}
local F = {title="RXRoundResultTitle", heading="RXRoundResultHeading", body="RXRoundResultBody",
    small="RXRoundResultSmall", number="RXRoundResultNumber"}
R.ResultsFonts = F
local resultBadge=Material("nextoren/gui/roles_icon/scp.png","smooth")

function R.ResultsLayout(width,height)
    width,height = width or ScrW(),height or ScrH()
    local s = math.Clamp(math.min(width/1920,height/1080),.65,1.4)
    local heroWidth=math.min(1000*s,width-64*s)
    local compactWidth=math.min(900*s,width-64*s)
    return {s=s,x=0,y=0,w=width,h=height,pad=28*s,
        hero={x=(width-heroWidth)/2,y=200*s,w=heroWidth,h=124*s},
        award={x=width/2-140*s,y=353*s,w=420*s,h=118*s},
        personal={x=width-446*s,y=height-390*s,w=410*s,h=304*s},
        countdown={x=width/2-220*s,y=height-122*s,w=440*s,h=54*s},
        compactX=(width-compactWidth)/2,compactY=38*s,compactW=compactWidth,compactH=62*s,
        toastX=width-466*s,toastY=116*s,toastW=430*s,toastH=338*s}
end

local function makeFonts()
    local s = R.ResultsLayout().s
    for name,size in pairs({title=52,heading=27,body=20,small=16,number=34}) do
        surface.CreateFont(F[name],{font=name=="number" and "Bahnschrift" or "Microsoft YaHei",size=math.Round(size*s),
            weight=name=="title" and 700 or 500,antialias=true,extended=true})
    end
end
makeFonts()

local function finite(value)
    value=tonumber(value)
    if not value or value~=value or value==math.huge or value==-math.huge then return nil end
    return value
end

local names = {
    ["Military Alive Only"]="仅剩军事人员存活",["Security Alive Only"]="仅剩安保人员存活",
    ["Scientists Alive Only"]="仅剩科研人员存活",["UIU Alive Only"]="仅剩特异事故处人员存活",
    ["Class-D Alive Only"]="仅剩D级人员存活",["Serpents Alive Only"]="仅剩蛇之手成员存活",
    ["GOC Alive Only"]="仅剩全球超自然联盟人员存活",["Class-D and Chaos Alive Only"]="仅剩D级人员与混沌分裂者存活",
    ["GRU Alive Only"]="仅剩格鲁乌人员存活",["Containment Breach has been ended"]="收容失效已结束",
    ["SCP-106 Dimension kill"]="SCP-106 口袋空间击杀"
}

function R.ResultText(value,fallback)
    local text=string.Trim(tostring(value or ""))
    if names[text] then return names[text] end
    if BREACH.TranslateString then text=BREACH.TranslateString(text) end
    local catalog=BREACH.Localization and BREACH.Localization.Catalog() or {}
    text=(isstring(catalog[text]) and catalog[text]) or text
    if text=="" or string.find(text,"l:",1,true) or string.find(text,"译文缺失",1,true)
        or not string.find(text,"[\228-\233][\128-\191][\128-\191]") then return fallback or "暂无记录" end
    return text
end

-- Keep received values intact; only display formatting is rounded.
function R.NormalizeExperience(stats,previousXP)
    local out={rows={},total=0,previousXP=finite(previousXP)}
    for _,entry in ipairs(istable(stats) and stats or {}) do
        local value=istable(entry) and finite(entry.value)
        if value then
            out.rows[#out.rows+1]={reason=R.ResultText(entry.reason,"其他结算项目"),value=value}
            out.total=out.total+value
        end
    end
    return out
end

local function amount(value)
    local rounded=math.Round(value or 0,1)
    return (rounded>0 and "+" or "")..tostring(rounded)
end

local function drawText(value,font,x,y,color,align)
    draw.SimpleText(tostring(value or ""),F[font],x,y+1,C.shadow,align or TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
    draw.SimpleText(tostring(value or ""),F[font],x,y,color or C.text,align or TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
end

-- Fade only the backdrop behind the text; the current live camera remains visible.
local function wash(x,y,width,height,alpha,reverse,minimum)
    local steps=math.max(1,math.ceil(height))
    local top=math.floor(y)
    local floor=minimum or 0
    for index=0,steps-1 do
        local fraction=index/math.max(1,steps-1)
        if reverse then fraction=1-fraction end
        -- One non-overlapping screen-pixel row avoids alpha seams. Keep enough
        -- shade behind the title/highlight on bright skies, then ease to clear.
        surface.SetDrawColor(4,7,8,alpha*(floor+(1-floor)*(1-fraction*fraction*fraction)))
        surface.DrawRect(x,top+index,width,1)
    end
end

local function fit(value,font,width)
    local text=utf8.force(tostring(value or ""))
    surface.SetFont(F[font])
    if surface.GetTextSize(text)<=width then return text end
    while utf8.len(text)>0 and surface.GetTextSize(text.."…")>width do text=utf8.sub(text,1,-2) end
    return text.."…"
end

local function wrap(value,font,width)
    local lines,line={},""
    local text=utf8.force(tostring(value or ""))
    surface.SetFont(F[font])
    for i=1,utf8.len(text) do
        local char=utf8.sub(text,i,i)
        if char=="\n" then lines[#lines+1],line=line,""
        elseif line~="" and surface.GetTextSize(line..char)>width then lines[#lines+1],line=line,char
        else line=line..char end
    end
    if line~="" then lines[#lines+1]=line end
    return lines
end

local function blocked(ignoreGameUI)
    local ply=LocalPlayer()
    if not IsValid(ply) or disablehud or ply.ShowMainMenu or playing or ply.BlackScreen or ply.IntroBlackOut then return true end
    local screenshot=GetConVar("breach_config_screenshot_mode")
    if screenshot and screenshot:GetBool() then return true end
    if not ignoreGameUI and gui.IsGameUIVisible() then return true end
    if IsValid(INTRO_PANEL) and INTRO_PANEL:IsVisible() then return true end
    if BREACH.RoleInfo and BREACH.RoleInfo.IsOpen() then return true end
    if BREACH.ReportUI and (IsValid(BREACH.ReportUI.Panel)
        or (BREACH.ReportUI.BlockMainMenuUntil or 0)>RealTime()) then return true end
    if GAMEMODE.ShowScoreboard or (IsEQVisible and IsEQVisible()) or (IsRoleMenuVisible and IsRoleMenuVisible()) then return true end
    if BREACH.IsDeploymentIntroActive and BREACH.IsDeploymentIntroActive() then return true end
    if BREACH.IsNu7TerminalOpen and BREACH.IsNu7TerminalOpen() then return true end
    return false
end
R.ResultsBlocked=blocked

function R.HasResults()
    return R.Results~=nil
end

function R.IsResultsVisible()
    return R.HasResults() and not R.Results.collapsed and IsValid(R.ResultPanel)
end

local function removePanel(name)
    if IsValid(R[name]) then R[name]:Remove() end
    R[name]=nil
end

function R.ClearResults()
    removePanel("ResultPanel")
    removePanel("ExperiencePanel")
    removePanel("MVPPanel")
    R.Results,R.PersonalResult,R.MVPResult=nil,nil,nil
    R.ResultsEscapeUntil=nil
end

function R.HideResults()
    if R.Results then R.Results.collapsed=true end
end

function R.HandleResultsEscape()
    -- Escape first opens the engine menu. Ignore that menu here, but let any
    -- actual foreground panel (inventory, role menu, introduction) own its key.
    if blocked(true) then R.ResultsEscapeUntil=nil return false end
    if R.IsResultsVisible() and input.IsKeyDown(KEY_ESCAPE) then
        R.HideResults()
        R.ResultsEscapeUntil=RealTime()+.3
        gui.HideGameUI()
        return true
    end
    if (R.ResultsEscapeUntil or 0)>RealTime() then gui.HideGameUI() return true end
    return false
end

function R.PersonalResultPage(now,compact)
    local state=R.PersonalResult
    if not state or #state.rows==0 then return nil end
    local pageSize=compact and 5 or 7
    local pages=math.max(1,math.ceil(#state.rows/pageSize))
    local page=math.floor(math.max(0,(now or RealTime())-state.received)/4)%pages
    local out={rows={},total=state.total,previousXP=state.previousXP,page=page+1,pages=pages}
    for n=1,pageSize do
        local entry=state.rows[page*pageSize+n]
        if not entry then break end
        out.rows[#out.rows+1]=entry
    end
    return out
end

local function experience(x,y,width,height,s,compact)
    local page=R.PersonalResultPage(nil,compact)
    if not page then return end
    drawText("最近一次个人结算","small",x,y,C.muted)
    drawText(fit("经验 "..amount(page.total),"heading",width),"heading",x,y+28*s,page.total<0 and C.negative or C.accent)
    for index,entry in ipairs(page.rows) do
        local lineY=y+(76+(index-1)*30)*s
        drawText(fit(entry.reason,"small",width-110*s),"small",x,lineY)
        drawText(fit(amount(entry.value),"small",100*s),"small",x+width,lineY,
            entry.value<0 and C.negative or C.accent,TEXT_ALIGN_RIGHT)
    end
    if page.pages>1 then
        drawText(string.format("明细 %d / %d · 自动翻页",page.page,page.pages),"small",x,y+height-22*s,C.muted)
    end
end

local awards={
    ["l:mvp_scpkill"]={kind="scpkill",title="SCP 击杀",metric="SCP 击杀"},
    ["l:mvp_headshot"]={kind="headshot",title="精准射击",metric="爆头击杀"},
    ["l:mvp_kill"]={kind="kill",title="战斗表现",metric="击杀数"},
    ["l:mvp_heal"]={kind="heal",title="医疗支援",metric="治疗得分"},
    ["l:mvp_damage"]={kind="damage",title="伤害输出",metric="造成伤害"}
}

function R.NormalizeMVP(data)
    if not istable(data) then return nil end
    local category=awards[data.title]
    local state={title=R.ResultText(data.title,""),kind=category and category.kind,
        award=category and category.title,metric=category and category.metric,rows={}}
    -- MakeMVPMenu already sorts this category. Preserve that server order;
    -- this is a single-category highlight, not a combined player ranking.
    for _,entry in ipairs(istable(data.plys) and data.plys or {}) do
        if #state.rows>=9 then break end
        local value=istable(entry) and finite(entry.value)
        local name=istable(entry) and isstring(entry.name) and utf8.force(entry.name):gsub("%c"," ") or ""
        name=string.Trim(name)
        if value and value>0 and name~="" then
            state.rows[#state.rows+1]={name=name,value=value}
        end
    end
    return state
end

function R.ResultsHighlight(state)
    state=state or R.MVPResult
    local first=state and state.rows and state.rows[1]
    if not state or state.title=="" or not first then return nil end
    return {title=state.award or state.title,metric=state.metric or state.title,
        kind=state.kind,name=first.name,value=first.value}
end

local function ranking(x,y,width,s)
    local highlight=R.ResultsHighlight()
    if not highlight then return end
    local textX=x
    if highlight.kind=="heal" then
        surface.SetDrawColor(C.accent)
        surface.DrawRect(x+18*s,y+33*s,16*s,48*s)
        surface.DrawRect(x+2*s,y+49*s,48*s,16*s)
        textX=x+88*s
    end
    local textWidth=width-(textX-x)
    drawText(fit("本局表现 · "..highlight.title,"small",textWidth),"small",textX,y,C.accent)
    drawText(fit(highlight.name,"heading",textWidth),"heading",textX,y+32*s)
    drawText(fit(highlight.metric.."  "..tostring(math.Round(highlight.value,1)),"small",textWidth),
        "small",textX,y+77*s,C.muted)
end

function R.ResultsCountdown(now)
    local data=R.Results
    if not data then return "" end
    local remaining=math.max(0,math.ceil(data.deadline-(now or CurTime())))
    if remaining==0 then return data.restarting and "等待服务器重启" or "等待下一回合" end
    return (data.restarting and "服务器重启  " or "下一回合  ")..remaining.." 秒"
end

local function resultPanel()
    removePanel("ResultPanel")
    local panel=vgui.Create("DPanel")
    R.ResultPanel=panel
    panel:SetMouseInputEnabled(false)
    panel:SetKeyboardInputEnabled(false)
    panel:SetDrawOnTop(true)
    panel.Paint=function(self,w,h)
        local state=R.Results
        if not state or blocked() then return end
        local l=R.ResultsLayout()
        local s=l.s
        if state.collapsed then
            drawText(fit(state.text,"body",w-300*s),"body",0,12*s)
            drawText(R.ResultsCountdown(),"body",w,12*s,C.accent,TEXT_ALIGN_RIGHT)
            return
        end
        wash(0,0,w,720*s,235)
        wash(0,h-180*s,w,180*s,100,true)
        if not resultBadge:IsError() then
            surface.SetMaterial(resultBadge) surface.SetDrawColor(255,255,255,190)
            surface.DrawTexturedRect(w/2-24*s,92*s,48*s,48*s)
        end
        if game.GetMap()=="rxsend_site19-1" then
            drawText("第十九号站点","small",w/2,164*s,C.muted,TEXT_ALIGN_CENTER)
        end
        local lines=wrap(state.text,"title",l.hero.w)
        for index=1,math.min(2,#lines) do
            local line=lines[index]
            if index==2 and #lines>2 then line=fit(line.."…","title",l.hero.w) end
            drawText(line,"title",w/2,l.hero.y+(index-1)*62*s,C.text,TEXT_ALIGN_CENTER)
        end
        surface.SetDrawColor(C.line)
        surface.DrawRect(w/2-28*s,l.hero.y+(#lines>1 and 134 or 80)*s,56*s,1)
        ranking(l.award.x,l.award.y,l.award.w,s)
        if R.PersonalResultPage(nil,true) then
            wash(l.personal.x-16*s,l.personal.y-16*s,l.personal.w+32*s,l.personal.h+16*s,230,false,.85)
            experience(l.personal.x,l.personal.y,l.personal.w,l.personal.h,s,true)
        end
        local remaining=math.max(0,math.ceil(state.deadline-CurTime()))
        if remaining>0 then
            drawText(state.restarting and "服务器重启" or "下一回合","small",w/2-24*s,
                l.countdown.y+12*s,C.muted,TEXT_ALIGN_RIGHT)
            drawText(string.ToMinutesSeconds(remaining),"number",w/2-4*s,l.countdown.y)
        else
            drawText(R.ResultsCountdown(),"body",w/2,l.countdown.y+10*s,C.muted,TEXT_ALIGN_CENTER)
        end
        drawText("Esc  收起","small",w-36*s,h-40*s,C.muted,TEXT_ALIGN_RIGHT)
    end
    panel.Think=function(self)
        local state=R.Results
        if not state then self:Remove() return end
        -- A missing phase packet must not leave a previous-round panel indefinitely.
        if CurTime()>state.deadline+8 then R.ClearResults() return end
        local l=R.ResultsLayout()
        if state.collapsed then self:SetPos(l.compactX,l.compactY) self:SetSize(l.compactW,l.compactH)
        else self:SetPos(l.x,l.y) self:SetSize(l.w,l.h) end
    end
    panel:Think()
end

function R.ShowResults(result,seconds)
    -- Results outrank an unfinished deployment; keep the received XP ledger.
    if R.EndDeployment then R.EndDeployment("results") end
    if BREACH.RoleInfo then BREACH.RoleInfo.Close() end
    if GAMEMODE.ScoreboardHide then GAMEMODE:ScoreboardHide() end
    if IsValid(BREACH_DESC_PANEL) then BREACH_DESC_PANEL:Remove() end
    removePanel("ExperiencePanel")
    removePanel("MVPPanel")
    local duration=math.Clamp(finite(seconds) or 27,0,3600)
    local rounds=GetGlobalInt("RoundUntilRestart",15)
    R.Results={raw=tostring(result or ""),text=R.ResultText(result,"回合已结束"),
        received=RealTime(),deadline=CurTime()+duration,restarting=rounds<1,roundsRemaining=rounds,collapsed=false}
    resultPanel()
end

function R.ShowPersonalResult(stats,previousXP)
    local state=R.NormalizeExperience(stats,previousXP)
    state.received=RealTime()
    R.PersonalResult=state
    removePanel("ExperiencePanel")
    if R.HasResults() or #state.rows==0 then return end
    local panel=vgui.Create("DPanel")
    R.ExperiencePanel=panel
    panel:SetMouseInputEnabled(false) panel:SetKeyboardInputEnabled(false)
    panel.Paint=function(self,w,h)
        if blocked() or R.HasResults() then return end
        local s=R.ResultsLayout().s
        wash(0,0,w,h,170)
        experience(20*s,18*s,w-40*s,h-34*s,s,true)
    end
    panel.Think=function(self)
        if R.PersonalResult~=state or R.HasResults() or RealTime()>state.received+20 then self:Remove() return end
        local l=R.ResultsLayout()
        local rows=math.min(5,math.max(1,#state.rows))
        -- Only actual ledger rows create a toast; reserve a footer for pages.
        local height=(152+(rows-1)*32+(#state.rows>5 and 32 or 0))*l.s
        self:SetPos(l.toastX,l.toastY) self:SetSize(l.toastW,math.min(l.toastH,height))
    end
    panel:Think()
end

function R.ShowMVP(data)
    if not R.HasResults() and not postround then return false end
    local state=R.NormalizeMVP(data)
    if not state then return false end
    state.received=RealTime()
    R.MVPResult=state
    removePanel("MVPPanel")
    if not R.HasResults() and R.ResultsHighlight(state) then
        local panel=vgui.Create("DPanel")
        R.MVPPanel=panel
        panel:SetMouseInputEnabled(false) panel:SetKeyboardInputEnabled(false)
        panel.Paint=function(self,w,h)
            if blocked() then return end
            local s=R.ResultsLayout().s
            ranking(0,0,w,s)
        end
        panel.Think=function(self)
            if R.MVPResult~=state or R.HasResults() or not postround or RealTime()>state.received+5 then self:Remove() return end
            local l=R.ResultsLayout()
            self:SetPos(l.award.x,l.award.y) self:SetSize(l.award.w,l.award.h)
        end
        panel:Think()
    end
    return true
end

concommand.Add("rx_round_results",function()
    if not R.HasResults() then return end
    R.Results.collapsed=false
    if not IsValid(R.ResultPanel) then resultPanel() end
end)

hook.Add("OnScreenSizeChanged","RXRoundResultsResize",makeFonts)

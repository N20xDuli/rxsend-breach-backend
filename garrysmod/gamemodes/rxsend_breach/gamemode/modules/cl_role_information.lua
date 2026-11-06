-- Read-only player information. Role/task/ability authority stays with the game.
BREACH = BREACH or {}
BREACH.RoleInfo = BREACH.RoleInfo or {}
local I = BREACH.RoleInfo
local C = {bg = Color(17,19,20,250), panel = Color(23,26,27), line = Color(63,68,67),
    text = Color(224,227,220), muted = Color(155,163,158), accent = Color(161,178,148),
    selected = Color(49,59,47), warning = Color(208,171,112)}
I.Colors = C
I.Fonts = {body = "RXInfoBody", small = "RXInfoSmall", title = "RXInfoTitle", heading = "RXInfoHeading"}

function I.Layout(width, height)
    width, height = width or ScrW(), height or ScrH()
    local s = math.Clamp(math.min(width / 1920, height / 1080), .7, 1.25)
    local w, h = math.min(1000*s, width-32), math.min(690*s, height-32)
    return {w=w,h=h,s=s,x=(width-w)/2,y=(height-h)/2,sidebar=224*s,contentWidth=w-280*s}
end

local function fonts()
    local s = I.Layout().s
    for name, size in pairs({body=18,small=14,title=30,heading=21}) do
        surface.CreateFont(I.Fonts[name], {font="Microsoft YaHei", size=math.Round(size*s),
            weight=name=="title" and 600 or 500, antialias=true, extended=true})
    end
end
fonts()

function I.Wrap(value, font, width)
    local text, lines, line = utf8.force(tostring(value or "")), {}, ""
    surface.SetFont(font)
    for index=1, utf8.len(text) do
        local char = utf8.sub(text,index,index)
        if char == "\n" then lines[#lines+1], line = line, ""
        elseif line ~= "" and surface.GetTextSize(line..char) > width then
            lines[#lines+1], line = line, char
        else line = line..char end
    end
    if line ~= "" then lines[#lines+1] = line end
    return lines
end

local function text(value, font, x, y, color, align)
    draw.SimpleText(tostring(value or ""), I.Fonts[font], x, y, color or C.text,
        align or TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function I.IsOpen() return IsValid(I.Panel) and I.Panel:IsVisible() end

function I.Close()
    if IsValid(I.Panel) then I.Panel:Remove() end
    I.Panel = nil
end

function I.HandleEscape()
    if I.IsOpen() and input.IsKeyDown(KEY_ESCAPE) then
        I.BlockMainMenuUntil = RealTime()+.3
        gui.HideGameUI()
        I.Close()
        return true
    end
    if (I.BlockMainMenuUntil or 0) > RealTime() then gui.HideGameUI() return true end
    return false
end

local function blocked()
    local ply = LocalPlayer()
    if postround then return true end
    if BREACH.RoundUI and BREACH.RoundUI.HasResults and BREACH.RoundUI.HasResults() then return true end
    if not IsValid(ply) or ply.ShowMainMenu or ply.CameraEnabled or ply.BlackScreen or ply.IntroBlackOut then return true end
    if gui.IsGameUIVisible() or (IsValid(INTRO_PANEL) and INTRO_PANEL:IsVisible()) then return true end
    if BREACH.IsDeploymentIntroActive and BREACH.IsDeploymentIntroActive() then return true end
    if BREACH.IsNu7TerminalOpen and BREACH.IsNu7TerminalOpen() then return true end
    if IsEQVisible and IsEQVisible() then return true end
    if IsRoleMenuVisible and IsRoleMenuVisible() then return true end
    return false
end

local function scrollbar(scroll)
    local bar = scroll:GetVBar()
    bar:SetWide(4*I.Layout().s)
    bar:SetHideButtons(true)
    bar.Paint = function(self,w,h) surface.SetDrawColor(C.panel) surface.DrawRect(0,0,w,h) end
    bar.btnGrip.Paint = function(self,w,h) surface.SetDrawColor(C.line) surface.DrawRect(0,0,w,h) end
end

local function paragraph(parent, value, font, color, gap)
    local s, width = I.Layout().s, I.Layout().contentWidth-12*I.Layout().s
    local lines = I.Wrap(value,I.Fonts[font],width)
    local spacing = (font=="small" and 22 or 28)*s
    local row = parent:Add("DPanel")
    row:Dock(TOP)
    row:DockMargin(0,0,0,(gap or 14)*s)
    row:SetTall(math.max(1,#lines)*spacing)
    row.Paint = function()
        for index,line in ipairs(lines) do text(line,font,0,(index-1)*spacing,color) end
    end
    row.RXText, row.RXLines = value, lines
    return row
end

local function heading(parent, value)
    return paragraph(parent,value,"heading",C.text,14)
end

local function buildContent(panel, snapshot)
    panel.Scroll:Clear()
    local scroll, s = panel.Scroll, I.Layout().s
    if I.ActiveTab == "controls" then
        heading(scroll,"按键帮助")
        paragraph(scroll,"技能按键可在设置中修改。","small",C.muted,20)
        for _, control in ipairs(I.Controls(LocalPlayer())) do
            local row = scroll:Add("DPanel")
            local lines = I.Wrap(control.description or "",I.Fonts.small,I.Layout().contentWidth-192*s)
            local keys = I.Wrap(control.key,I.Fonts.small,144*s)
            row:Dock(TOP) row:DockMargin(0,0,0,8*s)
            row:SetTall(math.max(62*s,(34+#lines*22)*s,(24+#keys*22)*s))
            row.Paint = function(self,w,h)
                surface.SetDrawColor(C.panel) surface.DrawRect(0,0,w,h)
                for index,line in ipairs(keys) do text(line,"small",12*s,(14+(index-1)*22)*s,C.accent) end
                text(control.label,"body",172*s,9*s)
                for index,line in ipairs(lines) do text(line,"small",172*s,(34+(index-1)*22)*s,C.muted) end
            end
        end
    elseif I.ActiveTab == "ability" then
        heading(scroll,"技能说明")
        if #(snapshot.abilities or {}) == 0 then
            paragraph(scroll,snapshot.observer and "观战期间无法使用角色技能。" or "暂无技能说明。","body",C.muted)
        else
            for index, ability in ipairs(snapshot.abilities) do
                heading(scroll,ability.title or ability.name)
                paragraph(scroll,ability.description,"body",C.text,10)
                local row = scroll:Add("DPanel")
                row:Dock(TOP) row:DockMargin(0,0,0,26*s) row:SetTall(52*s)
                row.Paint = function(self,w,h)
                    local current = panel.Snapshot.abilities[index]
                    if not current then return end
                    surface.SetDrawColor(C.panel) surface.DrawRect(0,0,w,h)
                    local status = current.status or ""
                    if current.count ~= nil then status = status.." · 剩余 "..current.count.." 次" end
                    text(current.passive and "被动生效" or (current.key or "未绑定").."  使用","body",14*s,15*s,C.accent)
                    text(status,"small",w-14*s,18*s,C.muted,TEXT_ALIGN_RIGHT)
                end
            end
        end
    else
        heading(scroll,"角色说明")
        paragraph(scroll,snapshot.description,"body",C.text,24)
        heading(scroll,snapshot.observer and "当前状态" or "行动目标")
        if #(snapshot.tasks or {}) == 0 then
            paragraph(scroll,snapshot.observer and "等待角色分配，可继续观战。" or "暂无任务说明。","body",C.muted)
        else
            for index, task in ipairs(snapshot.tasks) do
                paragraph(scroll,string.format("%02d  %s",index,task),"body",C.text,18)
            end
        end
    end
    scroll:InvalidateLayout(true)
end

local function contentSignature(snapshot)
    local parts = {snapshot.identity,snapshot.faction,snapshot.description,tostring(snapshot.observer),I.ActiveTab}
    for _, task in ipairs(snapshot.tasks or {}) do parts[#parts+1] = task end
    for _, ability in ipairs(snapshot.abilities or {}) do
        parts[#parts+1] = (ability.title or ability.name or "")..(ability.description or "")..(ability.key or "")
    end
    if I.ActiveTab == "controls" then parts[#parts+1] = util.TableToJSON(I.Controls(LocalPlayer())) end
    return table.concat(parts,"\n")
end

function I.Open(tab)
    if not I.Snapshot or blocked() then return false end
    I.Close()
    if GAMEMODE and GAMEMODE.ScoreboardHide then GAMEMODE:ScoreboardHide() end
    if IsValid(BREACH_DESC_PANEL) then BREACH_DESC_PANEL:Remove() end
    if IsValid(BREACH_DESC_LOGO) then BREACH_DESC_LOGO:Remove() end
    timer.Remove("Remove_Desc")
    local layout = I.Layout()
    local s = layout.s
    local panel = vgui.Create("DFrame")
    I.Panel = panel
    I.ActiveTab = ({role=true,ability=true,controls=true})[tab or ""] and tab or "role"
    panel:SetSize(layout.w,layout.h) panel:SetPos(layout.x,layout.y)
    panel:SetTitle("") panel:ShowCloseButton(false) panel:SetDraggable(false)
    panel:MakePopup()
    panel.Snapshot = I.Snapshot(LocalPlayer())
    panel.OnKeyCodePressed = function(self,key)
        if key==KEY_ESCAPE then I.BlockMainMenuUntil=RealTime()+.3 gui.HideGameUI() I.Close() end
        local name=input.GetKeyName(key)
        if name and (name==input.LookupBinding("gm_showhelp") or name==input.LookupBinding("br_description")) then I.Close() end
    end
    panel.OnRemove = function(self)
        if I.Panel==self then I.Panel=nil end
    end
    panel.Paint = function(self,w,h)
        surface.SetDrawColor(C.bg) surface.DrawRect(0,0,w,h)
        surface.SetDrawColor(C.panel) surface.DrawRect(0,72*s,layout.sidebar,h-124*s)
        surface.SetDrawColor(C.line) surface.DrawRect(0,71*s,w,1)
        surface.DrawRect(0,h-52*s,w,1)
        text("角色信息","heading",24*s,23*s)
        local state = self.Snapshot
        text(state.observer and "观战" or "当前身份","small",24*s,100*s,C.accent)
        local y = 132*s
        for _,line in ipairs(I.Wrap(state.identity,I.Fonts.title,layout.sidebar-48*s)) do
            text(line,"title",24*s,y) y=y+39*s
        end
        for _,line in ipairs(I.Wrap(state.faction,I.Fonts.body,layout.sidebar-48*s)) do
            text(line,"body",24*s,y+15*s,C.muted) y=y+28*s
        end
        if state.observer then text("观战中","small",24*s,h-100*s,C.accent) end
    end
    local tabs={{"role","身份与任务"},{"ability","技能说明"},{"controls","按键帮助"}}
    panel.Tabs={}
    for index,entry in ipairs(tabs) do
        local button=vgui.Create("DButton",panel)
        button:SetText("") button:SetPos(layout.sidebar+(index-1)*154*s,12*s) button:SetSize(148*s,48*s)
        button.Paint=function(self,w,h)
            if I.ActiveTab==entry[1] or self:IsHovered() then
                surface.SetDrawColor(I.ActiveTab==entry[1] and C.selected or C.panel) surface.DrawRect(0,0,w,h)
            end
            text(entry[2],"body",w/2,13*s,I.ActiveTab==entry[1] and C.accent or C.muted,TEXT_ALIGN_CENTER)
        end
        button.DoClick=function() I.ActiveTab=entry[1] panel.Signature=nil end
        panel.Tabs[entry[1]]=button
    end
    local close=vgui.Create("DButton",panel)
    close:SetText("") close:SetPos(layout.w-132*s,layout.h-43*s) close:SetSize(108*s,34*s)
    close.Paint=function(self,w,h)
        if self:IsHovered() then surface.SetDrawColor(C.selected) surface.DrawRect(0,0,w,h) end
        text("Esc  关闭","small",w/2,7*s,C.text,TEXT_ALIGN_CENTER)
    end
    close.DoClick=I.Close
    panel.Scroll=vgui.Create("DScrollPanel",panel)
    panel.Scroll:SetPos(layout.sidebar+28*s,98*s)
    panel.Scroll:SetSize(layout.contentWidth,layout.h-174*s)
    scrollbar(panel.Scroll)
    panel.Refresh=function(self)
        self.Snapshot=I.Snapshot(LocalPlayer())
        local signature=contentSignature(self.Snapshot)
        if self.Signature~=signature then self.Signature=signature buildContent(self,self.Snapshot) end
    end
    panel.Think=function(self)
        if I.HandleEscape() then return end
        if blocked() then I.Close() return end
        if (self.NextRefresh or 0)>RealTime() then return end
        self.NextRefresh=RealTime()+.15
        self:Refresh()
    end
    panel:Refresh()
    return true
end

function I.ShowBrief()
    local ply=LocalPlayer()
    if not I.Snapshot or blocked() or I.IsOpen() or not IsValid(ply) then return end
    local noDesc=GetConVar("breach_config_no_role_description")
    local state=I.Snapshot(ply)
    if state.observer or ply.NoDesc or (noDesc and noDesc:GetBool()) then return end
    timer.Remove("Remove_Desc")
    if IsValid(BREACH_DESC_PANEL) then BREACH_DESC_PANEL:Remove() end
    if IsValid(BREACH_DESC_LOGO) then BREACH_DESC_LOGO:Remove() end
    local s=I.Layout().s
    local panel=vgui.Create("DPanel")
    BREACH_DESC_PANEL=panel
    local lines=I.Wrap(state.tasks[1] or state.description,I.Fonts.body,366*s)
    local names=I.Wrap(state.identity,I.Fonts.heading,350*s)
    local name=names[1] or "当前身份"
    if #names>1 then name=name.."…" end
    panel:SetSize(414*s,(104+math.min(#lines,3)*28)*s) panel:SetPos(36*s,90*s)
    panel:SetMouseInputEnabled(false) panel:SetKeyboardInputEnabled(false)
    panel.Expires=RealTime()+9
    panel.Paint=function(self,w,h)
        surface.SetDrawColor(C.bg) surface.DrawRect(0,0,w,h)
        surface.SetDrawColor(C.accent) surface.DrawRect(0,0,2*s,h)
        text(name,"heading",20*s,16*s)
        for index=1,math.min(#lines,3) do text(lines[index],"body",20*s,(52+(index-1)*28)*s,C.muted) end
        text(I.InfoKey().."  查看身份、任务与技能","small",20*s,h-30*s,C.accent)
    end
    panel.Think=function(self)
        local current=I.Snapshot(LocalPlayer())
        if RealTime()>self.Expires or blocked() or I.IsOpen() or current.observer
            or current.roleId~=state.roleId or current.teamId~=state.teamId then self:Remove() end
    end
end

function I.CanUseHelpBinding(ply)
    local weapon=IsValid(ply) and ply:GetActiveWeapon()
    return not (IsValid(weapon) and weapon.CW20Weapon and weapon.dt and weapon.dt.State==CW_CUSTOMIZE)
end

hook.Add("PlayerBindPress","RXRoleInformationBinding",function(ply,bind,pressed)
    if not pressed or bind~="gm_showhelp" or not I.CanUseHelpBinding(ply) then return end
    if I.IsOpen() then I.Close() else I.Open() end
    return true
end)
hook.Add("OnScreenSizeChanged","RXRoleInformationResize",function()
    local wasOpen, tab=I.IsOpen(),I.ActiveTab
    fonts()
    if IsValid(BREACH_DESC_PANEL) then BREACH_DESC_PANEL:Remove() end
    if wasOpen then I.Open(tab) end
end)

hook.Add("HUDPaint","RXRoleInformationSpectatorHint",function()
    local ply=LocalPlayer()
    if not I.InfoKey or not IsValid(ply) or ply:GTeam()~=TEAM_SPEC or I.IsOpen() or blocked() then return end
    if GAMEMODE.ShowScoreboard then return end
    local s=I.Layout().s
    draw.SimpleTextOutlined(I.InfoKey().."  角色与帮助",I.Fonts.small,ScrW()-36*s,ScrH()-36*s,
        C.muted,TEXT_ALIGN_RIGHT,TEXT_ALIGN_TOP,1,Color(0,0,0,220))
end)

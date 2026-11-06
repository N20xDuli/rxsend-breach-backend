-- Public support UI. It never requests the remote-admin player/role snapshot.
local S = {scope = "mine", page = 1, sequence = 0, draft = {kind = "report", target = "", body = ""}}
BREACH.ReportUI = BREACH.ReportUI or {}
local UI = BREACH.ReportUI
if IsValid(UI.Panel) then UI.Panel:Remove() end
function UI.BlocksMainMenu()
    return IsValid(S.frame) or (UI.BlockMainMenuUntil or 0)>RealTime()
end
local function cancelConfirmation()
    local panel = S.confirmPanel
    S.confirmPanel, S.confirmToken = nil, nil
    if IsValid(panel) then panel:Remove() end
end
local function closePanel()
    UI.BlockMainMenuUntil=RealTime()+0.3
    gui.HideGameUI()
    cancelConfirmation()
    if IsValid(S.frame) then S.frame:Close() end
end
local function escapePanel()
    if S.escapeHeld then return end
    S.escapeHeld=true
    if IsValid(S.confirmPanel) then
        cancelConfirmation()
        UI.BlockMainMenuUntil=RealTime()+0.3
        gui.HideGameUI()
        if IsValid(S.frame) then S.frame:MakePopup() end
    else closePanel() end
end
function UI.HandleEscape()
    if not input.IsKeyDown(KEY_ESCAPE) then S.escapeHeld=false
    elseif IsValid(S.frame) or S.escapeHeld then
        escapePanel() gui.HideGameUI() return true
    end
    if (UI.BlockMainMenuUntil or 0)>RealTime() then gui.HideGameUI() return true end
    return false
end
local C = {bg = Color(17,20,24), panel = Color(25,29,34), hover = Color(33,38,44),
    line = Color(54,60,67), text = Color(231,233,236), muted = Color(143,153,165),
    accent = Color(219,174,98), bad = Color(230,107,106), good = Color(125,199,167)}
local kinds = {report = "举报", appeal = "申诉", help = "求助"}
local statuses = {new = "待处理", claimed = "处理中", closed = "已结案"}
local actions = {submit = "提交", claim = "接单", reply = "回复", close = "结案", reopen = "重新打开"}
surface.CreateFont("RXReportTitle", {font = "Microsoft YaHei", size = 25, weight = 700})
surface.CreateFont("RXReportText", {font = "Microsoft YaHei", size = 17, weight = 500})
surface.CreateFont("RXReportSmall", {font = "Microsoft YaHei", size = 14, weight = 400})

local function fill(c,w,h) surface.SetDrawColor(c) surface.DrawRect(0,0,w,h) end
local function label(parent, value, height, small)
    local l = vgui.Create("DLabel",parent)
    l:Dock(TOP) l:SetTall(height or 24) l:SetFont(small and "RXReportSmall" or "RXReportText")
    l:SetTextColor(small and C.muted or C.text) l:SetText(value) return l
end
local function button(parent, value, callback, width)
    local b = vgui.Create("DButton",parent) b:SetText("") b:SetSize(width or 100,36)
    b.Paint = function(self,w,h)
        fill(self:IsHovered() and C.hover or C.panel,w,h)
        surface.SetDrawColor(C.line) surface.DrawRect(0,h-1,w,1)
        draw.SimpleText(value,"RXReportText",w/2,h/2,self:IsEnabled() and C.text or C.muted,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end
    b.Think=function(self) self:SetEnabled(not S.pending or self.RXReportAllowPending==true) end
    b.DoClick=function(...)
        if S.pending and not b.RXReportAllowPending then return end
        return callback(...)
    end
    return b
end
local function entry(parent, placeholder, value, multiline, height)
    local e = vgui.Create("DTextEntry",parent)
    e:Dock(TOP) e:DockMargin(0,0,0,8) e:SetTall(height or 36)
    e:SetFont("RXReportText") e:SetText(value or "") e:SetMultiline(multiline or false)
    e:SetUpdateOnType(true)
    e:SetDrawLanguageID(false)
    e:SetPlaceholderText(placeholder) e:SetTextColor(C.text) e:SetCursorColor(C.accent)
    e.Think=function(self) self:SetEnabled(not S.pending and self.RXReportEditable~=false) end
    e.Paint = function(self,w,h)
        fill(C.bg,w,h) surface.SetDrawColor(self:HasFocus() and C.accent or C.line) surface.DrawRect(0,h-1,w,1)
        self:DrawTextEntryText(C.text,C.accent,C.text)
        if self:GetValue()=="" and not self:HasFocus() then draw.SimpleText(placeholder,"RXReportSmall",6,8,C.muted) end
    end
    return e
end
local function stamp(value) return os.date("%m-%d %H:%M",tonumber(value) or 0) end
local function feedback(message,ok)
    S.message,S.ok = tostring(message or ""),ok
    if not IsValid(S.frame) then chat.AddText(ok==false and C.bad or C.accent,"[举报与求助] "..S.message) end
end
local request,refresh,showDetail,showNew,rebuildList
request = function(op,args,callback)
    if S.pending then feedback("正在处理上一项操作，请稍候。",false) return end
    S.sequence = (S.sequence + 1) % 65536
    local seq = S.sequence
    S.pending = {seq=seq,op=op,callback=callback,started=RealTime()}
    feedback("正在读取…")
    -- Keep sequential UI requests outside the server's short network cooldown.
    local delay = math.max(0,(S.nextSend or 0)-RealTime())
    timer.Simple(delay,function()
        if not S.pending or S.pending.seq~=seq then return end
        S.nextSend = RealTime()+0.4
        net.Start("RXReports:Request") net.WriteUInt(seq,16) net.WriteString(op)
        net.WriteString(util.TableToJSON(args or {})) net.SendToServer()
    end)
    timer.Simple(8+delay,function()
        if S.pending and S.pending.seq==seq then
            S.pending=nil feedback("请求超时。请先刷新确认记录，避免重复提交。",false)
        end
    end)
end
refresh = function()
    request("list",{scope=S.scope,page=S.page},function(data)
        S.list=data S.page=data.page or 1 S.scope=data.scope or S.scope
        if IsValid(S.queueButton) then S.queueButton:SetVisible(data.staff==true) end
        rebuildList()
        feedback("已刷新",true)
    end)
end
local function readDetail(id)
    request("detail",{id=id},function(data) showDetail(data) feedback("已读取工单 #"..data.ticket.id,true) end)
end
local function bodyPanel()
    if not IsValid(S.body) then return end
    cancelConfirmation()
    S.body:Clear()
    return S.body
end
local function rich(parent)
    local r = vgui.Create("RichText",parent) r:Dock(FILL)
    r.PerformLayout=function(self) self:SetFontInternal("RXReportText") end
    return r
end
local function append(r,value,color)
    r:InsertColorChange(color.r,color.g,color.b,255) r:AppendText(value)
end
showDetail = function(data)
    S.detail=data S.view="detail"
    for i,record in ipairs(S.list and S.list.items or {}) do
        if record.id==data.ticket.id then S.list.items[i]=data.ticket end
    end
    rebuildList()
    local body=bodyPanel() if not body then return end
    local t,caps=data.ticket,data.capabilities or {}
    label(body,"工单 #"..t.id.."  "..(kinds[t.kind] or "工单").." / "..(statuses[t.status] or "未知状态"),30)
    label(body,"提交："..t.reporter_name.."  ·  "..stamp(t.created_at),23,true)
    local assigned=t.assignee_name and t.assignee_name~="" and t.assignee_name or "等待管理员接单"
    label(body,"处理人："..assigned,23,true)
    local target=t.target_id and t.target_id~="" and ((t.target_name or "").."  "..t.target_id) or "未指定"
    local targetLabel=label(body,"对象："..target.."  ·  地图："..t.map,23,true) targetLabel:SetTooltip(target)
    local bottom=vgui.Create("DPanel",body) bottom:Dock(BOTTOM) bottom:SetTall(184) bottom.Paint=function() end
    label(bottom,"提交人可以看到这条回复。",24,true)
    local reply=entry(bottom,"补充经过、证据链接或处理说明",S.replyTicket==t.id and S.replyDraft or "",true,78)
    reply.RXReportEditable=caps.reply or caps.close or caps.reopen or false
    reply:SetEnabled(reply.RXReportEditable)
    reply.OnValueChange=function(self) S.replyTicket=t.id S.replyDraft=self:GetValue() end
    local counter=label(bottom,"",20,true)
    counter.Think=function(self) self:SetText("文本 "..#reply:GetValue().." / 1000 字节（约 333 个汉字）") end
    local row=vgui.Create("DPanel",bottom) row:Dock(TOP) row:SetTall(34) row.Paint=function() end
    for _,a in ipairs({"claim","reply","close","reopen"}) do
        if caps[a] then
            local action=a
            local b=button(row,actions[a],function()
                local value=reply:GetValue()
                local frame=S.frame
                local function send()
                    if not IsValid(frame) or S.frame~=frame or not S.detail
                        or S.detail.ticket.id~=t.id or S.detail.ticket.version~=t.version then
                        feedback("原工单页面已改变，请刷新后重试。",false) return
                    end
                    request("action",{id=t.id,version=t.version,action=action,body=value},function(updated)
                        S.replyDraft="" showDetail(updated)
                        feedback("已"..actions[action].."。",true)
                    end)
                end
                if action=="close" then
                    cancelConfirmation()
                    local token={}
                    S.confirmToken=token
                    local dialog=Derma_Query("确认结案？处理说明将发送给提交人。","确认结案","结案",function()
                        -- Derma_Query removes its own window before calling this.
                        if S.confirmToken~=token then return end
                        S.confirmPanel,S.confirmToken=nil,nil
                        send()
                    end,"取消",function()
                        cancelConfirmation()
                        if IsValid(frame) then frame:MakePopup() end
                    end)
                    S.confirmPanel=dialog
                    dialog.OnKeyCodePressed=function(_,key) if key==KEY_ESCAPE then escapePanel() end end
                else send() end
            end,action=="reopen" and 120 or 82)
            b:Dock(LEFT) b:DockMargin(0,0,6,0)
        end
    end
    local reload=button(row,"刷新",function() readDetail(t.id) end,70) reload:Dock(RIGHT)
    local history=rich(body)
    append(history,"提交内容\n",C.accent) append(history,t.body.."\n\n",C.text)
    for _,event in ipairs(data.events or {}) do
        if event.action~="submit" then
            append(history,stamp(event.created_at).."  "..event.actor_name.." · "..(actions[event.action] or "记录").."\n",C.accent)
            if event.body and event.body~="" then append(history,event.body.."\n",C.text) end
            append(history,"\n",C.text)
        end
    end
    history:GotoTextEnd()
end
showNew = function()
    if S.pending then return end
    S.view="new" S.detail=nil
    local body=bodyPanel() if not body then return end
    label(body,"提交工单",32)
    label(body,"请填写发生时间、地点和经过，可附证据链接。",28,true)
    local row=vgui.Create("DPanel",body) row:Dock(TOP) row:SetTall(44) row.Paint=function() end
    for _,id in ipairs({"report","appeal","help"}) do
        local kind=id
        local b=button(row,kinds[id],function() S.draft.kind=kind showNew() end,92)
        b:Dock(LEFT) b:DockMargin(0,0,8,8)
        b.PaintOver=function(_,w,h)
            if S.draft.kind==kind then surface.SetDrawColor(C.accent) surface.DrawRect(0,h-2,w,2) end
        end
    end
    label(body,"相关玩家（可选）",24)
    local target=entry(body,"SteamID64 或 SteamID2；不清楚可留空",S.draft.target)
    target.OnValueChange=function(self) S.draft.target=self:GetValue() end
    label(body,"具体经过 / 申诉理由",26)
    local bottom=vgui.Create("DPanel",body) bottom:Dock(BOTTOM) bottom:SetTall(116) bottom.Paint=function() end
    local counter=label(bottom,"",24,true)
    counter.Think=function(self) self:SetText("文本 "..#S.draft.body.." / 1000 字节（约 333 个汉字）") end
    label(bottom,"仅你和有权限的管理员可查看。请勿填写密码。",24,true)
    label(bottom,S.draft.kind=="appeal" and "封禁申诉暂未开放。" or "",24,true)
    local send=button(bottom,"提交",function()
        request("submit",{kind=S.draft.kind,target=S.draft.target,body=S.draft.body},function(data)
            S.draft={kind="report",target="",body=""} S.replyDraft=""
            if S.list and S.page==1 then
                table.insert(S.list.items,1,data.ticket)
                if #S.list.items>20 then table.remove(S.list.items) end
                S.list.total=(S.list.total or 0)+1
                S.list.pages=math.max(1,math.ceil(S.list.total/20))
            end
            showDetail(data) feedback("工单 #"..data.ticket.id.." 已提交。",true)
        end)
    end) send:Dock(TOP)
    local input=entry(body,"请填写具体内容",S.draft.body,true,120) input:Dock(FILL)
    input.OnValueChange=function(self) S.draft.body=self:GetValue() end
end
rebuildList = function()
    if not IsValid(S.listPanel) then return end
    S.listPanel:Clear()
    local data=S.list or {items={}}
    if #data.items==0 then label(S.listPanel,"暂无工单记录",40,true) end
    for _,ticket in ipairs(data.items) do
        local t=ticket
        local b=button(S.listPanel,"",function() readDetail(t.id) end)
        b:Dock(TOP) b:SetTall(76) b:DockMargin(0,0,0,5)
        b.Paint=function(self,w,h)
            fill(self:IsHovered() and C.hover or C.panel,w,h)
            local selected=S.detail and S.detail.ticket.id==t.id
            surface.SetDrawColor(selected and C.accent or C.line) surface.DrawRect(0,0,3,h)
            draw.SimpleText("#"..t.id.."  "..(kinds[t.kind] or "工单"),"RXReportText",12,9,C.text)
            draw.SimpleText(statuses[t.status] or "未知状态","RXReportSmall",w-10,11,t.status=="closed" and C.muted or C.accent,TEXT_ALIGN_RIGHT)
            draw.SimpleText(utf8.sub(t.reporter_name or "",1,16),"RXReportSmall",12,34,C.muted)
            draw.SimpleText(stamp(t.updated_at),"RXReportSmall",12,54,C.muted)
        end
        b:SetTooltip(t.body or "")
    end
end
function BREACH.OpenReports(target,scope)
    if IsValid(S.frame) then
        S.frame:MakePopup()
        if S.pending then return end
        if target and target~="" then S.draft.target=target showNew() end
        if scope and scope~=S.scope and not S.pending then S.scope=scope S.page=1 refresh() end
        return
    end
    S.scope=scope or "mine" S.page=1 S.pending=nil S.detail=nil S.list=nil
    local f=vgui.Create("DFrame") S.frame=f UI.Panel=f
    f:SetSize(math.min(1120,ScrW()-40),math.min(780,ScrH()-40)) f:Center()
    f:SetTitle("") f:ShowCloseButton(false) f:SetDraggable(false) f:MakePopup() f:DockPadding(18,80,18,14)
    f.Paint=function(_,w,h)
        fill(C.bg,w,h) surface.SetDrawColor(C.accent) surface.DrawRect(0,0,w,3)
        draw.SimpleText("举报与求助","RXReportTitle",20,16,C.text)
    end
    f.OnKeyCodePressed=function(self,key) if key==KEY_ESCAPE then escapePanel() end end
    f.OnRemove=function()
        cancelConfirmation()
        if UI.Panel==f then UI.Panel=nil end
        S.pending=nil S.frame=nil S.body=nil S.listPanel=nil S.queueButton=nil
        if IsValid(INTRO_PANEL) and INTRO_PANEL:IsVisible() then INTRO_PANEL:MakePopup() end
    end
    local close=button(f,"关闭",closePanel,76) close.RXReportAllowPending=true close:SetPos(f:GetWide()-96,20)
    local footer=vgui.Create("DPanel",f) footer:Dock(BOTTOM) footer:SetTall(38) footer:DockMargin(0,8,0,0)
    footer.Paint=function(_,w,h) draw.SimpleText(S.message or "","RXReportSmall",4,h/2,S.ok==false and C.bad or C.muted,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER) end
    local left=vgui.Create("DPanel",f) left:Dock(LEFT) left:SetWide(f:GetWide()<1000 and 248 or 280)
    left:DockMargin(0,0,16,0) left.Paint=function() end
    local new=button(left,"新建举报 / 申诉 / 求助",showNew) new:Dock(TOP) new:DockMargin(0,0,0,8)
    local tabs=vgui.Create("DPanel",left) tabs:Dock(TOP) tabs:SetTall(38) tabs:DockMargin(0,0,0,8) tabs.Paint=function() end
    local mine=button(tabs,"我的工单",function() if S.pending then return end S.scope="mine" S.page=1 refresh() end,120) mine:Dock(LEFT)
    local queue=button(tabs,"管理队列",function() if S.pending then return end S.scope="queue" S.page=1 refresh() end,120) queue:Dock(RIGHT) queue:SetVisible(false) S.queueButton=queue
    for b,scopeID in pairs({[mine]="mine",[queue]="queue"}) do
        local selectedScope=scopeID
        b.PaintOver=function(_,w,h)
            if S.scope==selectedScope then surface.SetDrawColor(C.accent) surface.DrawRect(0,h-2,w,2) end
        end
    end
    local pages=vgui.Create("DPanel",left) pages:Dock(BOTTOM) pages:SetTall(38) pages.Paint=function(_,w,h)
        draw.SimpleText(S.page.." / "..((S.list and S.list.pages) or 1),"RXReportSmall",w/2,h/2,C.muted,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end
    button(pages,"上一页",function() if not S.pending and S.page>1 then S.page=S.page-1 refresh() end end,75):Dock(LEFT)
    button(pages,"下一页",function() if not S.pending and S.list and S.page<S.list.pages then S.page=S.page+1 refresh() end end,75):Dock(RIGHT)
    S.listPanel=vgui.Create("DScrollPanel",left) S.listPanel:Dock(FILL)
    S.body=vgui.Create("DPanel",f) S.body:Dock(FILL) S.body:DockPadding(14,8,14,10) S.body.Paint=function(_,w,h) fill(C.panel,w,h) end
    if target then S.draft.target=target end
    showNew() refresh()
end
concommand.Add("br_report",function() BREACH.OpenReports() end)
hook.Add("OnScreenSizeChanged","RXReports:Resize",closePanel)
hook.Add("BrScoreboardMenu","RXReports:Target",function(menu)
    if IsValid(menu.Player) and not menu.Player:IsBot() then
        local id=menu.Player:SteamID64()
        menu:AddOption("举报此玩家",function() BREACH.OpenReports(id) end)
    end
end)
net.Receive("RXReports:Open",function() BREACH.OpenReports() end)
net.Receive("RXReports:Notify",function() feedback(net.ReadString(),true) end)
net.Receive("RXReports:Response",function()
    local seq,op,ok,length=net.ReadUInt(16),net.ReadString(),net.ReadBool(),net.ReadUInt(16)
    if length>60000 then return end
    local raw=util.Decompress(net.ReadData(length),120000)
    local data=raw and util.JSONToTable(raw)
    if not data or not S.pending or S.pending.seq~=seq or (S.pending.op~=op and (ok or op~="")) then return end
    local callback=S.pending.callback S.pending=nil
    if not ok then feedback(data.message or "操作失败，请刷新后重试。",false) return end
    if IsValid(S.frame) then callback(data) end
end)

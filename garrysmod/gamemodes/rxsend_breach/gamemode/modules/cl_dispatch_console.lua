BREACH = BREACH or {}

local C = {
    bg = Color(9, 16, 26, 250), card = Color(17, 29, 43), edge = Color(43, 63, 83),
    ink = Color(230, 240, 250), soft = Color(133, 157, 180), blue = Color(98, 177, 246),
    hover = Color(23, 42, 62), green = Color(104, 213, 176), amber = Color(238, 189, 110),
}

function BREACH.OpenDispatchConsole(intercom)
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() or ply:GetRoleName() ~= role.Dispatcher then return end
    if not IsValid(intercom) or intercom:GetClass() ~= "object_intercom" then return end
    local old = BREACH.DispatchSpecial and BREACH.DispatchSpecial.MainPanel
    if IsValid(old) then
        if IsValid(old.Disclaimer) then old.Disclaimer:Remove() end
        old:Remove()
    end
    BREACH.DispatchSpecial = {}
    local scale = math.min(1, (ScrW() - 40) / 900, (ScrH() - 40) / 550)
    local function S(n) return math.floor(n * scale + .5) end
    for name, spec in pairs({Title={25,700}, Heading={21,650}, Body={16,500}, Small={13,500}, Code={12,600}}) do
        surface.CreateFont("RXDispatch" .. name, {font="Microsoft YaHei", size=S(spec[1]), weight=spec[2], extended=true})
    end
    local frame = vgui.Create("DFrame")
    BREACH.DispatchSpecial.MainPanel = frame
    frame:SetSize(S(900), S(550)); frame:Center()
    frame:SetTitle(""); frame:ShowCloseButton(false); frame:SetDraggable(false)
    frame:SetDeleteOnClose(true); frame:MakePopup()
    local function text(label, font, x, y, color, ax, ay)
        draw.SimpleText(label, "RXDispatch" .. font, S(x), S(y), color or C.ink, ax or TEXT_ALIGN_LEFT, ay or TEXT_ALIGN_TOP)
    end
    local function box(x,y,w,h,color)
        draw.RoundedBox(S(7), S(x), S(y), S(w), S(h), color)
    end
    frame.Paint = function(self, w, h)
        box(0,0,900,550,C.bg)
        surface.SetDrawColor(C.edge); surface.DrawOutlinedRect(0,0,w,h,1)
        text("设施 / 调度", "Code",24,22,C.blue)
        text("设施调度控制台", "Title",24,43)
        text("广播 · 监控 · 支援协调", "Small",24,79,C.soft)
        box(706,31,119,27,Color(17,45,43))
        text("●  链路已连接", "Small",765,44,C.green,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
        surface.SetDrawColor(C.edge); surface.DrawRect(S(24),S(102),S(852),1)
        text("基金会 / 调度中心", "Code",24,518,C.soft)
        text("ESC / 退格 关闭", "Small",876,518,C.soft,TEXT_ALIGN_RIGHT)
    end
    frame.OnKeyCodePressed = function(self,key)
        if key == KEY_ESCAPE or key == KEY_BACKSPACE then self:Close() end
    end
    frame.Think = function(self)
        if not IsValid(ply) or not ply:Alive() or ply:GetRoleName() ~= role.Dispatcher
            or not IsValid(intercom) or ply:GetPos():DistToSqr(intercom:GetPos()) > 150 * 150 then self:Close() end
    end
    frame.OnRemove = function(self)
        if BREACH.DispatchSpecial.MainPanel == self then BREACH.DispatchSpecial = {} end
    end
    local function send(action)
        if frame.Sent or not IsValid(frame) or not IsValid(intercom) then return end
        frame.Sent = true
        net.Start("IntercomAction"); net.WriteEntity(intercom); net.WriteString(action); net.SendToServer()
        frame:Close()
    end
    local close = vgui.Create("DButton",frame)
    close:SetPos(S(841),S(28)); close:SetSize(S(35),S(35)); close:SetText("")
    close.Paint = function(self) box(0,0,35,35,self:IsHovered() and C.hover or C.card);text("×","Heading",17,16,C.soft,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER) end
    close.DoClick = function() frame:Close() end
    local function actionCard(action,x,y,w,h,paint,enabled)
        local b = vgui.Create("DButton",frame)
        b:SetPos(S(x),S(y)); b:SetSize(S(w),S(h)); b:SetText("")
        b.Paint = function(self)
            box(0,0,w,h,self:IsHovered() and C.hover or C.card)
            paint(self)
        end
        b.DoClick = function() if not enabled or enabled() then send(action) end end
        return b
    end
    actionCard("camera",24,116,544,116,function()
        text("01 / 监控网络","Code",20,16,C.blue)
        text("设施摄像头","Heading",20,42)
        text("接入监控画面，切换镜头查看设施情况","Body",20,76,C.soft)
        text("进入监控  →","Small",524,23,C.blue,TEXT_ALIGN_RIGHT)
    end)
    actionCard("transmit",24,246,544,116,function()
        local status = intercom:GetStatus()
        local live = status == "Transmitting"
        local cooling = status == "Cooldown"
        text("02 / 设施广播","Code",20,16,C.blue)
        text(live and "结束当前广播" or "开启设施广播","Heading",20,42)
        text(cooling and ("广播冷却中 · 剩余 " .. intercom:GetWTFTimer() .. " 秒")
            or (live and ("正在广播 · 剩余 " .. intercom:GetWTFTimer() .. " 秒") or "广播持续 20 秒 · 结束后冷却 120 秒"),"Body",20,76,C.soft)
        text(cooling and "冷却中" or (live and "结束传输  ■" or "开始传输  →"),"Small",524,23,cooling and C.amber or C.green,TEXT_ALIGN_RIGHT)
    end,function() return intercom:GetStatus() ~= "Cooldown" end)
    local categories = {{"live","全部幸存者","办公区人员总数"},{"sci","科研人员","办公区科研人数"},{"mil","武装人员","办公区武装人数"}}
    for i,entry in ipairs(categories) do
        local item = entry
        actionCard(item[1],24+(i-1)*184,392,176,96,function()
            text("人数查询","Code",16,13,C.soft)
            text(item[2],"Body",16,35)
            text("查看终端  →","Small",16,65,C.blue)
        end)
    end
    local support = vgui.Create("DPanel",frame)
    support:SetPos(S(592),S(116));support:SetSize(S(284),S(372))
    support.Paint = function()
        box(0,0,284,372,C.card)
        box(0,0,284,4,C.blue)
        text("03 / 紧急增援","Code",20,22,C.blue)
        text("落锤特遣大队","Code",20,57,C.soft)
        text("落锤支援","Title",20,80)
        text("重夺设施控制权","Body",20,120,C.soft)
        surface.SetDrawColor(C.edge);surface.DrawRect(S(20),S(158),S(244),1)
        text("呼叫条件","Small",20,176,C.blue)
        text("基金会存活少于 5 人","Body",20,202)
        text("或人数不足敌方的 20%","Body",20,229)
        text("每局一次 · 成功部署后消耗","Small",20,270,C.soft)
        text("支援人数随本局总人数缩放","Small",20,292,C.soft)
    end
    actionCard("nu7",612,440,244,32,function(self)
        box(0,0,244,32,self:IsHovered() and Color(58,119,172) or Color(37,86,129))
        text("请求落锤支援  →","Body",122,16,C.ink,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end)
end

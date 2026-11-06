local state = {selected = {}, logs = {}, tab = "players"}
local C = {bg = Color(17, 20, 24), panel = Color(25, 29, 34), raised = Color(33, 38, 44),
    line = Color(54, 60, 67), text = Color(231, 233, 236), muted = Color(143, 153, 165),
    accent = Color(219, 174, 98), bad = Color(230, 107, 106), good = Color(125, 199, 167)}
surface.CreateFont("BreachRA:Title", {font = "Microsoft YaHei", size = 27, weight = 700})
surface.CreateFont("BreachRA:Text", {font = "Microsoft YaHei", size = 17, weight = 500})
surface.CreateFont("BreachRA:Small", {font = "Microsoft YaHei", size = 14, weight = 400})
surface.CreateFont("BreachRA:Mono", {font = "Consolas", size = 14, weight = 500})

local function rect(color, x, y, w, h)
    surface.SetDrawColor(color)
    surface.DrawRect(x, y, w, h)
end
local function text(label, x, y, font, color)
    draw.SimpleText(label, font or "BreachRA:Text", x, y, color or C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end
local function roleName(name)
    name = tostring(name or "Unknown")
    return GetLangRole and GetLangRole(name) or name
end
local function countSelected()
    local count = 0
    for _ in pairs(state.selected) do count = count + 1 end
    return count
end
local function log(message, ok)
    state.logs[#state.logs + 1] = {message = message, ok = ok, time = os.date("%H:%M:%S")}
    if #state.logs > 60 then table.remove(state.logs, 1) end
    if IsValid(state.logPanel) then
        state.logPanel:InsertColorChange(C.muted.r, C.muted.g, C.muted.b, 255)
        state.logPanel:AppendText(os.date("%H:%M:%S") .. "  ")
        local color = ok == false and C.bad or C.good
        state.logPanel:InsertColorChange(color.r, color.g, color.b, 255)
        state.logPanel:AppendText(message .. "\n")
        state.logPanel:GotoTextEnd()
    end
end
local function button(parent, label, callback, action)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b:SetTall(40)
    b.Paint = function(self, w, h)
        local permitted = not action or (state.data and state.data.permissions[action])
        local active = self:IsHovered() and permitted
        rect(active and C.raised or C.panel, 0, 0, w, h)
        rect(active and C.accent or C.line, 0, h - 1, w, 1)
        draw.SimpleText(label, "BreachRA:Text", w / 2, h / 2,
            permitted and C.text or C.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if not permitted then text("锁", w - 22, 3, "BreachRA:Small", C.muted) end
    end
    b.DoClick = function()
        if action and not (state.data and state.data.permissions[action]) then log("无权执行此操作。", false) return end
        callback()
    end
    return b
end
local function entry(parent, placeholder, default)
    local e = vgui.Create("DTextEntry", parent)
    e:SetFont("BreachRA:Text")
    e:SetText(default or "")
    e:SetPlaceholderText(placeholder)
    e:SetTall(38)
    e.Paint = function(self, w, h)
        rect(C.bg, 0, 0, w, h)
        rect(self:HasFocus() and C.accent or C.line, 0, h - 1, w, 1)
        self:DrawTextEntryText(C.text, C.accent, C.text)
        if self:GetValue() == "" and not self:HasFocus() then text(placeholder, 7, 9, "BreachRA:Small", C.muted) end
    end
    return e
end
local function request()
    if (state.nextRequest or 0) > CurTime() then return end
    state.nextRequest = CurTime() + 1.1
    net.Start("BreachRA:Request")
    net.SendToServer()
end
local function execute(id, value, reason)
    local action = BREACH.RemoteAdmin.Actions[id]
    local ids, names = {}, {}
    if action.targets then
        for _, p in ipairs(state.data.players) do
            if state.selected[p.id] then ids[#ids + 1] = p.id names[#names + 1] = p.name end
        end
        if #ids == 0 then log("请先在左侧选择玩家。", false) return end
        if #ids > 64 then log("一次最多选择64名玩家。", false) return end
        if action.single and #ids ~= 1 then log("此操作一次只能选择一名玩家。", false) return end
    end
    local function send()
        net.Start("BreachRA:Action")
        net.WriteString(id)
        net.WriteUInt(#ids, 7)
        for _, uid in ipairs(ids) do net.WriteUInt(uid, 16) end
        net.WriteString(value or "")
        net.WriteString(reason or "")
        net.SendToServer()
    end
    if action.confirm then
        Derma_Query(action.name .. "\n" .. (action.targets and table.concat(names, "、") or (action.kind == "group_permission" and ("权限组：" .. value) or "当前服务器"))
            .. (reason and reason ~= "" and ("\n原因：" .. reason) or ""), "确认操作", "执行", send, "取消")
    else send() end
end

local function section(parent, title, subtitle, height)
    local p = vgui.Create("DPanel", parent)
    p:Dock(TOP)
    p:DockMargin(0, 0, 0, 12)
    p:SetTall(height)
    p:DockPadding(16, subtitle and 64 or 48, 16, 12)
    p.Paint = function(_, w, h)
        rect(C.panel, 0, 0, w, h)
        text(title, 16, 14)
        if subtitle then text(subtitle, 16, 39, "BreachRA:Small", C.muted) end
    end
    return p
end
local function grid(parent, rows)
    local g = vgui.Create("DIconLayout", parent)
    g:Dock(FILL)
    g:SetSpaceX(8)
    g:SetSpaceY(8)
    for _, row in ipairs(rows) do button(g, row[1], row[2], row[3]):SetSize(240, 40) end
    g.PerformLayout = function(self)
        local w = math.max(100, (self:GetWide() - 8) / 2)
        for _, child in ipairs(self:GetChildren()) do child:SetSize(w, 40) end
        self:LayoutIcons_TOP()
    end
    return g
end

local function playersTab(body)
    local reports = button(body, "举报工单 / 接单与处理", function()
        if IsValid(state.frame) then state.frame:Close() end
        BREACH.OpenReports(nil, "queue")
    end)
    reports:Dock(TOP) reports:DockMargin(0, 0, 0, 12)
    if state.data.permissions.grant_admin or state.data.permissions.revoke_admin then
        local accounts = section(body, "管理员授权", "选择一名玩家；撤销后恢复普通玩家身份", 116)
        grid(accounts, {
            {"授予管理员", function() execute("grant_admin") end, "grant_admin"},
            {"撤销管理员", function() execute("revoke_admin") end, "revoke_admin"},
        })
    end
    local a = section(body, "玩家操作", "操作应用于左侧选中的玩家", 232)
    local rows = {}
    for _, id in ipairs({"bring", "goto_player", "god", "ungod", "noclip", "slay"}) do
        local action = id
        rows[#rows + 1] = {BREACH.RemoteAdmin.Actions[action].name, function() execute(action) end, action}
    end
    grid(a, rows)
    local hp = section(body, "生命值", nil, 102)
    local apply = button(hp, "设置生命值", function() execute("hp", state.hp:GetValue()) end, "hp")
    apply:Dock(RIGHT) apply:SetWide(160) apply:DockMargin(10, 0, 0, 0)
    state.hp = entry(hp, "生命值 1–10000", "100") state.hp:Dock(FILL)
    local moderation = section(body, "纪律管理", "踢出、封禁和禁言一次只操作一名玩家", 286)
    local input = vgui.Create("DPanel", moderation) input:Dock(TOP) input:SetTall(40) input:DockMargin(0, 0, 0, 10) input.Paint = function() end
    state.minutes = entry(input, "分钟，0为永久", "10") state.minutes:Dock(LEFT) state.minutes:SetWide(170) state.minutes:DockMargin(0, 0, 10, 0)
    state.reason = entry(input, "填写原因") state.reason:Dock(FILL)
    rows = {}
    for _, id in ipairs({"kick", "ban", "gag", "ungag", "mute", "unmute"}) do
        local action = id
        rows[#rows + 1] = {BREACH.RemoteAdmin.Actions[action].name, function()
            execute(action, state.minutes:GetValue(), state.reason:GetValue())
        end, action}
    end
    grid(moderation, rows)
end

local factionNames = {NU7 = "落锤", FBI_AGENTS = "UIU 特工组", FBI = "UIU 陆军组", NTF = "九尾狐", CHAOS = "混沌分裂者",
    GOC = "全球超自然联盟", GRU = "GRU", DZ = "蛇之手", COTSK = "猩红之子", OBR = "QRT", SCP = "SCP"}
local function rolesTab(body)
    local dummy = section(body, "Dummy 测试玩家", "使用当前所选角色，未选择时默认为九尾狐士兵；在准星位置创建", 104)
    local spawn = button(dummy, "刷 Dummy", function() execute("dummy", state.role or role.NTF_Soldier) end, "dummy")
    spawn:Dock(FILL)
    local top = section(body, "角色管理", "设置角色会重置目标的装备和属性，并保留当前位置", 114)
    local apply = button(top, "应用所选角色", function()
        if not state.role then log("请选择一个角色。", false) return end
        execute("role", state.role)
    end, "role")
    apply:Dock(RIGHT) apply:SetWide(175) apply:DockMargin(10, 0, 0, 0)
    local filter = entry(top, "搜索角色 / 阵营") filter:Dock(FILL)
    local list = vgui.Create("DPanel", body) list:Dock(TOP) list.Paint = function() end
    local function rebuild()
        list:Clear()
        local search = string.lower(filter:GetValue())
        local y = 0
        for _, r in ipairs(state.data.roles) do
            local name = roleName(r.id)
            local group = factionNames[r.group] or r.group
            if search == "" or string.find(string.lower(name .. " " .. group .. " " .. r.id), search, 1, true) then
                local id = r.id
                local row = button(list, "", function() state.role = id end)
                row:SetPos(0, y) row:SetTall(56)
                row.Paint = function(self, w, h)
                    rect(self:IsHovered() and C.raised or C.panel, 0, 0, w, h)
                    rect(state.role == id and C.accent or C.line, 0, 0, 3, h)
                    text(name, 16, 7)
                    text(group .. "  /  " .. id, 16, 32, "BreachRA:Small", C.muted)
                    if state.role == id then text("已选", w - 52, 18, "BreachRA:Small", C.accent) end
                end
                row.Think = function(self) self:SetWide(list:GetWide()) end
                y = y + 62
            end
        end
        list:SetTall(y)
    end
    filter.OnValueChange = rebuild
    rebuild()
end

local function serverTab(body)
    local supports = section(body, "支援调度", "从观察者中分配支援；UIU 首波为静默特工组", 318)
    local rows = {}
    for _, s in ipairs(BREACH.RemoteAdmin.Supports) do
        local id = s.id
        rows[#rows + 1] = {s.name, function() execute("support", id) end, "support"}
    end
    grid(supports, rows)
    local round = section(body, "回合管理", "执行前会显示确认窗口", 170)
    grid(round, {{"强制开始对局", function() execute("force_start") end, "force_start"}, {"重启当前回合", function() execute("restart_round") end, "restart_round"},
        {"重启游戏", function() execute("restart_game") end, "restart_game"}})
end

local function previewTab(body)
    local p = section(body, "入场动画预览", "仅在你自己的客户端播放，不刷人、不触发设施广播", 318)
    local rows = {}
    for _, cfg in ipairs({{"落锤", "nu7_intro_preview"}, {"全球超自然联盟", "goc_intro_preview"},
        {"UIU 特工组", "uiu_intro_preview", "agents"}, {"UIU 陆军组", "uiu_intro_preview"},
        {"九尾狐", "ntf_intro_preview"}, {"混沌分裂者", "ci_intro_preview"},
        {"GRU", "gru_intro_preview"}, {"猩红之子", "scarlet_intro_preview"},
        {"蛇之手", "sh_intro_preview"}, {"QRT", "qrt_intro_preview"}}) do
        local command, arg = cfg[2], cfg[3]
        rows[#rows + 1] = {cfg[1], function()
            state.frame:Close()
            if arg then RunConsoleCommand(command, arg) else RunConsoleCommand(command) end
        end}
    end
    grid(p, rows)
end

local function permissionsTab(body)
    local groups = state.data.groups or {}
    if not state.data.permissions.group_allow and not state.data.permissions.group_deny then
        section(body, "权限组", "需要 ULX 的 groupallow 或 groupdeny 权限", 100)
        return
    end
    local select = section(body, "选择权限组", "撤销只移除本组直接权限；从父组继承的权限仍然有效", 116)
    local names = {}
    for name in pairs(groups) do names[#names + 1] = name end
    table.sort(names)
    if not groups[state.permissionGroup] then state.permissionGroup = names[1] end
    local combo = vgui.Create("DComboBox", select)
    combo:Dock(FILL) combo:SetValue(state.permissionGroup or "没有权限组")
    for _, name in ipairs(names) do combo:AddChoice(name, name) end
    local filterPanel = section(body, "搜索权限", nil, 102)
    local filter = entry(filterPanel, "命令名或权限说明", state.permissionFilter) filter:Dock(FILL)
    local list = vgui.Create("DPanel", body) list:Dock(TOP) list.Paint = function() end
    local function inherited(group, access, visited)
        if not group or visited[group] then return nil end
        visited[group] = true
        local data = groups[group]
        if not data then return nil end
        if data.direct[access] ~= nil then return group end
        return inherited(data.inherit, access, visited)
    end
    local function rebuild()
        list:Clear()
        local group = state.permissionGroup
        local current = groups[group]
        if not current then list:SetTall(0) return end
        local search, y = string.lower(filter:GetValue()), 0
        for _, permission in ipairs(state.data.accesses or {}) do
            if search == "" or string.find(string.lower(permission.id .. " " .. permission.description), search, 1, true) then
                local access = permission.id
                local direct = current.direct[access] ~= nil
                local source = inherited(current.inherit, access, {})
                local label = direct and "本组直接授权" or (source and ("继承自 " .. source) or "未授权")
                local tag = current.direct[access]
                if isstring(tag) then label = label .. " · 限制：" .. tag end
                local row = vgui.Create("DPanel", list);row:SetPos(0,y);row:SetTall(90);row:DockPadding(12,43,12,7)
                row.Paint = function(self,w,h)
                    rect(C.panel,0,0,w,h)
                    text(access,12,7,"BreachRA:Mono")
                    text(label,12,26,"BreachRA:Small",C.muted)
                end
                row:SetTooltip(permission.description)
                row.Think = function(self) self:SetWide(list:GetWide()) end
                local revoke = button(row,"撤销直接权限",function() execute("group_deny",group,access) end,"group_deny")
                revoke:Dock(RIGHT) revoke:SetWide(150) revoke:SetEnabled(direct)
                local grant = button(row,"授予组权限",function() execute("group_allow",group,access) end,"group_allow")
                grant:Dock(RIGHT) grant:SetWide(150) grant:DockMargin(0,0,8,0) grant:SetEnabled(not direct)
                y=y+96
            end
        end
        list:SetTall(y)
    end
    combo.OnSelect=function(_,_,_,group) state.permissionGroup=group rebuild() end
    filter.OnValueChange=function() state.permissionFilter=filter:GetValue() rebuild() end
    rebuild()
end

local tabNames = {players = "玩家操作", roles = "角色管理", server = "服务器", preview = "动画预览", permissions = "权限组"}
local function buildTab()
    if not IsValid(state.body) then return end
    local scroll = state.body:GetVBar():GetScroll()
    state.body:Clear()
    local builders = {players = playersTab, roles = rolesTab, server = serverTab, preview = previewTab, permissions = permissionsTab}
    builders[state.tab](state.body)
    state.body:GetVBar():SetScroll(scroll)
end
local function rebuildPlayers()
    if not IsValid(state.playerList) then return end
    local scroll = state.playerList:GetVBar():GetScroll()
    state.playerList:Clear()
    local valid = {}
    for _, p in ipairs(state.data.players) do valid[p.id] = true end
    for id in pairs(state.selected) do if not valid[id] then state.selected[id] = nil end end
    local search = string.lower(state.search:GetValue())
    for _, p in ipairs(state.data.players) do
        if search == "" or string.find(string.lower(p.name .. " " .. p.id .. " " .. p.steam .. " " .. roleName(p.role)), search, 1, true) then
            local data = p
            local row = button(state.playerList, "", function() state.selected[data.id] = not state.selected[data.id] or nil end)
            row:Dock(TOP) row:SetTall(70) row:DockMargin(0, 0, 0, 5)
            row.Paint = function(self, w, h)
                local selected = state.selected[data.id]
                rect(selected and C.raised or C.panel, 0, 0, w, h)
                rect(selected and C.accent or C.line, 0, 0, 3, h)
                text(data.name, 14, 9)
                text(roleName(data.role), 14, 34, "BreachRA:Small", C.muted)
                text("#" .. data.id .. "  ·  " .. data.hp .. " HP  ·  " .. data.ping .. " ms", 14, 52, "BreachRA:Mono", C.muted)
                if selected then text("✓", w - 25, 10, "BreachRA:Text", C.accent) end
            end
            row:SetTooltip(data.name .. "\n" .. data.steam .. "\n" .. data.group)
        end
    end
    state.playerList:GetVBar():SetScroll(scroll)
end

local function open()
    if IsValid(state.frame) then state.frame:MakePopup() return end
    local frame = vgui.Create("DFrame") state.frame = frame
    frame:SetSize(math.min(1360, ScrW() * 0.94), math.min(930, ScrH() * 0.94))
    frame:Center() frame:SetTitle("") frame:ShowCloseButton(false) frame:SetDraggable(false) frame:MakePopup()
    frame:DockPadding(18, 94, 18, 16)
    frame.Paint = function(_, w, h)
        rect(C.bg, 0, 0, w, h) rect(C.accent, 0, 0, w, 3)
        text("远程管理", 22, 17, "BreachRA:Title")
        text("收容失效 / 管理终端", 23, 53, "BreachRA:Small", C.muted)
        local info = state.data.map .. "  ·  " .. #state.data.players .. "/" .. state.data.maxplayers .. " 在线"
        text(info, w > 950 and 330 or 23, w > 950 and 25 or 76, "BreachRA:Mono", C.muted)
    end
    frame.OnKeyCodePressed = function(self, key) if key == KEY_ESCAPE then self:Close() end end
    local close = button(frame, "关闭", function() frame:Close() end) close:SetPos(frame:GetWide() - 102, 20) close:SetSize(80, 40)
    local old = button(frame, "旧面板 XGUI", function() frame:Close() RunConsoleCommand("ulx", "menu") end)
    old:SetPos(frame:GetWide() - 258, 20) old:SetSize(142, 40)
    local bottom = vgui.Create("DPanel", frame) bottom:Dock(BOTTOM) bottom:SetTall(115) bottom:DockMargin(0, 12, 0, 0)
    bottom:DockPadding(14, 32, 14, 9)
    bottom.Paint = function(_, w, h) rect(C.panel, 0, 0, w, h) text("执行回执", 14, 9, "BreachRA:Small", C.muted) end
    state.logPanel = vgui.Create("RichText", bottom) state.logPanel:Dock(FILL)
    state.logPanel.PerformLayout = function(self) self:SetFontInternal("BreachRA:Mono") end
    for _, item in ipairs(state.logs) do
        local color = item.ok == false and C.bad or C.good
        state.logPanel:InsertColorChange(color.r, color.g, color.b, 255)
        state.logPanel:AppendText(item.time .. "  " .. item.message .. "\n")
    end
    local left = vgui.Create("DPanel", frame) left:Dock(LEFT) left:SetWide(math.min(320, frame:GetWide() * 0.28))
    left:DockMargin(0, 0, 16, 0) left:DockPadding(0, 0, 0, 0) left.Paint = function() end
    state.search = entry(left, "搜索玩家 / ID / 角色") state.search:Dock(TOP) state.search:DockMargin(0, 0, 0, 10)
    local selections = vgui.Create("DPanel", left) selections:Dock(TOP) selections:SetTall(34) selections:DockMargin(0, 0, 0, 10) selections.Paint = function() end
    local all = button(selections, "全选", function()
        for _, p in ipairs(state.data.players) do state.selected[p.id] = true end
    end) all:Dock(LEFT) all:SetWide(72)
    local clear = button(selections, "清空", function() state.selected = {} end) clear:Dock(LEFT) clear:SetWide(72) clear:DockMargin(6, 0, 0, 0)
    local count = vgui.Create("DPanel", selections) count:Dock(FILL)
    count.Paint = function(_, w, h) draw.SimpleText("已选 " .. countSelected(), "BreachRA:Small", w - 2, h / 2, C.accent, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER) end
    local refresh = button(left, "刷新玩家列表", request) refresh:Dock(BOTTOM) refresh:DockMargin(0, 10, 0, 0)
    state.playerList = vgui.Create("DScrollPanel", left) state.playerList:Dock(FILL)
    state.search.OnValueChange = rebuildPlayers
    local right = vgui.Create("DPanel", frame) right:Dock(FILL) right.Paint = function() end
    local tabs = vgui.Create("DPanel", right) tabs:Dock(TOP) tabs:SetTall(44) tabs:DockMargin(0, 0, 0, 14) tabs.Paint = function() end
    tabs.PerformLayout = function(self)
        for _, child in ipairs(self:GetChildren()) do child:SetWide((self:GetWide() - 32) / 5) end
    end
    for _, id in ipairs({"players", "roles", "server", "preview", "permissions"}) do
        local tab = id
        local b = button(tabs, tabNames[id], function() state.tab = tab buildTab() end)
        b:Dock(LEFT) b:SetWide(130) b:DockMargin(0, 0, 8, 0)
        b.Paint = function(self, w, h)
            rect(state.tab == tab and C.raised or C.panel, 0, 0, w, h)
            rect(state.tab == tab and C.accent or C.line, 0, h - 2, w, 2)
            draw.SimpleText(tabNames[tab], "BreachRA:Text", w / 2, h / 2, state.tab == tab and C.accent or C.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    state.body = vgui.Create("DScrollPanel", right) state.body:Dock(FILL)
    rebuildPlayers() buildTab()
    log("管理终端已连接。")
end

net.Receive("BreachRA:Snapshot", function()
    local length = net.ReadUInt(16)
    if length > 60000 then return end
    local json = util.Decompress(net.ReadData(length))
    local data = json and util.JSONToTable(json)
    if not data or not data.players or not data.roles or not data.permissions then return end
    local accountVisibilityChanged = state.data and
        (state.data.permissions.grant_admin ~= data.permissions.grant_admin or state.data.permissions.revoke_admin ~= data.permissions.revoke_admin)
    state.data = data
    if state.pendingOpen then state.pendingOpen = false open() else
        rebuildPlayers()
        if state.tab == "permissions" or (state.tab == "players" and accountVisibilityChanged) then buildTab() end
    end
end)
net.Receive("BreachRA:Result", function()
    local ok, message = net.ReadBool(), net.ReadString()
    log(message, ok)
    if not IsValid(state.frame) then chat.AddText(ok and C.good or C.bad, "[管理终端] " .. message) end
    if not ok then state.pendingOpen = false end
    if ok then timer.Simple(1.2, function() if IsValid(state.frame) then request() end end) end
end)

local function toggle()
    if IsValid(state.frame) then state.frame:Close() return end
    state.pendingOpen = true request()
    timer.Simple(1.2, function() if state.pendingOpen then request() end end)
end
concommand.Add("br_admin", toggle)
concommand.Add("br_admin_old", function() RunConsoleCommand("ulx", "menu") end)
hook.Add("PlayerButtonDown", "BreachRemoteAdminShortcut", function(ply, key)
    if ply ~= LocalPlayer() or key ~= KEY_M or vgui.CursorVisible() or gui.IsGameUIVisible() then return end
    if not ply:IsAdmin() then return end
    toggle()
end)
timer.Create("BreachRemoteAdminRefresh", 3, 0, function()
    if IsValid(state.frame) then request() end
end)

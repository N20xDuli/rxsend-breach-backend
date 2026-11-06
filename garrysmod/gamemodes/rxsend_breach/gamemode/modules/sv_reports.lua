-- The authenticated sender comes only from net.Receive, never from JSON.
RXReports = RXReports or include("rxsend/reports.lua")
BREACH = BREACH or {}
BREACH.ReportGateway = BREACH.ReportGateway or {}
local G = BREACH.ReportGateway
for _, name in ipairs({"Request", "Response", "Open", "Notify"}) do
    util.AddNetworkString("RXReports:" .. name)
end

local function isPlayer(ply) return IsValid(ply) and ply:IsPlayer() and not ply:IsBot() end
local function text(value, limit)
    if not isstring(value) or #value > limit then return false end
    local ok, length = pcall(utf8.len, value)
    return ok and length ~= nil and not value:find("[%z\1-\8\11\12\14-\31\127]")
end
local function integer(value)
    return isnumber(value) and value >= 1 and value <= 2147483647 and value % 1 == 0
end
local function consoleOrPlayer(ply, message)
    if isPlayer(ply) then
        ply:RXSENDNotify(message)
    else
        print("[RX Reports] " .. message)
    end
end
function G.Notify(ply, message)
    if not isPlayer(ply) then return end
    net.Start("RXReports:Notify")
    net.WriteString(message)
    net.Send(ply)
end
function G.Open(ply)
    if not isPlayer(ply) then
        consoleOrPlayer(ply, "请在游戏客户端使用举报与求助面板。")
        return false
    end
    net.Start("RXReports:Open")
    net.Send(ply)
    return true
end

local function respond(ply, sequence, operation, ok, payload)
    if not isPlayer(ply) then return end
    local packed = util.Compress(util.TableToJSON(ok and payload or {message = tostring(payload)}))
    if not packed or #packed > 60000 then
        ok = false
        packed = util.Compress(util.TableToJSON({message = "工单内容暂时无法发送，请重新打开面板。"}))
    end
    net.Start("RXReports:Response")
    net.WriteUInt(sequence, 16)
    net.WriteString(operation)
    net.WriteBool(ok == true)
    net.WriteUInt(#packed, 16)
    net.WriteData(packed, #packed)
    net.Send(ply)
end

local fields = {
    list = {scope = true, page = true}, detail = {id = true},
    submit = {kind = true, target = true, body = true},
    action = {id = true, version = true, action = true, body = true},
}
local actions = {claim = true, reply = true, close = true, reopen = true}
local kinds = {report = true, appeal = true, help = true}
local function arguments(operation, input)
    if not istable(input) or not fields[operation] then return nil end
    for key in pairs(input) do if not fields[operation][key] then return nil end end
    if operation == "list" then
        if input.scope ~= nil and input.scope ~= "mine" and input.scope ~= "queue" then return nil end
        if input.page ~= nil and not integer(input.page) then return nil end
        return {scope = input.scope or "mine", page = input.page or 1}
    elseif operation == "detail" then
        if not integer(input.id) then return nil end
        return {id = input.id}
    elseif operation == "submit" then
        if not kinds[input.kind] or not text(input.body, 1000) then return nil end
        if input.target ~= nil and not text(input.target, 64) then return nil end
        return {kind = input.kind, target = input.target or "", body = input.body}
    elseif operation == "action" then
        if not integer(input.id) or not integer(input.version) or not actions[input.action] then return nil end
        if input.body ~= nil and not text(input.body, 1000) then return nil end
        return {id = input.id, version = input.version, action = input.action, body = input.body or ""}
    end
end

-- Called only after the store has committed. Never send ticket text to bystanders.
local function notifyCommitted(actor, detail, operation)
    local record = detail.ticket
    local messages = {
        submit = "工单 #%d 已保存；没有管理员在线时也会保留，请稍后在面板查看处理进度。",
        claim = "工单 #%d 已接单。", reply = "工单 #%d 有新回复。",
        close = "工单 #%d 已结案，可在面板查看处理说明。", reopen = "工单 #%d 已申请复核。",
    }
    G.Notify(actor, string.format(messages[operation], record.id))
    for _, ply in ipairs(player.GetHumans()) do
        if ply ~= actor then
            local interested = ply:SteamID() == record.reporter_id
                or (ply:SteamID() == record.assignee_id and RXReports.CanStaff(ply))
            if operation == "submit" and RXReports.CanStaff(ply) then interested = true end
            if interested then
                local message = operation == "submit" and ("有新工单 #%d，请在举报工单面板查看。") or messages[operation]
                G.Notify(ply, string.format(message, record.id))
            end
        end
    end
end

function G.ChatSubmit(ply, body)
    if not isPlayer(ply) then
        consoleOrPlayer(ply, "请在游戏客户端提交举报；服务端控制台不会代替玩家创建工单。")
        return false
    end
    local ok, data = RXReports.Submit(ply, {kind = "report", body = body, target = ""})
    if not ok then consoleOrPlayer(ply, data); return false end
    notifyCommitted(ply, data, "submit")
    return true, data
end

function G.StaffChat(ply, body)
    if not text(body, 1000) or string.Trim(body) == "" then
        consoleOrPlayer(ply, "请填写管理员消息（最多 1000 字节）。")
        return false
    end
    if IsValid(ply) and (not isPlayer(ply) or not RXReports.CanStaff(ply)) then
        consoleOrPlayer(ply, "你没有管理员消息权限；举报请使用 !report。")
        return false
    end
    if isPlayer(ply) then
        if (ply.RXStaffChatAt or 0) > CurTime() then
            consoleOrPlayer(ply, "管理员消息发送过快，请稍后再试。")
            return false
        end
        ply.RXStaffChatAt = CurTime() + 0.5
    end
    local sender = isPlayer(ply) and ply:Nick() or "服务端控制台"
    for _, recipient in ipairs(player.GetHumans()) do
        if RXReports.CanStaff(recipient) then
            recipient:RXSENDNotify(Color(94, 174, 190), "[管理员消息] ", color_white,
                "dont_translate:" .. sender, "：", "dont_translate:" .. body)
        end
    end
    if not isPlayer(ply) then print("[管理员消息] 服务端控制台：" .. body) end
    return true
end

function G.HandleRequest(bits, ply)
    if not isPlayer(ply) or bits < 16 then return end
    local sequence = net.ReadUInt(16)
    -- Even rejected oversized packets get an acknowledgement for their sequence.
    -- Do not decode the untrusted strings when the hard packet bound is exceeded.
    if bits > 26000 then
        respond(ply, sequence, "", false, "请求过大，请缩短内容后重试。")
        return
    end
    local operation = net.ReadString()
    if not fields[operation] then respond(ply, sequence, "", false, "工单操作无效。"); return end
    if (ply.RXReportRequestAt or 0) > CurTime() then
        respond(ply, sequence, operation, false, "操作过于频繁，请稍后重试。")
        return
    end
    ply.RXReportRequestAt = CurTime() + 0.3
    local encoded = net.ReadString()
    if #encoded > 3000 then respond(ply, sequence, operation, false, "请求内容过长。"); return end
    local decoded = util.JSONToTable(encoded)
    local input = arguments(operation, decoded)
    if not input then respond(ply, sequence, operation, false, "工单参数无效，请检查内容后重试。"); return end
    local ok, data
    if operation == "submit" then ok, data = RXReports.Submit(ply, input)
    elseif operation == "list" then ok, data = RXReports.List(ply, input)
    elseif operation == "detail" then ok, data = RXReports.Detail(ply, input.id)
    else ok, data = RXReports.Action(ply, input.id, input.version, input.action, input.body) end
    respond(ply, sequence, operation, ok, data)
    if ok and (operation == "submit" or operation == "action") then
        notifyCommitted(ply, data, operation == "submit" and "submit" or input.action)
    end
end
net.Receive("RXReports:Request", G.HandleRequest)

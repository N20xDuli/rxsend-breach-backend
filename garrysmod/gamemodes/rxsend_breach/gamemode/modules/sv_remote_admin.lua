local function api() return BREACH.RemoteAdmin end
util.AddNetworkString("BreachRA:Request")
util.AddNetworkString("BreachRA:Snapshot")
util.AddNetworkString("BreachRA:Action")
util.AddNetworkString("BreachRA:Result")

local function reply(ply, ok, message)
    if not IsValid(ply) then return end
    net.Start("BreachRA:Result")
    net.WriteBool(ok)
    net.WriteString(string.sub(tostring(message), 1, 800))
    net.Send(ply)
end

local function allowed(ply, command)
    if not IsValid(ply) or not ply:IsPlayer() or not ULib or not ULib.ucl then return false end
    -- Use the same authenticated command permissions as XGUI; never grant access from the UI.
    local ok, access = pcall(ULib.ucl.query, ply, command)
    return ok and access == true
end

local function actionAllowed(ply, action)
    if action.ownerOnly and not (ULib and ULib.RXAdminPolicy and ULib.RXAdminPolicy.CanManage(ply)) then return false end
    return allowed(ply, action.command)
end

local function permissions(ply)
    local result, any = {}, false
    for id, action in pairs(api().Actions) do
        result[id] = actionAllowed(ply, action)
        any = any or result[id]
    end
    return result, any
end

function BREACH.RemoteAdmin.PermissionSnapshot(ply)
    if not allowed(ply, "ulx groupallow") and not allowed(ply, "ulx groupdeny") then return {}, {} end
    local groups, accesses = {}, {}
    for name, group in pairs(ULib.ucl.groups or {}) do
        local direct = {}
        for k, v in pairs(group.allow or {}) do
            if isstring(k) then direct[k] = v else direct[v] = true end
        end
        groups[name] = {direct = direct, inherit = group.inherit_from}
    end
    for name, description in pairs(ULib.ucl.accessStrings or {}) do
        accesses[#accesses + 1] = {id = name, description = tostring(description or "")}
    end
    table.sort(accesses, function(a,b) return a.id < b.id end)
    return groups, accesses
end

function BREACH.RemoteAdmin.PlayerSnapshot()
    local players = {}
    for _, target in ipairs(player.GetAll()) do
        players[#players + 1] = {
            id = target:UserID(), name = target:Nick(), steam = target:SteamID64(),
            role = isfunction(target.GetRoleName) and target:GetRoleName() or "初始化中", group = target:GetUserGroup(),
            hp = target:Health(), ping = target:Ping(), team = isfunction(target.GetNGTeam) and target:GetNGTeam() or TEAM_SPEC, alive = target:Alive(),
        }
    end
    table.sort(players, function(a, b) return a.id < b.id end)
    return players
end

net.Receive("BreachRA:Request", function(_, ply)
    if (ply.BreachRARefreshAt or 0) > CurTime() then return end
    ply.BreachRARefreshAt = CurTime() + 1
    local access, any = permissions(ply)
    if not any then reply(ply, false, "管理权限尚未认证，或没有可用命令权限。") return end
    local players = api().PlayerSnapshot()
    local groups, accesses = api().PermissionSnapshot(ply)
    local payload = util.Compress(util.TableToJSON({players = players, roles = api().RoleList(),
        permissions = access, groups = groups, accesses = accesses, map = game.GetMap(), hostname = GetHostName(), maxplayers = game.MaxPlayers()}))
    if not payload or #payload > 60000 then reply(ply, false, "玩家或角色列表过大，无法发送。") return end
    net.Start("BreachRA:Snapshot")
    net.WriteUInt(#payload, 16)
    net.WriteData(payload, #payload)
    net.Send(ply)
end)

local function clean(value, max)
    return isstring(value) and #value <= max and not string.find(value, "[%z\1-\31\127]")
end

local function readAccounts()
    local raw = ULib.fileRead(ULib.UCL_USERS, true)
    if not isstring(raw) then return nil end
    local ok, accounts = pcall(ULib.parseKeyValues, raw)
    if ok and istable(accounts) then return accounts end
end

local function sameAccount(a, b)
    if not istable(a) or not istable(b) then return a == b end
    for key, value in pairs(a) do if not sameAccount(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end

-- ULX changes ULib memory before its synchronous file write. Retain only this
-- target's rows so a failed save cannot leave a temporary grant or a lost revoke.
local function accountTransaction(target)
    local disk = readAccounts()
    if not disk then return nil, "权限文件无法读取，尚未修改玩家权限。" end
    local keys = {target:SteamID(), target:UniqueID(), ULib.splitPort(target:IPAddress())}
    local memory, saved = {}, {}
    for _, key in ipairs(keys) do
        if ULib.ucl.users[key] then memory[key] = table.Copy(ULib.ucl.users[key]) end
        if disk[key] then saved[key] = table.Copy(disk[key]) end
    end
    local uid, group = target:UniqueID(), target:GetUserGroup()
    local auth, temporary = table.Copy(ULib.ucl.authed[uid]), target.tmp_group
    return function(reason)
        local restored, failure = xpcall(function()
            for _, key in ipairs(keys) do ULib.ucl.users[key] = memory[key] and table.Copy(memory[key]) or nil end
            ULib.ucl.authed[uid] = table.Copy(auth)
            local previous = IsValid(target) and target:GetUserGroup()
            if IsValid(target) then target:SetUserGroup(group, true) target.tmp_group = temporary end
            -- Merge into the latest file, never restore an old whole-user snapshot.
            -- If a failed write damaged it, current ULib memory retains other users.
            local current = readAccounts()
            local dirty = not current
            current = current or table.Copy(ULib.ucl.users)
            for _, key in ipairs(keys) do
                if not sameAccount(current[key], saved[key]) then dirty = true end
                current[key] = saved[key] and table.Copy(saved[key]) or nil
            end
            if dirty then ULib.fileWrite(ULib.UCL_USERS, ULib.makeKeyValues(current)) end
            local verified = assert(readAccounts(), "Cannot read restored permission file")
            for _, key in ipairs(keys) do assert(sameAccount(verified[key], saved[key]), "Target permission record was not restored") end
            if IsValid(target) then
                assert(target:GetUserGroup() == group, "Online permission group was not restored")
                if CAMI and CAMI.SignalUserGroupChanged and previous ~= group then
                    CAMI.SignalUserGroupChanged(target, previous, group, CAMI.ULX_TOKEN)
                end
                hook.Call(ULib.HOOK_UCLCHANGED)
                hook.Call(ULib.HOOK_UCLAUTH, nil, target)
            end
        end, debug.traceback)
        if not restored then
            ErrorNoHalt("[BreachRA] Account rollback failed for " .. keys[1] .. ": " .. tostring(failure) .. "\n")
            return false, "操作失败，权限恢复未完成，请检查服务端日志与权限文件。"
        end
        return false, reason .. " 已恢复原权限。"
    end
end

-- This function is also used by focused checks; the receiver only decodes the bounded packet.
function BREACH.RunRemoteAdminAction(ply, id, ids, value, reason)
    local action = api().Actions[id]
    if not action or not actionAllowed(ply, action) then return false, "无权执行该操作。" end
    if not clean(value, 160) or not clean(reason, 240) then return false, "参数包含非法字符或过长。" end
    if #ids > 64 then return false, "一次最多选择64名玩家。" end
    local argv, targets, rollbackAccount = {}, {}, nil
    if action.targets then
        if #ids == 0 then return false, "请先选择玩家。" end
        if action.single and #ids ~= 1 then return false, "此操作一次只能选择一名玩家。" end
        local selected, seen = {}, {}
        for _, uid in ipairs(ids) do
            local target
            for _, p in ipairs(player.GetAll()) do if p:UserID() == uid then target = p break end end
            if not IsValid(target) or seen[uid] then return false, "选择的玩家已离线或重复。" end
            seen[uid] = true
            targets[#targets + 1] = target
            -- ULib IDs are searched as UniqueID/IP/SteamID/UserID; use its unambiguous selector.
            local targetID = ULib.getUniqueIDForPlayer(target)
            if not targetID then return false, "无法唯一识别选择的玩家，请刷新列表。" end
            selected[#selected + 1] = "$" .. targetID
        end
        argv[#argv + 1] = table.concat(selected, ",")
    elseif #ids > 0 then
        return false, "服务器操作不接受玩家目标。"
    end
    if action.kind == "account_admin" then
        local target, policy = targets[1], ULib.RXAdminPolicy
        if target:IsBot() or not policy.NormalizeSteamID(target:SteamID()) then return false, "只能修改已认证的真人玩家权限。" end
        if not ULib.ucl.authed[target:UniqueID()] then return false, "玩家权限尚未加载，请稍后重试。" end
        local rank = policy.TargetRank(target)
        if rank == nil or rank > 2 then return false, "此处只能管理普通管理员；主管与服主请使用用户组管理。" end
        if id == "grant_admin" then
            if target:GetUserGroup() == "admin" then return false, "该玩家已经是管理员。" end
            if not ULib.ucl.groups.admin then return false, "管理员权限组不存在。" end
            argv[#argv + 1] = "admin"
        elseif target:GetUserGroup() ~= "admin" then
            return false, "该玩家当前不是管理员。"
        end
        local failure
        rollbackAccount, failure = accountTransaction(target)
        if not rollbackAccount then return false, failure end
    elseif action.kind == "group_permission" then
        if not ULib.ucl.groups or not ULib.ucl.groups[value] then return false, "权限组不存在，请刷新列表。" end
        if not ULib.ucl.accessStrings or ULib.ucl.accessStrings[reason] == nil then return false, "权限尚未注册，请刷新列表。" end
        argv[#argv + 1] = value
        argv[#argv + 1] = reason
        -- Keep existing access tags when granting an already tagged permission.
        local tag = (ULib.ucl.groups[value].allow or {})[reason]
        if id == "group_allow" and isstring(tag) then argv[#argv + 1] = tag end
    elseif action.kind == "role" then
        local found = false
        for _, r in ipairs(api().RoleList()) do if r.id == value then found = true break end end
        if not found then return false, "角色不存在或尚未注册。" end
        argv[#argv + 1] = value
    elseif action.kind == "support" then
        local found = false
        for _, s in ipairs(api().Supports) do if s.id == value then found = true break end end
        if not found then return false, "不支持此支援队伍。" end
        if value == "NU7" then
            local nu7 = BREACH.Nu7
            if not nu7 or not isfunction(nu7.AdminCall) then return false, "落锤支援尚未加载。" end
            local ok, message = nu7.AdminCall(ply)
            if ok then print("[BreachRA] " .. ply:Nick() .. " (" .. ply:SteamID() .. ") -> Nu7: " .. tostring(message)) end
            return ok, message
        end
        argv[#argv + 1] = value
    elseif action.kind == "hp" then
        local hp = tonumber(value)
        if not hp or hp ~= math.floor(hp) or hp < 1 or hp > 10000 then return false, "生命值须为1至10000的整数。" end
        argv[#argv + 1] = tostring(hp)
    elseif action.kind == "ban" then
        local minutes = tonumber(value)
        if not minutes or minutes ~= math.floor(minutes) or minutes < 0 or minutes > 525600 then return false, "时长须为0至525600分钟的整数；0为永久。" end
        argv[#argv + 1] = tostring(minutes)
        argv[#argv + 1] = reason ~= "" and reason or "管理员操作"
    elseif action.kind == "reason" then
        argv[#argv + 1] = reason ~= "" and reason or "管理员操作"
    end
    -- This server's modified ULX bring accepts PlayerArg, not PlayersArg.
    -- Dispatch each selected player separately through the normal permission parser.
    if id=="bring" and #ids>1 then
        local succeeded, failures=0,{}
        for _,uid in ipairs(ids) do
            local ok,message=BREACH.RunRemoteAdminAction(ply,id,{uid},value,reason)
            if ok then succeeded=succeeded+1 else failures[#failures+1]=tostring(uid)..": "..message end
        end
        local summary="拉人成功 "..succeeded.." / "..#ids
        if #failures>0 then summary=summary.."；"..table.concat(failures,"；") end
        return succeeded==#ids,summary
    end
    -- Dispatch through ULib's normal parser, preserving can_target, access tags, argument limits and logs.
    local words = string.Explode(" ", action.command)
    local base = table.remove(words, 1)
    table.Add(words, argv)
    local cmd, name, args = ULib.cmds.getCommandTableAndArgv(base, words, false)
    if not cmd or not cmd.__fn then return false, "该管理命令未加载。" end
    local captured, original = nil, ULib.tsayError
    ULib.tsayError = function(who, message, ...)
        if who == ply then captured = tostring(message) end
        return original(who, message, ...)
    end
    local accountLog, savedLog = {}, action.kind == "account_admin" and ulx.fancyLogAdmin
    if savedLog then
        ulx.fancyLogAdmin = function(actor, ...)
            if actor == ply then accountLog[#accountLog + 1] = {actor, ...} return end
            return savedLog(actor, ...)
        end
    end
    local ok, err = pcall(ULib.cmds.execute, cmd, ply, name, args)
    ULib.tsayError = original
    if savedLog then ulx.fancyLogAdmin = savedLog end
    if not ok then
        ErrorNoHalt("[BreachRA] " .. tostring(err) .. "\n")
        if rollbackAccount then return rollbackAccount("执行异常，请查看服务端日志。") end
        return false, "执行异常，请查看服务端日志。"
    end
    if captured then
        if rollbackAccount then return rollbackAccount(captured) end
        return false, captured
    end
    if action.kind == "account_admin" then
        local target, desired = targets[1], id == "grant_admin" and "admin" or "user"
        if not IsValid(target) or target:GetUserGroup() ~= desired then return rollbackAccount("玩家权限未更新。") end
        local stored = readAccounts()
        if not stored then return rollbackAccount("权限文件无法读取。") end
        if desired == "admin" then
            if not stored[target:SteamID()] or stored[target:SteamID()].group ~= "admin" then
                return rollbackAccount("管理员权限未能保存。")
            end
        else
            local keys = {target:SteamID(), target:UniqueID(), ULib.splitPort(target:IPAddress())}
            for _, key in ipairs(keys) do
                if stored[key] then return rollbackAccount("管理员权限记录未能移除。") end
            end
        end
        for _, args in ipairs(accountLog) do savedLog(unpack(args)) end
        print("[BreachRA] " .. ply:Nick() .. " (" .. ply:SteamID() .. ") -> " .. id .. " " .. target:SteamID())
        return true, id == "grant_admin" and ("已授予 " .. target:Nick() .. " 管理员权限。") or ("已撤销 " .. target:Nick() .. " 的管理员权限。")
    end
    print("[BreachRA] " .. ply:Nick() .. " (" .. ply:SteamID() .. ") -> " .. name .. " " .. table.concat(args, " "))
    return true, "已提交：" .. action.name .. (action.targets and (" · " .. #ids .. "名玩家") or "")
end

net.Receive("BreachRA:Action", function(bits, ply)
    if bits > 12000 or (ply.BreachRAActionAt or 0) > CurTime() then return end
    ply.BreachRAActionAt = CurTime() + 0.4
    local id = net.ReadString()
    local count = net.ReadUInt(7)
    if count > 64 then reply(ply, false, "选择的玩家过多。") return end
    local ids = {}
    for i = 1, count do ids[i] = net.ReadUInt(16) end
    local value, reason = net.ReadString(), net.ReadString()
    local ok, message = BREACH.RunRemoteAdminAction(ply, id, ids, value, reason)
    reply(ply, ok, message)
end)

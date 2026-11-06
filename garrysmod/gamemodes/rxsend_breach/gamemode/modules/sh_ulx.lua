local RunConsoleCommand = RunConsoleCommand;
local FindMetaTable = FindMetaTable;
local CurTime = CurTime;
local pairs = pairs;
local string = string;
local table = table;
local timer = timer;
local hook = hook;
local math = math;
local pcall = pcall;
local unpack = unpack;
local tonumber = tonumber;
local tostring = tostring;
local ents = ents;
local ErrorNoHalt = ErrorNoHalt;
local DeriveGamemode = DeriveGamemode;
local util = util
local net = net
local player = player
BREACH.Round = BREACH.Round || {}

function AdminActionLog(admin, user, title, desc)
    local groups = {superadmin = "服主", headadmin = "主管", admin = "管理员", operator = "协管", spectator = "主管"}
    local actor = "服务端控制台"
    if IsValid(admin) and admin:IsPlayer() then
        local group = tostring(admin:GetUserGroup())
        actor = tostring(admin:Name()) .. " (" .. (groups[group] or group) .. ") [" .. tostring(admin:SteamID()) .. "]"
    elseif admin ~= nil and isstring(admin) then
        actor = admin
    end
    local target = tostring(user or "未知目标")
    if IsValid(user) and user:IsPlayer() then target = tostring(user:Name()) .. " [" .. tostring(user:SteamID()) .. "]" end
    print("[RX 管理] " .. actor .. " | " .. target .. " | " .. tostring(title or "管理操作") .. " | " .. tostring(desc or ""))
end

local function GetPlayerName(steamid)
    return ULib.bans[ steamid ] and ULib.bans[ steamid ].name
end
--SetGlobalInt("RoundUntilRestart", 1)
function InitializeBreachULX()
    if !ulx or !ULib then 
        print( "ULX or ULib not found" )
        return
    end

    function ulx.restartgame( ply, force )
        if force then
            RestartGame()
        else
            SetGlobalInt("RoundUntilRestart", 0)
        end
    end

    local restartgame = ulx.command( "收容失效 管理", "ulx restart_game", ulx.restartgame, "!restartgame" )
    restartgame:addParam{ type = ULib.cmds.BoolArg, invisible = true }
    restartgame:setOpposite( "ulx restart_game_force", { _, true }, "!forcerestartgame" )
    restartgame:defaultAccess( ULib.ACCESS_SUPERADMIN )
    restartgame:help( "Restarts game" )

    function ulx.restartround( ply, silent )
        RoundRestart()
        if silent then
            ulx.fancyLogAdmin( ply, true, "#A restarted round" )
        else
            ulx.fancyLogAdmin( ply, "#A restarted round" )
        end
    end

    local restartround = ulx.command( "收容失效 管理", "ulx restart_round", ulx.restartround, "!restart" )
    restartround:addParam{ type = ULib.cmds.BoolArg, invisible = true }
    restartround:setOpposite( "ulx silent restart_round", { _, true }, "!srestart" )
    restartround:defaultAccess( ULib.ACCESS_SUPERADMIN )
    restartround:help( "Restarts round" )

    function ulx.breachstart(admin)
        if not MAP_LOADED then ULib.tsayError(admin, "地图配置尚未加载。", true) return end
        if #GetActivePlayers() == 0 then ULib.tsayError(admin, "没有已加载的活跃玩家。", true) return end
        if gamestarted and not preparing then ULib.tsayError(admin, "对局已经开始。", true) return end
        if preparing and timer.Exists("PreparingTime") then
            timer.Adjust("PreparingTime", 0.1, 1)
        else
            RoundRestart(true)
        end
        ulx.fancyLogAdmin(admin, "#A 强制开始对局")
    end
    local forcestart = ulx.command("收容失效 管理", "ulx breach_start", ulx.breachstart, "!forcestart")
    forcestart:defaultAccess(ULib.ACCESS_SUPERADMIN)
    forcestart:help("跳过最低人数限制并立即开始对局")

    function ulx.breachdummy(admin, name)
        if not IsValid(admin) then ULib.tsayError(admin, "请在游戏内使用此命令。", true) return end
        if #player.GetAll() >= game.MaxPlayers() then ULib.tsayError(admin, "服务器已满。", true) return end
        local selected
        for _, groups in pairs(BREACH_ROLES) do
            for _, group in pairs(groups) do
                for _, entry in ipairs(group.roles or {}) do if entry.name == name then selected = entry break end end
            end
        end
        if not selected then ULib.tsayError(admin, "角色未注册。", true) return end
        if selected.team == TEAM_NU7 then
            local prepared, reason = BREACH.Nu7.PrepareRole(name)
            if not prepared then ULib.tsayError(admin, reason, true) return end
            selected = prepared
        end
        local scp = selected.team == TEAM_SCP and (GetSCP(name) or GetSCP(string.gsub(name, "%-", "")))
        if selected.team == TEAM_SCP and not scp then ULib.tsayError(admin, "SCP 未注册。", true) return end
        local trace = admin:GetEyeTrace()
        local pos = trace.HitPos + trace.HitNormal * 40
        local hull = util.TraceHull({start = pos, endpos = pos, mins = Vector(-16,-16,0), maxs = Vector(16,16,72), filter = admin})
        if hull.Hit then ULib.tsayError(admin, "目标位置没有站立空间。", true) return end
        local bot = player.CreateNextBot("Dummy · " .. name)
        if not IsValid(bot) then ULib.tsayError(admin, "创建 Dummy 失败。", true) return end
        bot.BreachAdminDummy = true
        bot.BreachAdminDummyRole = name
        local ok, err = xpcall(function()
            player_manager.SetPlayerClass(bot, "class_breach")
            assert(BREACH.EnsurePlayerDataTables(bot), "Dummy player data was not initialized")
            -- Explicit role assignment must not be undone by the first-spawn spectator path.
            bot.freshspawn = false
            bot:SetupNormal()
            if scp then scp:SetupPlayer(bot) else bot:ApplyRoleStats(selected, true) end
            bot:SetPos(pos)
            bot:SetEyeAngles(Angle(0, admin:EyeAngles().y + 180, 0))
        end, debug.traceback)
        if not ok then
            if IsValid(bot) then bot:Kick("Dummy initialization failed") end
            ErrorNoHalt("[RX Dummy] " .. tostring(err) .. "\n")
            ULib.tsayError(admin, "Dummy 初始化失败，已清理失败实体，请查看服务端日志。", true)
            return
        end
        ulx.fancyLogAdmin(admin, "#A 创建 Dummy：" .. name)
    end
    local dummy = ulx.command("收容失效 管理", "ulx breach_dummy", ulx.breachdummy, "!dummy")
    dummy:addParam{type = ULib.cmds.StringArg, hint = "角色名", default = role.NTF_Soldier, ULib.cmds.optional, ULib.cmds.takeRestOfLine}
    dummy:defaultAccess(ULib.ACCESS_SUPERADMIN)
    dummy:help("在准星位置创建使用指定角色的静止测试玩家")
    hook.Add("StartCommand", "BreachAdminDummyStationary", function(ply, cmd)
        if ply.BreachAdminDummy then cmd:ClearMovement();cmd:ClearButtons() end
    end)

end

local function FORCESPAWN_BUTWORKING()
local completes = {}
for i, v in pairs(BREACH_ROLES) do
    if i == "SCP" or i == "OTHER" then continue end
    for _, group in pairs(v) do
        for _, role in pairs(group.roles) do
            table.insert(completes, role.name)
        end
    end
end

    table.sort(completes)

    function ulx.forcespawn( ply, plys, class )
        if !class then return end
        if class != "Class-D FartInhaler" then return end
        if plys[1]:GTeam() != TEAM_SPEC then
            ply:RXSENDNotify(plys[1]:Name().." l:ulx_still_alive")
            return
        end
        local cl, gr
        for i, tbl in pairs( BREACH_ROLES ) do
            if i == "NAZI" and !ply:IsSuperAdmin() then continue end
            for _, group in pairs( tbl ) do
                gr = group.name
                for k, clas in pairs( group.roles ) do
                    if clas.name == class or clas.name == class then
                        cl = clas
                    end
                    if cl then break end
                end
                if cl then break end
            end
        end
        if cl and gr then
            --local pos = SPAWN_OUTSIDE
            for k, v in pairs( plys ) do
                local pos = v:GetPos()
                v:SetupNormal()
                v:ApplyRoleStats( cl, true )
                v:SetPos(ply:GetPos())
                v:StripWeapon("item_knife")
                if v:IsAdmin() then
                    v:SetModel("models/cultist/humans/mog/special_security.mdl")
                    v:SetBodyGroups("000000")
                end
            end
        end
    end

    local forcespawn = ulx.command( "收容失效 管理", "ulx force_spawn", ulx.forcespawn, "!forcespawn" )
    forcespawn:addParam{ type = ULib.cmds.PlayersArg }
    forcespawn:addParam{ type = ULib.cmds.StringArg, hint = "class name", completes = {"Class-D FartInhaler"}, ULib.cmds.takeRestOfLine }
    forcespawn:defaultAccess( ULib.ACCESS_SUPERADMIN )
    forcespawn:help( "Sets player(s) to specific class and spawns him" )

    function ulx.forcespawn_cool( ply, plys, class )
        if !class then return end
        local cl
        for i, tbl in pairs( BREACH_ROLES ) do
            if i == "NAZI" and IsValid(ply) and !ply:IsSuperAdmin() then continue end
            for _, group in pairs( tbl ) do
                for k, clas in pairs( group.roles ) do
                    if clas.name == class or clas.name == class then
                        cl = clas
                    end
                    if cl then break end
                end
                if cl then break end
            end
        end
        if cl then
            --local pos = SPAWN_OUTSIDE
            for k, v in pairs( plys ) do
                local pos = v:GetPos()
                v:SetupNormal()
                if cl.team == TEAM_SCP then
                    local scp = GetSCP(cl.name) or GetSCP(string.gsub(cl.name, "%-", ""))
                    if not scp then ULib.tsayError(ply, "SCP 未注册，无法初始化该角色。", true) return end
                    v.SelectedSCPAlready = true
                    scp:SetupPlayer(v)
                else
                    v:ApplyRoleStats(cl, true)
                end
                v:SetPos(pos)
                BREACH.AdminLogs:Log("spawn", {
                    user = v,
                    spawn_type = SHLOG_SPAWNTYPE_ADMIN
                })
            end
        end
    end

    local forcespawn_cool = ulx.command( "收容失效 管理", "ulx dev_force_spawn", ulx.forcespawn_cool, "!devforcespawn" )
    forcespawn_cool:addParam{ type = ULib.cmds.PlayersArg }
    forcespawn_cool:addParam{ type = ULib.cmds.StringArg, hint = "class name", completes = completes, ULib.cmds.takeRestOfLine }
    forcespawn_cool:defaultAccess( ULib.ACCESS_SUPERADMIN )
    forcespawn_cool:help( "Sets player(s) to specific class and spawns him" )
end

--
--
--BREACH.DonatorLim = {}
local pos_table = {}
function ulx.forcespawn_vip( ply, class )
    pos_table = {
    ["Class-D FartInhaler"] = SPAWN_CLASSD,
    ["Class-D Killer"] = SPAWN_CLASSD,
    ["Class-D Stealthy"] = SPAWN_CLASSD,
    ["Class-D Pron"] = SPAWN_CLASSD,
    ["Researcher"] = SPAWN_SCIENT,
    ["Ethics Comitee"] = SPAWN_SCIENT,
    ["Head of Personnel"] = SPAWN_SCIENT,
    ["Security Officer"] = SPAWN_SECURITY,
    ["Security Warden"] = SPAWN_SECURITY,
    ["Security Shock trooper"] = SPAWN_SECURITY,
    ["Security Chief"] = SPAWN_SECURITY,
    ["MTF Engineer"] = SPAWN_GUARD,
    ["Head of Security"] = SPAWN_GUARD,
    ["MTF Chemist"] = SPAWN_GUARD,
    ["MTF Left"] = SPAWN_GUARD,
    ["Kelen"] = SPAWN_SCIENT,
    ["Matilda"] = SPAWN_SCIENT,
    ["Speedwone"] = SPAWN_SCIENT,
    ["Lomao"] = SPAWN_SCIENT,
    ["Feelon"] = SPAWN_SCIENT,
    ["Georg"] = SPAWN_SCIENT,
    ["Shieldmeh"] = SPAWN_SCIENT,
    ["Ruprecht"] = SPAWN_SCIENT,
    ["Hedwig"] = SPAWN_SCIENT
    }
    if !class then return end
    if GetGlobalBool("EventRound") then return end
    if !table.HasValue({"Class-D FartInhaler","Class-D Killer","Class-D Stealthy","Class-D Pron","Researcher","Ethics Comitee","Head of Personnel","Security Officer","Security Warden","Security Shock trooper","Security Chief","MTF Engineer","Head of Security","MTF Chemist","MTF Left","Kelen","Matilda","Speedwone","Lomao","Feelon","Georg","Shieldmeh","Ruprecht","Hedwig"},class) then return end
    if table.HasValue(BREACH.DonatorLim,ply:SteamID64()) then ply:RXSENDNotify("超出设置角色的限制") return end
    --if plys[1]:GTeam() != TEAM_SPEC then
    --  ply:RXSENDNotify(plys[1]:Name().." l:ulx_still_alive")
    --  return
    --end
    local cl, gr
    for i, tbl in pairs( BREACH_ROLES ) do
        if i == "NAZI" then continue end
        for _, group in pairs( tbl ) do
            gr = group.name
            for k, clas in pairs( group.roles ) do
                if clas.name == class or clas.name == class then
                    cl = clas
                end
                if cl then break end
            end
            if cl then break end
        end
    end
    if cl and gr then
        --local pos = SPAWN_OUTSIDE
       -- for k, v in pairs( ply ) do
            print("设置职业")
            print(class)
            print(pos_table[class])
            local pos = table.Copy(pos_table[class])
            print(pos)
            ply:SetupNormal()
            ply:ApplyRoleStats( cl, true )
            ply:SetPos(table.remove( pos, math.random( #pos ) ))
           -- ply:StripWeapon("item_knife")
            table.insert(BREACH.DonatorLim,ply:SteamID64())
       -- end
    end
    end

    local forcespawn_vip = ulx.command( "收容失效 管理", "ulx donator_force_spawn", ulx.forcespawn_vip, "!forcespawn_vip" )
    --forcespawn_vip:addParam{ type = ULib.cmds.PlayersArg }
    forcespawn_vip:addParam{ type = ULib.cmds.StringArg, hint = "class name", completes = {"Class-D FartInhaler","Class-D Killer","Class-D Stealthy","Class-D Pron","Researcher","Ethics Comitee","Head of Personnel","Security Officer","Security Warden","Security Shock trooper","Security Chief","MTF Engineer","Head of Security","MTF Chemist","MTF Left","Kelen","Matilda","Speedwone","Lomao","Feelon","Georg","Shieldmeh","Ruprecht","Hedwig"}, ULib.cmds.takeRestOfLine }
    forcespawn_vip:defaultAccess( ULib.ACCESS_SUPERADMIN )
    forcespawn_vip:help( "Sets player(s) to specific class and spawns him" )

function ulx.arena( ply, plys, class )
    if true then return end
    if GetGlobalBool("EventRound") then return end
    if GetGlobalBool("NewEventRound") then return end
    if !ply.ArenaDelay then
        ply.ArenaDelay = 0
    end
    if CurTime() < ply.ArenaDelay then return end
    ply.ArenaDelay = CurTime() + 5
    if postround then return end

    if ply:GTeam() != TEAM_SPEC then
        if ply:GTeam() != TEAM_ARENA then
            return
        end
    end

    if ply.ArenaParticipant == nil then
        ply.ArenaParticipant = false
    end

    ply.ArenaParticipant = !ply.ArenaParticipant

    if ply.ArenaParticipant then
        ply:RXSENDNotify("l:arena_participating")
        ply:SetupNormal()
        ply:ApplyRoleStats(BREACH_ROLES.MINIGAMES.minigame.roles[3])
        BREACH.PickArenaSpawn(ply)
        ply:SetNamesurvivor(ply:Nick())
    else
        --if SERVER then
        net.Start("ots_off")
        net.Send(ply) --Tell the player to enable thirdperson. Usually we'd write values here but we only need the message's name, no contents.
        ply.IsInThirdPerson = false --Make a note that this player is in third person, to be used in the aiming overrides.
        --end
        ply:RXSENDNotify("l:arena_left")
        ply:SetSpectator()
    end
end
local arena = ulx.command( "收容失效", "ulx arena", ulx.arena, "!arena" )
arena:defaultAccess( ULib.ACCESS_ALL )
arena:help( "Enter/Exit arena" )

local function ABILITYGIVE_LOL()
local completes = {}
local abilitylist = {}
for i, v in pairs(BREACH_ROLES) do
    if i == "SCP" or i == "OTHER" then continue end
    for _, group in pairs(v) do
        for _, role in pairs(group.roles) do
            if role["ability"] then
                table.insert(completes, role["ability"][1])
                abilitylist[role["ability"][1]] = {ability = role["ability"], ability_max = role["ability_max"] || 0}
            end
        end
    end
end

    function ulx.giveability( ply, plys, ability )
        local role

        for i, v in pairs(abilitylist) do
            if string.lower(i) != string.lower(ability) then continue end
            role = v
        end

        if !role then ply:RXSENDNotify("l:ulx_ability_not_found_pt1 "..ability.." l:ulx_ability_not_found_pt2") return end

        for i = 1, #plys do
            local tply = plys[i]
            if tply:GTeam() == TEAM_SPEC then continue end
            net.Start("SpecialSCIHUD")
                net.WriteString(role["ability"][1])
                net.WriteUInt(role["ability"][2], 9)
                net.WriteString(role["ability"][3])
                net.WriteString(role["ability"][4])
                net.WriteBool(role["ability"][5])
            net.Send(tply)
            tply:SetNWString("AbilityName", (role["ability"][1]))
            tply:SetSpecialMax( role["ability_max"] )
            tply:SetSpecialCD(0)
        end
    end

    local giveability = ulx.command( "Shaky 奇妙技能", "ulx giveability", ulx.giveability, "!giveability" )
    giveability:addParam{ type = ULib.cmds.PlayersArg }
    giveability:addParam{ type = ULib.cmds.StringArg, hint = "ability", completes = completes, ULib.cmds.takeRestOfLine }
    giveability:defaultAccess( ULib.ACCESS_SUPERADMIN )
    giveability:help( "" )
end

function ulx.steamsharing( ply, tply )
    if tply:OwnerSteamID64() == tply:SteamID64() then
        ply:RXSENDNotify("l:ulx_family_sharing_pt1 \""..tply:Name().."\" l:ulx_family_sharing_pt2")
        return
    end

    ply:RXSENDNotify("l:ulx_family_sharing_pt1 \""..tply:Name().."\" l:ulx_family_sharing_pt3 = <\""..tply:OwnerSteamID64().."\".")
end

local steamsharing = ulx.command( "管理", "ulx steamsharing", ulx.steamsharing, "!steamsharing" )
steamsharing:addParam{ type = ULib.cmds.PlayerArg }
steamsharing:defaultAccess( ULib.ACCESS_ADMIN )
steamsharing:help( "" )

function ulx.getgaginfo( ply, s64 )

    if s64 == "" then s64 = ply:SteamID64() end

    local steamid = util.SteamIDFrom64(s64)

    if !BREACH.Punishment.Gags[steamid] then
        ply:RXSENDNotify("l:ulx_not_gagged")
        return
    end

    local admin = BREACH.Punishment.Gags[steamid].admin
    local reason = BREACH.Punishment.Gags[steamid].reason
    local unmute = BREACH.Punishment.Gags[steamid].unban

    if reason == "" then
        reason = "No reason given"
    end

    local unmutetext = "l:ulx_never"

    if unmute > 0 then
        unmutetext = "l:ulx_after "..string.NiceTime_Full_Rus(unmute - os.time()).."."
    end

    ply:RXSENDNotify("l:ulx_gagged_by \""..admin.."\"")
    ply:RXSENDNotify("l:ulx_gag_reason <\""..reason.."\">")
    ply:RXSENDNotify("l:ulx_gag_expires "..unmutetext)

end

local getgaginfo = ulx.command( "管理", "ulx getgaginfo", ulx.getgaginfo, "!getgaginfo" )
getgaginfo:addParam{ type = ULib.cmds.StringArg, hint="SteamID64", ULib.cmds.optional }
getgaginfo:defaultAccess( ULib.ACCESS_ADMIN )
getgaginfo:help( "" )

function ulx.getmuteinfo( ply, s64 )

    if s64 == "" then s64 = ply:SteamID64() end

    local steamid = util.SteamIDFrom64(s64)

    if !BREACH.Punishment.Mutes[steamid] then
        ply:RXSENDNotify("l:ulx_not_gagged")
        return
    end

    local admin = BREACH.Punishment.Mutes[steamid].admin
    local reason = BREACH.Punishment.Mutes[steamid].reason
    local unmute = BREACH.Punishment.Mutes[steamid].unban

    if reason == "" then
        reason = "No reason given"
    end

    local unmutetext = "l:ulx_never"

    if unmute > 0 then
        unmutetext = "l:ulx_after "..string.NiceTime_Full_Rus(unmute - os.time()).."."
    end

    ply:RXSENDNotify("l:ulx_muted_by \""..admin.."\"")
    ply:RXSENDNotify("l:ulx_mute_reason <\""..reason.."\">")
    ply:RXSENDNotify("l:ulx_mute_expires "..unmutetext)

end

local getmuteinfo = ulx.command( "管理", "ulx getmuteinfo", ulx.getmuteinfo, "!getmuteinfo" )
getmuteinfo:addParam{ type = ULib.cmds.StringArg, hint="SteamID64", ULib.cmds.optional }
getmuteinfo:defaultAccess( ULib.ACCESS_ADMIN )
getmuteinfo:help( "" )

function ulx.globalban(ply, target)
    local label = IsValid(target) and target:Name() or tostring(target)
    return GlobalBan(target, ply, function(ok)
        if not ok then return end
        local message = "已永久封禁玩家「" .. label .. "」。"
        if IsValid(ply) then ply:RXSENDNotify(message) else print(message) end
        AdminActionLog(ply, target, "永久封禁", "兼容旧管理命令")
    end)
end

local globalban = ulx.command( "管理", "ulx globalban", ulx.globalban, "!globalban" )
globalban:addParam{ type = ULib.cmds.PlayerArg }
globalban:defaultAccess( ULib.ACCESS_ADMIN )
globalban:help( "兼容旧命令：按本服权限执行普通永久封禁。" )

function ulx.lastseenuser( ply, tply )
    GetConnectedUsersList(ply, tply)
end

local lastseenuser = ulx.command( "管理", "ulx lastseenuser", ulx.lastseenuser, "!lastseenuser" )
lastseenuser:addParam{ type = ULib.cmds.PlayerArg }
lastseenuser:defaultAccess( ULib.ACCESS_ADMIN )
lastseenuser:help( "" )

function ulx.unglobalban(ply, steamid)
    return UnGlobalBan(steamid, ply, function(ok)
        if not ok then return end
        local message = "已解除账号 " .. tostring(steamid) .. " 的封禁。"
        if IsValid(ply) then ply:RXSENDNotify(message) else print(message) end
        AdminActionLog(ply, steamid, "解除封禁", "兼容旧管理命令")
    end)
end

local unglobalban = ulx.command( "管理", "ulx unglobalban", ulx.unglobalban, "!unglobalban" )
unglobalban:addParam{ type = ULib.cmds.StringArg, hint = "SteamID64" }
unglobalban:defaultAccess( ULib.ACCESS_ADMIN )
unglobalban:help( "兼容旧命令：按本服权限解除封禁。" )

function ulx.giveexp( admin, ply, amount )

    ply:AddExp(amount)
    admin:RXSENDNotify("玩家 ", Color(255,0,0), "\""..ply:Name().."\"", color_white, " 获得了 "..amount.." 经验 ")
    ply:RXSENDNotify("你被赐予了：",Color(255,0,0), amount.." 经验")

end
local giveexp = ulx.command( "管理", "ulx giveexp", ulx.giveexp, "!giveexp" )
giveexp:addParam{ type = ULib.cmds.PlayerArg }
giveexp:addParam{ type = ULib.cmds.NumArg, min=0 }
giveexp:defaultAccess( ULib.ACCESS_ADMIN )
giveexp:help( "" )

function ulx.givelevel( admin, ply, amount )

    ply:AddLevel(amount)
    admin:RXSENDNotify("玩家 ", Color(255,0,0), "\""..ply:Name().."\"", color_white, " 获得了 "..amount.." 等级 ")
    ply:RXSENDNotify("你被赐予了：",Color(255,0,0), amount.." 等级")

end

local givelevel = ulx.command( "管理", "ulx givelevel", ulx.givelevel, "!givelevel" )
givelevel:addParam{ type = ULib.cmds.PlayerArg }
givelevel:addParam{ type = ULib.cmds.NumArg, min=-100 }
givelevel:defaultAccess( ULib.ACCESS_ADMIN )
givelevel:help( "" )


function ulx.givepenaltiid( admin, steamid64, amount )
    
    GivePenalty(steamid64, amount, true)
    
end
--
local givepenaltiid = ulx.command( "收容失效 帝皇", "ulx givepenaltiid", ulx.givepenaltiid, "!givepenaltiid" )
givepenaltiid:addParam{ type = ULib.cmds.StringArg, hint="SteamID64", ULib.cmds.optional }
givepenaltiid:addParam{ type = ULib.cmds.NumArg, min=-100 }
givepenaltiid:defaultAccess( ULib.ACCESS_ADMIN )
givepenaltiid:help( "" )

function ulx.getpenaltiid( admin, steamid64, amount )
    --BREACH.DataBaseSystem:UpdateData(steamid64, "level", amount, true)
    local ply = player.GetBySteamID64(steamid64)
    --if IsValid(ply) and ply:IsPlayer() then
    --  --util.SetPData(util.SteamIDFrom64(steamid64), "breach_penalty", util.GetPData(util.SteamIDFrom64("76561198966614836"), "breach_penalty", 0) + amount)
    --  GivePenalty(ply:SteamID64(), amount, true)
    admin:RXSENDNotify(util.GetPData(util.SteamIDFrom64(steamid64), "breach_penalty", 0))
    --else
    --  util.SetPData(util.SteamIDFrom64(steamid64), "breach_penalty", util.GetPData(util.SteamIDFrom64("76561198966614836"), "breach_penalty", 0) + amount)
    --end
    --GivePenalty(ply:SteamID64(), amount, true)
    
end
--
local getpenaltiid = ulx.command( "收容失效 帝皇", "ulx getpenaltiid", ulx.getpenaltiid, "!getpenaltiid" )
getpenaltiid:addParam{ type = ULib.cmds.StringArg, hint="SteamID64", ULib.cmds.optional }
getpenaltiid:defaultAccess( ULib.ACCESS_ADMIN )
getpenaltiid:help( "" )

function ulx.giveprem( admin, steamid64, amount )
    Shaky_SetupPremium(steamid64,amount * 60)
end

local giveprem = ulx.command( "收容失效 帝皇", "ulx giveprem", ulx.giveprem, "!giveprem" )
giveprem:addParam{ type = ULib.cmds.StringArg, hint="SteamID64", ULib.cmds.optional }
giveprem:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
giveprem:defaultAccess( ULib.ACCESS_ADMIN )
giveprem:help( "" )

function ulx.giverolechange( admin, steamid64, amount )

    SetPremiumSub(steamid64,amount)
    --ply:RXSENDNotify( ("Администратор %s выдал вам возможность менять роль на %s дней"):format(admin:Name(), amount) )
    admin:RXSENDNotify( ("你已给予玩家 %s 更改角色的权限，持续 %s 天"):format(steamid64, amount) )

end

local giverolechange = ulx.command( "收容失效 帝皇", "ulx giverolechange", ulx.giverolechange, "!giverolechange" )
giverolechange:addParam{ type = ULib.cmds.StringArg, hint="SteamID64", ULib.cmds.optional }
giverolechange:addParam{ type = ULib.cmds.NumArg, min=-100 }
giverolechange:defaultAccess( ULib.ACCESS_SUPERADMIN )
giverolechange:help( "!!!请指定天数!!!" )

function ulx.getrolechange( admin, steamid64, amount )
    --BREACH.DataBaseSystem:UpdateData(steamid64, "level", amount, true)
    local ply = player.GetBySteamID64(steamid64)
    --if IsValid(ply) and ply:IsPlayer() then
    --  --util.SetPData(util.SteamIDFrom64(steamid64), "breach_penalty", util.GetPData(util.SteamIDFrom64("76561198966614836"), "breach_penalty", 0) + amount)
    --  GivePenalty(ply:SteamID64(), amount, true)
    --admin:RXSENDNotify(util.GetPData(util.SteamIDFrom64(steamid64), "premium_sub", 0))

    local ExpireDate = tonumber(util.GetPData(util.SteamIDFrom64(steamid64), "premium_sub", 0))

    local str = string.NiceTime_Full_Rus(ExpireDate - os.time())

    if str then
        admin:RXSENDNotify("l:ulx_premium_will_expire_pt1 ", Color(255,255,0,200), "l:ulx_premium_will_expire_pt2", color_white, " l:ulx_premium_will_expire_pt3 ", Color(255,0,0, 200), str)
    end 
    --else
    --  util.SetPData(util.SteamIDFrom64(steamid64), "breach_penalty", util.GetPData(util.SteamIDFrom64("76561198966614836"), "breach_penalty", 0) + amount)
    --end
    --GivePenalty(ply:SteamID64(), amount, true)
    
end
--
local getrolechange = ulx.command( "收容失效 帝皇", "ulx getrolechange", ulx.getrolechange, "!getrolechange" )
getrolechange:addParam{ type = ULib.cmds.StringArg, hint="SteamID64", ULib.cmds.optional }
getrolechange:defaultAccess( ULib.ACCESS_ADMIN )
getrolechange:help( "" )

function ulx.setlevelid( admin, steamid64, amount )

    local ply = player.GetBySteamID64(steamid64)
    if IsValid(ply) and ply:IsPlayer() then
        ply:SetNLevel(amount)
        ply:RXSENDNotify("l:levels_setted_pt1 "..tostring(amount).."l:levels_setted_pt2")
    end

    BREACH.DataBaseSystem:UpdateData(steamid64, "level", amount, false)

end

local setlevelid = ulx.command( "收容失效 帝皇", "ulx setlevelid", ulx.setlevelid, "!setlevelid" )
setlevelid:addParam{ type = ULib.cmds.StringArg, hint="SteamID64", ULib.cmds.optional }
setlevelid:addParam{ type = ULib.cmds.NumArg, min=0 }
setlevelid:defaultAccess( ULib.ACCESS_ADMIN )
setlevelid:help( "" )

function ulx.givelevelid( admin, steamid64, amount )

    --BREACH.DataBaseSystem:UpdateData(steamid64, "level", amount, true)
    local ply = player.GetBySteamID64(steamid64)
    if IsValid(ply) and ply:IsPlayer() then
        ply:SetNLevel(ply:GetNLevel() + amount)
        ply:RXSENDNotify("l:levels_gifted_pt1 "..tostring(amount).."l:levels_gifted_pt2")
    end

    BREACH.DataBaseSystem:UpdateData(steamid64, "level", amount, true)

end

local givelevelid = ulx.command( "收容失效 帝皇", "ulx givelevelid", ulx.givelevelid, "!givelevelid" )
givelevelid:addParam{ type = ULib.cmds.StringArg, hint="SteamID64", ULib.cmds.optional }
givelevelid:addParam{ type = ULib.cmds.NumArg, min=-100 }
givelevelid:defaultAccess( ULib.ACCESS_ADMIN )
givelevelid:help( "" )

function ulx.removepenalty( admin, ply )

    SetPenalty(ply:SteamID64(), 0, true)
    admin:RXSENDNotify("玩家 ", Color(255,0,0), "\""..ply:Name().."\"", color_white, " 已被免除惩罚！")

end

local removepenalty = ulx.command( "收容失效 帝皇", "ulx removepenalty", ulx.removepenalty, "!removepenalty" )
removepenalty:addParam{ type = ULib.cmds.PlayerArg }
removepenalty:defaultAccess( ULib.ACCESS_ADMIN )
removepenalty:help( "" )

function ulx.checkpenalty( me )

    local amount = me:GetPenaltyAmount()

    if amount > 0 then

        me:RXSENDNotify("距离解除惩罚所需次数: ",Color(255,0,0), amount)

    else

        me:RXSENDNotify("你没有受到惩罚")

    end

end

local checkpenalty = ulx.command( "收容失效", "ulx checkpenalty", ulx.checkpenalty, "!checkpenalty" )
checkpenalty:defaultAccess( ULib.ACCESS_ALL )
checkpenalty:help( "" )

function ulx.logs( me )

    me:ConCommand("shlogs_openmenu")

end

local logs = ulx.command( "管理", "ulx logs", ulx.logs, "!logs" )
logs:defaultAccess( ULib.ACCESS_ALL )
logs:help( "打开日志面板" )

local function SendSpecMessage(ignore, ...)
    local plys = player.GetAll()
    for i = 1, #plys do
        local ply = plys[i]
        if ply:GTeam() != TEAM_SPEC and !ply:IsAdmin() then continue end
        if ply == ignore then continue end
        local msg = {...}
        ply:RXSENDNotify(unpack(msg))
    end
end

local function SendAdminMessage(ignore, ...)
    local plys = player.GetAll()
    for i = 1, #plys do
        local ply = plys[i]
        if !ply:IsAdmin() then continue end
        if ply == ignore then continue end
        local msg = {...}
        ply:RXSENDNotify(unpack(msg))
    end
end

local function ChangeTalkPunishment(caller, target, minutes, reason, voice, remove, access)
    if not ULib.ucl.query(caller, access) then
        ULib.tsayError(caller, "你没有执行此操作的权限。", true)
        return false
    end
    local amount = minutes == nil and 0 or tonumber(minutes)
    local seconds = amount and amount * 60
    if not seconds or seconds ~= seconds or seconds == math.huge or seconds < 0 then
        ULib.tsayError(caller, "处罚时长无效。", true)
        return false
    end
    local expiry = seconds == 0 and 0 or os.time() + seconds
    local label = IsValid(target) and target:IsPlayer() and target:Name() or tostring(target)
    local action = voice and "语音禁言" or "文字禁言"
    local actorName = IsValid(caller) and caller:IsPlayer() and caller:Name() or "服务端控制台"
    local logActor = IsValid(caller) and caller:IsPlayer() and (tostring(actorName) .. " (" .. tostring(caller:GetUserGroup()) .. ") [" .. tostring(caller:SteamID()) .. "]") or "服务端控制台"
    local method = (remove and "Un" or "") .. (voice and "Gag" or "Mute")
    local function complete(ok, err, record)
        if not ok then return end -- The storage layer reports failure to the caller.
        local message
        if remove then
            message = "已解除玩家「" .. label .. "」的" .. action .. "。"
        else
            local duration = seconds == 0 and "永久" or (tostring(amount) .. " 分钟")
            message = "玩家「" .. label .. "」已被" .. action .. "，期限：" .. duration .. "。"
        end
        if reason and reason ~= "" then message = message .. " 原因：" .. reason end
        if IsValid(caller) and caller:IsPlayer() then caller:RXSENDNotify(message) else print("[RX 处罚] " .. message) end
        local recipient = IsValid(target) and target:IsPlayer() and target or player.GetBySteamID(record and record.steamID or tostring(target))
        if IsValid(recipient) and recipient ~= caller then
            recipient:RXSENDNotify(message .. " 处理人：" .. actorName)
        end
        for _, observer in ipairs(player.GetAll()) do
            if observer ~= caller and observer ~= recipient and (observer:IsAdmin() or observer:GTeam() == TEAM_SPEC) then observer:RXSENDNotify(message) end
        end
        AdminActionLog(logActor, label, (remove and "解除" or "设置") .. action, message)
    end
    if remove then return BREACH.Punishment[method](BREACH.Punishment, target, caller, reason, complete) end
    return BREACH.Punishment[method](BREACH.Punishment, target, caller, expiry, reason, complete)
end

function ulx.mute(call_ply, ply, time, reason)
    return ChangeTalkPunishment(call_ply, ply, time, reason, false, false, "ulx mute")
end

local mute = ulx.command( "管理", "ulx mute", ulx.mute, "!mute" )
mute:addParam{ type=ULib.cmds.PlayerArg }
mute:addParam{ type=ULib.cmds.NumArg, hint="in minutes, 0 is Permanent", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
mute:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine }
mute:defaultAccess( ULib.ACCESS_ADMIN )
mute:help( "" )

function ulx.gag(call_ply, target, time, reason)
    return ChangeTalkPunishment(call_ply, target, time, reason, true, false, "ulx gag")
end

local gag = ulx.command( "管理", "ulx gag", ulx.gag, "!gag" )
gag:addParam{ type=ULib.cmds.PlayerArg }
gag:addParam{ type=ULib.cmds.NumArg, hint="in minutes, 0 is Permanent", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
gag:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine }
gag:defaultAccess( ULib.ACCESS_ADMIN )
gag:help( "" )

function ulx.forcesupport( call_ply, supname )
    SupportSpawn(true,supname)
end

local forcesupport = ulx.command( "管理", "ulx forcesupport", ulx.forcesupport, "!forcesupport" )
forcesupport:addParam{ type=ULib.cmds.StringArg, hint="supportname", completes = {"GRU", "COTSK", "FBI", "CHAOS", "NTF", "GOC", "DZ", "AR","CBG","OBR","FBIAgents"} }
forcesupport:defaultAccess( ULib.ACCESS_SUPERADMIN )
forcesupport:help( "" )

function ulx.forceround( call_ply, roundname )

    --if call_ply:SteamID64() != "76561198869328954" then return end

    forceround = roundname
    if forceround == "furry_event" then
        SetGlobalBool("NextFurry", true)
    end

end

local forceround = ulx.command( "管理", "ulx forceround", ulx.forceround, "!forceround" )
forceround:addParam{ type=ULib.cmds.StringArg, hint="roundname", completes = {"normal","normalevent", "ww2tdm", "hl2tdm","uiugoc","event","ny_event","furry_event"} }
forceround:defaultAccess( ULib.ACCESS_SUPERADMIN )
forceround:help( "" )

function ulx.adminlog( call_ply, type, admin, victim )

    if !admin or admin == "admin" then admin = "" end
    if !victim or victim == "victim" then victim = "" end
    if type == "all" then type = "" end

    if admin:find("STEAM_") then admin = util.SteamIDTo64(admin) end
    if victim:find("STEAM_") then victim = util.SteamIDTo64(victim) end

    request_admin_log(call_ply, type, admin, victim)

end

local adminlog = ulx.command( "管理", "ulx adminlog", ulx.adminlog, "!adminlog" )
adminlog:addParam{ type=ULib.cmds.StringArg, hint="type", completes = {"gag", "mute", "ungag", "unmute", "ban", "unban", "all"} }
adminlog:addParam{ type=ULib.cmds.StringArg, hint="admin", ULib.cmds.optional }
adminlog:addParam{ type=ULib.cmds.StringArg, hint="victim", ULib.cmds.optional }
adminlog:defaultAccess( ULib.ACCESS_ADMIN )
adminlog:help( "" )

function ulx.prioritysupport( call_ply )

    --forcesupportplys = call_ply
    if !call_ply:IsDonator() then return call_ply:RXSENDNotify("不行，滚") end
    if !call_ply:GetNWBool("prioritysup") or call_ply:GetNWBool("prioritysup") == nil then
        call_ply:RXSENDNotify("感谢支持，您已获得下次生成的优先权")
        call_ply:SetNWBool("prioritysup",true)
    else
        call_ply:RXSENDNotify("优先权已被收回")
        call_ply:SetNWBool("prioritysup",false)
    end
    --call_ply:RXSENDNotify(v:Name())

end

local prioritysupport = ulx.command( "管理", "ulx prioritysupport", ulx.prioritysupport, "!prioritysupport" )
prioritysupport:defaultAccess( ULib.ACCESS_SUPERADMIN )
prioritysupport:help( "增加生成几率（每次生成后需要重新开启）" )

function ulx.priorityvoice( call_ply )

    --forcesupportplys = call_ply
    if !call_ply:GetNWBool("priorityvoice") or call_ply:GetNWBool("priorityvoice") == nil then
        call_ply:RXSENDNotify("你已获得对所有人说话的权限")
        call_ply:SetNWBool("priorityvoice",true)
    else
        call_ply:RXSENDNotify("权限已被收回")
        call_ply:SetNWBool("priorityvoice",false)
    end
    --call_ply:RXSENDNotify(v:Name())

end

local priorityvoice = ulx.command( "管理", "ulx priorityvoice", ulx.priorityvoice, "!priorityvoice" )
priorityvoice:defaultAccess( ULib.ACCESS_SUPERADMIN )
priorityvoice:help( "开启后所有人都能听到你说话" )

function ulx.expiredaterole( ply )

    if !ply:HasPremiumSub() then
        ply:RXSENDNotify("你没有设置角色的权限")
        return
    end

    local ExpireDate = tonumber(util.GetPData(util.SteamIDFrom64(ply:SteamID64()), "premium_sub", 0))

    local str = string.NiceTime_Full_Rus(ExpireDate - os.time())

    if str then
        ply:RXSENDNotify("你的 ", Color(255,255,0,200), "角色设置权限", color_white, " 将在以下时间后到期：", Color(255,0,0, 200), str)
    end 

end

local expiredaterole = ulx.command( "会员", "ulx expiredaterole", ulx.expiredaterole, "!expiredaterole" )
expiredaterole:defaultAccess( ULib.ACCESS_ALL )
expiredaterole:help( "" )

function ulx.expiredate( ply )

    if !ply:IsPremium() then
        ply:RXSENDNotify("l:ulx_premium_expired")
        return
    end

    local ExpireDate = tonumber(ply:GetBreachData("premium"))

    local str = string.NiceTime_Full_Rus(ExpireDate - os.time())

    if str then
        ply:RXSENDNotify("l:ulx_premium_will_expire_pt1 ", Color(255,255,0,200), "l:ulx_premium_will_expire_pt2", color_white, " l:ulx_premium_will_expire_pt3 ", Color(255,0,0, 200), str)
    end 

end

local expiredate = ulx.command( "会员", "ulx expiredate", ulx.expiredate, "!expiredate" )
expiredate:defaultAccess( ULib.ACCESS_ALL )
expiredate:help( "" )

function ulx.expiredate_admin( ply )

    if !ply:IsUserGroup("donate_admin") then
        ply:RXSENDNotify("l:ulx_admin_expired")
        return
    end

    local ExpireDate = tonumber(ply:GetBreachData("adminka"))

    local str = string.NiceTime_Full_Rus(ExpireDate - os.time())

    if str then
        ply:RXSENDNotify("l:ulx_admin_will_expire_pt1 ", Color(0,255,255,200), "l:ulx_admin_will_expire_pt2", color_white, " l:ulx_admin_will_expire_pt3 ", Color(255,0,0, 200), str)
    end 

end

local expiredate_admin = ulx.command( "管理", "ulx expiredate_admin", ulx.expiredate_admin, "!expiredate_admin" )
expiredate_admin:defaultAccess( ULib.ACCESS_ALL )
expiredate_admin:help( "" )

function ulx.muteid(call_ply, target, time, reason)
    return ChangeTalkPunishment(call_ply, target, time, reason, false, false, "ulx muteid")
end

local muteid = ulx.command( "管理", "ulx muteid", ulx.muteid, "!muteid" )
muteid:addParam{ type=ULib.cmds.StringArg, hint="SteamID64" }
muteid:addParam{ type=ULib.cmds.NumArg, hint="in minutes, 0 is Permanent", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
muteid:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine }
muteid:defaultAccess( ULib.ACCESS_ADMIN )
muteid:help( "" )

if SERVER then
    util.AddNetworkString("FUNNY_PIC_NET")
else
    net.Receive("FUNNY_PIC_NET", function()
    
        local emg = net.ReadString()

        local img = vgui.Create("DImage")
        img:SetSize(ScrW(), ScrH())

        local mat = LOUNGE_CHAT.GetDownloadedImage(emg)
            if (mat) then
                img.m_Image = mat
                --img:SetSize(mat:Width(), mat:Height())
                --img:Center()
            else
        LOUNGE_CHAT.DownloadImage(
            emg,
                function(mat)
                    if (IsValid(img)) then
                        img.m_Image = mat
                        --img:SetSize(mat:Width(), mat:Height())
                        --img:Center()
                    end
                end
            )
        end

        img.Paint = function(self, w, h)
            if self.m_Image then
                if !self.disappear then
                    self.disappear = true
                    self:AlphaTo(0, 5, 0, function() self:Remove() end)
                end
                surface.SetDrawColor(255,255,255)
                surface.SetMaterial(self.m_Image)
                surface.DrawTexturedRect(0,0,w,h)
            end
        end

        timer.Simple(10, function() img:Remove() end)

    end)
end

function ulx.funnypic(call_ply, plys, img)

    
    net.Start("FUNNY_PIC_NET")
    net.WriteString(img)
    net.Send(plys)

end

local funnypic = ulx.command( "Shaky 奇妙技能", "ulx funnypic", ulx.funnypic, "!funnypic" )
funnypic:addParam{ type=ULib.cmds.PlayersArg }
funnypic:addParam{ type=ULib.cmds.StringArg, hint="Image url (MUST BE IMGUR)" }
funnypic:defaultAccess( ULib.ACCESS_SUPERADMIN )
funnypic:help( "" )

function ulx.gagid(call_ply, target, time, reason)
    return ChangeTalkPunishment(call_ply, target, time, reason, true, false, "ulx gagid")
end

local gagid = ulx.command( "管理", "ulx gagid", ulx.gagid, "!gagid" )
gagid:addParam{ type=ULib.cmds.StringArg, hint="SteamID64" }
gagid:addParam{ type=ULib.cmds.NumArg, hint="in minutes, 0 is Permanent", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
gagid:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine }
gagid:defaultAccess( ULib.ACCESS_ADMIN )
gagid:help( "" )

function ulx.unmute(call_ply, target)
    return ChangeTalkPunishment(call_ply, target, 0, nil, false, true, "ulx unmute")
end

local unmute = ulx.command( "管理", "ulx unmute", ulx.unmute, "!unmute" )
unmute:addParam{ type=ULib.cmds.PlayerArg }
unmute:defaultAccess( ULib.ACCESS_ADMIN )
unmute:help( "" )

function ulx.ungag(call_ply, target)
    return ChangeTalkPunishment(call_ply, target, 0, nil, true, true, "ulx ungag")
end

local ungag = ulx.command( "管理", "ulx ungag", ulx.ungag, "!ungag" )
ungag:addParam{ type=ULib.cmds.PlayerArg }
ungag:defaultAccess( ULib.ACCESS_ADMIN )
ungag:help( "" )

function ulx.unmuteid(call_ply, target)
    return ChangeTalkPunishment(call_ply, target, 0, nil, false, true, "ulx unmuteid")
end

local unmuteid = ulx.command( "管理", "ulx unmuteid", ulx.unmuteid, "!unmuteid" )
unmuteid:addParam{ type=ULib.cmds.StringArg, hint="SteamID64" }
unmuteid:defaultAccess( ULib.ACCESS_ADMIN )
unmuteid:help( "" )

function ulx.ungagid(call_ply, target)
    return ChangeTalkPunishment(call_ply, target, 0, nil, true, true, "ulx ungagid")
end

local ungagid = ulx.command( "管理", "ulx ungagid", ulx.ungagid, "!ungagid" )
ungagid:addParam{ type=ULib.cmds.StringArg, hint="SteamID64" }
ungagid:defaultAccess( ULib.ACCESS_ADMIN )
ungagid:help( "" )

if SERVER then
    util.AddNetworkString("change_ignore_state")
else
    net.Receive("change_ignore_state", function()
        local ply = net.ReadEntity()
        local client = LocalPlayer()
        local name = ply:Name()
        if client:GTeam() != TEAM_SPEC and ply:GTeam() != TEAM_SPEC then
            --но зачем?
            --name = ply:GetNamesurvivor()
        end
        if ply:IsMuted() then
            chat.AddText(Color(0, 255, 0), "[Legacy Breach] ", Color(255, 255, 255), BREACH.TranslateString("l:ulx_unignore ")..name)
        else
            if client:GTeam() != TEAM_SPEC then
                if !(client:GTeam() == TEAM_SCP and ply:GTeam() == TEAM_SCP) then
                    chat.AddText(Color(0, 255, 0), "[Legacy Breach] ", Color(255, 255, 255), BREACH.TranslateString("l:clientside_mute_spec_only"))
                    return
                end
            end
            chat.AddText(Color(0, 255, 0), "[Legacy Breach] ", Color(255, 255, 255), BREACH.TranslateString("l:ulx_ignore ")..name)
        end
        ply:SetMuted(!ply:IsMuted())
    end)

end

function ulx.ignore(call_ply, send_ply)

    net.Start("change_ignore_state")
    net.WriteEntity(send_ply)
    net.Send(call_ply)

end

local ignore = ulx.command( "管理", "ulx ignore", ulx.ignore, "!ignore" )
ignore:addParam{ type=ULib.cmds.PlayerArg }
ignore:defaultAccess( ULib.ACCESS_ALL )
ignore:help( "" )

-- Expiry for online and offline punishments is owned by rxsend/punishments.lua.
if SERVER then hook.Remove("Think", "RXSEND_MuteThink") end

function SetupForceSCP()
    if !ulx or !ULib then 
        print( "ULX or ULib not found" )
        return
    end
    
    function ulx.forcescp( plyc, plyt, scp, silent )
        if !scp then return end
        --for k, v in pairs( SPCS ) do
            --if v.name == scp then
                --v.func( plyt )
        local scp_obj = GetSCP( scp )
        if scp_obj then
            plyt:SetupNormal()
            scp_obj:SetupPlayer( plyt )

            if silent then
                ulx.fancyLogAdmin( plyc, true, "#A force spawned #T as "..scp, plyt )
            else
                ulx.fancyLogAdmin( plyc, "#A force spawned #T as "..scp, plyt )
            end
                --break
            --end
        else
            ULib.tsayError( plyc, "Invalid SCP "..scp.."!", true )
        end
    end

    local forcescp = ulx.command( "收容失效 管理", "ulx force_scp", ulx.forcescp, "!forcescp" )
    forcescp:addParam{ type = ULib.cmds.PlayerArg }
    forcescp:addParam{ type = ULib.cmds.StringArg, hint = "SCP name", completes = SCPS, ULib.cmds.takeRestOfLine }
    forcescp:addParam{ type = ULib.cmds.BoolArg, invisible = true }
    forcescp:setOpposite( "ulx silent force_scp", { _, _, _, true }, "!sforcescp" )
    forcescp:defaultAccess( ULib.ACCESS_SUPERADMIN )
    forcescp:help( "Sets player to specific SCP and spawns him" )
end

InitializeBreachULX()
SetupForceSCP()
FORCESPAWN_BUTWORKING()
ABILITYGIVE_LOL()

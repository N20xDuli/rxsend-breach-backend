local nu7 = BREACH.Nu7
util.AddNetworkString("NU7_DeploymentIntro")
resource.AddWorkshop(nu7.Config.ModelWorkshopID)
resource.AddFile("materials/nextoren/gui/roles_icon/nu7.png")
resource.AddFile("materials/nextoren/gui/roles_icon/nu7_intro_badge.png")
resource.AddFile("sound/" .. nu7.SpawnAnnouncement)
resource.AddFile("sound/rxsend/nu7/nu7_intro_301c3f19c0.ogg")
nu7.CallsThisRound = nu7.CallsThisRound or 0

function nu7.ResetRoundState()
    if nu7.ResetSkills then nu7.ResetSkills() end
    nu7.CallsThisRound = 0
    nu7.SpawnAnnounced = false
end

-- Facility announcement is sent only by an accepted nu7.Call deployment.

local enemyTeams = {
    [TEAM_CLASSD] = true, [TEAM_CHAOS] = true, [TEAM_DZ] = true,
    [TEAM_GOC] = true, [TEAM_USA] = true, [TEAM_GRU] = true,
    [TEAM_COTSK] = true,
}

-- Count living human units. SCPs and spectators never affect the ratio.
function nu7.GetForceCounts()
    local foundationCount, enemyCount = 0, 0
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() and ply:Health() > 0 and ply.GTeam then
            local teamID = ply:GTeam()
            local roleName = ply.GetRoleName and ply:GetRoleName() or ""
            local isEnemySpy = roleName == role.SECURITY_Spy or roleName == role.SCI_SpyUSA
                or roleName == role.SCI_SpyDZ or roleName == role.ClassD_GOCSpy
            local isAlliedGRU = teamID == TEAM_GRU and GRU_Objectives
                and GRU_Objective == GRU_Objectives["MilitaryHelp"]
            if teamID ~= TEAM_SCP and teamID ~= TEAM_SPEC then
                if isEnemySpy then
                    enemyCount = enemyCount + 1
                elseif nu7.IsFoundationTeam(teamID) then
                    foundationCount = foundationCount + 1
                elseif enemyTeams[teamID] and not isAlliedGRU then
                    enemyCount = enemyCount + 1
                end
            end
        end
    end
    return foundationCount, enemyCount
end

local function roundAllowsCall()
    if not gamestarted or preparing or postround then
        return false, "仅可在正式回合期间呼叫支援。"
    end
    if nu7.CallsThisRound >= nu7.Config.MaxCallsPerRound then
        return false, "本局已呼叫过落锤支援。"
    end
    return true
end

-- Permission/condition API for the broadcast-room panel; does not deploy a wave.
function nu7.CanCall(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() or ply:Health() <= 0
        or ply:GetRoleName() ~= role.Dispatcher or not ply.GTeam
        or not nu7.IsFoundationTeam(ply:GTeam()) then
        return false, "仅存活的基金会调度员可以呼叫落锤支援。"
    end
    local allowed, reason = roundAllowsCall()
    if not allowed then return false, reason end
    local foundationCount, enemyCount = nu7.GetForceCounts()
    if not nu7.IsInDanger(foundationCount, enemyCount) then
        return false, "基金会未达到支援条件：少于5人，或人数不足敌方的20%。"
    end
    return true
end

function nu7.CanAdminCall(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ULib or not ULib.RXAdminPolicy
        or (ULib.RXAdminPolicy.GroupRank(ply:GetUserGroup()) or 0) < 1
        or not ULib.ucl.query(ply, "ulx forcesupport") then
        return false, "没有支援调度权限。"
    end
    return roundAllowsCall()
end

-- Call only after a deployment request is accepted; failed calls must not consume it.
function nu7.MarkCallAccepted()
    if nu7.CallsThisRound >= nu7.Config.MaxCallsPerRound then return false end
    nu7.CallsThisRound = nu7.CallsThisRound + 1
    return true
end

local function deploy()
    local candidates = {}
    for _, ply in ipairs(GetActivePlayers()) do
        if IsValid(ply) and not ply:IsBot() and ply:GTeam() == TEAM_SPEC
            and not ply.AFK and ply.SpawnAsSupport ~= false and ply:GetPenaltyAmount() <= 0 then
            candidates[#candidates + 1] = ply
        end
    end
    if #candidates == 0 then return false, "没有可加入支援的观察者：需要未挂机、允许支援且无处罚的真实玩家。" end
    if not SPAWN_OUTSIDE or #SPAWN_OUTSIDE == 0 then return false, "当前地图缺少落锤出生点配置（SPAWN_OUTSIDE）。" end
    local count = math.min(nu7.GetSupportCount(), #candidates, #SPAWN_OUTSIDE)
    if count < 1 then return false, "当前没有可用的落锤支援名额。" end
    table.Shuffle(candidates)
    local spawns = table.Copy(SPAWN_OUTSIDE)
    table.Shuffle(spawns)
    local order = {"commander", "containment", "medic", "heavy", "marksman", "soldier"}
    local prepared = {}
    -- Validate the entire deployment before spending the once-per-round call or changing a player.
    for i = 1, count do
        local member = nu7.FindMember(order[i] or "soldier")
        local entry, errorText = nu7.PrepareRole(member.name)
        if not entry then return false, errorText end
        prepared[i] = entry
    end
    if not nu7.MarkCallAccepted() then return false, "本局已呼叫过落锤支援。" end
    nu7.SpawnAnnounced = true
    PlayAnnouncer(nu7.SpawnAnnouncement)
    for i = 1, count do
        local ply = candidates[i]
        ply:SetupNormal()
        ply:ApplyRoleStats(prepared[i])
        ply:SetPos(spawns[i])
        ply:SelectWeapon(prepared[i].weapons[3])
    end
    return true, "已部署 " .. count .. " 名落锤支援人员。"
end

function nu7.Call(caller)
    local allowed, reason = nu7.CanCall(caller)
    if not allowed then return false, reason end
    return deploy()
end

-- Management dispatch bypasses only the dispatcher role and force ratio.
-- Both paths share the same real roles, spectator eligibility and round budget.
function nu7.AdminCall(caller)
    local allowed, reason = nu7.CanAdminCall(caller)
    if not allowed then return false, reason end
    return deploy()
end

-- Deployment requests now come from the dispatcher's intercom menu.
hook.Remove("OnEntityCreated", "NU7BroadcastPanel")
timer.Simple(0, function()
    for _, panel in ipairs(ents.FindByClass("ent_nu7_support_panel")) do panel:Remove() end
end)

-- Superadmin test uses the same prepared role and ammunition as normal deployment.
concommand.Add("nu7_test_spawn", function(admin, _, args)
 if not IsValid(admin) or not admin:IsSuperAdmin() then return end
 local key = string.lower(args[1] or "commander")
 local member = nu7.FindMember(key)
 if not member then admin:PrintMessage(HUD_PRINTCONSOLE, "Nu-7: commander / containment / soldier / heavy / marksman / medic"); return end
 local prepared, reason = nu7.PrepareRole(member.name)
 if not prepared then admin:RXSENDNotify(reason); return end
 local announced = nu7.SpawnAnnounced
 admin:SetupNormal()
 admin:ApplyRoleStats(prepared)
 nu7.SpawnAnnounced = announced
 admin:SelectWeapon(prepared.weapons[3])
 admin:PrintMessage(HUD_PRINTCONSOLE, "Nu-7 " .. member.key .. ": " .. prepared.weapons[3])
end)

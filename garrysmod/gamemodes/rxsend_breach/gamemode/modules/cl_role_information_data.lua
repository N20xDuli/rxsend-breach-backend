-- Read-only view of the local player's current role. No observed-player data is used.
BREACH = BREACH or {}
BREACH.RoleInfo = BREACH.RoleInfo or {}
local I = BREACH.RoleInfo

local keyLabels = {
    mouse1 = "鼠标左键", mouse2 = "鼠标右键", mouse3 = "鼠标中键",
    mouse4 = "鼠标侧键 1", mouse5 = "鼠标侧键 2",
    mwheelup = "滚轮向上", mwheeldown = "滚轮向下", space = "空格",
    lshift = "左 Shift", rshift = "右 Shift", lcontrol = "左 Ctrl", rcontrol = "右 Ctrl",
    lalt = "左 Alt", ralt = "右 Alt", enter = "回车", escape = "Esc", tab = "Tab",
    backspace = "退格", uparrow = "上方向键", downarrow = "下方向键",
    leftarrow = "左方向键", rightarrow = "右方向键", none = "未绑定"
}

function I.KeyName(code)
    local key = isnumber(code) and (code > 0 and input.GetKeyName(code) or nil) or code
    if not isstring(key) or key == "" then return "未绑定" end
    return keyLabels[string.lower(key)] or string.upper(key)
end

function I.Binding(command)
    return I.KeyName(input.LookupBinding(command))
end

function I.ConfigKey(name)
    local value = GetConVar(name)
    return I.KeyName(value and value:GetInt())
end

function I.InfoKey()
    return I.KeyName(input.LookupBinding("br_description") or input.LookupBinding("gm_showhelp"))
end

local abilityNames = {
    ["Shuriken"] = "投掷飞镖", speed = "加速", ["Directed Psy-Attack"] = "定向精神攻击",
    ["Mass Psy-Attack"] = "群体精神攻击", ["Melee grab"] = "近身抓取",
    ["Full-Recover"] = "完全治疗", ["Global Heal"] = "范围治疗", ["Slime Trap"] = "黏液束缚",
    ["Slime Blind"] = "黏液致盲", ["Stun gun"] = "电击枪", Shotgun = "霰弹枪", Revolver = "左轮手枪"
}

local function translated(value, fallback)
    local text = tostring(value or "")
    if BREACH.TranslateString then text = BREACH.TranslateString(text) end
    local catalog = BREACH.Localization and BREACH.Localization.Catalog() or {}
    text = abilityNames[text] or (isstring(catalog[text]) and catalog[text]) or text
    text = string.Trim(text)
    if text == "" or string.find(text, "l:", 1, true) == 1 then return fallback or "暂无说明" end
    return text
end

function I.FindRole(roleId, teamId)
    local fallback
    local scpId = isstring(roleId) and string.match(roleId, "^SCP[%d%-%s_]") and string.gsub(roleId, "[^%w]", "")
    for _, groups in pairs(BREACH_ROLES or {}) do
        if not istable(groups) then continue end
        for _, group in pairs(groups) do
            if not istable(group) or not istable(group.roles) then continue end
            for _, entry in pairs(group.roles) do
                local matches = entry.name == roleId or (scpId and isstring(entry.name) and
                    string.gsub(entry.name, "[^%w]", "") == scpId)
                if matches then
                    if entry.team == teamId then return entry end
                    fallback = fallback or entry
                end
            end
        end
    end
    return fallback
end

local function taskLines(text)
    local result = {}
    for _, line in ipairs(string.Explode("\n", translated(text, ""))) do
        line = string.Trim(line)
        if line ~= "" then result[#result + 1] = line end
    end
    return result
end

local reloadAbilities = {
    weapon_scp_106 = true, weapon_scp_076_defend = true, weapon_scp_2012 = true,
    weapon_scp_2012_crossbow = true, weapon_scp_811 = true, weapon_scp_973 = true, weapon_scp_542 = true
}

-- Fill empty legacy descriptions from the corresponding SWEP actions. These are
-- display strings only; skill parameters and authorization still come from the weapon.
local scpDescriptions = {
    weapon_scp_106 = {
        "切换幽灵模式，隐藏身形并提高移动速度；幽灵模式期间不能使用另外两项技能。",
        "进入口袋维度。冷却结束后，在维度内按 H 返回进入前的位置。",
        "向前释放一列暗影陷阱，将触碰陷阱的人类送入口袋维度。"
    },
    weapon_scp_811 = {
        "向前发射酸液弹。", "向远处发射酸液弹。", "在准星所指的位置放置酸液陷阱。",
        "向前喷吐酸液；动作期间无法自由移动。", "释放酸液爆发，对附近区域造成爆炸伤害。"
    },
    weapon_scp_682 = {
        "获得持续 15 秒的伤害减免。", "大幅提高移动速度，持续 7 秒。",
        "逐步恢复生命，总量最多为最大生命的 20%。", "咆哮干扰附近人类的视野、听觉与转向。"
    },
    weapon_scp_1903 = {
        "近距离瞄准一名人类，使其短暂失明并持续受到精神伤害。",
        "对周围人类施加失明和持续精神伤害，并短暂标记受影响的目标。"
    },
    weapon_scp_973 = {"近距离电击一名人类，使其暂时无法移动。", "取出霰弹枪。", "取出左轮手枪。"},
    weapon_scp_2012 = {"切换剑盾与双手剑战斗姿态。"},
    weapon_scp_2012_crossbow = {"收起弩，切换为双手剑。", "收起弩，切换为剑盾。"}
}

local function abilityKey(value, weaponClass)
    if value == "Nonekey" then return "被动" end
    if value == "LMB" then return I.Binding("+attack") end
    if value == "RMB" then return I.Binding("+attack2") end
    -- Some legacy icons label Reload with a numeric key; SCP-062 instead polls KEY_R.
    if value == "R" or (value == KEY_R and reloadAbilities[weaponClass]) then return I.Binding("+reload") end
    return I.KeyName(value)
end

local function abilityStatus(remaining, count, blocked, passive)
    if passive then return "被动能力" end
    if count ~= nil and count <= 0 then return "次数已用尽" end
    if blocked then return "暂不可用" end
    if remaining == nil then return "状态更新中" end
    if remaining > 0 then return "冷却中 · " .. remaining .. " 秒" end
    return "就绪"
end

local function scpAbilities(ply)
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or not istable(weapon.AbilityIcons) or #weapon.AbilityIcons == 0 then
        weapon = nil
        for _, carried in ipairs(ply:GetWeapons()) do
            if IsValid(carried) and istable(carried.AbilityIcons) and #carried.AbilityIcons > 0 then
                weapon = carried
                break
            end
        end
    end
    local result = {}
    if not IsValid(weapon) then return result end
    local definitions, weaponClass = weapon.AbilityIcons, weapon:GetClass()
    if weaponClass == "weapon_scp_2012" and weapon.GetStance then
        definitions = definitions[weapon:GetStance()] or {}
    end
    for index, definition in ipairs(definitions) do
        if not istable(definition) or not definition.Name then continue end
        -- SCP weapons treat an unset initial deadline as zero in their own checks.
        local remaining = math.max(0, math.ceil((tonumber(definition.CooldownTime) or 0) - CurTime()))
        local title = translated(definition.Name, "异常能力")
        local passive = definition.KEY == "Nonekey"
        local count = definition.max and weaponClass == "weapon_scp_811" and math.max(0, ply:GetSpecialMax()) or nil
        local blocked = definition.Forbidden == true or ply:IsFrozen() or ply.MovementLocked == true
        local status = abilityStatus(remaining, count, blocked, passive)
        local description = translated(definition.Description)
        local supplemental = scpDescriptions[weaponClass]
        if supplemental and supplemental[index] then description = supplemental[index] end
        local cooldown = tonumber(definition.Cooldown)
        if definition.bodies and weapon.GetBodies then
            local bodies = weapon:GetBodies()
            description = description .. "\n解锁条件：吸食 " .. definition.bodies .. " 具尸体。"
            if bodies < definition.bodies then
                -- This weapon writes missing bodies into CooldownTime for its old icon.
                remaining, blocked, status = nil, true, "尚未解锁 · 还需 " .. (definition.bodies - bodies) .. " 具尸体"
            end
        end
        if definition.Acid and weapon.GetAcidAmount then
            local acid = math.max(0, math.floor(weapon:GetAcidAmount()))
            description = description .. "\n消耗酸液：" .. definition.Acid .. "。"
            if acid < definition.Acid then blocked, status = true, "酸液不足" end
            status = status .. " · 酸液 " .. acid
        end
        if weaponClass == "weapon_scp_973" and weapon.GetRage then
            local cost = ({25, 75, 50})[index]
            local rage = math.max(0, math.floor(weapon:GetRage()))
            -- The legacy icon calls rage cost Cooldown; only the stun has a timer.
            cooldown = index == 1 and 4 or nil
            remaining = index == 1 and math.max(0, math.ceil((weapon.NextSecondaryAttack or 0) - CurTime())) or 0
            blocked = rage < cost or ply:IsFrozen() or ply.MovementLocked == true
            status = rage < cost and "怒气不足" or abilityStatus(remaining, nil, blocked)
            description = description .. "\n消耗怒气：" .. cost .. "。"
            status = status .. " · 怒气 " .. rage
        elseif weaponClass == "weapon_scp_035" then
            description, status, blocked = "当前版本未开放这项操作。", "未开放", true
        elseif weaponClass == "weapon_scp_912" then
            description = description .. "\n手持配发的沙鹰手枪时使用。"
            local active = ply:GetActiveWeapon()
            if not IsValid(active) or active:GetClass() ~= "cw_kk_scp_912_deagle" then
                blocked, status = true, "需要手持配发沙鹰"
            end
        end
        result[#result + 1] = {
            title = title, name = title, description = description,
            key = abilityKey(definition.KEY, weaponClass), cooldown = cooldown,
            remaining = remaining, count = count, blocked = blocked,
            status = status, passive = passive
        }
    end
    return result
end

local function humanAbilities(ply, entry, roleId, teamId)
    local configured = entry and entry.ability
    local special = ply.SpecialTable
    local registeredName = ply:GetNWString("AbilityName", "")
    local panel = istable(BREACH.Abilities) and BREACH.Abilities.HumanSpecial
    local panelMatches = not IsValid(panel) or not panel.RXRole or
        (panel.RXRole == roleId and panel.RXTeam == teamId)
    -- The role and ability arrive on different channels. Never display the previous
    -- role's SpecialTable during that interval, including roles with no active skill.
    local tiedToRole = IsValid(panel) and panel.RXRole == roleId and panel.RXTeam == teamId
    local received = istable(special) and registeredName ~= "" and special.Name == registeredName and
        panelMatches and (tiedToRole or (configured and special.Name == configured[1]))
    if not configured and not received then return {} end
    local definition = received and special or {
        Name = configured[1], Cooldown = configured[2], Description = configured[3], Countable = configured[5]
    }
    local current = received or (configured and registeredName == configured[1] and panelMatches)
    local remaining = current and math.max(0, math.ceil(ply:GetSpecialCD() - CurTime())) or nil
    local count = current and definition.Countable and math.max(0, ply:GetSpecialMax()) or nil
    local blocked = current and ((IsValid(panel) and panel.Blocked == true) or
        ply:IsFrozen() or ply.MovementLocked == true) or false
    local title = translated(definition.Name, "角色技能")
    local status = abilityStatus(remaining, count, blocked)
    local abilityKeyName = I.ConfigKey("breach_config_useability")
    local radio = ply.GetWeapon and ply:GetWeapon("item_radio")
    if IsValid(radio) and abilityKeyName ~= "未绑定" and abilityKeyName == I.ConfigKey("breach_config_radio_mute") then
        status, blocked = "按键被无线电静音占用", true
    end
    return {{title = title, name = title, description = translated(definition.Description),
        key = abilityKeyName, cooldown = tonumber(definition.Cooldown), remaining = remaining,
        count = count, blocked = blocked, status = status}}
end

function I.Snapshot(ply)
    ply = ply or LocalPlayer()
    local observer = not IsValid(ply) or not ply:Alive() or ply:Health() <= 0 or
        ply:GTeam() == TEAM_SPEC or (ply.GetObserverMode and ply:GetObserverMode() ~= OBS_MODE_NONE)
    if observer then
        return {observer = true, identity = "观察员", roleId = "", teamId = TEAM_SPEC,
            faction = "观战", description = "等待角色分配，可查看角色图鉴。",
            tasks = {}, abilities = {}}
    end
    local roleId, teamId = ply:GetRoleName(), ply:GTeam()
    local entry = I.FindRole(roleId, teamId)
    local tasks = taskLines(entry and entry.tasks)
    if BREACH.Nu7 and BREACH.Nu7.FindMember(roleId) then
        tasks = taskLines(BREACH.Nu7.MissionText)
    elseif BREACH.IsUiuAgent and BREACH:IsUiuAgent(roleId) then
        tasks = taskLines(BREACH.GetDescription(roleId))
    elseif teamId == TEAM_GRU then
        local objective = GRU_Objective
        if objective and objective ~= "" then
            tasks[#tasks + 1] = "当前行动：" .. translated(objective)
        end
    end
    local abilities = teamId == TEAM_SCP and scpAbilities(ply) or humanAbilities(ply, entry, roleId, teamId)
    return {observer = false, identity = GetLangRole(roleId), roleId = roleId, teamId = teamId,
        faction = translated(gteams.GetName(teamId), "未知阵营"),
        description = translated(BREACH.GetDescription(roleId)), tasks = tasks,
        abilities = abilities, ability = abilities[1]}
end

function I.Controls(ply)
    ply = ply or LocalPlayer()
    local result = {
        {key = I.InfoKey(), label = "角色与帮助", description = "查看当前身份、任务、技能与按键。"},
        {key = I.Binding("gm_showteam"), label = "角色图鉴", description = "观战时查看各阵营与角色资料。"},
        {key = I.Binding("+showscores"), label = "计分板", description = "按住查看；仅观战、竞技场与超级管理员可用。"},
        {key = "F3", label = "技能与设备鼠标", description = "查看技能提示，或操作摄像头、广播设备。"},
        {key = I.ConfigKey("breach_config_openinventory"), label = "背包", description = "移动时也可打开；左键拿取物品，右键丢弃，再次按下关闭。"},
        {key = I.Binding("+use"), label = "交互与搜尸", description = "靠近并对准物品、门或尸体后使用。"},
        {key = "1 / 2 / 3", label = "物品快捷栏", description = "在背包中悬停物品并按数字绑定；关闭背包后按数字切换。"},
        {key = I.ConfigKey("breach_config_useability"), label = "角色技能", description = "人类主动技能使用此键；SCP 技能按键见技能说明。"},
        {key = I.ConfigKey("breach_config_radio_mute"), label = "无线电静音", description = "携带无线电时切换静音；与技能同键时优先操作无线电。"},
        {key = I.ConfigKey("breach_config_quickchat"), label = "快捷交流", description = "打开预设交流菜单。"},
        {key = I.Binding("+voicerecord"), label = "语音交流", description = "按住说话；接收范围由阵营、无线电及观战状态决定。"},
        {key = I.Binding("messagemode"), label = "文字聊天", description = "打开文字输入框。"},
        {key = I.Binding("+attack") .. " / " .. I.Binding("+attack2"), label = "主要与次要操作", description = "武器射击、瞄准或道具的主要、次要功能。"},
        {key = I.Binding("+reload"), label = "装填与道具操作", description = "装填武器；部分道具与 SCP 使用此键执行专属操作。"},
        {key = I.Binding("+speed") .. " / " .. I.Binding("+duck"), label = "奔跑与蹲下", description = "按住奔跑；按蹲下键切换蹲姿，受当前角色与状态限制。"},
        {key = "Esc", label = "关闭与设置", description = "关闭当前窗口；游戏主菜单中可调整操作设置。"}
    }
    return result
end

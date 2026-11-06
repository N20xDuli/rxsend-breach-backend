-- Combat presentation only. Gameplay, prediction and input stay with their owners.
BREACH.CombatHUD = BREACH.CombatHUD or {}
local H = BREACH.CombatHUD
local enabled = CreateClientConVar("rx_combat_hud", "1", true, false, "使用现代战术战斗界面", 0, 1)
H.Colors = {
    text = Color(224, 227, 220), muted = Color(155, 163, 158),
    accent = Color(161, 178, 148), danger = Color(215, 139, 130),
    warning = Color(208, 171, 112), background = Color(17, 19, 20, 210),
    line = Color(69, 77, 70, 210), shadow = Color(0, 0, 0, 220)
}
local C = H.Colors
H.Fonts = H.Fonts or {}
local cachedLayout

function H.Enabled() return enabled:GetBool() end

function H.Layout(width, height)
    local w, h = width or ScrW(), height or ScrH()
    if cachedLayout and cachedLayout.w == w and cachedLayout.h == h then return cachedLayout end
    local s = math.Clamp(math.min(w / 1920, h / 1080), 0.7, 1.6)
    cachedLayout = {w = w, h = h, scale = s, margin = 36 * s, bottom = 72 * s, vitalsWidth = 270 * s}
    cachedLayout.vitals = {x = 36 * s, y = h - 198 * s, w = 270 * s, h = 126 * s}
    cachedLayout.weapon = {x = w - 376 * s, y = h - 188 * s, w = 340 * s, h = 116 * s}
    cachedLayout.ability = {x = w / 2 - 130 * s, y = h - 120 * s, w = 260 * s, h = 48 * s}
    cachedLayout.quick = {x = w / 2 - 246 * s, y = h - 36 * s, w = 492 * s, h = 24 * s}
    return cachedLayout
end

local function fonts()
    local s = H.Layout().scale
    for key, size in pairs({Small = 14, Body = 18, Number = 32, Health = 52, Ammo = 56, Reserve = 24}) do
        local name = "RXCombat" .. key
        H.Fonts[key] = name
        surface.CreateFont(name, {font = "Microsoft YaHei", size = math.Round(size * s),
            weight = (key == "Small" or key == "Body") and 500 or 600, extended = true, antialias = true})
    end
end
fonts()
hook.Add("OnScreenSizeChanged", "RXCombatFonts", fonts)

function H.Text(text, font, x, y, color, align)
    return draw.SimpleTextOutlined(tostring(text or ""), font, math.Round(x), math.Round(y),
        color or C.text, align or TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, C.shadow)
end

function H.Fit(text, font, width)
    text = utf8.force(tostring(text or ""))
    surface.SetFont(font)
    if surface.GetTextSize(text) <= width then return text end
    for count = utf8.len(text) - 1, 1, -1 do
        local value = utf8.sub(text, 1, count) .. "…"
        if surface.GetTextSize(value) <= width then return value end
    end
    return "…"
end

function H.ShouldDraw(ply)
    if not H.Enabled() or not IsValid(ply) or not ply.GetRoleName or not ply.GTeam then return false end
    if not ply:Alive() or ply:Health() <= 0 or ply:GTeam() == TEAM_SPEC or ply:GetMoveType() == MOVETYPE_OBSERVER then return false end
    if disablehud or playing or preparing or postround or gui.IsGameUIVisible() then return false end
    if BREACH.RoundUI and BREACH.RoundUI.HasResults and BREACH.RoundUI.HasResults() then return false end
    if ply.ShowMainMenu or ply.CameraEnabled or ply.BlackScreen or ply.IntroBlackOut or ply:GetInDimension() then return false end
    if BREACH.IsDeploymentIntroActive and BREACH.IsDeploymentIntroActive() then return false end
    if BREACH.IsNu7TerminalOpen and BREACH.IsNu7TerminalOpen() then return false end
    if IsValid(INTRO_PANEL) and INTRO_PANEL:IsVisible() then return false end
    if IsEQVisible and IsEQVisible() then return false end
    if BREACH.RoleInfo and BREACH.RoleInfo.IsOpen and BREACH.RoleInfo.IsOpen() then return false end
    local mode = GetConVar("breach_config_screenshot_mode")
    if mode and mode:GetBool() then return false end
    local parent = ply:GetParent()
    return not (IsValid(parent) and parent:GetClass() == "prop_ragdoll")
end

function H.LocalLevel()
    -- Account progress always belongs to the local player, even while following someone.
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply.GetNLevel then return nil end
    local level = tonumber(ply:GetNLevel())
    return level and math.max(0, math.floor(level)) or nil
end

function H.ShouldDrawLevel(ply)
    if not H.Enabled() or not IsValid(ply) or not ply.GTeam then return false end
    if disablehud or playing or gui.IsGameUIVisible() then return false end
    if ply.ShowMainMenu or ply.CameraEnabled or ply.BlackScreen or ply.IntroBlackOut then return false end
    if BREACH.RoundUI and (BREACH.RoundUI.DeathState
        or (BREACH.RoundUI.HasResults and BREACH.RoundUI.HasResults())) then return false end
    if BREACH.IsDeploymentIntroActive and BREACH.IsDeploymentIntroActive() then return false end
    if BREACH.IsNu7TerminalOpen and BREACH.IsNu7TerminalOpen() then return false end
    if IsValid(INTRO_PANEL) and INTRO_PANEL:IsVisible() then return false end
    if IsEQVisible and IsEQVisible() then return false end
    if BREACH.RoleInfo and BREACH.RoleInfo.IsOpen and BREACH.RoleInfo.IsOpen() then return false end
    if GAMEMODE.ShowScoreboard or (BREACH.ReportUI and IsValid(BREACH.ReportUI.Panel)) then return false end
    local mode = GetConVar("breach_config_screenshot_mode")
    return not (mode and mode:GetBool())
end

function H.VitalsState(ply)
    local maxHealth = math.max(ply:GetMaxHealth(), 1)
    local hasStamina = ply:GTeam() ~= TEAM_SCP or ply.SCP035_IsWear or ply:GetRoleName() == "SCP3114"
    local maximum = math.max((tonumber(ply:GetStaminaScale()) or 1) * 100, 1)
    local stamina = tonumber(ply.Stamina)
    local armorClass = ply:GetUsingArmor()
    local helmetClass = ply:GetUsingHelmet()
    return {health = math.max(0, ply:Health()), maxHealth = maxHealth,
        healthFraction = math.Clamp(ply:Health() / maxHealth, 0, 1), armor = math.max(0, ply:Armor()),
        hasStamina = hasStamina, stamina = stamina and math.Clamp(stamina / maximum, 0, 1),
        exhausted = ply.exhausted, vest = isstring(armorClass) and armorClass ~= "",
        helmet = isstring(helmetClass) and helmetClass ~= ""}
end

local gradient = Material("vgui/gradient-d")
local function drawVitals(ply, l)
    local s, x, y = l.scale, l.vitals.x, l.vitals.y
    local v = H.VitalsState(ply)
    local roleName = GetLangRole and GetLangRole(ply:GetRoleName()) or "未知身份"
    H.Text(H.Fit(roleName, H.Fonts.Body, l.vitalsWidth), H.Fonts.Body, x, y, C.text)
    local healthColor = v.healthFraction <= 0.3 and C.danger or C.text
    local numberWidth = H.Text(v.health, H.Fonts.Health, x - 2 * s, y + 25 * s, healthColor)
    H.Text("生命", H.Fonts.Small, x + numberWidth + 9 * s, y + 51 * s, C.muted)
    H.Text("/ " .. v.maxHealth, H.Fonts.Small, x + numberWidth + 9 * s, y + 70 * s, C.muted)
    if ply:GTeam() ~= TEAM_SCP or v.armor > 0 then
        H.Text(v.armor, H.Fonts.Reserve, x + l.vitalsWidth, y + 38 * s, v.armor > 0 and C.accent or C.muted, TEXT_ALIGN_RIGHT)
        H.Text("护甲", H.Fonts.Small, x + l.vitalsWidth, y + 70 * s, C.muted, TEXT_ALIGN_RIGHT)
    end
    surface.SetDrawColor(C.line) surface.DrawRect(x, y + 94 * s, l.vitalsWidth, 3 * s)
    surface.SetDrawColor(v.healthFraction <= 0.3 and C.danger or C.accent)
    surface.DrawRect(x, y + 94 * s, l.vitalsWidth * v.healthFraction, 3 * s)
    if v.hasStamina then
        H.Text(v.exhausted and "力竭" or "体力", H.Fonts.Small, x, y + 109 * s, v.exhausted and C.warning or C.muted)
        surface.SetDrawColor(C.line) surface.DrawRect(x + 44 * s, y + 118 * s, l.vitalsWidth - 44 * s, 2 * s)
        if v.stamina then
            surface.SetDrawColor(v.exhausted and C.warning or C.accent)
            surface.DrawRect(x + 44 * s, y + 118 * s, (l.vitalsWidth - 44 * s) * v.stamina, 2 * s)
        end
    end
    local protection = {}
    if v.vest then protection[#protection + 1] = "防弹衣已穿戴" end
    if v.helmet then protection[#protection + 1] = "头盔已穿戴" end
    if #protection > 0 then H.Text(table.concat(protection, " · "), H.Fonts.Small, x, y - 24 * s, C.muted) end
    local effects = {}
    if ply:GetBoosted() then effects[#effects + 1] = "生命强化" end
    if ply:GetEnergized() then effects[#effects + 1] = "体能增强" end
    if ply:GetAdrenaline() then effects[#effects + 1] = "肾上腺素" end
    if #effects > 0 then H.Text(table.concat(effects, " · "), H.Fonts.Small, x, y - 47 * s, C.accent) end
end

function H.Binding(command)
    local key = input.LookupBinding(command)
    if not key then return "未绑定" end
    local names = {MOUSE1 = "鼠标左键", MOUSE2 = "鼠标右键", MOUSE3 = "鼠标中键", SPACE = "空格", TAB = "制表键"}
    key = string.upper(key)
    return names[key] or key
end

local function drawQuickSlots(ply, l)
    local s, y = l.scale, l.h - 36 * l.scale
    if BREACH.RoleInfo and BREACH.RoleInfo.InfoKey then
        H.Text(BREACH.RoleInfo.InfoKey() .. "  角色与帮助", H.Fonts.Small, l.w - l.margin, y, C.muted, TEXT_ALIGN_RIGHT)
    end
    if not BREACH.QuickSlots or not CanShowEQ or not CanShowEQ() then return end
    H.Text(H.Binding("+menu", "Q") .. "  背包", H.Fonts.Small, l.margin, y, C.muted)
    local width, gap = 148 * s, 24 * s
    local start = l.quick.x
    for index = 1, 3 do
        local class = BREACH.QuickSlots.bindings[index]
        local item = class and ply:GetWeapon(class)
        local owned = IsValid(item)
        local name = owned and BREACH.InventoryUIText.Name(item) or (class and "未携带" or "未绑定")
        local color = owned and (item == ply:GetActiveWeapon() and C.accent or C.text) or C.muted
        local x = start + (index - 1) * (width + gap)
        H.Text(index, H.Fonts.Small, x, y, color)
        H.Text(H.Fit(name, H.Fonts.Small, width - 23 * s), H.Fonts.Small, x + 23 * s, y, color)
        if owned and item == ply:GetActiveWeapon() then
            surface.SetDrawColor(C.accent) surface.DrawRect(x, y + 23 * s, width, s)
        end
    end
end

function H.DrawRoundTimer(value, nuclear)
    local l = H.Layout()
    H.Text(nuclear and "核弹倒计时" or "回合剩余时间", H.Fonts.Small, l.w / 2, 24 * l.scale,
        nuclear and C.danger or C.muted, TEXT_ALIGN_CENTER)
    H.Text(value, H.Fonts.Number, l.w / 2, 44 * l.scale, nuclear and C.danger or C.text, TEXT_ALIGN_CENTER)
end

function H.DrawCorpsePrompt(ply, ent)
    if not H.ShouldDraw(ply) or not ent:GetNWBool("BreachSearchable", ent.breachsearchable == true) then
        -- Older corpses only network DiedWhen/SurvivorName; the server validates searching.
        if not H.ShouldDraw(ply) or (ent:GetNWInt("DiedWhen", 0) <= 0 and ent:GetNWString("SurvivorName", "") == "") then return end
    end
    local l = H.Layout()
    local y = l.h / 2 + 70 * l.scale
    local name = ent:GetNWString("SurvivorName", "")
    local title = H.Binding("+use") .. "  搜查遗体" .. (name ~= "" and " · " .. name or "")
    H.Text(H.Fit(title, H.Fonts.Body, 440 * l.scale), H.Fonts.Body, l.w / 2, y, C.text, TEXT_ALIGN_CENTER)
    local time = ent:GetNWInt("DiedWhen", 0)
    local elapsed = math.max(os.time() - time, 0)
    local age = time <= 0 and "死亡时间未知" or (elapsed < 60 and "刚刚死亡" or math.floor(elapsed / 60) .. " 分钟前死亡")
    local reason = BREACH.TranslateString(ent:GetNWString("DeathReason1", "l:body_death_unknown"))
    H.Text(H.Fit(age .. " · " .. reason, H.Fonts.Small, 400 * l.scale), H.Fonts.Small,
        l.w / 2, y + 27 * l.scale, C.muted, TEXT_ALIGN_CENTER)
    local detail = BREACH.TranslateString(ent:GetNWString("DeathReason2", ""))
    if detail ~= "" then H.Text(H.Fit(detail, H.Fonts.Small, 400 * l.scale), H.Fonts.Small,
        l.w / 2, y + 48 * l.scale, C.danger, TEXT_ALIGN_CENTER) end
end

function H.DrawPickupPrompt(ply, ent)
    if not H.ShouldDraw(ply) or IsValid(ent:GetOwner()) then return end
    if ply:GTeam() == TEAM_SCP and not ply.SCP035_IsWear and ply:GetRoleName() ~= "SCP3114" then return end
    local l = H.Layout()
    local name = BREACH.InventoryUIText and BREACH.InventoryUIText.Name(ent) or "物品"
    H.Text(H.Binding("+use", "E") .. "  拾取  " .. H.Fit(name, H.Fonts.Body, 260 * l.scale),
        H.Fonts.Body, l.w / 2, l.h / 2 + 70 * l.scale, C.text, TEXT_ALIGN_CENTER)
end

hook.Add("HUDPaint", "RXCombatHUD", function()
    local ply = LocalPlayer()
    if not H.ShouldDraw(ply) then return end
    local l = H.Layout()
    surface.SetMaterial(gradient) surface.SetDrawColor(0, 0, 0, 125)
    surface.DrawTexturedRect(0, l.h - 250 * l.scale, l.w, 250 * l.scale)
    drawVitals(ply, l)
    if H.DrawWeapon then H.DrawWeapon(ply, l) end
    drawQuickSlots(ply, l)
end)

hook.Add("HUDPaint", "RXPlayerLevel", function()
    local ply = LocalPlayer()
    if not H.ShouldDrawLevel(ply) then return end
    local level = H.LocalLevel()
    if level == nil then return end
    local l = H.Layout()
    local bottom = ply:GTeam() == TEAM_SPEC and 27 or 60
    H.Text("我的等级  " .. level, H.Fonts.Small, l.margin, l.h - bottom * l.scale, C.muted)
end)

-- Compact tactical ability display. The server remains authoritative for charges/CD.
BREACH = BREACH or {}
BREACH.CombatHUD = BREACH.CombatHUD or {}
local H = BREACH.CombatHUD

local mouseKeys = {
    [MOUSE_LEFT] = "鼠标左键", [MOUSE_RIGHT] = "鼠标右键", [MOUSE_MIDDLE] = "鼠标中键",
    [MOUSE_4] = "鼠标侧键 1", [MOUSE_5] = "鼠标侧键 2"
}

local function keyName(code)
    if mouseKeys[code] then return mouseKeys[code] end
    local key = input.GetKeyName(code)
    if not key then return "未绑定" end
    local names = {space = "空格", lshift = "左 Shift", rshift = "右 Shift",
        lcontrol = "左 Ctrl", rcontrol = "右 Ctrl", lalt = "左 Alt", ralt = "右 Alt"}
    return names[key] or string.upper(key)
end

local function fit(text, font, width)
    text = utf8.force(tostring(text or ""))
    surface.SetFont(font)
    if surface.GetTextSize(text) <= width then return text end
    while utf8.len(text) > 0 and surface.GetTextSize(text .. "…") > width do
        text = utf8.sub(text, 1, utf8.len(text) - 1)
    end
    return text .. "…"
end

local function translated(value, fallback)
    local text = BREACH.TranslateString(tostring(value or ""))
    return text ~= "" and text or fallback
end

function H.AbilityState(ply, definition, panel, now)
    now = now or CurTime()
    local count = definition.Countable and math.max(0, ply:GetSpecialMax()) or nil
    local remaining = math.max(0, math.ceil(ply:GetSpecialCD() - now))
    local blocked = panel and panel.Blocked or false
    if count ~= nil and count <= 0 then blocked = true end
    local convar = GetConVar("breach_config_useability")
    local key = convar and convar:GetInt() or KEY_G
    return {name = translated(definition.Name, "战术技能"), remaining = remaining,
        count = count, blocked = blocked, keyCode = key, keyName = keyName(key)}
end

local closeCursor
local function removeTip()
    if BREACH.Abilities and IsValid(BREACH.Abilities.TipWindow) then
        BREACH.Abilities.TipWindow:Remove()
        BREACH.Abilities.TipWindow = nil
    end
end

-- SCP weapons share this legacy panel even when they copy the base HUD implementation.
-- Visibility is presentation-only: retain the weapon's charges, cooldowns and bindings.
function H.SCPAbilityHUDVisible(ply)
    if not IsValid(ply) or not ply:Alive() or ply:Health()<=0 or ply:GTeam()==TEAM_SPEC then return false end
    if preparing or postround or disablehud or playing or gui.IsGameUIVisible() then return false end
    if ply.ShowMainMenu or ply.CameraEnabled or ply.BlackScreen or ply.IntroBlackOut then return false end
    local round=BREACH.RoundUI
    if round and (round.DeathState or (round.HasResults and round.HasResults())) then return false end
    if BREACH.IsDeploymentIntroActive and BREACH.IsDeploymentIntroActive() then return false end
    if BREACH.IsNu7TerminalOpen and BREACH.IsNu7TerminalOpen() then return false end
    if BREACH.RoleInfo and BREACH.RoleInfo.IsOpen and BREACH.RoleInfo.IsOpen() then return false end
    if GAMEMODE.ShowScoreboard or (IsValid(INTRO_PANEL) and INTRO_PANEL:IsVisible()) then return false end
    if IsEQVisible and IsEQVisible() then return false end
    if IsRoleMenuVisible and IsRoleMenuVisible() then return false end
    local screenshot=GetConVar("breach_config_screenshot_mode")
    return not (screenshot and screenshot:GetBool())
end

hook.Add("Think","RXCombatSCPAbilityVisibility",function()
    local panel=BREACH.Abilities
    if not IsValid(panel) or not panel.AbilityIcons or not panel.SCP_Name then return end
    local ply=LocalPlayer()
    if IsValid(ply) and (ply:Health()<=0 or ply:GTeam()==TEAM_SPEC or ply:GetRoleName()~=panel.SCP_Name) then
        removeTip()
        closeCursor(panel)
        panel:Remove()
        return
    end
    local visible=H.SCPAbilityHUDVisible(ply)
    panel:SetVisible(visible)
    panel:SetMouseInputEnabled(visible)
    panel:SetKeyboardInputEnabled(false)
    if not visible then removeTip() closeCursor(panel) end
end)

closeCursor = function(panel)
    if panel.RXOwnsCursor then
        local ply = LocalPlayer()
        local anotherUI = (IsEQVisible and IsEQVisible()) or
            (BREACH.IsNu7TerminalOpen and BREACH.IsNu7TerminalOpen()) or
            (IsValid(ply) and ply.ShowMainMenu) or gui.IsGameUIVisible() or
            (BREACH.RoleInfo and BREACH.RoleInfo.IsOpen and BREACH.RoleInfo.IsOpen()) or
            GAMEMODE.ShowScoreboard or (IsRoleMenuVisible and IsRoleMenuVisible())
        if not anotherUI then gui.EnableScreenClicker(false) end
        panel.RXOwnsCursor = nil
    end
end
H.ReleaseAbilityCursor = closeCursor

local function wrap(text, font, width)
    local lines, current = {}, ""
    text = utf8.force(text)
    surface.SetFont(font)
    for i = 1, utf8.len(text) do
        local char = utf8.sub(text, i, i)
        if char == "\n" then
            lines[#lines + 1], current = current, ""
        elseif current ~= "" and surface.GetTextSize(current .. char) > width then
            lines[#lines + 1], current = current, char
        else
            current = current .. char
        end
    end
    if current ~= "" then lines[#lines + 1] = current end
    return lines
end

local function showTip(panel)
    removeTip()
    if not panel:IsVisible() or not vgui.CursorVisible() then return end
    local s, c = H.Layout().scale, H.Colors
    local definition = panel.RXDefinition
    local width = math.min(380 * s, ScrW() - 32 * s)
    local lines = wrap(translated(definition.Description, "暂无技能说明"), H.Fonts.Small, width - 28 * s)
    local height = (72 + #lines * 20) * s
    local tip = vgui.Create("DPanel")
    BREACH.Abilities.TipWindow = tip
    tip:SetSize(width, math.min(height, ScrH() - 32 * s))
    tip:SetMouseInputEnabled(false)
    tip:SetKeyboardInputEnabled(false)
    tip.Paint = function(self, w, h)
        if not IsValid(panel) or not panel:IsVisible() or not vgui.CursorVisible() then
            self:Remove()
            return
        end
        self:SetPos(math.Clamp(gui.MouseX() + 16 * s, 16 * s, ScrW() - w - 16 * s),
            math.Clamp(gui.MouseY() - h - 12 * s, 16 * s, ScrH() - h - 16 * s))
        surface.SetDrawColor(c.background)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(c.accent)
        surface.DrawRect(0, 0, 2 * s, h)
        H.Text(fit(translated(definition.Name, "战术技能"), H.Fonts.Body, w - 28 * s),
            H.Fonts.Body, 14 * s, 12 * s, c.text)
        for i, line in ipairs(lines) do
            H.Text(line, H.Fonts.Small, 14 * s, (40 + (i - 1) * 20) * s, c.muted)
        end
        H.Text("基础冷却：" .. tostring(definition.Cooldown or 0) .. " 秒", H.Fonts.Small,
            14 * s, h - 25 * s, c.accent)
    end
end

function H.CreateAbility(definition)
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    removeTip()
    local old = BREACH.Abilities
    if IsValid(old) then old:Remove() end
    if istable(old) and IsValid(old.HumanSpecial) then old.HumanSpecial:Remove() end
    if istable(old) and IsValid(old.HumanSpecialButt) then old.HumanSpecialButt:Remove() end

    local panel = vgui.Create("DPanel")
    local button = vgui.Create("DButton", panel)
    BREACH.Abilities = {HumanSpecial = panel, HumanSpecialButt = button}
    panel.RXTactical = true
    panel.RXDefinition = definition
    panel.RXRole, panel.RXTeam = ply:GetRoleName(), ply:GTeam()
    panel.CreationTime = CurTime()
    panel:SetVisible(false)
    panel:SetKeyboardInputEnabled(false)
    panel:SetMouseInputEnabled(false)
    button:SetKeyboardInputEnabled(false)
    button:SetText("")
    button.Paint = function() end
    button.OnCursorEntered = function() showTip(panel) end
    button.OnCursorExited = removeTip
    panel.OnRemove = function(self)
        removeTip()
        closeCursor(self)
    end
    panel.Paint = function(self, w, h)
        if not H.ShouldDraw(ply) then return end
        local s, c = H.Layout().scale, H.Colors
        local iconSize = 48 * s
        local state = H.AbilityState(ply, definition, self)
        local icon = self.RXIcon
        if not icon then
            icon = Material(definition.Icon or "nextoren/gui/special_abilities/ability_placeholder.png", "smooth")
            self.RXIcon = icon
        end
        surface.SetDrawColor(c.background)
        surface.DrawRect(0, 0, iconSize, iconSize)
        if not icon:IsError() then
            surface.SetMaterial(icon)
            surface.SetDrawColor(224, 227, 220, (state.remaining > 0 or state.blocked) and 85 or 220)
            surface.DrawTexturedRect(2 * s, 2 * s, iconSize - 4 * s, iconSize - 4 * s)
        end
        if self.OverridePaintFunc and isfunction(self.OverridePaintFunc) then
            self:OverridePaintFunc(iconSize, iconSize)
        elseif state.remaining > 0 then
            H.Text(tostring(state.remaining), H.Fonts.Number, iconSize / 2, 6 * s, c.text, TEXT_ALIGN_CENTER)
        elseif state.blocked then
            H.Text("不可用", H.Fonts.Small, iconSize / 2, 15 * s, c.muted, TEXT_ALIGN_CENTER)
        end
        H.Text(fit(state.name, H.Fonts.Body, w - 60 * s), H.Fonts.Body, 60 * s, 1 * s, c.text)
        local status, color
        if state.blocked then
            status, color = state.count == 0 and "次数已用尽" or "暂不可用", c.muted
        elseif state.remaining > 0 then
            status, color = "冷却中 · " .. state.remaining .. " 秒", c.muted
        else
            status, color = state.keyName .. " 使用", c.accent
        end
        if state.count and state.count > 0 then status = status .. " · " .. state.count .. " 次" end
        H.Text(fit(status, H.Fonts.Small, w - 60 * s), H.Fonts.Small, 60 * s, 27 * s, color)
    end
end

-- This runs independently of panel visibility: hidden abilities must still expire.
hook.Add("Think", "RXCombatAbilityLifecycle", function()
    local abilities = BREACH.Abilities
    local panel = istable(abilities) and abilities.HumanSpecial
    if not IsValid(panel) or not H.Enabled then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if H.Enabled() ~= (panel.RXTactical == true) then
        if ply.SpecialTable then DrawSpecialAbility(ply.SpecialTable) end
        return
    end
    if not panel.RXTactical then return end
    if ply:Health() <= 0 or ply:GTeam() == TEAM_SPEC or
        (CurTime() - panel.CreationTime > 1 and
        (panel.RXRole ~= ply:GetRoleName() or panel.RXTeam ~= ply:GTeam())) then
        ply.SpecialTable = nil
        panel:Remove()
        if BREACH.Abilities == abilities then BREACH.Abilities = nil end
        return
    end
    local visible = H.ShouldDraw(ply)
    panel:SetVisible(visible)
    panel:SetMouseInputEnabled(visible and vgui.CursorVisible())
    if IsValid(abilities.HumanSpecialButt) then
        abilities.HumanSpecialButt:SetMouseInputEnabled(visible and vgui.CursorVisible())
    end
    if not visible then
        removeTip()
        closeCursor(panel)
    end
    local layout, state = H.Layout(), H.AbilityState(ply, panel.RXDefinition, panel)
    local rect = layout.ability
    panel:SetSize(rect.w, rect.h)
    panel:SetPos(rect.x, rect.y)
    if IsValid(abilities.HumanSpecialButt) then abilities.HumanSpecialButt:SetSize(rect.w, rect.h) end
    ply.AbilityKey, ply.AbilityKeyCode = state.keyName, state.keyCode
    local pressed = input.IsKeyDown(KEY_F3)
    if visible and pressed and not panel.RXF3Down then
        if vgui.CursorVisible() then
            gui.EnableScreenClicker(false)
            panel.RXOwnsCursor = nil
            removeTip()
        else
            gui.EnableScreenClicker(true)
            panel.RXOwnsCursor = true
        end
    end
    panel.RXF3Down = pressed
end)

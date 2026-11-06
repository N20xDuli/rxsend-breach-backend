-- Read weapon state without changing firing, reload, ammunition or attachment logic.
BREACH = BREACH or {}
BREACH.CombatHUD = BREACH.CombatHUD or {}
local H = BREACH.CombatHUD

local fireModes = {
    auto = "全自动", semi = "半自动", double = "双动", bolt = "栓动",
    pump = "泵动", ["break"] = "折管装填", ["2burst"] = "两发点射",
    ["3burst"] = "三发点射", safe = "保险", melee = "近战", single = "单发",
    barfast = "高速连射", barslow = "低速连射", dbsfast = "双管齐射", dbsslow = "单管射击"
}

function H.WeaponFireMode(weapon)
    local mode = weapon.FireMode
    if fireModes[mode] then return fireModes[mode] end
    local burst = isstring(mode) and mode:match("^(%d+)burst$")
    if burst then return burst .. " 发点射" end
    if mode then return "射击" end
    return weapon.Primary and weapon.Primary.Automatic and "全自动" or "半自动"
end

local function ammoCount(ply, ammo)
    if not isnumber(ammo) or ammo < 0 then return nil end
    return math.max(0, ply:GetAmmoCount(ammo))
end

function H.WeaponState(ply)
    if not IsValid(ply) then return end
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) then return end
    local class = weapon:GetClass()
    local state = {
        weapon = weapon, class = class, kind = "item", mode = "手持装备",
        name = BREACH.InventoryUIText and BREACH.InventoryUIText.Name(weapon, class) or "手持装备"
    }
    if class == "br_holster" then
        state.mode = "武器已收起"
        return state
    end

    local clip = weapon:Clip1()
    local capacity = weapon:GetMaxClip1()
    local reserve = ammoCount(ply, weapon:GetPrimaryAmmoType())
    if class == "item_tazer" then
        -- Each charge powers one discharge; this is not a percentage of ClipSize (1000).
        state.kind, state.clip, state.unit = "charge", math.max(0, clip), "次"
        state.mode = state.clip > 0 and "剩余电击次数" or "需要电池"
        state.low = state.clip <= 2
        return state
    end

    -- Melee weapons, SCP abilities, keycards and medical items do not have a gun counter.
    if reserve == nil then return state end
    if weapon.KKINS2Nade or weapon.Base == "cw_grenade_base" then
        state.kind, state.clip, state.unit = "throwable", reserve + math.max(0, clip), "枚"
        state.mode, state.low = "投掷物", state.clip <= 0
        return state
    end
    if capacity > 0 and clip >= 0 then
        state.kind, state.clip, state.capacity, state.reserve = "gun", clip, capacity, reserve
        state.mode = H.WeaponFireMode(weapon)
        state.low = clip <= capacity * 0.25
    else
        state.kind, state.clip, state.unit = "reserve", reserve, "剩余"
        state.mode = "可用弹药"
        state.low = reserve <= 0
    end

    local dt = weapon.dt
    if dt and (dt.M203Active or dt.INS2GLActive) then
        state.secondary = state.kind == "gun" and ("主武器  " .. clip .. " / " .. reserve) or nil
        state.name = state.name .. " · 下挂榴弹"
        state.kind, state.clip, state.capacity = "gun", weapon.M203Chamber and 1 or 0, 1
        state.reserve = math.max(0, ply:GetAmmoCount("40MM"))
        state.mode, state.low = "单发", not weapon.M203Chamber
    elseif weapon.CW20Weapon then
        local grenades = ply:GetAmmoCount("Frag Grenades")
        if grenades > 0 then state.secondary = "破片手雷  " .. grenades end
    end

    if weapon.IsReloading and (tonumber(weapon.Cycle) or 0) <= 0.98 then
        state.status = "装填中"
    elseif state.clip == 0 and state.kind == "gun" then
        state.status = state.reserve > 0 and "需要装填" or "弹药耗尽"
    end
    return state
end

-- Called only for CW's floating ammo overlay, never for its sights or attachment menu.
function H.ReplacesWeaponAmmo(ply)
    return H.Enabled and H.Enabled() and H.WeaponState and IsValid(ply)
        and IsValid(ply:GetActiveWeapon())
end

local function fitted(text, font, width)
    text = utf8.force(tostring(text or ""))
    surface.SetFont(font)
    if surface.GetTextSize(text) <= width then return text end
    local length = utf8.len(text)
    while length > 0 do
        local shortened = utf8.sub(text, 1, length) .. "…"
        if surface.GetTextSize(shortened) <= width then return shortened end
        length = length - 1
    end
    return "…"
end

function H.DrawWeapon(ply, layout)
    local state = H.WeaponState(ply)
    if not state then return end
    local s, right = layout.scale, layout.weapon.x + layout.weapon.w
    local bottom = layout.weapon.y + layout.weapon.h
    local top = layout.weapon.y
    local F, C = H.Fonts, H.Colors
    local width = layout.weapon.w

    if state.kind == "item" then
        H.Text(fitted(state.name, F.Body, width), F.Body, right, bottom - 52 * s, C.text, TEXT_ALIGN_RIGHT)
        H.Text(state.mode, F.Small, right, bottom - 23 * s, C.muted, TEXT_ALIGN_RIGHT)
        return
    end

    H.Text(fitted(state.name, F.Body, width), F.Body, right, top, C.text, TEXT_ALIGN_RIGHT)
    local suffix = state.reserve ~= nil and (" / " .. state.reserve) or ("  " .. (state.unit or ""))
    surface.SetFont(F.Reserve)
    local suffixWidth = surface.GetTextSize(suffix)
    H.Text(suffix, F.Reserve, right, top + 49 * s, C.muted, TEXT_ALIGN_RIGHT)
    H.Text(tostring(state.clip), F.Ammo, right - suffixWidth, top + 22 * s,
        state.low and C.warning or C.text, TEXT_ALIGN_RIGHT)
    local status = state.mode .. (state.status and ("  ·  " .. state.status) or "")
    H.Text(status, F.Small, right, top + 85 * s,
        state.status and C.warning or C.muted, TEXT_ALIGN_RIGHT)
    if state.secondary then
        H.Text(state.secondary, F.Small, right, top + 105 * s, C.muted, TEXT_ALIGN_RIGHT)
    end
end

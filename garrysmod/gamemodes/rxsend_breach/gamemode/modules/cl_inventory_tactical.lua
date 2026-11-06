-- The inventory is a view of the existing player/corpse data. Ownership and
-- transfers remain authoritative on the server; requests never remove tiles.
BREACH = BREACH or {}
BREACH.InventoryUI = BREACH.InventoryUI or {}
local UI = BREACH.InventoryUI

local C = {
    backdrop = Color(5, 7, 8, 170), background = Color(17, 19, 20, 252),
    panel = Color(23, 26, 27), tile = Color(30, 33, 34), hover = Color(41, 45, 45),
    line = Color(63, 68, 67), text = Color(224, 227, 220), muted = Color(155, 163, 158),
    accent = Color(161, 178, 148), selected = Color(49, 59, 47),
    warning = Color(208, 171, 112), danger = Color(215, 139, 130), disabled = Color(93, 100, 96)
}
local ammoLimits = {Pistol = 60, Revolver = 30, SMG1 = 120, AR2 = 120,
    Shotgun = 80, Sniper = 30, RPG_Rocket = 2, GOC = 120, GRU = 120}
local equipmentSlots = {
    {id = "cloth", label = "服装", getter = "GetUsingCloth"},
    {id = "armor", label = "护甲", getter = "GetUsingArmor"},
    {id = "helmet", label = "头部装备", getter = "GetUsingHelmet"},
    {id = "bag", label = "背包", getter = "GetUsingBag"}
}
local categoryNames = {ordinary = "随身物品", equipment = "携带装备", fixed = "专属物品"}
local iconCache = {}

local function itemName(item, class)
    local text = BREACH.InventoryUIText
    if text and text.Name then return text.Name(item, class) end
    return "未命名物品"
end

local function itemDescription(item, class)
    local text = BREACH.InventoryUIText
    if text and text.Description then return text.Description(item, class) end
    return ""
end

local function ammoName(id)
    local text = BREACH.InventoryUIText
    if text and text.AmmoName then return text.AmmoName(id) end
    return "弹药"
end

local function iconFor(item)
    local icon = item and item.InvIcon
    if isstring(icon) and icon ~= "" then
        if iconCache[icon] == nil then iconCache[icon] = Material(icon, "smooth") end
        icon = iconCache[icon]
    end
    if icon and icon.IsError and not icon:IsError() then return icon end
end

local function drawIcon(item, x, y, w, h, alpha)
    local icon = iconFor(item)
    if icon then
        surface.SetDrawColor(255, 255, 255, alpha or 255)
        surface.SetMaterial(icon)
        surface.DrawTexturedRect(x, y, w, h)
    else
        surface.SetDrawColor(C.line)
        surface.DrawOutlinedRect(x + w * .24, y + h * .24, w * .52, h * .52, 1)
        surface.DrawLine(x + w * .24, y + h * .24, x + w * .76, y + h * .76)
    end
end

local function lineText(text, font, x, y, color, maxWidth)
    text = utf8.force(tostring(text or ""))
    surface.SetFont(font)
    if maxWidth and surface.GetTextSize(text) > maxWidth then
        local chars = utf8.len(text) or #text
        while chars > 0 and surface.GetTextSize(utf8.sub(text, 1, chars) .. "…") > maxWidth do chars = chars - 1 end
        text = utf8.sub(text, 1, chars) .. "…"
    end
    draw.SimpleText(text, font, x, y, color or C.text)
end

local function wrapText(text, font, width, maxLines)
    surface.SetFont(font)
    local lines, current = {}, ""
    for _, code in utf8.codes(utf8.force(tostring(text or ""))) do
        local char = utf8.char(code)
        if char == "\n" or (current ~= "" and surface.GetTextSize(current .. char) > width) then
            lines[#lines + 1] = current
            current = char == "\n" and "" or char
        else current = current .. char end
        if #lines >= maxLines then
            local tail = lines[maxLines]
            while tail ~= "" and surface.GetTextSize(tail .. "…") > width do tail = utf8.sub(tail, 1, -2) end
            lines[maxLines] = tail .. "…"
            return lines
        end
    end
    if current ~= "" then lines[#lines + 1] = current end
    return lines
end

local function category(item)
    if item.Equipableitem then return "equipment" end
    if item.UnDroppable then return "fixed" end
    return "ordinary"
end

local function disguised3114(ply)
    return BREACH.SCP3114 and BREACH.SCP3114.HasInventory(ply)
end

function UI.PlayerSnapshot(ply)
    local data = {items = {}, equipment = {}, ammo = {}, counts = {ordinary = 0, equipment = 0, fixed = 0},
        maxSlots = math.max(0, ply:GetMaxSlots())}
    local sig = {tostring(data.maxSlots)}
    for _, weapon in ipairs(ply:GetWeapons()) do
        if IsValid(weapon) then
            local class = weapon:GetClass()
            local kind = category(weapon)
            -- Match the server's independent counters, including dual-flag items.
            if not weapon.Equipableitem and not weapon.UnDroppable then data.counts.ordinary = data.counts.ordinary + 1 end
            if weapon.Equipableitem then data.counts.equipment = data.counts.equipment + 1 end
            if weapon.UnDroppable then data.counts.fixed = data.counts.fixed + 1 end
            sig[#sig + 1] = class .. ":" .. weapon:EntIndex()
            if class ~= "item_special_document" then
                data.items[#data.items + 1] = {key = "own:" .. class, class = class, item = weapon,
                    source = "own", category = kind}
            end
        end
    end
    for _, slot in ipairs(equipmentSlots) do
        local class = ply[slot.getter] and ply[slot.getter](ply) or ""
        local stored = class ~= "" and scripted_ents.GetStored(class)
        data.equipment[#data.equipment + 1] = {key = "equip:" .. slot.id, class = class,
            item = stored and stored.t or {ClassName = class}, source = "equip", slot = slot}
        sig[#sig + 1] = slot.id .. ":" .. class
    end
    for id, amount in pairs(ply:GetAmmo()) do
        if amount > 0 then
            data.ammo[#data.ammo + 1] = {key = "ammo:" .. id, source = "ammo", ammoID = id, amount = amount}
            sig[#sig + 1] = "ammo:" .. id .. ":" .. amount
        end
    end
    table.sort(data.items, function(a, b) return a.class < b.class end)
    table.sort(data.ammo, function(a, b) return a.ammoID < b.ammoID end)
    table.sort(sig)
    data.signature = table.concat(sig, "|")
    return data
end

local function corpseEntries(state)
    local items, ammo = {}, {}
    for _, class in ipairs(state.loot.Weapons or {}) do
        if isstring(class) then
            -- Get includes inherited flags (for example breach_scp_base's
            -- droppable=false), matching the authoritative transfer rules.
            local definition = weapons.Get(class)
            items[#items + 1] = {key = "loot:" .. class, class = class,
                item = definition or {ClassName = class}, missing = not definition,
                source = "loot", category = definition and category(definition) or "ordinary"}
        end
    end
    for id, amount in pairs(state.ammo or {}) do
        id, amount = tonumber(id), tonumber(amount)
        if id and amount and amount > 0 then
            ammo[#ammo + 1] = {key = "lootammo:" .. id, source = "lootammo", ammoID = id, amount = amount}
        end
    end
    table.sort(items, function(a, b) return a.class < b.class end)
    table.sort(ammo, function(a, b) return a.ammoID < b.ammoID end)
    return items, ammo
end

local function corpseReady(state, ply)
    local corpse = state.frame.SnapshotCorpse
    if not IsValid(corpse) then return false, "尸体已不存在" end
    if corpse:GetPos():DistToSqr(ply:GetPos()) > 4900 then return false, "距离过远，请靠近尸体" end
    if ply:GetEyeTrace().Entity ~= corpse then return false, "请保持面向正在搜查的尸体" end
    if ply:GTeam() == TEAM_SCP and not disguised3114(ply) then return false, "当前角色不能搜查尸体" end
    return true
end

function UI.CanTake(state, entry, ply)
    local ok, reason = corpseReady(state, ply)
    if not ok then return false, reason end
    if entry.missing then return false, "物品暂不可用" end
    if state.pending then return false, "正在取走…" end
    if entry.source == "lootammo" then
        local limit = ammoLimits[game.GetAmmoName(entry.ammoID)]
        local available = math.min(entry.amount, 65535)
        if limit then available = math.min(available, math.max(0, limit - ply:GetAmmoCount(entry.ammoID))) end
        if available < 1 then return false, "该类弹药已达携带上限" end
        return true, "", available
    end
    if ply:HasWeapon(entry.class) then return false, "已持有同类物品" end
    if disguised3114(ply) and not BREACH.SCP3114.CanUse(ply, entry.class) then return false, "当前伪装不能使用此物品" end
    local counts = state.own.counts
    if counts.ordinary >= state.own.maxSlots then return false, "随身物品已满，请先腾出空间" end
    if counts.equipment >= 6 then return false, "携带装备已满，请先腾出空间" end
    if counts.fixed >= 6 then return false, "专属物品已满，无法继续拾取" end
    local class, item = entry.class, entry.item
    if class == "item_special_document" then
        if ply:GTeam() ~= TEAM_USA or ply:GetRoleName() ~= role.SCI_SpyUSA then return false, "仅指定的潜伏人员可以收集" end
        return true
    end
    if class == "item_special_document_o5" then
        if ply:GetModel() ~= "models/cultist/humans/fbi/fbi_agent.mdl" then return false, "当前身份不能收集此文件" end
        return true
    end
    if item.UnDroppable and class ~= "ritual_paper" and class ~= "kasanov_cbg_cog" then return false, "此物品不能从尸体取走" end
    if class == "ritual_paper" and ply:GTeam() ~= TEAM_COTSK then return false, "仅猩红之子可以收集" end
    if class == "kasanov_cbg_cog" and ply:GTeam() ~= TEAM_CBG then return false, "当前阵营不能收集此物品" end
    if item.droppable == false then return false, "此物品不能转移" end
    return true
end

local function status(state, message, bad)
    state.message = message or ""
    state.messageColor = bad and C.warning or C.accent
end

local function requestLoot(state, entry)
    local ply = LocalPlayer()
    local allowed, reason, maximum = UI.CanTake(state, entry, ply)
    if not allowed then status(state, reason, true) return end
    if entry.source == "lootammo" then
        local amount = math.Clamp(math.floor(state.quantity or maximum), 1, maximum)
        net.Start("LC_TakeAmmo")
        net.WriteEntity(state.frame.SnapshotCorpse)
        net.WriteUInt(entry.ammoID, 16)
        net.WriteUInt(amount, 16)
    else
        net.Start("LC_TakeWep")
        net.WriteEntity(state.frame.SnapshotCorpse)
        net.WriteString(entry.class)
    end
    net.SendToServer()
    state.pending = {key = entry.key, expires = CurTime() + 3}
    status(state, "正在取走…")
end

local function close(state)
    if state.closing then return end
    state.closing = true
    if RememberCursorPosition then RememberCursorPosition() end
    if HideEQ then HideEQ(false) else state.frame:Remove() end
end

-- This is a private preview copy. Never reparent the real player's heads,
-- armour or other networked bonemerges into a VGUI model panel.
local function copyAppearance(source, target)
    target:SetSkin(source:GetSkin())
    target:SetColor(source:GetColor())
    target:SetMaterial(source:GetMaterial())
    for _, group in ipairs(source:GetBodyGroups()) do
        target:SetBodygroup(group.id, source:GetBodygroup(group.id))
    end
    for index = 0, #source:GetMaterials() - 1 do
        target:SetSubMaterial(index, source:GetSubMaterial(index))
    end
end

local function clearPreviewParts(panel)
    for _, part in ipairs(panel.RXPreviewParts or {}) do
        if IsValid(part.copy) then part.copy:Remove() end
    end
    panel.RXPreviewParts = {}
end

local function refreshPreview(state, ply)
    local panel = state.characterPanel
    if not IsValid(panel) then return end
    local model = ply:GetModel()
    local current = panel:GetEntity()
    if not IsValid(current) or current:GetModel() ~= model then
        clearPreviewParts(panel)
        panel.RXPreviewSignature = nil
        panel:SetModel(model)
        local ent = panel:GetEntity()
        if not IsValid(ent) then return end
        ent:SetAngles(Angle(0, 0, 0))
        for _, name in ipairs({"idle_all_01", "idle_passive", "idle"}) do
            local sequence = ent:LookupSequence(name)
            if sequence and sequence >= 0 then ent:ResetSequence(sequence) break end
        end
        local mins, maxs = ent:GetRenderBounds()
        local center = (mins + maxs) * .5
        local height = math.max(maxs.z - mins.z, 48)
        local distance = math.max(height * 1.65, (maxs.x - mins.x) * 2, (maxs.y - mins.y) * 2)
        panel:SetLookAt(center)
        panel:SetCamPos(center + Vector(distance, distance * .16, height * .02))
    end
    local ent = panel:GetEntity()
    copyAppearance(ply, ent)
    local sources, signature = {}, {model}
    for _, source in pairs(ply.LookupBonemerges and ply:LookupBonemerges() or {}) do
        if IsValid(source) then
            sources[#sources + 1] = source
            signature[#signature + 1] = source:EntIndex() .. ":" .. (source:GetModel() or "")
        end
    end
    table.sort(signature)
    signature = table.concat(signature, "|")
    if signature ~= panel.RXPreviewSignature then
        clearPreviewParts(panel)
        panel.RXPreviewSignature = signature
        for _, source in ipairs(sources) do
            local part = ClientsideModel(source:GetModel(), RENDERGROUP_OTHER)
            if IsValid(part) then
                part:SetNoDraw(true)
                part:SetParent(ent)
                part:SetLocalPos(vector_origin)
                part:SetLocalAngles(angle_zero)
                part:AddEffects(EF_BONEMERGE)
                panel.RXPreviewParts[#panel.RXPreviewParts + 1] = {source = source, copy = part}
            end
        end
    end
    for _, part in ipairs(panel.RXPreviewParts or {}) do
        if IsValid(part.source) and IsValid(part.copy) then
            copyAppearance(part.source, part.copy)
            part.visible = not (part.source.GetInvisible and part.source:GetInvisible())
        end
    end
end

local function border(w, h, color)
    surface.SetDrawColor(color or C.line)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
end

local function scrollPanel(parent, x, y, w, h)
    local panel = vgui.Create("DScrollPanel", parent)
    panel:SetPos(x, y) panel:SetSize(w, h)
    panel.Paint = function(_, pw, ph) surface.SetDrawColor(C.panel) surface.DrawRect(0, 0, pw, ph) end
    local bar = panel:GetVBar()
    bar:SetWide(5)
    bar.Paint = function() end
    bar.btnUp.Paint = function() end
    bar.btnDown.Paint = function() end
    bar.btnGrip.Paint = function(_, pw, ph) surface.SetDrawColor(C.line) surface.DrawRect(0, 0, pw, ph) end
    return panel
end

local function fonts(scale)
    for name, spec in pairs({Title = {25, 700}, Heading = {18, 650}, Body = {16, 500}, Small = {13, 500}}) do
        surface.CreateFont("RXInventory" .. name, {font = "Microsoft YaHei", size = math.max(12, math.Round(spec[1] * scale)),
            weight = spec[2], extended = true, antialias = true})
    end
end

local rebuild
local function button(parent, x, y, w, h, label, action, enabled)
    local panel = vgui.Create("DButton", parent)
    panel:SetPos(x, y) panel:SetSize(w, h) panel:SetText("")
    panel.Paint = function(self, pw, ph)
        local active = not enabled or enabled()
        surface.SetDrawColor(active and (self:IsHovered() and C.hover or C.tile) or C.panel)
        surface.DrawRect(0, 0, pw, ph)
        border(pw, ph, active and C.line or C.panel)
        draw.SimpleText(isfunction(label) and label() or label, "RXInventoryBody", pw / 2, ph / 2,
            active and C.text or C.disabled, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    panel.DoClick = function() if not enabled or enabled() then action() end end
    return panel
end

local function selectedEntry(state)
    return state.entries[state.selected]
end

local function selectEntry(state, entry)
    state.selected = entry.key
    state.quantity = nil
    if not state.pending then state.message = "" end
end

local ownAction
local function releaseKeyboard(panel)
    panel:SetKeyboardInputEnabled(false)
    for _, child in ipairs(panel:GetChildren()) do releaseKeyboard(child) end
end

local function tile(state, parent, entry, x, y, w, h)
    local S = state.S
    local panel = vgui.Create("DButton", parent)
    panel:SetPos(x, y) panel:SetSize(w, h) panel:SetText("")
    state.entries[entry.key] = entry
    if entry.source == "own" and BREACH.QuickSlots then
        BREACH.QuickSlots.Attach(panel, function() return IsValid(entry.item) and entry.item or nil end)
    end
    panel.Paint = function(self, pw, ph)
        local selected = state.selected == entry.key
        surface.SetDrawColor(selected and C.selected or self:IsHovered() and C.hover or C.tile)
        surface.DrawRect(0, 0, pw, ph)
        border(pw, ph, selected and C.accent or C.line)
        local isAmmo = entry.source == "ammo" or entry.source == "lootammo"
        if isAmmo then
            draw.SimpleText(tostring(entry.amount), "RXInventoryTitle", pw / 2, S(27), C.text, TEXT_ALIGN_CENTER)
        else
            local iconSize = math.min(S(60), pw - S(20))
            drawIcon(entry.item, (pw - iconSize) / 2, S(7), iconSize, iconSize)
        end
        local name = isAmmo and ammoName(entry.ammoID) or itemName(entry.item, entry.class)
        local lines = wrapText(name, "RXInventorySmall", pw - S(12), 2)
        for i, text in ipairs(lines) do
            draw.SimpleText(text, "RXInventorySmall", pw / 2, ph - S(35) + (i - 1) * S(16), C.text, TEXT_ALIGN_CENTER)
        end
        if entry.source == "own" and IsValid(entry.item) then
            if LocalPlayer():GetActiveWeapon() == entry.item or LocalPlayer().DoWeaponSwitch == entry.item then
                surface.SetDrawColor(C.accent) surface.DrawRect(S(5), S(5), S(4), S(15))
            end
            for index, class in pairs(BREACH.QuickSlots and BREACH.QuickSlots.bindings or {}) do
                if class == entry.class then draw.SimpleText(index, "RXInventorySmall", pw - S(7), S(4), C.accent, TEXT_ALIGN_RIGHT) end
            end
        end
    end
    panel.OnCursorEntered = function()
        if not state.pending then selectEntry(state, entry) end
    end
    panel.DoClick = function()
        selectEntry(state, entry)
        if entry.source == "own" then ownAction(state, "select")
        elseif entry.source == "loot" then requestLoot(state, entry) end
    end
    panel.DoRightClick = function()
        selectEntry(state, entry)
        if entry.source == "own" then ownAction(state, "drop") end
    end
    return panel
end

local function group(state, scroll, title, entries, y)
    local S = state.S
    local width = scroll:GetWide() - S(20)
    local label = vgui.Create("DPanel", scroll:GetCanvas())
    label:SetPos(S(10), y) label:SetSize(width, S(30))
    label.Paint = function(_, w) lineText(title, "RXInventorySmall", 0, S(7), C.muted, w) end
    y = y + S(34)
    if #entries == 0 then
        local empty = vgui.Create("DPanel", scroll:GetCanvas())
        empty:SetPos(S(10), y) empty:SetSize(width, S(31))
        empty.Paint = function() lineText("暂无物品", "RXInventorySmall", S(3), S(4), C.disabled) end
        return y + S(36)
    end
    local gap, minWidth, height = S(7), S(92), S(106)
    local columns = math.max(1, math.floor((width + gap) / (minWidth + gap)))
    local tileWidth = math.floor((width - (columns - 1) * gap) / columns)
    for index, entry in ipairs(entries) do
        local row, col = math.floor((index - 1) / columns), (index - 1) % columns
        tile(state, scroll:GetCanvas(), entry, S(10) + col * (tileWidth + gap), y + row * (height + gap), tileWidth, height)
    end
    return y + math.ceil(#entries / columns) * (height + gap) + S(8)
end

rebuild = function(state)
    local S, ply = state.S, LocalPlayer()
    state.own = UI.PlayerSnapshot(ply)
    state.entries = {}
    for _, scroll in ipairs({state.equipmentPanel, state.ownPanel, state.lootPanel}) do
        if IsValid(scroll) then scroll.SavedScroll = scroll:GetVBar():GetScroll() scroll:GetCanvas():Clear() end
    end
    local y = S(8)
    for _, entry in ipairs(state.own.equipment) do
        state.entries[entry.key] = entry
        local panel = vgui.Create("DButton", state.equipmentPanel:GetCanvas())
        panel:SetPos(S(10), y) panel:SetSize(state.equipmentPanel:GetWide() - S(20), S(38)) panel:SetText("")
        panel.Paint = function(self, w, h)
            local occupied = entry.class ~= ""
            surface.SetDrawColor(state.selected == entry.key and C.selected or self:IsHovered() and C.hover or C.tile)
            surface.DrawRect(0, 0, w, h) border(w, h, state.selected == entry.key and C.accent or C.line)
            if occupied then drawIcon(entry.item, S(5), S(4), S(30), S(30)) end
            lineText(entry.slot.label, "RXInventorySmall", S(42), S(3), C.muted, w - S(48))
            lineText(occupied and itemName(entry.item, entry.class) or "未穿戴", "RXInventorySmall", S(42), S(19), occupied and C.text or C.disabled, w - S(48))
        end
        panel.DoClick = function() selectEntry(state, entry) end
        panel.DoRightClick = function() selectEntry(state, entry) ownAction(state, "drop") end
        y = y + S(42)
    end
    local ownY = S(3)
    for _, kind in ipairs({"ordinary", "equipment", "fixed"}) do
        local entries = {}
        for _, entry in ipairs(state.own.items) do if entry.category == kind then entries[#entries + 1] = entry end end
        local limit = kind == "ordinary" and state.own.maxSlots or 6
        ownY = group(state, state.ownPanel, categoryNames[kind] .. "  " .. state.own.counts[kind] .. " / " .. limit, entries, ownY)
    end
    if #state.own.ammo > 0 then group(state, state.ownPanel, "备用弹药", state.own.ammo, ownY) end
    if state.looting then
        local items, ammo = corpseEntries(state)
        local lootY = group(state, state.lootPanel, "可搜查物品  " .. #items, items, S(3))
        if #ammo > 0 then group(state, state.lootPanel, "尸体弹药", ammo, lootY) end
    end
    for _, scroll in ipairs({state.equipmentPanel, state.ownPanel, state.lootPanel}) do
        if IsValid(scroll) then scroll:InvalidateLayout(true) scroll:GetVBar():SetScroll(scroll.SavedScroll or 0) end
    end
    if state.selected and not state.entries[state.selected] then state.selected = nil state.quantity = nil end
    -- DButton enables keyboard input in Init, even under a mouse-only parent.
    -- Repeat after rebuilding tiles so clicking an item cannot steal movement.
    if not state.looting then releaseKeyboard(state.frame) end
end

ownAction = function(state, action)
    local entry, ply = selectedEntry(state), LocalPlayer()
    if not entry or (state.nextAction or 0) > CurTime() then return end
    state.nextAction = CurTime() + .25
    state.switching = nil
    if entry.source == "equip" and entry.class ~= "" then
        if entry.slot.id == "cloth" then
            DropCurrentVest()
        else
            net.Start("DropAdditionalArmor") net.WriteString(entry.class) net.SendToServer()
        end
        status(state, "已请求卸下装备")
    elseif entry.source == "own" and IsValid(entry.item) and entry.item:GetOwner() == ply then
        if action == "select" then
            if disguised3114(ply) and not BREACH.SCP3114.CanUse(ply, entry.class) then
                status(state, "当前伪装不能使用此物品", true)
                return
            end
            ply:SelectWeapon(entry.class)
            state.switching = {weapon = entry.item, expires = CurTime() + 3}
            status(state, "正在切换…")
        elseif action == "drop" and not entry.item.UnDroppable and entry.item.droppable ~= false then
            ply:DropWeapon(entry.class)
            status(state, "已请求丢弃物品")
        elseif action == "drop" then
            status(state, "此物品不能丢弃", true)
        elseif action == "charge" and entry.class:find("battery_", 1, true) and ply:HasWeapon("item_tazer") then
            net.Start("tazer_load") net.WriteEntity(entry.item) net.SendToServer()
            status(state, "已请求装入电击器电池")
        end
    end
end

local function actionState(state)
    local entry = selectedEntry(state)
    if not entry then return "选择物品", false, "左键拿到手中，右键丢弃；悬停查看详情" end
    if entry.source == "loot" or entry.source == "lootammo" then
        local allowed, reason, amount = UI.CanTake(state, entry, LocalPlayer())
        return entry.source == "lootammo" and "拾取弹药" or "取走物品", allowed, reason, amount
    end
    if entry.source == "equip" then return "卸下装备", entry.class ~= "", entry.class == "" and "该位置没有穿戴装备" or "点击卸下" end
    if entry.source == "ammo" then return "备用弹药", false, "备用弹药" end
    if not IsValid(entry.item) or entry.item:GetOwner() ~= LocalPlayer() then return "物品不可用", false, "物品已离开背包" end
    if disguised3114(LocalPlayer()) and not BREACH.SCP3114.CanUse(LocalPlayer(), entry.class) then return "无法使用", false, "当前伪装不能使用此物品" end
    return "切换到手中", true, entry.item.UnDroppable and "专属物品，不能丢弃" or "左键拿到手中，右键丢弃"
end

function UI.RefreshLoot(vtab, ammo)
    local state = UI.Current
    if not state or not IsValid(state.frame) or not state.looting or not istable(vtab) then return false end
    if vtab.Entity and vtab.Entity ~= state.frame.SnapshotCorpse then return false end
    state.loot, state.ammo = vtab, istable(ammo) and ammo or {}
    rebuild(state)
    return true
end

net.Receive("RXInventoryLootResult", function()
    local corpse, success, message = net.ReadEntity(), net.ReadBool(), net.ReadString()
    local vtab, ammo = net.ReadTable(), net.ReadTable()
    local state = UI.Current
    if not state or not IsValid(state.frame) or state.frame.SnapshotCorpse ~= corpse then return end
    if not UI.RefreshLoot(vtab, ammo) then return end
    -- Empty messages are passive broadcasts about another looter. They must
    -- not acknowledge or unlock this player's outstanding request.
    if message ~= "" then
        state.pending = nil
        status(state, message, not success)
    end
end)

function UI.Open(notvictim, vtab, ammo)
    local ply = LocalPlayer()
    if not IsValid(ply) or not CanShowEQ() then return false end
    local looting = not notvictim
    if looting and (not istable(vtab) or not IsValid(vtab.Entity)) then return false end
    if IsValid(BREACH.Inventory) then
        if looting and BREACH.Inventory.SnapshotCorpse == vtab.Entity then
            -- A refreshed/reopened view must not terminate the same session.
            BREACH.Inventory.RXInventoryClosing = true
        end
        BREACH.Inventory:Remove()
    end
    local width, height = looting and 1240 or 950, 730
    local scale = math.min(1, (ScrW() - 32) / width, (ScrH() - 32) / height)
    local function S(value) return math.floor(value * scale + .5) end
    fonts(scale)
    local frame = vgui.Create("EditablePanel")
    local state = {frame = frame, S = S, scale = scale, looting = looting,
        loot = vtab or {}, ammo = ammo or {}, entries = {}, message = "", screenW = ScrW(), screenH = ScrH()}
    UI.Current, BREACH.Inventory = state, frame
    frame.RXInventoryTactical, frame.IsLooting = true, looting
    frame.SnapshotCorpse = looting and vtab.Entity or nil
    frame:SetSize(S(width), S(height)) frame:Center() frame:MakePopup()
    -- Own inventory keeps movement bindings in the game. Corpse searching
    -- retains its existing input lock and authoritative distance checks.
    frame:SetKeyboardInputEnabled(looting)
    local openingKey = GetConVar("breach_config_openinventory")
    state.closeKey = openingKey and openingKey:GetInt() or KEY_Q
    state.closeKeyArmed = not input.IsKeyDown(state.closeKey)
    EQHUD = EQHUD or {}
    EQHUD.enabled = true
    local bodyY, bodyHeight = 109, 399
    local equipmentWidth, gap = 224, 12
    local ownX = 18 + equipmentWidth + gap
    local ownWidth = looting and 472 or width - ownX - 18
    frame.Paint = function(_, w, h)
        surface.SetDrawColor(C.background) surface.DrawRect(0, 0, w, h) border(w, h)
        surface.SetDrawColor(C.accent) surface.DrawRect(S(18), S(20), S(3), S(27))
        lineText(looting and "搜查尸体" or "背包", "RXInventoryTitle", S(32), S(17), C.text)
        local name = ply.GetNamesurvivor and ply:GetNamesurvivor() or ply:Nick()
        if not isstring(name) or name == "none" or name == "" then name = ply:Nick() end
        lineText(name, "RXInventorySmall", S(33), S(53), C.muted, S(width - 150))
        lineText("角色与穿戴", "RXInventoryHeading", S(18), S(82), C.text)
        lineText("我的物品", "RXInventoryHeading", S(ownX), S(82), C.text)
        if looting then
            local title = isstring(state.loot.Name) and state.loot.Name ~= "" and "尸体 · " .. state.loot.Name or "尸体物品"
            lineText(title, "RXInventoryHeading", S(ownX + ownWidth + gap), S(82), C.text, S(width - ownX - ownWidth - gap - 18))
        end
        surface.SetDrawColor(C.line) surface.DrawRect(S(18), S(690), w - S(36), 1)
        local key = GetConVar("breach_config_openinventory")
        local keyName = string.upper(input.GetKeyName(key and key:GetInt() or KEY_Q) or "Q")
        lineText("左键拿取 · 右键丢弃 · 悬停按 1 / 2 / 3 绑定快捷栏", "RXInventorySmall", S(18), S(703), C.muted, S(width - 200))
        draw.SimpleText("返回：" .. keyName .. " / ESC", "RXInventorySmall", w - S(18), S(703), C.muted, TEXT_ALIGN_RIGHT)
    end
    button(frame, S(width - 66), S(20), S(48), S(30), "关闭", function() close(state) end)
    local character = vgui.Create("DModelPanel", frame)
    state.characterPanel = character
    character:SetPos(S(18), S(bodyY)) character:SetSize(S(equipmentWidth), S(211))
    character:SetFOV(36)
    character:SetAmbientLight(Color(140, 140, 140))
    character:SetDirectionalLight(BOX_FRONT, Color(220, 226, 216))
    character:SetMouseInputEnabled(false)
    character:SetKeyboardInputEnabled(false)
    character.LayoutEntity = function(_, ent) ent:SetAngles(angle_zero) end
    character.PostDrawModel = function(self)
        for _, part in ipairs(self.RXPreviewParts or {}) do
            if part.visible and IsValid(part.copy) then part.copy:DrawModel() end
        end
    end
    local modelOnRemove = character.OnRemove
    character.OnRemove = function(self)
        clearPreviewParts(self)
        if modelOnRemove then modelOnRemove(self) end
    end
    refreshPreview(state, ply)
    state.equipmentPanel = scrollPanel(frame, S(18), S(bodyY + 219), S(equipmentWidth), S(bodyHeight - 219))
    state.ownPanel = scrollPanel(frame, S(ownX), S(bodyY), S(ownWidth), S(bodyHeight))
    if looting then
        local lootX = ownX + ownWidth + gap
        state.lootPanel = scrollPanel(frame, S(lootX), S(bodyY), S(width - lootX - 18), S(bodyHeight))
    end
    local details = vgui.Create("DPanel", frame)
    details:SetPos(S(18), S(520)) details:SetSize(S(width - 36), S(155))
    details.Paint = function(_, w, h)
        surface.SetDrawColor(C.panel) surface.DrawRect(0, 0, w, h)
        local entry = selectedEntry(state)
        local title = entry and ((entry.source == "ammo" or entry.source == "lootammo") and ammoName(entry.ammoID) or itemName(entry.item, entry.class)) or "物品详情"
        local _, _, reason = actionState(state)
        lineText(title, "RXInventoryHeading", S(14), S(12), C.text, w - S(32))
        local description = entry and ((entry.source == "ammo" or entry.source == "lootammo") and "现有数量：" .. entry.amount or itemDescription(entry.item, entry.class)) or "悬停物品查看详情。"
        local lines = wrapText(description, "RXInventorySmall", w - S(32), 2)
        for index, text in ipairs(lines) do lineText(text, "RXInventorySmall", S(14), S(40 + (index - 1) * 17), C.muted) end
        lineText(state.message ~= "" and state.message or reason, "RXInventorySmall", S(14), S(78), state.message ~= "" and state.messageColor or C.muted, w - S(32))
    end
    button(details, S(14), S(108), S(140), S(32), function() local label = actionState(state) return label end,
        function()
            local entry = selectedEntry(state)
            if not entry then return end
            if entry.source == "loot" or entry.source == "lootammo" then requestLoot(state, entry)
            else ownAction(state, "select") end
        end, function() local _, enabled = actionState(state) return enabled end)
    local drop = button(details, S(164), S(108), S(100), S(32), "丢弃",
        function() ownAction(state, "drop") end,
        function()
            local entry = selectedEntry(state)
            return entry and entry.source == "own" and IsValid(entry.item) and not entry.item.UnDroppable and entry.item.droppable ~= false
        end)
    local charge = button(details, S(274), S(108), S(172), S(32), "装入电击器电池",
        function() ownAction(state, "charge") end,
        function()
            local entry = selectedEntry(state)
            return entry and entry.source == "own" and IsValid(entry.item) and entry.class:find("battery_", 1, true) and ply:HasWeapon("item_tazer")
        end)
    local quantityPanel = vgui.Create("DPanel", details)
    quantityPanel:SetPos(S(164), S(108)) quantityPanel:SetSize(S(320), S(32))
    quantityPanel.Paint = function(_, w, h)
        local entry = selectedEntry(state)
        local maximum
        if entry then local _, _, amount = UI.CanTake(state, entry, ply) maximum = amount end
        maximum = maximum or 0
        local amount = math.Clamp(state.quantity or maximum, 0, maximum)
        draw.SimpleText("数量：" .. amount, "RXInventoryBody", S(150), h / 2, C.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    local function adjust(delta, all)
        local entry = selectedEntry(state)
        if not entry then return end
        local allowed, _, maximum = UI.CanTake(state, entry, ply)
        if not allowed then return end
        state.quantity = all and maximum or math.Clamp((state.quantity or maximum) + delta, 1, maximum)
    end
    button(quantityPanel, 0, 0, S(42), S(32), "−10", function() adjust(-10) end)
    button(quantityPanel, S(47), 0, S(35), S(32), "−", function() adjust(-1) end)
    button(quantityPanel, S(208), 0, S(35), S(32), "+", function() adjust(1) end)
    button(quantityPanel, S(248), 0, S(42), S(32), "+10", function() adjust(10) end)
    frame.OnKeyCodePressed = function(_, key)
        local binding = GetConVar("breach_config_openinventory")
        if key == KEY_ESCAPE or (state.closeKeyArmed and key == (binding and binding:GetInt() or KEY_Q)) then
            if key == KEY_ESCAPE then UI.BlockMainMenuUntil = RealTime() + .3 gui.HideGameUI() end
            close(state)
            return true
        end
    end
    frame.Think = function()
        if not input.IsKeyDown(state.closeKey) then state.closeKeyArmed = true end
        if input.IsKeyDown(KEY_ESCAPE) then
            UI.BlockMainMenuUntil = RealTime() + .3
            gui.HideGameUI()
            close(state)
            return
        end
        if not IsValid(ply) or not CanShowEQ() or ply:IsFrozen() or ply.StartEffect
            or (ply.MovementLocked and not state.looting)
            or (BREACH.IsDeploymentIntroActive and BREACH.IsDeploymentIntroActive()) then close(state) return end
        if state.looting and (not IsValid(frame.SnapshotCorpse) or frame.SnapshotCorpse:GetPos():DistToSqr(ply:GetPos()) > 4900) then close(state) return end
        if state.screenW ~= ScrW() or state.screenH ~= ScrH() then close(state) return end
        if (state.nextRefresh or 0) < CurTime() then
            state.nextRefresh = CurTime() + .2
            refreshPreview(state, ply)
            local snapshot = UI.PlayerSnapshot(ply)
            if not state.own or snapshot.signature ~= state.own.signature then rebuild(state) end
        end
        if state.pending and state.pending.expires < CurTime() then
            state.pending = nil
            status(state, "未收到结果，请重新搜查。", true)
        end
        if state.switching then
            if ply:GetActiveWeapon() == state.switching.weapon then
                state.switching = nil
                status(state, "已拿到手中")
            elseif not IsValid(state.switching.weapon) or state.switching.expires < CurTime() then
                state.switching = nil
                status(state, "暂时无法切换，请重试", true)
            end
        end
        local entry = selectedEntry(state)
        local takingAmmo = entry and entry.source == "lootammo"
        quantityPanel:SetVisible(takingAmmo or false)
        drop:SetVisible(entry and entry.source == "own" or false)
        charge:SetVisible(entry and entry.source == "own" and entry.class:find("battery_", 1, true) ~= nil or false)
    end
    frame.OnRemove = function()
        if UI.Current == state then
            UI.Current = nil
            if EQHUD then EQHUD.enabled = false end
            gui.EnableScreenClicker(false)
            if state.looting and not frame.RXInventoryClosing then
                net.Start("RXInventoryLootEnd")
                net.WriteEntity(IsValid(frame.SnapshotCorpse) and frame.SnapshotCorpse or NULL)
                net.SendToServer()
            end
        end
        if BREACH.Inventory == frame then BREACH.Inventory = nil end
        -- HideEQ marks RXInventoryClosing before removal; direct removals also
        -- release the session without recursively calling HideEQ.
    end
    rebuild(state)
    if RestoreCursorPosition then RestoreCursorPosition() end
    return true
end

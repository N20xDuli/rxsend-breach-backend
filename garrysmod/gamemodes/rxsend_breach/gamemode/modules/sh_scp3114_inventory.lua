BREACH = BREACH or {}
BREACH.SCP3114 = BREACH.SCP3114 or {}
local inventory = BREACH.SCP3114
-- Explicit existing utility classes; new addons do not become usable just by naming a gun item_*.
local utilities = {
    ["breach_keycard_1"] = true,
    ["breach_keycard_2"] = true,
    ["breach_keycard_3"] = true,
    ["breach_keycard_4"] = true,
    ["breach_keycard_5"] = true,
    ["breach_keycard_6"] = true,
    ["breach_keycard_7"] = true,
    ["breach_keycard_crack"] = true,
    ["breach_keycard_guard_1"] = true,
    ["breach_keycard_guard_2"] = true,
    ["breach_keycard_guard_3"] = true,
    ["breach_keycard_guard_4"] = true,
    ["breach_keycard_sci_1"] = true,
    ["breach_keycard_sci_2"] = true,
    ["breach_keycard_sci_3"] = true,
    ["breach_keycard_sci_4"] = true,
    ["breach_keycard_security_1"] = true,
    ["breach_keycard_security_2"] = true,
    ["breach_keycard_security_3"] = true,
    ["breach_keycard_security_4"] = true,
    ["breach_keycard_support"] = true,
    ["breach_keycard_usa_spy"] = true,
    ["item_adrenaline"] = true,
    ["item_chaos_radio"] = true,
    ["item_cheemer"] = true,
    ["item_deffib_medic"] = true,
    ["item_drink_294"] = true,
    ["item_drink_coffee"] = true,
    ["item_drink_dado_fire"] = true,
    ["item_drink_dado_radioactive"] = true,
    ["item_drink_energy"] = true,
    ["item_drink_soda"] = true,
    ["item_drink_water"] = true,
    ["item_eyedrops_1"] = true,
    ["item_eyedrops_2"] = true,
    ["item_eyedrops_3"] = true,
    ["item_hamburger"] = true,
    ["item_keys"] = true,
    ["item_medkit_1"] = false,
    ["item_medkit_2"] = false,
    ["item_medkit_3"] = false,
    ["item_medkit_4"] = false,
    ["item_nightvision_blue"] = true,
    ["item_nightvision_goc"] = true,
    ["item_nightvision_green"] = true,
    ["item_nightvision_red"] = true,
    ["item_nightvision_white"] = true,
    ["item_ntf_shield"] = true,
    ["item_pills"] = true,
    ["item_radio"] = true,
    ["item_scp_005"] = true,
    ["item_scp_1033"] = true,
    ["item_scp_109"] = true,
    ["item_scp_1499"] = true,
    ["item_scp_207"] = true,
    ["item_scp_215"] = true,
    ["item_scp_268"] = true,
    ["item_scp_427"] = true,
    ["item_scp_447"] = true,
    ["item_scp_500"] = true,
    ["item_scp_714"] = true,
    ["item_screwdriver"] = true,
    ["item_shield"] = true,
    ["item_special_document"] = true,
    ["item_syringe"] = true,
    ["item_toolkit"] = true,
}
function inventory.HasInventory(ply)
    return IsValid(ply) and ply:GTeam() == TEAM_SCP and ply:GetRoleName() == "SCP3114"
        and ply:GetNWBool("SCP3114Disguised", false)
end
function inventory.AllowsClass(class)
    return class == "weapon_scp_3114" or utilities[class] == true
end
function inventory.CanUse(ply, class)
    return class == "weapon_scp_3114" or (inventory.HasInventory(ply) and utilities[class] == true)
end
if SERVER then
    function inventory.TakeDisguiseItems(ply, body)
        local items = body.vtable and body.vtable.Weapons
        if not istable(items) or not inventory.HasInventory(ply) then return end
        for i = #items, 1, -1 do
            local class = items[i]
            if isstring(class) and utilities[class] and not ply:HasWeapon(class) then
                local definition = weapons.GetStored(class)
                if definition then
                    local category = definition.Equipableitem and "equipment" or (definition.UnDroppable and "fixed" or "ordinary")
                    local count = 0
                    for _, existing in ipairs(ply:GetWeapons()) do
                        local kind = existing.Equipableitem and "equipment" or (existing.UnDroppable and "fixed" or "ordinary")
                        if kind == category then count = count + 1 end
                    end
                    local limit = category == "ordinary" and ply:GetMaxSlots() or 6
                    if count < limit then
                        ply:BreachGive(class)
                        -- Only remove items that actually reached the player; guns and overflow stay on the body.
                        if ply:HasWeapon(class) then table.remove(items, i) end
                    end
                end
            end
        end
    end
    hook.Add("PlayerSwitchWeapon", "SCP3114UtilityWeaponsOnly", function(ply, old, new)
        if ply:GetRoleName() == "SCP3114" and ply:GTeam() == TEAM_SCP and IsValid(new)
            and not inventory.CanUse(ply, new:GetClass()) then return true end
    end)
    hook.Add("StartCommand", "SCP3114BlockInjectedWeapons", function(ply, cmd)
        if ply:GetRoleName() ~= "SCP3114" or ply:GTeam() ~= TEAM_SCP then return end
        local active = ply:GetActiveWeapon()
        if IsValid(active) and not inventory.CanUse(ply, active:GetClass()) then
            cmd:RemoveKey(IN_ATTACK) cmd:RemoveKey(IN_ATTACK2)
            if ply:HasWeapon("weapon_scp_3114") then ply:SelectWeapon("weapon_scp_3114") end
        end
    end)
    hook.Add("PlayerDeath", "SCP3114ClearDisguiseInventory", function(ply) ply:SetNWBool("SCP3114Disguised", false) end)
end

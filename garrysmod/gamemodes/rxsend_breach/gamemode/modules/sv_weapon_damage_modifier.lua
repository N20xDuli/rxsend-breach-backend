-- 放到 garrysmod/lua/autorun/server/ 目录下即可自动生效

-----------------------------------------------------------
-- 【配置区 1】：武器基础伤害翻倍倍率
-----------------------------------------------------------
local damageMultipliers = {
    ["cw_cultist_semisniper_arx160"] = 1.09,
    ["cw_kk_ins2_nv4"] = 1.26,
    ["cw_cultist_goc_freedom"] = 1.48,
    ["cw_cultist_goc_fate"] = 1.67,
    ["cw_kk_ins2_p90"] = 1.73,
    ["cw_kk_ins2_edge"] = 1.3,
    ["cw_kk_ins2_cz805"] = 1.3,
    ["3x_particle_disruptor"] = 0.1,
    ["cw_kk_ins2_fnf2000"] = 1.3,
    ["cw_kk_ins2_m98"] = 1.3,
    ["cw_kk_scp_912_deagle"] = 1.2,
    ["cw_cultist_machinegun_m60"] = 1.3,
}

-- 全局默认倍率
local globalMultiplier = 1.0


hook.Add("EntityTakeDamage", "Guashifu_WeaponDamageModifier", function(target, dmginfo)
    -- 获取伤害来源（攻击者）和直接造成伤害的实体（Inflictor）
    local attacker = dmginfo:GetAttacker()
    local inflictor = dmginfo:GetInflictor()

    -- 【兼容物理子弹/LeyHitreg】：如果攻击者不是玩家（比如是一颗物理子弹），向上追溯开枪的主人
    if IsValid(attacker) and not attacker:IsPlayer() and IsValid(attacker:GetOwner()) then
        attacker = attacker:GetOwner()
    end

    -- 确保真正的攻击者是玩家
    if IsValid(attacker) and attacker:IsPlayer() then
        local weapon = NULL

        -- 优先从 Inflictor 获取武器（某些插件会把子弹的 Inflictor 设置为武器本身）
        if IsValid(inflictor) and inflictor:IsWeapon() then
            weapon = inflictor
        else
            -- 否则获取玩家当前正拿在手里的武器
            weapon = attacker:GetActiveWeapon()
        end

        if IsValid(weapon) then
            local wepClass = weapon:GetClass() -- 获取武器的类名（例如 cw_l115）
            
            -- 获取基础伤害值
            local originalDamage = dmginfo:GetDamage()
            local finalDamage = originalDamage

            -- 1. 检查是否有针对这把枪的专属倍率配置
            if damageMultipliers[wepClass] then
                finalDamage = finalDamage * damageMultipliers[wepClass]
            -- 2. 如果没有专属配置，则使用全局默认倍率
            else
                finalDamage = finalDamage * globalMultiplier
            end

            -- 应用修改后的伤害
            dmginfo:SetDamage(finalDamage)
            
            -- print("[伤害拦截] 玩家: " .. attacker:Nick() .. " | 武器: " .. wepClass .. " | 原伤害: " .. originalDamage .. " | 翻倍后: " .. finalDamage)
        end
    end
end)
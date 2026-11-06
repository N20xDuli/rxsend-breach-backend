BREACH = BREACH or {}
BREACH.Nu7 = BREACH.Nu7 or {}
local nu7 = BREACH.Nu7

nu7.Config = {
    FullServerCount = 15,
    FoundationCountThreshold = 5,
    FoundationEnemyRatio = 0.2,
    MaxCallsPerRound = 1,
    ModelWorkshopID = "3814632544",
    OriginalModelWorkshopID = "3773787314",
    WeaponWorkshopID = "3811157151",
}

-- Combat baselines are copied from existing NTF roles; weapon classes are verified from the installed packs.
local modelRoot = "models/player/cheddar/mtf/nu7/"
nu7.Roster = {
    { key = "commander", name = role.NU7_Commander, model = modelRoot .. "nu7_commander.mdl", primaryWeaponName = "Blackout", primaryWeaponClass = "cw_kk_ins2_blackout" },
    { key = "containment", name = role.NU7_Instructor, model = modelRoot .. "nu7_officer.mdl", primaryWeaponName = "M1014", primaryWeaponClass = "cw_kk_ins2_m1014" },
    { key = "soldier", name = role.NU7_Soldier, model = modelRoot .. "nu7_enlisted.mdl", primaryWeaponName = "XM8", primaryWeaponClass = "cw_kk_ins2_xm8" },
    { key = "heavy", name = role.NU7_Heavy, model = modelRoot .. "nu7_autorifleman.mdl", primaryWeaponName = "Minimi", primaryWeaponClass = "cw_cultist_machinegun_minimi", armor = 750 },
    { key = "marksman", name = role.NU7_Marksman, model = modelRoot .. "nu7_marksman.mdl", primaryWeaponName = "AWM", primaryWeaponClass = "cw_kk_ins2_awm" },
    { key = "medic", name = role.NU7_Medic, model = modelRoot .. "nu7_medic.mdl", primaryWeaponName = "MK18", primaryWeaponClass = "cw_kk_ins2_mk18" },
}
nu7.HandsModel = modelRoot .. "nu7_arms.mdl"
nu7.FactionIcon = "nextoren/gui/roles_icon/nu7.png"
nu7.SpawnAnnouncement = "rxsend/nu7/nu7_spawn.mp3"
nu7.Objectives = {
    "拯救设施幸存人员",
    "应对外部势力入侵",
    "重新控制设施",
}
nu7.MissionText = table.concat(nu7.Objectives, "\n")
for _, member in ipairs(nu7.Roster) do member.tasks = nu7.MissionText end

function nu7.FindMember(keyOrName)
    if keyOrName == "instructor" then keyOrName = "containment" end
    for _, member in ipairs(nu7.Roster) do
        if member.key == keyOrName or member.name == keyOrName then return member end
    end
end

function nu7.RegisterRoles()
    if not BREACH_ROLES or not BREACH_ROLES.NTF then return false end
    local templates = {}
    for _, entry in ipairs(BREACH_ROLES.NTF.ntf.roles) do templates[entry.name] = entry end
    local mapping = {commander = role.NTF_Commander, containment = role.NTF_Specialist, marksman = role.NTF_Sniper}
    local entries = {}
    for _, member in ipairs(nu7.Roster) do
        local entry = table.Copy(templates[mapping[member.key]] or templates[role.NTF_Soldier])
        entry.name, entry.team = member.name, TEAM_NU7
        if member.armor then entry.armor = member.armor end
        entry.model, entry.showmodel, entry.tasks = member.model, member.model, member.tasks
        entry.usehead, entry.randomizehead, entry.randomizeface = false, false, false
        entry.head, entry.headgear, entry.female_head, entry.female_headgear, entry.premium_female = nil, nil, nil, nil, nil
        entry.ability = nu7.Skills and nu7.Skills[member.key] and table.Copy(nu7.Skills[member.key]) or nil
        entry.ability_max, entry.max = nil, member.key == "containment" and 1 or nil
        entry.level = 0
        for i = 0, 9 do entry["bodygroup" .. i] = 0 end
        local primary = member.primaryWeaponClass or member.primaryWeaponChoices[1]
        entry.weapons = {"br_holster", "item_radio", primary, "item_nightvision_green", "item_medkit_3"}
        if member.key == "medic" then entry.weapons[#entry.weapons+1] = "item_deffib_medic" end
        if member.key == "commander" then entry.weapons[#entry.weapons+1] = "item_nu7_terminal" end
        entry.ammo = {}
        entries[#entries + 1] = entry
    end
    BREACH_ROLES.NU7 = {nu7 = {name = "MTF Nu-7", color = Color(72, 145, 220), roles = entries}}
    return true
end

-- Select the marksman's weapon for each deployment, and resolve ammunition from its actual SWEP.
function nu7.PrepareRole(name)
    local member = nu7.FindMember(name)
    if not member or not BREACH_ROLES.NU7 then return nil, "落锤兵种未注册。" end
    local primary = member.primaryWeaponClass
    if member.primaryWeaponChoices then primary = member.primaryWeaponChoices[math.random(#member.primaryWeaponChoices)] end
    local weapon = weapons.GetStored(primary)
    if not weapon then return nil, "缺少武器：" .. primary end
    for _, path in ipairs({weapon.ViewModel, weapon.WorldModel}) do
        if isstring(path) and path ~= "" and not util.IsValidModel(path) then return nil, "缺少武器模型：" .. path end
    end
    if not util.IsValidModel(member.model) then return nil, "缺少落锤模型：" .. member.model end
    local base
    for _, entry in ipairs(BREACH_ROLES.NU7.nu7.roles) do if entry.name == member.name then base = entry break end end
    if not base then return nil, "落锤兵种未注册。" end
    local result = table.Copy(base)
    result.weapons[3] = primary
    local clip = weapon.Primary and weapon.Primary.ClipSize or 0
    -- Four magazines by default; individual roles may override the total ammunition.
    if clip > 0 then result.ammo = {{primary, member.totalAmmo or clip * 4}} end
    result.Nu7Prepared = true
    return result
end

nu7.FoundationTeams = {
    [TEAM_GUARD] = true, [TEAM_SECURITY] = true, [TEAM_SCI] = true,
    [TEAM_SPECIAL] = true, [TEAM_NTF] = true, [TEAM_QRT] = true,
    [TEAM_OSN] = true, [TEAM_NU7] = true, [TEAM_ALPHA9] = true,
}

function nu7.IsFoundationTeam(teamID)
    return nu7.FoundationTeams[teamID] == true
end

function nu7.GetSupportCount(totalPlayers, maxPlayers)
    totalPlayers = totalPlayers or #player.GetHumans()
    maxPlayers = maxPlayers or game.MaxPlayers()
    if totalPlayers <= 0 or maxPlayers <= 0 then return 0 end
    return math.Clamp(math.Round(nu7.Config.FullServerCount * totalPlayers / maxPlayers), 1, nu7.Config.FullServerCount)
end

function nu7.IsInDanger(foundationCount, enemyCount)
    return foundationCount < nu7.Config.FoundationCountThreshold
        or (enemyCount > 0 and foundationCount < enemyCount * nu7.Config.FoundationEnemyRatio)
end

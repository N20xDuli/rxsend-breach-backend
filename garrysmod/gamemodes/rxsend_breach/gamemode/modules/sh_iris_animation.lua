-- Resolve Iris locomotion on her own model, including when no weapon exists.
BREACH = BREACH or {}
BREACH.IrisAnimation = BREACH.IrisAnimation or {}
local animation = BREACH.IrisAnimation
local MODEL = 'models/special_agent_thompson/iris_female_v1.mdl'
local aliases = {smg = 'smg1', gren = 'grenade', items = 'passive', heal = 'passive',
    keycard = 'passive', pass = 'passive', shield = 'passive', gauss = 'physgun',
    crowbar = 'melee', axe = 'melee', zombie = 'melee', ww2tdm = 'ar2'}

function animation.IsModel(ply)
    return IsValid(ply) and ply:GetModel() == MODEL
end

local function pick(ply, names)
    for _, name in ipairs(names) do
        local id = ply:LookupSequence(name)
        if id and id >= 0 then return id end
    end
end

function animation.Prepare(ply, weapon)
    if not animation.IsModel(ply) then return false end
    weapon = weapon or ply:GetActiveWeapon()
    local hold = 'normal'
    if IsValid(weapon) then
        local t = weapon:GetTable()
        local stored = weapons.GetStored(weapon:GetClass())
        local cw = t.CW20Weapon or (stored and stored.Base == 'cw_kk_ins2_base')
        hold = (cw and (t.NormalHoldType or (stored and stored.NormalHoldType))) or weapon:GetHoldType() or t.HoldType or 'normal'
    end
    hold = string.lower(hold)
    local t = ply:GetTable()
    if t.RXIrisModel == MODEL and t.Old_Model == MODEL and t.AnimationHoldType == hold and t.RXIrisIdle == t.IdleSafemode then return true end
    local kind = aliases[hold] or hold
    local idle = pick(ply, {'idle_' .. kind, 'idle_all_01'})
    local walk = pick(ply, {'walk_' .. kind, 'walk_all'})
    local run = pick(ply, {'run_' .. kind, 'run_all_01'})
    local crouchIdle = pick(ply, {'cidle_' .. kind, 'cidle_all'})
    local crouchWalk = pick(ply, {'cwalk_' .. kind, 'cwalk_all'})
    local jump = pick(ply, {'jump_' .. kind, 'jump_pistol'})
    if not (idle and walk and run and crouchIdle and crouchWalk and jump) then return false end
    t.Idle, t.IdleAim, t.IdleSafemode = idle, idle, idle
    t.Walk, t.AimWalk, t.SafeModeWalk = walk, walk, walk
    t.Run, t.SafeRun = run, run
    t.CrouchWalkAim, t.CrouchWalkIdle = crouchWalk, crouchIdle
    t.CrouchIdleAim, t.CrouchIdleSafemode = crouchIdle, crouchIdle
    t.JumpAnimation, t.AltWalk = jump, 0
    t.AttackAnimations = pick(ply, {'range_' .. kind})
    local reload = pick(ply, {'reload_' .. kind})
    local crouchReload = pick(ply, {'reload_' .. kind .. '_crouch'}) or reload
    t.ReloadAnimations = reload and {reload, crouchReload} or nil
    t.GestureAnimationIdle, t.GestureAnimationWalk, t.GestureAnimationRun = nil, nil, nil
    t.RXIrisModel, t.RXIrisIdle = MODEL, idle
    t.RXIrisCrouchIdle, t.RXIrisCrouchWalk = crouchIdle, crouchWalk
    t.AnimationHoldType, t.Old_Model, t.Old_Weapon = hold, MODEL, weapon
    return true
end

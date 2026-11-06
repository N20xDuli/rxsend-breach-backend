-- Iris (SCP-105) animation fix.
-- RX builds its per-player animation table from scientist.mdl sequence indices
-- (sh_mtables.lua GetMainSequenceTable), which are meaningless for iris.mdl.
-- Remap every locomotion slot by name against the player's own model.

local IRIS_MODEL = 'models/special_agent_thompson/iris.mdl'

local ALIAS = {
	smg = 'smg1',
	gren = 'grenade',
	normal = 'passive',
	items = 'passive',
	heal = 'passive',
	keycard = 'passive',
	pass = 'passive',
	shield = 'passive',
	gauss = 'passive',
	crowbar = 'melee',
	axe = 'melee',
	zombie = 'melee',
	ww2tdm = 'ar2',
	dual = 'dual',
}

local function pick(ply, list)
	for i = 1, #list do
		local q = ply:LookupSequence(list[i])
		if q and q >= 0 then return q end
	end
	return nil
end

local function fixPlayer(ply)
	if not IsValid(ply) then return end
	if ply:GetModel() ~= IRIS_MODEL then return end
	local t = ply:GetTable()
	if not t then return end
	local ht = t.AnimationHoldType
	if not ht then return end
	local h = ALIAS[ht] or ht

	local idle = pick(ply, { 'idle_' .. h, 'idle_all_01' })
	if not idle then return end
	local walk = pick(ply, { 'walk_' .. h, 'walk_all' }) or idle
	local run = pick(ply, { 'run_' .. h, 'run_all_01' }) or walk
	local cidle = pick(ply, { 'cidle_' .. h, 'cidle_all' }) or idle
	local cwalk = pick(ply, { 'cwalk_' .. h, 'cwalk_all' }) or walk
	local jump = pick(ply, { 'jump_' .. h, 'jump_pistol' }) or run

	t.Idle = idle
	t.IdleAim = idle
	t.IdleSafemode = idle
	t.Walk = walk
	t.AimWalk = walk
	t.SafeModeWalk = walk
	t.Run = run
	t.SafeRun = run
	t.CrouchWalkAim = cwalk
	t.CrouchWalkIdle = cidle
	t.CrouchIdleAim = cidle
	t.CrouchIdleSafemode = cidle
	t.JumpAnimation = jump
	t.AltWalk = 0
	t.AttackAnimations = pick(ply, { 'range_melee', 'seq_meleeattack01', 'zombie_attack_01' })
	t.ReloadAnimations = nil
	t.GestureAnimationIdle = nil
	t.GestureAnimationWalk = nil
	t.GestureAnimationRun = nil
end

local function loaded()
	local t = hook.GetTable()
	return t.PlayerWeaponChanged and t.PlayerWeaponChanged.IrisAnimFix
end

if not loaded() then
	hook.Add('PlayerWeaponChanged', 'IrisAnimFix', function(ply)
		if IsValid(ply) and ply:GetModel() == IRIS_MODEL then
			timer.Simple(0, function() fixPlayer(ply) end)
		end
	end)

	hook.Add('PlayerSpawn', 'IrisAnimFix', function(ply)
		timer.Simple(0.3, function() fixPlayer(ply) end)
	end)

	hook.Add('PlayerSetModel', 'IrisAnimFix', function(ply)
		timer.Simple(0.3, function() fixPlayer(ply) end)
	end)

	timer.Create('IrisAnimFixSweep', 4, 0, function()
		for _, p in ipairs(player.GetAll()) do
			if p:GetModel() == IRIS_MODEL then fixPlayer(p) end
		end
	end)
end

if SERVER then
	file.Write('rx_iris_animfix.json', util.TableToJSON({
		loaded = true,
		realm = 'SERVER',
		players = #player.GetAll(),
	}, true))
end

return fixPlayer

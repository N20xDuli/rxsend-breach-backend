local state = {}
local ok, err = pcall(function()
 local byidx = {}
 for name, idx in pairs(BREACH.Animations.MainSequenceTable or {}) do
  if not byidx[idx] then byidx[idx] = name end
 end
 local fields = {'Idle','IdleAim','IdleSafemode','Walk','AimWalk','AltWalk','Run','SafeRun','SafeModeWalk',
                 'CrouchWalkAim','CrouchWalkIdle','CrouchIdleAim','CrouchIdleSafemode','JumpAnimation',
                 'GestureAnimationIdle','GestureAnimationWalk','GestureAnimationRun','AttackAnimations','ReloadAnimations'}
 local out = {maintable = 0, players = {}}
 for _ in pairs(BREACH.Animations.MainSequenceTable or {}) do out.maintable = out.maintable + 1 end
 for _, p in ipairs(player.GetAll()) do
  if p:EntIndex() == 1 or p:EntIndex() == 13 then
   local t = p:GetTable()
   local row = {idx = p:EntIndex(), nick = p:Nick(), model = p:GetModel(),
                seqs = p:GetSequenceCount(), fields = {}}
   for _, f in ipairs(fields) do
    local v = t[f]
    if v ~= nil then
     if type(v) == 'number' then
      local nm = byidx[v]
      row.fields[f] = {v = v, name = nm, exists = nm and p:LookupSequence(nm) or nil}
     elseif type(v) == 'string' then
      row.fields[f] = {s = v, exists = p:LookupSequence(v)}
     else
      row.fields[f] = {t = type(v)}
     end
    end
   end
   row.calc = {CalcIdeal = tostring(t.CalcIdeal), CalcSeqOverride = tostring(t.CalcSeqOverride),
               AnimationHoldType = tostring(t.AnimationHoldType), role = tostring(t.AnimationRole)}
   out.players[#out.players + 1] = row
  end
 end
 file.Write('rx_animtable.json', util.TableToJSON(out, true))
end)
state.ok = ok
state.err = ok and '' or tostring(err)
file.Write('rx_animtable_server.json', util.TableToJSON(state, true))

local state = {}
local code = [==[
local lp = LocalPlayer()
local orig = lp:GetModel()
local res = {player = lp:Nick(), orig = orig, rows = {}}
local acts = {
 idle = ACT_MP_STAND_IDLE,
 run = ACT_MP_RUN,
 walk = ACT_MP_WALK,
 crouch = ACT_MP_CROUCH_IDLE,
 jump = ACT_MP_JUMP,
 swim = ACT_MP_SWIM,
}
local models = {
 {'iris','models/special_agent_thompson/iris.mdl'},
 {'police','models/player/police.mdl'},
 {'female01','models/player/group01/female_01.mdl'},
 {'kleiner','models/player/kleiner.mdl'},
}
for _, m in ipairs(models) do
 local row = {name = m[1], path = m[2]}
 local ok, err = pcall(function()
  lp:SetModel(m[2])
  row.count = lp:GetSequenceCount()
  row.cur = lp:GetSequence()
  row.curname = lp:GetSequenceName(lp:GetSequence())
  row.curact = lp:GetSequenceActivity(lp:GetSequence())
  row.act = {}
  for k, v in pairs(acts) do
   local r = lp:SelectWeightedSequence(v)
   row.act[k] = r
  end
  row.lookup_idle_all_01 = lp:LookupSequence('idle_all_01')
  row.lookup_run_all = lp:LookupSequence('run_all')
  row.lookup_walk_all = lp:LookupSequence('walk_all')
  row.bones = lp:GetBoneCount()
 end)
 if not ok then row.err = tostring(err) end
 res.rows[#res.rows + 1] = row
end
lp:SetModel(orig)
timer.Simple(0.3, function()
 local js = util.TableToJSON(res)
 net.Start('RXAnimAck2')
 net.WriteString(js)
 net.SendToServer()
end)
]==]
local ok, err = pcall(function()
 util.AddNetworkString('RXAnimAck2')
 net.Receive('RXAnimAck2', function(len, p)
  local s = net.ReadString()
  file.Append('rx_anim_ack2.txt', '[' .. tostring(len) .. ']' .. s .. '\n')
 end)
 state.pushed = 0
 for _, p in ipairs(player.GetHumans()) do
  if p:Nick() == 'shikieiki2333' then
   ULib.clientRPC(p, 'RunString', code, 'RXAnimActTest2', false)
   state.pushed = state.pushed + 1
  end
 end
end)
state.ok = ok
state.err = ok and '' or tostring(err)
file.Write('rx_anim_ack2_server.json', util.TableToJSON(state, true))

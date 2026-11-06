local code = [==[
local mdl = 'models/special_agent_thompson/iris.mdl'
local lp = LocalPlayer()
local orig = lp:GetModel()
local t = {player = lp:Nick(), orig = orig}
local ok, err = pcall(function()
 lp:SetModel(mdl)
 local a = {}
 timer.Simple(1.0, function()
  t.seq_a = lp:GetSequence()
  t.seqname_a = lp:GetSequenceName(lp:GetSequence())
  t.cycle_a = lp:GetCycle()
  t.act = lp:GetSequenceActivity(lp:GetSequence())
  t.playback = lp:GetPlaybackRate()
 end)
 timer.Simple(2.0, function()
  t.cycle_b = lp:GetCycle()
  t.seqname_b = lp:GetSequenceName(lp:GetSequence())
  t.moving = t.cycle_a ~= t.cycle_b
  lp:SetModel(orig)
  net.Start('RXAnimProbeAck')
  net.WriteString(util.TableToJSON(t))
  net.SendToServer()
 end)
end)
if not ok then
 t.err = tostring(err)
 net.Start('RXAnimProbeAck')
 net.WriteString(util.TableToJSON(t))
 net.SendToServer()
end
]==]
for _, p in ipairs(player.GetHumans()) do
 if p:Nick() == 'shikieiki2333' then
  ULib.clientRPC(p, 'RunString', code, 'RXAnimSelfTest', false)
 end
end

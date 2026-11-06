local state = {}
local code = [==[
local lp = LocalPlayer()
local orig = lp:GetModel()
local res = {player = lp:Nick(), orig = orig, rows = {}}
local list = {
 {'iris','models/special_agent_thompson/iris.mdl'},
 {'police','models/player/police.mdl'},
 {'female01','models/player/group01/female_01.mdl'},
}
local i = 0
local function step()
 i = i + 1
 local m = list[i]
 if not m then
  lp:SetModel(orig)
  timer.Simple(0.3, function()
   net.Start('RXAnimAck2')
   net.WriteString(util.TableToJSON(res))
   net.SendToServer()
  end)
  return
 end
 local row = {name = m[1]}
 res.rows[#res.rows + 1] = row
 lp:SetModel(m[2])
 timer.Simple(0.5, function()
  row.s1 = lp:GetSequence()
  row.n1 = lp:GetSequenceName(lp:GetSequence())
  row.c1 = lp:GetCycle()
  row.cnt = lp:GetSequenceCount()
  timer.Simple(0.9, function()
   row.s2 = lp:GetSequence()
   row.n2 = lp:GetSequenceName(lp:GetSequence())
   row.c2 = lp:GetCycle()
   row.advanced = row.c1 ~= row.c2
   step()
  end)
 end)
end
step()
]==]
local ok, err = pcall(function()
 util.AddNetworkString('RXAnimAck2')
 net.Receive('RXAnimAck2', function(len, p)
  file.Append('rx_anim_ack2.txt', '[' .. tostring(len) .. ']' .. net.ReadString() .. '\n')
 end)
 state.pushed = 0
 for _, p in ipairs(player.GetHumans()) do
  if p:Nick() == 'shikieiki2333' then
   ULib.clientRPC(p, 'RunString', code, 'RXAnimAB', false)
   state.pushed = state.pushed + 1
  end
 end
end)
state.ok = ok
state.err = ok and '' or tostring(err)
file.Write('rx_anim_ack2_server.json', util.TableToJSON(state, true))

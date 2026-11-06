local state = {}
local code = [==[
local ok, err = pcall(function()
 local res = {me = LocalPlayer():Nick(), rows = {}}
 local function snap(tag)
  for _, pl in ipairs(player.GetAll()) do
   local e = res.rows[pl:EntIndex()]
   if not e then e = {nick = pl:Nick()} res.rows[pl:EntIndex()] = e end
   local s = pl:GetSequence()
   e[tag] = {model = pl:GetModel(), seq = s, name = pl:GetSequenceName(s),
             act = pl:GetSequenceActivity(s), cycle = pl:GetCycle(),
             speed = math.floor(pl:GetVelocity():Length())}
  end
 end
 snap('a')
 timer.Simple(0.8, function()
  snap('b')
  timer.Simple(0.8, function()
   snap('c')
   net.Start('RXAnimAck2')
   net.WriteString(util.TableToJSON(res))
   net.SendToServer()
  end)
 end)
end)
if not ok then
 net.Start('RXAnimAck2')
 net.WriteString(util.TableToJSON({err = tostring(err), me = LocalPlayer():Nick()}))
 net.SendToServer()
end
]==]
local MDL = 'models/special_agent_thompson/iris.mdl'
local ok, err = pcall(function()
 util.AddNetworkString('RXAnimAck2')
 net.Receive('RXAnimAck2', function(len, p)
  file.Append('rx_anim_ack2.txt', '[' .. tostring(len) .. ']' .. net.ReadString() .. '\n')
 end)
 state.all = {}
 for _, p in ipairs(player.GetAll()) do
  state.all[#state.all + 1] = {idx = p:EntIndex(), nick = p:Nick(), model = p:GetModel(), bot = p:IsBot()}
 end
 for _, p in ipairs(player.GetHumans()) do
  if p:Nick() == 'shikieiki2333' then
   ULib.clientRPC(p, 'RunString', code, 'RXAnimLive', false)
   state.pushed = 1
  end
 end
end)
state.ok = ok
state.err = ok and '' or tostring(err)
file.Write('rx_anim_live_server.json', util.TableToJSON(state, true))

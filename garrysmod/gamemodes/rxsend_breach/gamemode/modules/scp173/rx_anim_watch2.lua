local state = {}
local code = [==[
local ok, err = pcall(function()
 local res = {me = LocalPlayer():Nick(), rows = {}}
 local function snap(tag)
  for _, pl in ipairs(player.GetAll()) do
   local k = tostring(pl:EntIndex())
   local e = res.rows[k]
   if not e then e = {nick = pl:Nick()} res.rows[k] = e end
   local s = pl:GetSequence()
   e[tag] = {
    model = pl:GetModel(),
    seq = s,
    name = pl:GetSequenceName(s),
    act = pl:GetSequenceActivity(s),
    cycle = pl:GetCycle(),
    speed = math.floor(pl:GetVelocity():Length()),
   }
  end
 end
 snap('a')
 timer.Simple(0.9, function()
  snap('b')
  net.Start('RXAnimAck2')
  net.WriteString(util.TableToJSON(res))
  net.SendToServer()
 end)
end)
if not ok then
 net.Start('RXAnimAck2')
 net.WriteString(util.TableToJSON({err = tostring(err), me = LocalPlayer():Nick()}))
 net.SendToServer()
end
]==]
local ok, err = pcall(function()
 util.AddNetworkString('RXAnimAck2')
 net.Receive('RXAnimAck2', function(len, p)
  file.Append('rx_anim_ack2.txt', '[' .. tostring(len) .. ']' .. net.ReadString() .. '\n')
 end)
 local watcher = 'shikieiki2333'
 state.humans = {}
 for _, p in ipairs(player.GetHumans()) do
  state.humans[#state.humans + 1] = p:Nick()
  if p:Nick() == watcher then
   ULib.clientRPC(p, 'RunString', code, 'RXAnimWatch2', false)
   state.pushed = (state.pushed or 0) + 1
  end
 end
end)
state.ok = ok
state.err = ok and '' or tostring(err)
file.Write('rx_anim_watch_server.json', util.TableToJSON(state, true))

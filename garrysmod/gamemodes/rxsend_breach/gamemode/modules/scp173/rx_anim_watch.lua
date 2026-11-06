local state = {}
local code = [==[
local res = {me = LocalPlayer():Nick(), rows = {}}
local function snap(tag)
 for _, pl in ipairs(player.GetAll()) do
  local e = res.rows[pl:EntIndex()]
  if not e then e = {nick = pl:Nick()} res.rows[pl:EntIndex()] = e end
  e[tag] = {
   model = pl:GetModel(),
   seq = pl:GetSequence(),
   name = pl:GetSequenceName(pl:GetSequence()),
   act = pl:GetSequenceActivity(pl:GetSequence()),
   cycle = pl:GetCycle(),
   speed = math.floor(pl:GetVelocity():Length()),
  }
 end
end
snap('a')
timer.Simple(0.9, function()
 snap('b')
 timer.Simple(0.2, function()
  net.Start('RXAnimAck2')
  net.WriteString(util.TableToJSON(res))
  net.SendToServer()
 end)
end)
]==]
local ok, err = pcall(function()
 util.AddNetworkString('RXAnimAck2')
 net.Receive('RXAnimAck2', function(len, p)
  file.Append('rx_anim_ack2.txt', '[' .. tostring(len) .. ']' .. net.ReadString() .. '\n')
 end)
 local watcher = 'shikieiki2333'
 local target
 for _, p in ipairs(player.GetHumans()) do
  if p:Nick() ~= watcher and not target then target = p end
 end
 if not target then state.err = 'no target player' return end
 state.target = target:Nick()
 state.orig_model = target:GetModel()
 target:SetModel('models/special_agent_thompson/iris.mdl')
 state.applied = target:GetModel()
 for _, p in ipairs(player.GetHumans()) do
  if p:Nick() == watcher then
   ULib.clientRPC(p, 'RunString', code, 'RXAnimWatch', false)
   state.pushed = 1
  end
 end
 timer.Simple(6, function()
  if IsValid(target) then target:SetModel(state.orig_model) end
  file.Write('rx_anim_watch_done.json', util.TableToJSON({target = state.target, restored = true}, true))
 end)
end)
state.ok = ok
state.err = state.err or (ok and '' or tostring(err))
file.Write('rx_anim_watch_server.json', util.TableToJSON(state, true))

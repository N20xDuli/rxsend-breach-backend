local state = {}
local ping = [==[
net.Start('RXAnimAck2')
net.WriteString(util.TableToJSON({ping = true, me = LocalPlayer():Nick(), n = #player.GetAll()}))
net.SendToServer()
]==]
local mid = [==[
local r = {me = LocalPlayer():Nick(), rows = {}}
for _, pl in ipairs(player.GetAll()) do
 r.rows[#r.rows + 1] = {nick = pl:Nick(), model = pl:GetModel(), seq = pl:GetSequence(), name = pl:GetSequenceName(pl:GetSequence())}
end
net.Start('RXAnimAck2')
net.WriteString(util.TableToJSON(r))
net.SendToServer()
]==]
local full = [==[
local r = {me = LocalPlayer():Nick(), rows = {}}
for _, pl in ipairs(player.GetAll()) do
 local s = pl:GetSequence()
 r.rows[#r.rows + 1] = {nick = pl:Nick(), model = pl:GetModel(), seq = s, name = pl:GetSequenceName(s), act = pl:GetSequenceActivity(s), cyc = pl:GetCycle()}
end
net.Start('RXAnimAck2')
net.WriteString(util.TableToJSON(r))
net.SendToServer()
]==]
local ok, err = pcall(function()
 util.AddNetworkString('RXAnimAck2')
 net.Receive('RXAnimAck2', function(len, p)
  file.Append('rx_anim_ack2.txt', '[' .. tostring(len) .. ']' .. net.ReadString() .. '\n')
 end)
 for _, p in ipairs(player.GetHumans()) do
  if p:Nick() == 'shikieiki2333' then
   ULib.clientRPC(p, 'RunString', ping, 'RXPing', false)
   timer.Simple(1, function() if IsValid(p) then ULib.clientRPC(p, 'RunString', mid, 'RXMid', false) end end)
   timer.Simple(2, function() if IsValid(p) then ULib.clientRPC(p, 'RunString', full, 'RXFull', false) end end)
  end
 end
end)
state.ok = ok
state.err = ok and '' or tostring(err)
file.Write('rx_anim_watch_server.json', util.TableToJSON(state, true))

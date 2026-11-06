local state = {}
local code = [==[
local ok, err = pcall(function()
 local res = {me = LocalPlayer():Nick(), rows = {}}
 local probe = {0, 1, 2, 3, 13, 108, 170, 171, 2155, 2167}
 local function row(pl, tag)
  local o = {tag = tag, nick = pl:Nick(), model = pl:GetModel(),
             bones = pl:GetBoneCount(), seqs = pl:GetSequenceCount(), a = {}}
  for _, i in ipairs(probe) do
   if i < o.seqs then
    o.a[#o.a + 1] = i .. '=' .. tostring(pl:GetSequenceName(i)) .. '#' .. tostring(pl:GetSequenceActivity(i))
   end
  end
  local q = pl:LookupSequence('idle_all_01')
  o.idle_all_01 = q
  o.idle_all_01_act = q and q >= 0 and pl:GetSequenceActivity(q) or -99
  return o
end
res.rows[#res.rows + 1] = row(LocalPlayer(), 'self')
for _, pl in ipairs(player.GetAll()) do
 if pl:EntIndex() == 1 then res.rows[#res.rows + 1] = row(pl, 'ctrl') end
end
net.Start('RXAnimAck2')
net.WriteString(util.TableToJSON(res))
net.SendToServer()
end)
if not ok then
 net.Start('RXAnimAck2')
 net.WriteString(util.TableToJSON({err = tostring(err)}))
 net.SendToServer()
end
]==]
local ok, err = pcall(function()
 util.AddNetworkString('RXAnimAck2')
 net.Receive('RXAnimAck2', function(len, p)
  file.Append('rx_anim_ack2.txt', '[' .. tostring(len) .. ']' .. net.ReadString() .. '\n')
 end)
 for _, p in ipairs(player.GetHumans()) do
  if p:Nick() == 'shikieiki2333' then
   ULib.clientRPC(p, 'RunString', code, 'RXAnimActs', false)
   state.pushed = 1
  end
 end
end)
state.ok = ok
state.err = ok and '' or tostring(err)
file.Write('rx_anim_acts_server.json', util.TableToJSON(state, true))

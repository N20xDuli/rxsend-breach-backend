local state = {}
local code = [==[
local ok, err = pcall(function()
 local res = {me = LocalPlayer():Nick(), rows = {}}
 local function row(pl, tag)
  local s = pl:GetSequence()
  return {tag = tag, nick = pl:Nick(), model = pl:GetModel(),
          bones = pl:GetBoneCount(), seqs = pl:GetSequenceCount(),
          head = pl:LookupBone('ValveBiped.Bip01_Head1'),
          seq = s, name = pl:GetSequenceName(s),
          act = pl:GetSequenceActivity(s), cycle = pl:GetCycle()}
 end
 if player.GetByID(1) and IsValid(player.GetByID(1)) then
  res.rows[#res.rows + 1] = row(player.GetByID(1), 'byid1')
 end
 for _, pl in ipairs(player.GetAll()) do
  if pl:EntIndex() == 1 then res.rows[#res.rows + 1] = row(pl, 'idx1') end
 end
 res.rows[#res.rows + 1] = row(LocalPlayer(), 'self')
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
   ULib.clientRPC(p, 'RunString', code, 'RXAnimSanity', false)
   state.pushed = 1
  end
 end
end)
state.ok = ok
state.err = ok and '' or tostring(err)
file.Write('rx_anim_sanity_server.json', util.TableToJSON(state, true))

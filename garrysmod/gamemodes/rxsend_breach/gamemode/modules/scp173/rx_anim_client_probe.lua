local state = {}
local ok, err = pcall(function()
 util.AddNetworkString('RXAnimProbeAck')
 net.Receive('RXAnimProbeAck', function(len, p)
  if len > 4000 then return end
  file.Append('rx_anim_probe_ack.txt', net.ReadString() .. '\n')
 end)
 local code = [==[
local t = {player = LocalPlayer():Nick()}
local mdl = 'models/special_agent_thompson/iris.mdl'
t.iris_exists = file.Exists(mdl, 'GAME')
t.iris_valid = util.IsValidModel(mdl)
t.manm_exists = file.Exists('models/m_anm.mdl', 'GAME')
local ent = ClientsideModel(mdl)
t.client_seqs = IsValid(ent) and ent:GetSequenceCount() or -1
t.bones = IsValid(ent) and ent:GetBoneCount() or -1
if IsValid(ent) then ent:Remove() end
net.Start('RXAnimProbeAck')
net.WriteString(util.TableToJSON(t))
net.SendToServer()
]==]
 for _, p in ipairs(player.GetHumans()) do
  ULib.clientRPC(p, 'RunString', code, 'RXAnimProbe', false)
 end
 state.pushed = #player.GetHumans()
end)
state.ok = ok
state.err = ok and '' or tostring(err)
file.Write('rx_anim_probe_server.json', util.TableToJSON(state, true))

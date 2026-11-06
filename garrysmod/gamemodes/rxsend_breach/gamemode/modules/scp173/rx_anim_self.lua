local state = {}
local code = [==[
local lp = LocalPlayer()
local res = {me = lp:Nick(), model = lp:GetModel(), samples = {}}
local bones = {'ValveBiped.Bip01_Head1', 'ValveBiped.Bip01_Spine4', 'ValveBiped.Bip01_Pelvis',
               'ValveBiped.Bip01_L_Thigh', 'ValveBiped.Bip01_R_Thigh', 'ValveBiped.Bip01_L_Hand'}
res.bone_lookup = {}
for _, b in ipairs(bones) do res.bone_lookup[b] = lp:LookupBone(b) end
res.bone_count = lp:GetBoneCount()
res.seq_count = lp:GetSequenceCount()
local n = 0
local function take()
 n = n + 1
 local s = lp:GetSequence()
 res.samples[n] = {
  seq = s,
  name = lp:GetSequenceName(s),
  act = lp:GetSequenceActivity(s),
  cycle = lp:GetCycle(),
  speed = math.floor(lp:GetVelocity():Length()),
 }
 if n < 10 then
  timer.Simple(0.4, take)
 else
  net.Start('RXAnimAck2')
  net.WriteString(util.TableToJSON(res))
  net.SendToServer()
 end
end
take()
]==]
local ok, err = pcall(function()
 util.AddNetworkString('RXAnimAck2')
 net.Receive('RXAnimAck2', function(len, p)
  file.Append('rx_anim_ack2.txt', '[' .. tostring(len) .. ']' .. net.ReadString() .. '\n')
 end)
 state.pushed = 0
 for _, p in ipairs(player.GetHumans()) do
  if p:Nick() == 'shikieiki2333' then
   ULib.clientRPC(p, 'RunString', code, 'RXAnimSelf', false)
   state.pushed = state.pushed + 1
  end
 end
end)
state.ok = ok
state.err = ok and '' or tostring(err)
file.Write('rx_anim_self_server.json', util.TableToJSON(state, true))

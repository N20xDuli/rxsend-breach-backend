local state = {}
local ok, err = pcall(function()
 local rows = {}
 for _, p in ipairs(player.GetAll()) do
  local s = p:GetSequence()
  rows[#rows + 1] = {
   idx = p:EntIndex(),
   nick = p:Nick(),
   model = p:GetModel(),
   seq = s,
   name = p:GetSequenceName(s),
   act = p:GetSequenceActivity(s),
   cycle = p:GetCycle(),
   speed = math.floor(p:GetVelocity():Length()),
   alive = p:Alive(),
   team = p.GTeam and p:GTeam() or -1,
  }
 end
 file.Write('rx_srv_anim.json', util.TableToJSON(rows, true))
end)
state.ok = ok
state.err = ok and '' or tostring(err)
file.Write('rx_srv_anim_server.json', util.TableToJSON(state, true))

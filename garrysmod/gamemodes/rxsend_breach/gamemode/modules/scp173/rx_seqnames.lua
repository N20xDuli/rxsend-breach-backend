local state = {}
local ok, err = pcall(function()
 local cands = {
  'idle_all_01', 'idle_all_02', 'idle_all', 'walk_all', 'walk_all_01', 'run_all_01', 'run_all',
  'crouch_all', 'crouchidle', 'cidle_all', 'crouchwalk_all', 'crouch_walk_all',
  'jump_all', 'hop_all', 'jump_generic', 'attack_all', 'melee_all', 'range_all',
  'reload_all', 'idle_physgun', 'swim_idle_all', 'swim_all', 'sit_all', 'ragdoll', 'reference',
 }
 local out = {players = {}}
 for _, p in ipairs(player.GetAll()) do
  if p:EntIndex() == 13 or p:EntIndex() == 1 then
   local row = {idx = p:EntIndex(), nick = p:Nick(), model = p:GetModel(),
                seqs = p:GetSequenceCount(), found = {}}
   for _, n in ipairs(cands) do
    local q = p:LookupSequence(n)
    if q and q >= 0 then
     row.found[n] = {idx = q, act = p:GetSequenceActivity(q)}
    end
   end
   out.players[#out.players + 1] = row
  end
 end
 file.Write('rx_seqnames.json', util.TableToJSON(out, true))
end)
state.ok = ok
state.err = ok and '' or tostring(err)
file.Write('rx_seqnames_server.json', util.TableToJSON(state, true))

local state = {}
local ok, err = pcall(function()
 local out = {}
 for _, p in ipairs(player.GetAll()) do
  if p:EntIndex() == 13 then
   local names = p:GetSequenceList()
   local keep = {}
   for _, n in ipairs(names) do
    local l = string.lower(n)
    if string.find(l, 'crouch', 1, true) or string.find(l, 'jump', 1, true)
       or string.find(l, 'walk', 1, true) or string.find(l, 'run', 1, true)
       or string.find(l, 'attack', 1, true) or string.find(l, 'melee', 1, true)
       or string.find(l, 'reload', 1, true) or string.find(l, 'swim', 1, true) then
     keep[#keep + 1] = n
    end
   end
   out[idx or 13] = keep
   file.Write('rx_seqn_matches.json', util.TableToJSON({model = p:GetModel(), total = #names, matches = keep}, true))
  end
 end
end)
state.ok = ok
state.err = ok and '' or tostring(err)
file.Write('rx_seqn_server.json', util.TableToJSON(state, true))

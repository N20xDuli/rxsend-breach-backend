local paths = {
 'models/m_anm.mdl','models/humans/m_anm.mdl','models/player/m_anm.mdl','models/f_anm.mdl','models/humans/f_anm.mdl',
 'models/special_agent_thompson/iris.mdl',
}
local t = {stamp=os.time(), exists={}, valid={}}
for _, p in ipairs(paths) do
 t.exists[p] = file.Exists(p, 'GAME')
 t.valid[p] = util.IsValidModel(p)
end
local e = ents.Create('prop_dynamic'); e:SetModel('models/special_agent_thompson/iris.mdl'); e:SetPos(Vector(0,0,-16000)); e:SetNoDraw(true); e:Spawn()
t.seqs = {}
for i = 0, math.min(e:GetSequenceCount()-1, 8) do t.seqs[#t.seqs+1] = e:GetSequenceName(i) end
t.seqcount = e:GetSequenceCount()
e:Remove()
file.Write('rx_iris_anim_probe.json', util.TableToJSON(t, true))

-- Resolve indices on the current skeleton or stolen model, never the generic human index table.
hook.Add("CalcMainActivity","RX3114ModelAnimation",function(p,velocity)
 if not IsValid(p) or not p:Alive() or p:GetRoleName()~="SCP3114" then return end
 local forced=p:GetTable().ForceAnimSequence
 if forced and forced~=0 then return end
 local speed=velocity:Length2DSqr()
 local names
 if p:Crouching()then names=speed>1 and {"cwalk_all","crouchwalk_all"} or {"cidle_all","crouchidle","crouchIdle_panicked4"}
 elseif not p:OnGround()then names={"jump","jump_fist","idle_all_01"}
 elseif speed>22500 then names={"run_all_01","run_all","walk_all"}
 elseif speed>1 then names={"walk_all","walk_all_moderate"}
 else names={"idle_all_01","idle_all","0_049_idle","idle"}end
 for _,name in ipairs(names)do local id=p:LookupSequence(name);if id>=0 then return ACT_IDLE,id end end
end)

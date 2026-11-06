-- SCP-062-DE starts without a SWEP; the general animation system initializes on weapon changes.
hook.Add("CalcMainActivity","RX062DEUnarmed",function(ply,velocity)
 if not IsValid(ply) or not ply:Alive() or ply:GetRoleName()~="SCP062DE" or IsValid(ply:GetActiveWeapon()) then return end
 local forced=ply:GetTable().ForceAnimSequence
 if forced and forced~=0 then return end
 local speed=velocity:Length2DSqr()
 local name=speed>15000 and "run_all" or (speed>1 and "walk_all" or "idle_all_01")
 if ply:Crouching() then name=speed>1 and "cwalk_all" or "crouchidle" end
 local seq=ply:LookupSequence(name)
 if seq<0 then seq=ply:LookupSequence("idle_all_01") end
 if seq<0 then return end
 return ACT_IDLE,seq
end)

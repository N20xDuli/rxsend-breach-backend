-- Keep repaired support skills outside the legacy player module.
BREACH.SupportSkillFixes=BREACH.SupportSkillFixes or {}
local fixes=BREACH.SupportSkillFixes
local function notify(ply,message)
 if SERVER and (ply.RXSupportSkillNotice or 0)<=CurTime() then
  ply.RXSupportSkillNotice=CurTime()+2;ply:RXSENDNotify(message)
 end
end
local function targetOf(ply)
 local extent=Vector(8,10,5)
 return util.TraceHull({start=ply:GetShootPos(),endpos=ply:GetShootPos()+ply:GetAimVector()*165,filter=ply,mins=-extent,maxs=extent}).Entity
end
function fixes.Handle(ply,key)
 if not IsValid(ply) then return false end
 local name=ply:GetRoleName()
 local healer=ply:GetNWString("AbilityName")=="l:abilities_name_matilda"
 if name~=role.NTF_Specialist and name~=role.GRU_Commander and not healer then return false end
 local configured=SERVER and (ply.specialability or ply:GetInfoNum("breach_config_useability",KEY_H))
  or (GetConVar("breach_config_useability") and GetConVar("breach_config_useability"):GetInt())
 if key~=configured then return false end
 local mute=SERVER and ply:GetInfoNum("breach_config_radio_mute",KEY_H)
  or (GetConVar("breach_config_radio_mute") and GetConVar("breach_config_radio_mute"):GetInt() or KEY_H)
 if key==mute and IsValid(ply:GetWeapon("item_radio")) then
  notify(ply,"技能键与对讲机静音键冲突，请在设置中换一个技能键。")
  return true
 end
 if not SERVER then return true end
 if not ply:Alive() or ply:Health()<=0 or ply:GTeam()==TEAM_SPEC or ply:IsFrozen() or ply.MovementLocked then return true end
 if ply:GetSpecialCD()>CurTime() then
  notify(ply,"技能冷却中，剩余 "..math.ceil(ply:GetSpecialCD()-CurTime()).." 秒。")
  return true
 end
 if healer then
  -- Preserve the existing 40 HP / 250 unit / 45 second skill balance.
  -- Dead players and spectators must never receive health from a nearby cast.
  ply:SetSpecialCD(CurTime()+45)
  ply:EmitSound("nextoren/vo/special_sci/medic/medic_"..math.random(1,11)..".mp3")
  local healed=0
  for _,target in ipairs(ents.FindInSphere(ply:GetPos(),250)) do
   if IsValid(target) and target:IsPlayer() and target:Alive() and target:Health()>0
    and target:GTeam()~=TEAM_SPEC and target:Health()<target:GetMaxHealth() then
    target:SetHealth(math.min(target:Health()+40,target:GetMaxHealth()))
    healed=healed+1
   end
  end
  notify(ply,"范围治疗已生效，治疗了 "..healed.." 人。")
  return true
 end
 local target=targetOf(ply)
 if not IsValid(target) or not target:IsPlayer() or not target:Alive() or target:Health()<=0 then
  notify(ply,"请对准约 4 米内的存活目标。")
  return true
 end
 if name==role.NTF_Specialist then
  if target:GTeam()~=TEAM_SCP then notify(ply,"震颤只能作用于 SCP。")return true end
  local identity,roleName=target:GetNamesurvivor(),target:GetRoleName()
  target.RXNTFStunToken=(target.RXNTFStunToken or 0)+1
  local token=target.RXNTFStunToken
  ply:SetSpecialCD(CurTime()+90);target:Freeze(true)
  local sequence=target:GetModel()=="models/cultist/scp/scp_682.mdl" and "0_Stun_29" or "0_SCP_542_lifedrain"
  if target:LookupSequence(sequence)>=0 then target:SetForcedAnimation(sequence,false,false,6)end
  timer.Create("RXNTFStun"..target:EntIndex(),6,1,function()
   if IsValid(target) and target.RXNTFStunToken==token and target:GetNamesurvivor()==identity and target:GetRoleName()==roleName and target:GTeam()==TEAM_SCP then target:Freeze(false)end
  end)
  notify(ply,"目标已冻结，持续 6 秒。")
 else
  if target:GTeam()==TEAM_GRU or target:GTeam()==TEAM_SPEC then notify(ply,"不能审讯本队人员或观察者。")return true end
  if ply:GetVelocity():LengthSqr()>100 then notify(ply,"请站定后审讯，并持续对准目标。")return true end
  if ply.ProgressBarData then notify(ply,"正在进行其他交互。")return true end
  ply:BrProgressBar("l:progress_wait",7,"nextoren/gui/special_abilities/special_gru_commander.png",target,false,function()
   if not IsValid(ply) or not ply:Alive() or ply:GetRoleName()~=role.GRU_Commander or not IsValid(target) or not target:Alive() or target:GTeam()==TEAM_GRU or target:GTeam()==TEAM_SPEC then return end
   ply:SetSpecialCD(CurTime()+120)
   SetGlobalInt("TASKS_GRU_3",GetGlobalInt("TASKS_GRU_3")+1)
   notify(ply,"审讯完成。")
  end)
 end
 return true
end
function fixes.Bind()
 local current=(hook.GetTable().PlayerButtonDown or {}).Specials
 if not current or current==fixes.wrapper then return end
 fixes.previous=current
 fixes.wrapper=function(ply,key)
  if fixes.Handle(ply,key) then return end
  return fixes.previous(ply,key)
 end
 hook.Add("PlayerButtonDown","Specials",fixes.wrapper)
end
hook.Add("InitPostEntity","RXSupportSkillFixes",fixes.Bind)
timer.Simple(0,fixes.Bind)

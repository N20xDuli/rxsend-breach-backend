BREACH.SCP076Forward=BREACH.SCP076Forward or {}
local skill=BREACH.SCP076Forward
skill.Active=skill.Active or {}
function skill.Cancel(w)
 local state=skill.Active[w];if not state then return end
 skill.Active[w]=nil;timer.Remove(state.timer)
 if IsValid(w) then w.killmode=false;w.noattack=false;w:SetInSeq(false) end
 local p=state.owner
 if IsValid(p) then
  p.forward_076=false
  if p:GetRoleName()=="SCP076" then p:SetRunSpeed(state.run);p:SetWalkSpeed(state.walk);p:SetNoCollideWithTeammates(false) end
 end
end
function skill.Use(p,w)
 if not IsValid(p) or not p:Alive() or p:GetRoleName()~="SCP076" or p:IsFrozen() then return false end
 if not IsValid(w) or w:GetClass()~="weapon_scp_076" or w:GetOwner()~=p or p:GetActiveWeapon()~=w then return false end
 if (p.ForceAnimSequence and p.ForceAnimSequence~=0) or skill.Active[w] then return false end
 local icon=w.AbilityIcons and w.AbilityIcons[3];if not icon then return false end
 if (icon.CooldownTime or 0)>CurTime() then p:RXSENDNotify("向前劈砍冷却中："..math.ceil(icon.CooldownTime-CurTime()).." 秒。");return false end
 local sequence="wos_judge_h_left_t3";local id=p:LookupSequence(sequence)
 if id<0 then p:RXSENDNotify("向前劈砍动画缺失，请联系管理员。");return false end
 local duration=math.max(p:SequenceDuration(id),1.6)
 local state={owner=p,run=p:GetRunSpeed(),walk=p:GetWalkSpeed(),timer="RX076Forward"..p:UserID(),expires=CurTime()+duration+0.1}
 skill.Active[w]=state;w:Cooldown(3,icon.Cooldown or 80);w:SetInSeq(true);w.noattack=true;p.forward_076=true
 p:SetForcedAnimation(sequence,duration,nil,function()skill.Cancel(w)end)
 net.Start("ThirdPersonCutscene2");net.WriteUInt(2,4);net.WriteBool(false);net.Send(p)
 timer.Create(state.timer,1.1,1,function()
  if skill.Active[w]~=state then return end
  if not IsValid(p) or not IsValid(w) or not p:Alive() or p:GetActiveWeapon()~=w then skill.Cancel(w);return end
  p.forward_076=false;w.killmode=true;p:SetRunSpeed(0);p:SetWalkSpeed(0);p:SetNoCollideWithTeammates(true)
  p:SetVelocity(p:EyeAngles():Forward()*3000)
 end)
 return true
end
hook.Remove("PlayerButtonDown","SCP_076_abil")
hook.Remove("SetupMove","SCP_076_move_forward")
hook.Add("PlayerButtonDown","RX076ForwardKey",function(p,key)if key==KEY_Q then skill.Use(p,p:GetActiveWeapon()) end end)
hook.Add("SetupMove","RX076ForwardMove",function(p,mv)
 if p.forward_076 and p:GetRoleName()=="SCP076" then mv:SetForwardSpeed(115);mv:SetSideSpeed(0);mv:SetUpSpeed(0) end
end)
hook.Add("Think","RX076ForwardCleanup",function()
 for w,state in pairs(skill.Active)do
  local p=state.owner
  if not IsValid(w) or not IsValid(p) or not p:Alive() or p:GetRoleName()~="SCP076" or p:GetActiveWeapon()~=w or CurTime()>state.expires then skill.Cancel(w) end
 end
end)

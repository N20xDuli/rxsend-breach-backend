local nu7=BREACH.Nu7
local cfg=nu7.SkillConfig
resource.AddFile("sound/rxsend/nu7/heavy_defense.wav")
resource.AddFile("sound/rxsend/nu7/marksman_scan.wav")
util.AddNetworkString("NU7TerminalOpen")
util.AddNetworkString("NU7TerminalRequest")
util.AddNetworkString("NU7TerminalResult")
util.AddNetworkString("NU7MarksmanTargetsV2")
util.AddNetworkString("NU7ScanTargets")
nu7.ActiveAnchors=nu7.ActiveAnchors or {}

function nu7.ClearHeavy(ply)
 if ply.Nu7HeavyBoost then
  -- Waiting-state observer transitions can bypass ApplyRoleStats. Restore only
  -- our retained speeds when another role has already installed different stats.
  local sameRole=nu7.GetMemberKey(ply)=="heavy"
  if sameRole or (ply.Nu7HeavyWalk and math.abs(ply:GetWalkSpeed()-ply.Nu7HeavyWalk)<.05) then
   ply:SetWalkSpeed(ply:GetWalkSpeed()/cfg.HeavySpeedScale)
  end
  if sameRole or (ply.Nu7HeavyRun and math.abs(ply:GetRunSpeed()-ply.Nu7HeavyRun)<.05) then
   ply:SetRunSpeed(ply:GetRunSpeed()/cfg.HeavySpeedScale)
  end
  ply.Nu7HeavyBoost=nil;ply.Nu7HeavyWalk=nil;ply.Nu7HeavyRun=nil
 end
 ply:SetNWFloat("Nu7HeavyUntil",0)
end

function nu7.ClearPlayerSkills(ply)
 if not IsValid(ply) then return end
 nu7.ClearHeavy(ply)
 ply:SetNWFloat("Nu7MarksmanUntil",0)
 ply:SetNWFloat("Nu7ScanReady",0);ply.Nu7IdentityCheck=nil
 if IsValid(ply.Nu7Anchor) then ply.Nu7Anchor:Remove() end
 ply.Nu7Anchor=nil
end

function nu7.IsAnchored(ply)
 if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() or ply:GTeam()~=TEAM_SCP then return false end
 for ent in pairs(nu7.ActiveAnchors) do
  if IsValid(ent) and ply:GetPos():DistToSqr(ent:GetPos())<=cfg.AnchorRadius^2 then return true end
 end
 return false
end

function nu7.ModifyDamage(target,damage)
 local attacker=damage:GetAttacker()
 if IsValid(attacker) and not attacker:IsPlayer() and IsValid(attacker:GetOwner()) then attacker=attacker:GetOwner() end
 if nu7.IsAnchored(attacker) then damage:ScaleDamage(cfg.AnchorOutgoing) end
 local inflictor=damage:GetInflictor()
 local anchorBurn=IsValid(inflictor) and inflictor:GetClass()=="ent_nu7_anchor"
 if not anchorBurn and attacker~=target and IsValid(attacker) and attacker:IsPlayer() and nu7.IsAnchored(target) then
  damage:ScaleDamage(cfg.AnchorIncoming)
 end
 if IsValid(target) and target:IsPlayer() and nu7.GetMemberKey(target)=="heavy"
  and target:GetNWFloat("Nu7HeavyUntil",0)>CurTime() then damage:ScaleDamage(cfg.HeavyDamageScale) end
end
hook.Add("EntityTakeDamage","NU7SkillDamage",nu7.ModifyDamage)

include(engine.ActiveGamemode() .. "/gamemode/modules/sv_nu7_anchor_placement.lua")

function nu7.ToggleAnchor(ply)
 if not nu7.CanUseEquipment(ply,"containment") then return false end
 if IsValid(ply.Nu7Anchor) then ply.Nu7Anchor:Remove();ply.Nu7Anchor=nil;return true end
 local pos,reason=nu7.FindAnchorPosition(ply)
 if not pos then return false,reason end
 local anchor=ents.Create("ent_nu7_anchor")
 if not IsValid(anchor) then return false,"稳定锚实体创建失败。" end
 anchor:SetPos(pos);anchor:SetAngles(Angle(0,ply:EyeAngles().y,0));anchor:SetOwner(ply);anchor:Spawn()
 ply.Nu7Anchor=anchor
 return true
end

function nu7.ActivateSkill(ply,key)
 if not nu7.CanUseEquipment(ply,key) or not nu7.Skills[key] then return false end
 if ply:GetSpecialCD()>CurTime() then return false end
 if key=="commander" then
  local gear=ply:GetWeapon("item_nu7_terminal")
  if not IsValid(gear) then gear=ply:Give("item_nu7_terminal") end
  if not IsValid(gear) then return false end
  ply:SelectWeapon("item_nu7_terminal")
  net.Start("NU7TerminalOpen");net.Send(ply)
 elseif key=="heavy" then
  nu7.ClearHeavy(ply)
  ply.Nu7HeavyBoost=true
  ply:SetWalkSpeed(ply:GetWalkSpeed()*cfg.HeavySpeedScale);ply:SetRunSpeed(ply:GetRunSpeed()*cfg.HeavySpeedScale)
  ply.Nu7HeavyWalk=ply:GetWalkSpeed();ply.Nu7HeavyRun=ply:GetRunSpeed()
  ply:SetNWFloat("Nu7HeavyUntil",CurTime()+cfg.HeavyDuration);ply:SetSpecialCD(CurTime()+cfg.HeavyCooldown)
  ply:EmitSound("rxsend/nu7/heavy_defense.wav",80,100,1,CHAN_VOICE)
 elseif key=="marksman" then
  if nu7.EnsureClientSkills then nu7.EnsureClientSkills(ply) end
  ply:SetNWFloat("Nu7MarksmanUntil",CurTime()+cfg.MarksmanDuration);ply:SetSpecialCD(CurTime()+cfg.MarksmanCooldown)
  ply:EmitSound("rxsend/nu7/marksman_scan.wav",80,100,1,CHAN_VOICE)
 elseif key=="containment" then
  local success,reason=nu7.ToggleAnchor(ply)
  if not success and reason then ply:RXSENDNotify(reason) end
  return success
 end
 return true
end

function nu7.TerminalTargets(ply,mode)
 local result={}
 if mode==2 then
  local trace=util.TraceLine({start=ply:EyePos(),endpos=ply:EyePos()+ply:GetAimVector()*160,filter=ply,mask=MASK_SHOT})
  local target=trace.Entity
  if IsValid(target) and target:IsPlayer() and target:Alive() and target:GTeam()~=TEAM_SPEC then result[1]=target end
 else
  for _,target in ipairs(player.GetAll()) do
   if target~=ply and target:Alive() and target:Health()>0 and not target:Outside() and not target:GetInDimension()
    and ((mode==0 and target:GTeam()==TEAM_SCP) or (mode==1 and nu7.IsUnknownUnit(target))) then result[#result+1]=target end
  end
  table.sort(result,function(a,b) return a:GetPos():DistToSqr(ply:GetPos())<b:GetPos():DistToSqr(ply:GetPos()) end)
 end
 return result
end

function nu7.RequestTerminal(ply,mode)
 if mode>2 or not nu7.CanUseEquipment(ply,"commander") or not ply:HasWeapon("item_nu7_terminal") then return end
 if (ply.Nu7TerminalNext or 0)>CurTime() then return end
 ply.Nu7TerminalNext=CurTime()+.5
 if mode==2 then
  local checker=weapons.GetStored("weapon_checker")
  if checker and checker.PrimaryAttack then
   ply.Nu7IdentityCheck=ply.Nu7IdentityCheck or {Owner=ply,AlreadyChecked={},Nu7Terminal=true}
   ply.Nu7IdentityCheck.Nu7Terminal=true
   checker.PrimaryAttack(ply.Nu7IdentityCheck)
  else ply:RXSENDNotify("身份查验模块未加载，请联系管理员。") end
  return
 end
 if ply:GetNWFloat("Nu7ScanReady",0)>CurTime() then
  ply:RXSENDNotify("扫描冷却中："..math.ceil(ply:GetNWFloat("Nu7ScanReady",0)-CurTime()).." 秒。")
  return
 end
 local targets=nu7.TerminalTargets(ply,mode)
 if #targets==0 then
  net.Start("NU7TerminalResult");net.WriteUInt(mode,2);net.WriteUInt(0,7);net.Send(ply)
  return
 end
 ply:SetNWFloat("Nu7ScanReady",CurTime()+cfg.ScanCooldown)
 nu7.ScanTargets=targets;nu7.ScanUntil=CurTime()+cfg.ScanDuration
 local recipients={}
 for _,member in ipairs(player.GetAll()) do
  if member:GTeam()==TEAM_NU7 and member:Alive() then recipients[#recipients+1]=member end
 end
 net.Start("NU7ScanTargets");net.WriteUInt(math.min(#targets,127),7)
 for i=1,math.min(#targets,127) do net.WriteUInt(targets[i]:EntIndex(),16) end
 net.WriteFloat(nu7.ScanUntil);net.Send(recipients)
 net.Start("NU7TerminalResult");net.WriteUInt(mode,2);net.WriteUInt(math.min(#targets,127),7)
 for i=1,math.min(#targets,127) do
  local target=targets[i]
  net.WriteEntity(target);net.WriteVector(target:GetPos())
  net.WriteString(mode==0 and target:GetRoleName() or "未知人员")
  net.WriteUInt(math.Clamp(math.ceil(target:Health()),0,65535),16)
 end
 net.Send(ply)
end
net.Receive("NU7TerminalRequest",function(_,ply) nu7.RequestTerminal(ply,net.ReadUInt(2)) end)

timer.Create("NU7SkillLifecycle",.25,0,function()
 for _,ply in ipairs(player.GetAll()) do
  local member=nu7.GetMemberKey(ply)
  if ply.Nu7HeavyBoost and (member~="heavy" or not ply:Alive() or ply:GetNWFloat("Nu7HeavyUntil",0)<=CurTime()) then nu7.ClearHeavy(ply) end
  local untilTime=ply:GetNWFloat("Nu7MarksmanUntil",0)
  if untilTime>0 then
   local targets={}
   if member=="marksman" and ply:Alive() and untilTime>CurTime() then
    for _,target in ipairs(player.GetAll()) do
     if ply:GetPos():DistToSqr(target:GetPos())<=cfg.MarksmanRadius^2 and nu7.IsArmedEnemy(ply,target) then targets[#targets+1]=target end
    end
   else ply:SetNWFloat("Nu7MarksmanUntil",0) end
   net.Start("NU7MarksmanTargetsV2");net.WriteUInt(math.min(#targets,127),7)
   for i=1,math.min(#targets,127) do net.WriteUInt(targets[i]:EntIndex(),16) end
   net.WriteFloat(ply:GetNWFloat("Nu7MarksmanUntil",0));net.Send(ply)
  end
  if IsValid(ply.Nu7Anchor) and (member~="containment" or not ply:Alive()) then ply.Nu7Anchor:Remove();ply.Nu7Anchor=nil end
 end
end)

hook.Add("PlayerDeath","NU7SkillDeath",nu7.ClearPlayerSkills)
hook.Add("PlayerDisconnected","NU7SkillLeave",nu7.ClearPlayerSkills)
function nu7.ResetSkills()
 for _,ply in ipairs(player.GetAll()) do nu7.ClearPlayerSkills(ply) end
 for ent in pairs(nu7.ActiveAnchors) do if IsValid(ent) then ent:Remove() end end
 nu7.ActiveAnchors={};nu7.ScanTargets={};nu7.ScanUntil=0
end

-- Transmit scanned players even when they are across the facility's PVS boundaries.
hook.Add("SetupPlayerVisibility","NU7ScanVisibility",function(ply)
 if ply:GTeam()~=TEAM_NU7 or not ply:Alive() or (nu7.ScanUntil or 0)<=CurTime() then return end
 for _,target in ipairs(nu7.ScanTargets or {}) do
  if IsValid(target) and target:Alive() then AddOriginToPVS(target:GetPos()) end
 end
end)

-- Enemy entities behind walls must be transmitted before the client can draw them.
hook.Add("SetupPlayerVisibility","NU7MarksmanVisibility",function(ply)
 if nu7.GetMemberKey(ply)~="marksman" or not ply:Alive()
  or ply:GetNWFloat("Nu7MarksmanUntil",0)<=CurTime() then return end
 for _,target in ipairs(player.GetAll()) do
  if ply:GetPos():DistToSqr(target:GetPos())<=cfg.MarksmanRadius^2 and nu7.IsArmedEnemy(ply,target) then
   AddOriginToPVS(target:GetPos())
  end
 end
end)

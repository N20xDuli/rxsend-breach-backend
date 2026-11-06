local nu7 = BREACH.Nu7
nu7.Skills = {
 commander = {"战术指挥终端", 0, "打开便携式终端，扫描设施内 SCP、未知人员，并查验真实阵营（4 秒，无冷却）。两种扫描共用 120 秒冷却，全队红色透视 10 秒。", "rxsend/nu7/skills/commander.png", false},
 containment = {"便携式斯克兰顿稳定锚", 0, "放置 / 收回稳定锚。7 米内 SCP 每秒失去最大生命的 5%，承伤 +60%、伤害 -60%。", "rxsend/nu7/skills/anchor.png", false},
 heavy = {"重装防御姿态", 90, "10 秒内全局减伤 50%，步行与奔跑速度提高 10%。", "rxsend/nu7/skills/heavy.png", false},
 marksman = {"战术目标捕获", 45, "10 秒内透视 20 米内的敌对武装人员。", "rxsend/nu7/skills/marksman.png", false},
}
nu7.SkillConfig = {HeavyDuration=10, HeavyCooldown=90, HeavyDamageScale=.5, HeavySpeedScale=1.1,
 MarksmanDuration=10, MarksmanCooldown=45, MarksmanRadius=20/.0254,
 ScanCooldown=120, ScanDuration=10, AnchorRadius=7/.0254, AnchorHealthFraction=.05, AnchorIncoming=1.6, AnchorOutgoing=.4}

function nu7.GetMemberKey(ply)
 if not IsValid(ply) or not ply:IsPlayer() or ply:GTeam() ~= TEAM_NU7 then return end
 local member=nu7.FindMember(ply:GetRoleName())
 return member and member.key
end

function nu7.CanUseEquipment(ply,key)
 return nu7.GetMemberKey(ply)==key and ply:Alive() and ply:Health()>0
  and not ply:IsFrozen() and not ply.ForceAnimSequence
end

function nu7.IsUnknownUnit(ply)
 if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() or ply:Health()<=0 then return false end
 local teamID=ply:GTeam()
 if teamID==TEAM_SPEC or teamID==TEAM_CLASSD or teamID==TEAM_SCP or teamID==TEAM_ARENA then return false end
 local name=ply:GetRoleName()
 if name==role.SECURITY_Spy or name==role.SCI_SpyUSA or name==role.SCI_SpyDZ or name==role.ClassD_GOCSpy then return true end
 if teamID==TEAM_GRU and GRU_Objectives and GRU_Objective==GRU_Objectives.MilitaryHelp then return false end
 return not nu7.IsFoundationTeam(teamID)
end

function nu7.IsArmedEnemy(observer,target)
 if not IsValid(target) or not target:IsPlayer() or not target:Alive() or target:Health()<=0 then return false end
 if target==observer or target:GTeam()==TEAM_SPEC or target:GTeam()==TEAM_SCP or target:GTeam()==TEAM_ARENA then return false end
 if (nu7.IsFoundationTeam(target:GTeam()) or IsTeamKill(target,observer)) and not nu7.IsUnknownUnit(target) then return false end
 for _,wep in ipairs(target:GetWeapons()) do
  if IsValid(wep) and wep.Primary and (tonumber(wep.Primary.ClipSize) or 0)>0
   and wep.Primary.Ammo and wep.Primary.Ammo~="none" then return true end
 end
 return false
end

function nu7.HandleSkillKey(ply)
 local key=nu7.GetMemberKey(ply)
 if not nu7.Skills[key] then return false end
 if SERVER then nu7.ActivateSkill(ply,key) end
 return true
end

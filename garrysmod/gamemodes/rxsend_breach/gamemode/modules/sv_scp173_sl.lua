local scp=BREACH.SCP173SL
local cfg=scp.Config
function scp.ObservedBy(owner,observer)
 if not scp.IsEnemy(observer) then return false end
 local eye=observer:EyePos()
 local center=owner:GetPos()+Vector(0,0,40)
 local halfFov=math.Clamp(observer:GetFOV()/2+5,30,85)
 if observer:GetAimVector():Dot((center-eye):GetNormalized())<math.cos(math.rad(halfFov)) then return false end
 for _,height in ipairs({16,40,66}) do
  local point=owner:GetPos()+Vector(0,0,height)
  local tr=util.TraceLine({start=eye,endpos=point,filter={observer,owner},mask=MASK_VISIBLE})
  if not tr.Hit then return true end
 end
 return false
end
function scp.UpdateObservers(weapon)
 local owner=weapon:GetOwner();if not scp.Is173(owner) then return end
 local count=0
 for _,ply in ipairs(player.GetHumans()) do if scp.ObservedBy(owner,ply) then count=count+1 end end
 -- Bots are valid observers for local tests and admin dummies too.
 for _,ply in ipairs(player.GetBots()) do if scp.ObservedBy(owner,ply) then count=count+1 end end
 local state=weapon.SLState
 if scp.ChangeObservers(state,count,CurTime()) then
  weapon:SetSLWatching(count);weapon:SetSLBlinkStop(state.stopTime);weapon:SetSLBlinkWindow(state.sustainEnd)
 end
end
function scp.Snap(weapon,target)
 local owner=weapon:GetOwner()
 if not scp.Is173(owner) or not scp.IsEnemy(target) or target:HasGodMode() or weapon:GetSLFast() then return false end
 local damage=DamageInfo();damage:SetDamage(math.max(target:Health()+target:Armor()+1,10000))
 damage:SetDamageType(DMG_SLASH);damage:SetAttacker(owner);damage:SetInflictor(weapon)
 target:SetLastHitGroup(HITGROUP_HEAD);target:TakeDamageInfo(damage)
 target:EmitSound("nextoren/scp/173/snap_"..math.random(1,3)..".ogg")
 return true
end
function scp.BlinkSnap(weapon)
 if weapon:GetSLFast() then return end
 local owner=weapon:GetOwner();local best,dist
 for _,target in ipairs(ents.FindInSphere(owner:GetPos()+Vector(0,0,36),cfg.KillRadius+44)) do
  if scp.IsEnemy(target) and not target:HasGodMode() then
   local delta=target:GetPos()-owner:GetPos()
   local d=delta.x^2+delta.y^2
   if math.abs(delta.z)<2.2*cfg.Meter and d<=cfg.KillRadius^2 and (not dist or d<dist) then
    local tr=util.TraceLine({start=owner:WorldSpaceCenter(),endpos=target:WorldSpaceCenter(),filter={owner,target},mask=MASK_SHOT})
    if not tr.Hit then best=target;dist=d end
   end
  end
 end
 if best then scp.Snap(weapon,best) end
end
function scp.ToggleFast(weapon)
 local now=CurTime()
 if weapon:GetSLFast() then
  if now-(weapon.SLFastStarted or now)<1 then return end
  weapon:SetSLFast(false);weapon:SetSLFastCooldown(now+cfg.FastCooldown);weapon.SLFastStop=nil
 elseif weapon:GetSLFastCooldown()<=now then
  weapon:SetSLFast(true);weapon.SLFastStarted=now;weapon.SLFastStop=nil
 end
end
function scp.Cleanup(ply)
 if not IsValid(ply) then return end
 ply:SetNWFloat("RX173StainedUntil",0)
 if ply:GetRoleName()=="SCP173" then
  ply:SetNoDraw(false);ply:SetNotSolid(false);ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
  ply:SetNWEntity("SCP173Statue",NULL)
 end
end
hook.Add("PlayerDeath","RX173SLCleanup",scp.Cleanup)
hook.Add("PlayerSpawn","RX173SLCleanup",scp.Cleanup)
hook.Add("PreCleanupMap","RX173SLHazards",function()
 for _,ent in ipairs(ents.FindByClass("rx_scp173_tantrum")) do ent:Remove() end
end)
hook.Add("KeyPress","RX173SLFastKey",function(ply,key)
 if key~=IN_SPEED or not scp.Is173(ply) then return end
 local weapon=ply:GetActiveWeapon()
 if IsValid(weapon) and weapon:GetClass()=="weapon_scp_173" then scp.ToggleFast(weapon) end
end)
hook.Add("PlayerButtonDown","RX173SLTantrumKey",function(ply,key)
 if key~=KEY_F or not scp.Is173(ply) then return end
 local weapon=ply:GetActiveWeapon()
 if IsValid(weapon) and weapon:GetClass()=="weapon_scp_173" then weapon:PlaceTantrum() end
end)
-- The old core forces every human to blink for three seconds, every three seconds.
-- Modern SL blink windows belong to 173 instead; leave the original core untouched.
local old=hook.GetTable().Think and hook.GetTable().Think.PlayerBlink_Think
if old and old~=scp.BlinkWrapper then scp.LegacyBlinkThink=old end
scp.BlinkWrapper=function()
 for _,ply in ipairs(player.GetAll()) do if scp.Is173(ply) then return end end
 if scp.LegacyBlinkThink then return scp.LegacyBlinkThink() end
end
hook.Add("Think","PlayerBlink_Think",scp.BlinkWrapper)
hook.Add("RegisterSCP","RX173SLRegister",function()
 if GetSCP("SCP173") then return end
 RegisterSCP("SCP173","models/cultist/scp/173.mdl",{"weapon_scp_173"},{
  base_health=cfg.Health,max_health=cfg.Health,base_speed=cfg.Speed,run_speed=cfg.Speed,max_speed=cfg.FastSpeed,
  damagemodifier=1,scaledamage={HITGROUP_HEAD=1,HITGROUP_CHEST=1,HITGROUP_STOMACH=1,HITGROUP_LEFTARM=1,
   HITGROUP_RIGHTARM=1,HITGROUP_LEFTLEG=1,HITGROUP_RIGHTLEG=1,HITGROUP_GEAR=1}
 },{},nil,function(ply)
  ply:SetNoDraw(false);ply:SetNotSolid(false);ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
  ply:SetNWEntity("SCP173Statue",ply);ply.canblink=false;ply:SetJumpPower(0)
  ply:RXSENDNotify("SCP-173：被注视时不能移动；右键选点后松开瞬移；Shift 疾速；F 放置排泄物。")
 end)
end)

-- Keep hitgroup multipliers at 1: apply this once for hitscan and physical bullets.
hook.Add("EntityTakeDamage","RX173SLBallisticResistance",function(target,damage)
 if not scp.Is173(target) then return end
 if damage:IsBulletDamage() or damage:IsDamageType(DMG_BUCKSHOT) or damage:IsExplosionDamage() then
  damage:ScaleDamage(cfg.BallisticDamageReceived)
 end
end)

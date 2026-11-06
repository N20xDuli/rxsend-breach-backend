local scp=BREACH.SCP106
local function valid(weapon,owner,life)
 return IsValid(weapon) and IsValid(owner) and owner:Alive() and scp.Is106(owner)
  and weapon:GetOwner()==owner and (owner.RX106Life or 0)==life
end
local function lock(weapon,enabled)
 weapon.RX106Transition=enabled
 for i=1,3 do weapon:ForbidAbility(i,enabled) end
end
local function animate(weapon,sequence,duration,finish)
 local owner=weapon:GetOwner();local life=owner.RX106Life or 0
 owner:Freeze(true)
 scp.PlayAnimation(owner,sequence,duration,nil,function()
  if valid(weapon,owner,life) then finish(owner) end
 end)
end
local function unlock(weapon,owner)
 if not IsValid(weapon) or not IsValid(owner) then return end
 owner:Freeze(false);lock(weapon,false)
end
local function notify(owner,text)
 if owner.RXSENDNotify then owner:RXSENDNotify(text) else owner:ChatPrint(text) end
end
function SWEP:Deploy()
 local owner=self:GetOwner()
 if not IsValid(owner) then return end
 self:SetGhostMode(false);self:SetInDimension(false);owner:SetInDimension(false)
 owner:SetNoDraw(false);owner:SetNotSolid(false);owner.Block_Use=nil
 lock(self,true)
 for i,ability in ipairs(self.AbilityIcons) do ability.CooldownTime=CurTime()+ability.Cooldown end
 animate(self,"0_106_new_spawn_1",4.25,function(ply) unlock(self,ply) end)
 return true
end
function SWEP:Reload()
 local owner=self:GetOwner();local ability=self.AbilityIcons[1]
 if not scp.Is106(owner) or self.RX106Transition or owner:GetInDimension() or ability.Forbidden or (ability.CooldownTime or 0)>CurTime() then return end
 local ghost=self:GetGhostMode()
 local materialize=ghost and scp.SafePosition(owner,owner:GetPos())
 if ghost and not materialize then notify(owner,"这里无法现身，请先离开障碍物。");return end
 ability.CooldownTime=CurTime()+ability.Cooldown
 lock(self,true)
 if ghost then
  owner:SetPos(materialize)
  self:SetGhostMode(false);owner:SetNoDraw(false);owner:SetNotSolid(false);owner.Block_Use=nil
  owner:SetWalkSpeed(scp.WalkSpeed);owner:SetRunSpeed(scp.WalkSpeed)
  animate(self,"0_106_new_spawn_1",4.25,function(ply) unlock(self,ply) end)
 else
  self:DrawTeleportDecal(owner)
  animate(self,"0_106_new_despawn_2",3,function(ply)
   self:SetGhostMode(true);ply:SetNoDraw(true);ply:SetNotSolid(true);ply.Block_Use=true
   ply:SetWalkSpeed(scp.GhostSpeed);ply:SetRunSpeed(scp.GhostSpeed);unlock(self,ply)
   self:ForbidAbility(2,true);self:ForbidAbility(3,true)
  end)
 end
end
function SWEP:OwnerTeleport(_,leave)
 local owner=self:GetOwner()
 if not scp.Is106(owner) or self:GetGhostMode() or self.RX106Transition then return false end
 if leave and not owner:GetInDimension() then return false end
 local alreadyInside=owner:GetInDimension()
 local destination
 if leave then destination=scp.SafePosition(owner,self.DimensionEnterPosition) else destination=scp.PickPocketPoint(owner,alreadyInside and owner:GetPos() or nil) end
 if not destination then notify(owner,"没有安全的空间传送点，本次传送已取消。");return false end
 if not leave and not alreadyInside then self.DimensionEnterPosition=owner:GetPos() end
 lock(self,true);self:DrawTeleportDecal(owner)
 animate(self,"0_106_new_despawn_1",2,function(ply)
  local safe=scp.SafePosition(ply,destination)
  if not safe then unlock(self,ply);notify(ply,"目标点被占用，传送已取消。");return end
  ply:SetPos(safe);ply:SetInDimension(not leave);self:SetInDimension(not leave)
  ply:SetNotSolid(not leave);self:DrawTeleportDecal(ply)
  if leave then self.DimensionEnterPosition=nil end
  animate(self,"0_106_new_spawn_1",4.25,function(ply) unlock(self,ply) end)
 end)
 return true
end
function CreateSearchSequence(ply,position,initial)
 local exitpos=scp.PickPocketPoint(ply,position)
 if not exitpos then scp.Escape(ply);return false end
 if IsValid(ply.Dimension_TouchEntity) then scp.StopSearch(ply) end
 ply.RX106Captured=true;ply.RX106ReturnPosition=initial
 local exit=ents.Create("rx_scp106_exit")
 if not IsValid(exit) then scp.Escape(ply);return false end
 exit:SetPos(exitpos);exit:SetOwner(ply);exit.RX106Life=ply.RX106Life or 0;exit:Spawn()
 ply.Dimension_TouchEntity=exit
 net.Start("DimensionSequence");net.WriteVector(exitpos);net.WriteBool(true);net.Send(ply)
 if ply.PlayMusic then ply:PlayMusic(BR_MUSIC_DIMENSION_SCP106) end
 return true
end
function CheckLabirintRandom(ply,away,_,initial)
 local point=scp.PickPocketPoint(ply,away)
 if away then return point end
 if not IsValid(ply) or not point then return false end
 ply:SetPos(point)
 if ply:GTeam()~=TEAM_SCP then return CreateSearchSequence(ply,point,initial) end
 return true
end
function SWEP:TeleportSequence(victim)
 if not IsValid(victim) or not victim:IsPlayer() or not victim:Alive() or victim:GTeam()==TEAM_SCP or victim:GTeam()==TEAM_SPEC
  or victim:GetInDimension() or victim.RX106CapturePending then return end
 local point=scp.PickPocketPoint(victim)
 if not point then victim.Teleported=nil;return end
 local initial=victim:GetPos();local life=victim.RX106Life or 0
 victim.RX106CapturePending=true
 victim:Freeze(true)
 victim:SetForcedAnimation("0_106_victum",1.25,nil,function()
  if not IsValid(victim) or not victim:Alive() or (victim.RX106Life or 0)~=life then return end
  victim.RX106CapturePending=nil;victim.Teleported=nil
  if victim:GTeam()==TEAM_SCP or victim:GTeam()==TEAM_SPEC then victim:Freeze(false);return end
  local safe=scp.SafePosition(victim,point)
  if not safe then victim:Freeze(false);return end
  victim:SetInDimension(true);victim.RX106ReturnPosition=initial;victim.RX106Captured=true
  victim:SetMoveType(MOVETYPE_WALK);victim:SetPos(safe);victim:Freeze(false)
  CreateSearchSequence(victim,safe,initial)
 end)
end
function SWEP:DistantAttack()
 local owner=self:GetOwner();local life=owner.RX106Life or 0
 if self:GetGhostMode() or owner:GetInDimension() or self.RX106Transition then return false end
 lock(self,true)
  animate(self,"0_106_new_range_attack",3.8,function(ply) unlock(self,ply) end)
 for step=1,24 do
  timer.Simple(1.3+step*0.1,function()
   if not valid(self,owner,life) then return end
   local start=owner:GetShootPos()+owner:GetForward()*(48*step)
   local wall=util.TraceLine({start=owner:GetShootPos(),endpos=start,filter=owner,mask=MASK_SHOT})
   if wall.Hit then return end
   local floor=util.TraceLine({start=start,endpos=start-Vector(0,0,1000),filter=owner,mask=MASK_SHOT})
   if not floor.Hit then return end
   local effect=EffectData();effect:SetOrigin(floor.HitPos+floor.HitNormal)
   util.Effect("scp106_shadowattack",effect,true,true)
   for _,target in ipairs(ents.FindInSphere(floor.HitPos+Vector(0,0,32),60)) do self:TeleportSequence(target) end
  end)
 end
 return true
end
function SWEP:PrimaryAttack()
 if self.RX106Transition or self:GetGhostMode() then return end
 self:SetNextPrimaryFire(CurTime()+1)
 local owner=self:GetOwner()
 if not scp.Is106(owner) then return end
 local tr=util.TraceHull({start=owner:GetShootPos(),endpos=owner:GetShootPos()+owner:GetAimVector()*90,filter=owner,mins=Vector(-12,-4,-32),maxs=Vector(12,4,32),mask=MASK_SHOT})
 local target=tr.Entity
 if not IsValid(target) or not target:IsPlayer() or not target:Alive() or target:GTeam()==TEAM_SCP or target:GTeam()==TEAM_SPEC then return end
 if owner:GetInDimension() then
  if not target:GetInDimension() then return end
  owner:SetHealth(math.min(owner:Health()+target:Health(),owner:GetMaxHealth()))
  target:Kill();owner:AddToStatistics("SCP-106 Dimension kill",150)
 else self:TeleportSequence(target) end
end
function SWEP:OnRemove()
 local owner=self:GetOwner()
 if not IsValid(owner) then return end
 if scp.Is106(owner) then
  if owner:GetInDimension() then
   local safe=scp.SafePosition(owner,self.DimensionEnterPosition)
   if safe then owner:SetPos(safe) end
  end
  owner:SetInDimension(false);owner:SetNoDraw(false);owner:SetNotSolid(false);owner:Freeze(false);owner.Block_Use=nil
  owner:SetWalkSpeed(scp.WalkSpeed);owner:SetRunSpeed(scp.WalkSpeed)
 end
end

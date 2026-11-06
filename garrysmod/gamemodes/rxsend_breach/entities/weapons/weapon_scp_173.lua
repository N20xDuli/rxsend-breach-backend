if SERVER then AddCSLuaFile() end
if not (BREACH and BREACH.SCP173SL) then include(engine.ActiveGamemode() .. "/gamemode/modules/sh_scp173_sl.lua") end
SWEP.Base="breach_scp_base"
SWEP.PrintName="SCP-173"
SWEP.HoldType="normal"
SWEP.Spawnable=false
SWEP.droppable=false
SWEP.ViewModel=""
SWEP.WorldModel=""
SWEP.DrawAmmo=false
SWEP.DrawCrosshair=false
SWEP.Primary={Automatic=false,Ammo="none",ClipSize=-1,DefaultClip=-1}
SWEP.Secondary={Automatic=false,Ammo="none",ClipSize=-1,DefaultClip=-1}
SWEP.AbilityIcons={
 {Name="眨眼瞬移",Description="右键选点，松开瞬移；被注视时每 3 秒可使用一次。",Cooldown=3,CooldownTime=0,KEY="RMB",Icon="nextoren/gui/special_abilities/scp173_eye.png"},
 {Name="疾速模式",Description="Shift 切换；移动更快，眨眼冷却减半，期间无法扭脖子。",Cooldown=40,CooldownTime=0,KEY=KEY_LSHIFT,Icon="nextoren/gui/special_abilities/scp173_invisibility.png"},
 {Name="排泄物",Description="F 放置；人类经过时减速且不能奔跑。",Cooldown=30,CooldownTime=0,KEY=KEY_F,Icon="nextoren/gui/special_abilities/scp173_stun.png"}}
local scp=BREACH.SCP173SL
local cfg=scp.Config
function SWEP:SetupDataTables()
 self:NetworkVar("Int",0,"SLWatching")
 self:NetworkVar("Bool",0,"SLFast")
 self:NetworkVar("Float",0,"SLBlinkStop")
 self:NetworkVar("Float",1,"SLBlinkWindow")
 self:NetworkVar("Float",2,"SLFastCooldown")
 self:NetworkVar("Float",3,"SLTantrumCooldown")
end
function SWEP:Initialize()
 self:SetHoldType("normal")
 self.AbilityIcons=table.Copy(self.AbilityIcons)
 self.HotKeyTable={MOUSE_RIGHT,KEY_LSHIFT,KEY_F}
 local owner=self:GetOwner();if IsValid(owner) then owner.EquipTime=RealTime() end
end
function SWEP:Deploy()
 if SERVER then
  local owner=self:GetOwner();if not IsValid(owner) then return false end
  if IsValid(self.StatueEntity) then self.StatueEntity:Remove() end
  self.StatueEntity=nil
  owner:SetNoDraw(false);owner:SetNotSolid(false);owner:SetCollisionGroup(COLLISION_GROUP_PLAYER)
  owner:DrawViewModel(false);owner:SetNWEntity("SCP173Statue",owner)
  owner:SetWalkSpeed(cfg.Speed);owner:SetRunSpeed(cfg.Speed);owner:SetJumpPower(0)
  self.SLState={observers=0,stopTime=0,cooldown=cfg.BlinkCooldown,sustainEnd=0}
  self:SetSLWatching(0);self:SetSLFast(false);self:SetSLBlinkStop(0);self:SetSLBlinkWindow(0)
  self:SetSLFastCooldown(CurTime()+cfg.FastCooldown);self:SetSLTantrumCooldown(0)
 end
 return true
end
function SWEP:DrawWorldModel() end
function SWEP:ShouldDrawViewModel() return false end
function SWEP:SecondaryAttack()
 self:SetNextSecondaryFire(CurTime()+.1)
 self.SLAiming=true
end
function SWEP:Reload() end
function SWEP:ReadyToBlink()
 local state={observers=self:GetSLWatching(),stopTime=self:GetSLBlinkStop(),cooldown=cfg.BlinkCooldown,sustainEnd=self:GetSLBlinkWindow()}
 return scp.BlinkReady(state,CurTime(),self:GetSLFast())
end
function SWEP:Think()
 local owner=self:GetOwner();if not scp.Is173(owner) then return end
 if SERVER then
  if not self.SLState then self:Deploy() end
  if (self.SLNextObservers or 0)<=CurTime() then
   scp.UpdateObservers(self);self.SLNextObservers=CurTime()+.05
  end
  if self:GetSLFast() then
   if self:GetSLWatching()>0 and not self.SLFastStop then self.SLFastStop=CurTime()+cfg.FastStareLimit end
   if self.SLFastStop and self.SLFastStop<=CurTime() then scp.ToggleFast(self) end
  end
  local speed=self:GetSLFast() and cfg.FastSpeed or cfg.Speed
  if owner:GetWalkSpeed()~=speed then owner:SetWalkSpeed(speed);owner:SetRunSpeed(speed) end
 end
 if self.SLAiming and not owner:KeyDown(IN_ATTACK2) then
  self.SLAiming=false
  if SERVER then self:TryBlink() end
 end
 self.AbilityIcons[1].CooldownTime=self:GetSLBlinkStop()+cfg.BlinkCooldown*(self:GetSLFast() and .5 or 1)
 self.AbilityIcons[2].CooldownTime=self:GetSLFastCooldown()
 self.AbilityIcons[3].CooldownTime=self:GetSLTantrumCooldown()
end
if SERVER then
 function SWEP:TryBlink()
  if not scp.Is173(self:GetOwner()) then return false end
  scp.UpdateObservers(self)
  if not self:ReadyToBlink() then return false end
  local owner=self:GetOwner()
  local point=scp.BlinkPosition(owner,cfg.BlinkDistance*(self:GetSLFast() and 1.8 or 1))
  if not point then return false end
  owner:SetPos(point);owner:SetLocalVelocity(vector_origin)
  self.SLState.stopTime=CurTime();self:SetSLBlinkStop(CurTime())
  scp.UpdateObservers(self)
  owner:EmitSound("nextoren/scp/173/rattle_"..math.random(1,3)..".ogg")
  scp.BlinkSnap(self);return true
 end
 function SWEP:PrimaryAttack()
  self:SetNextPrimaryFire(CurTime()+.3)
  if not scp.Is173(self:GetOwner()) or self:GetSLFast() then return end
  scp.UpdateObservers(self);if self:GetSLWatching()>0 then return end
  local owner=self:GetOwner()
  owner:LagCompensation(true)
  local tr=util.TraceHull({start=owner:GetShootPos(),endpos=owner:GetShootPos()+owner:GetAimVector()*cfg.SnapDistance,
   mins=Vector(-4,-4,-4),maxs=Vector(4,4,4),filter=owner,mask=MASK_SHOT})
  owner:LagCompensation(false)
  if scp.IsEnemy(tr.Entity) then scp.Snap(self,tr.Entity) end
 end
 function SWEP:PlaceTantrum()
  if not scp.Is173(self:GetOwner()) or self:GetSLTantrumCooldown()>CurTime() then return false end
  scp.UpdateObservers(self)
  if self:GetSLWatching()>0 or self:GetSLBlinkWindow()==-1 or self:GetSLBlinkWindow()>CurTime() then return false end
  local owner=self:GetOwner()
  local floor=util.TraceLine({start=owner:GetPos()+Vector(0,0,8),endpos=owner:GetPos()-Vector(0,0,3*cfg.Meter),filter=owner,mask=MASK_PLAYERSOLID})
  if not floor.Hit or floor.HitNormal.z<.5 then return false end
  local hazard=ents.Create("rx_scp173_tantrum");if not IsValid(hazard) then return false end
  hazard:SetPos(floor.HitPos+Vector(0,0,2));hazard:SetOwner(owner);hazard:Spawn()
  self:SetSLTantrumCooldown(CurTime()+cfg.TantrumCooldown);return true
 end
 function SWEP:Holster()
  if IsValid(self.StatueEntity) then self.StatueEntity:Remove() end
  scp.Cleanup(self:GetOwner());return true
 end
 function SWEP:OnRemove() self:Holster() end
else
 function SWEP:PrimaryAttack() self:SetNextPrimaryFire(CurTime()+.3) end
 function SWEP:Holster() self.SLAiming=false;return true end
end

AddCSLuaFile()
ENT.Type="anim"
ENT.Base="base_gmodentity"
ENT.PrintName="便携式斯克兰顿稳定锚"
ENT.Spawnable=false

if SERVER then
 function ENT:Initialize()
  self:SetModel("models/rxsend/nu7/sra_portable_h_v2.mdl")
  self:SetMoveType(MOVETYPE_NONE);self:SetSolid(SOLID_BBOX);self:SetCollisionBounds(Vector(-16,-16,0),Vector(16,16,38))
  self:SetUseType(SIMPLE_USE)
  BREACH.Nu7.ActiveAnchors[self]=true
  self.NextBurn=CurTime()+1
 end
 function ENT:Think()
  local owner=self:GetOwner()
  if not IsValid(owner) or not owner:Alive() or BREACH.Nu7.GetMemberKey(owner)~="containment" then self:Remove();return end
  if self.NextBurn<=CurTime() then
   self.NextBurn=CurTime()+1
   for _,target in ipairs(ents.FindInSphere(self:GetPos(),BREACH.Nu7.SkillConfig.AnchorRadius)) do
    if IsValid(target) and target:IsPlayer() and target:Alive() and target:GTeam()==TEAM_SCP
     and target:GetPos():DistToSqr(self:GetPos())<=BREACH.Nu7.SkillConfig.AnchorRadius^2
     and (target.Nu7AnchorLastBurn or 0)<=CurTime()-1 then
     target.Nu7AnchorLastBurn=CurTime()
     local damage=DamageInfo();damage:SetDamage(target:GetMaxHealth()*BREACH.Nu7.SkillConfig.AnchorHealthFraction)
     damage:SetDamageType(DMG_GENERIC);damage:SetAttacker(owner);damage:SetInflictor(self);target:TakeDamageInfo(damage)
    end
   end
  end
  self:NextThink(CurTime()+.1);return true
 end
 function ENT:Use(ply)
  if ply==self:GetOwner() and ply:GetPos():DistToSqr(self:GetPos())<=128^2 then self:Remove() end
 end
 function ENT:OnRemove()
  BREACH.Nu7.ActiveAnchors[self]=nil
  local owner=self:GetOwner();if IsValid(owner) and owner.Nu7Anchor==self then owner.Nu7Anchor=nil end
 end
else
 local glow=Material("sprites/light_glow02_add")
 function ENT:Draw()
  self:DrawModel()
  local pos=self:GetPos()+Vector(0,0,24)
  local light=DynamicLight(self:EntIndex())
  if light then light.pos=pos;light.r=255;light.g=20;light.b=12;light.brightness=3;light.size=BREACH.Nu7.SkillConfig.AnchorRadius;light.decay=0;light.dietime=CurTime()+.2 end
  render.SetMaterial(glow);render.DrawSprite(pos,42,42,Color(255,32,20,230))
  -- The translucent field and boundary use the same radius as server effects.
  local radius=BREACH.Nu7.SkillConfig.AnchorRadius
  render.SetColorMaterial()
  render.DrawSphere(self:GetPos(),radius,32,16,Color(255,28,18,12))
  render.DrawSphere(self:GetPos(),-radius,32,16,Color(255,28,18,12))
  local center=self:GetPos()+Vector(0,0,3)
  for i=0,63 do
   local a,b=i*math.pi/32,(i+1)*math.pi/32
   local first=center+Vector(math.cos(a)*radius,math.sin(a)*radius,0)
   local last=center+Vector(math.cos(b)*radius,math.sin(b)*radius,0)
   render.DrawBeam(first,last,3,0,1,Color(255,45,30,210))
  end
  if EyePos():DistToSqr(pos)>650^2 then return end
  local ang=Angle(0,EyeAngles().y-90,90)
  cam.Start3D2D(pos+Vector(0,0,20),ang,.045)
   draw.SimpleText("斯克兰顿锚 / 7 米","DermaDefaultBold",0,0,Color(255,93,83),TEXT_ALIGN_CENTER)
   if LocalPlayer()==self:GetOwner() then draw.SimpleText("[E] 收回","DermaDefault",0,18,color_white,TEXT_ALIGN_CENTER) end
  cam.End3D2D()
 end
end

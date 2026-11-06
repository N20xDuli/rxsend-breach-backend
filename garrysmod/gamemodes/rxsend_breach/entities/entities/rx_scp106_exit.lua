AddCSLuaFile()
ENT.Type="anim"
ENT.Base="base_anim"
ENT.PrintName="SCP-106 口袋空间出口"
ENT.Spawnable=false
if SERVER then
 function ENT:Initialize()
  self:SetModel("models/props_lab/keypad.mdl");self:SetNoDraw(true);self:SetSolid(SOLID_NONE)
 end
 function ENT:Think()
  local owner=self:GetOwner()
  if not IsValid(owner) or not owner:Alive() or not owner:GetInDimension() or not owner.RX106Captured
   or (owner.RX106Life or 0)~=self.RX106Life then self:Remove();return end
  if owner:GetPos():DistToSqr(self:GetPos())<=80*80 then BREACH.SCP106.Escape(owner) end
  self:NextThink(CurTime()+0.2);return true
 end
end

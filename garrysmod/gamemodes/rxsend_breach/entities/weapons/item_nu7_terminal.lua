AddCSLuaFile()
SWEP.PrintName="落锤便携式战术终端"
SWEP.Spawnable=false
SWEP.Base="weapon_base"
SWEP.Slot=1
SWEP.ViewModel="models/weapons/c_arms.mdl"
SWEP.WorldModel="models/props_lab/clipboard.mdl"
SWEP.DrawViewModel=false
SWEP.DrawAmmo=false
SWEP.DrawCrosshair=false
SWEP.UseHands=false
SWEP.droppable=false
SWEP.Equipableitem=true
SWEP.HoldType="slam"
SWEP.Primary={ClipSize=-1,DefaultClip=-1,Automatic=false,Ammo="none"}
SWEP.Secondary={ClipSize=-1,DefaultClip=-1,Automatic=false,Ammo="none"}
function SWEP:Initialize() self:SetHoldType(self.HoldType) end
function SWEP:Deploy()
 if SERVER and BREACH.Nu7.CanUseEquipment(self:GetOwner(),"commander") then net.Start("NU7TerminalOpen");net.Send(self:GetOwner()) end
 return true
end
function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end
if CLIENT then
 function SWEP:PreDrawViewModel() return true end
 SWEP.InvIcon=Material("rxsend/nu7/skills/commander.png")
 function SWEP:DrawWorldModel()
  local owner=self:GetOwner()
  if not IsValid(owner) then self:DrawModel();return end
  local bone=owner:LookupBone("ValveBiped.Bip01_R_Hand");if not bone then return end
  local pos,ang=owner:GetBonePosition(bone);if not pos or not ang then return end
  ang:RotateAroundAxis(ang:Forward(),90)
  self:SetRenderOrigin(pos);self:SetRenderAngles(ang);self:DrawModel();self:SetRenderOrigin();self:SetRenderAngles()
 end
end

AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Nu-7 支援呼叫面板"
ENT.Spawnable = false

function ENT:Initialize()
 if not SERVER then return end
 self:SetModel("models/props_lab/monitor01b.mdl")
 self:SetMoveType(MOVETYPE_NONE)
 self:SetSolid(SOLID_NONE)
 self:SetUseType(SIMPLE_USE)
 self:SetSolidFlags(bit.bor(FSOLID_TRIGGER, FSOLID_USE_TRIGGER_BOUNDS))
 self:SetTrigger(true)
 self:UseTriggerBounds(true, 24)
end

if SERVER then
 function ENT:Use(ply)
  if not IsValid(ply) or not ply:IsPlayer() or ply:GetPos():DistToSqr(self:GetPos()) > 150 * 150 then return end
  if (ply.Nu7PanelNextUse or 0) > CurTime() then return end
  ply.Nu7PanelNextUse = CurTime() + 1
  ply:RXSENDNotify("请使用广播室调度员专属面板呼叫落锤。")
 end
else
 function ENT:Draw()
  self:DrawModel()
  if EyePos():DistToSqr(self:GetPos()) > 500 * 500 then return end
  local angle = self:GetAngles()
  angle:RotateAroundAxis(angle:Right(), 90)
  angle:RotateAroundAxis(angle:Up(), 90)
  cam.Start3D2D(self:GetPos() + self:GetUp() * 18, angle, 0.06)
   draw.RoundedBox(8, -240, -56, 480, 112, Color(9, 17, 28, 245))
   draw.SimpleText("MTF NU-7 · 落锤支援", "DermaLarge", 0, -36, Color(139, 190, 255), TEXT_ALIGN_CENTER)
   draw.SimpleText("请使用广播室调度员专属面板", "DermaDefaultBold", 0, 12, color_white, TEXT_ALIGN_CENTER)
  cam.End3D2D()
 end
end

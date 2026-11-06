include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    if LocalPlayer():GetRoleName() == role.MTF_O5 and !LocalPlayer():HasWeapon("breach_keycard_7") then
        outline.Add(self,Color(255,255,255),2)
    end
end

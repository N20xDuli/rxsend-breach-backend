include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    --if LocalPlayer():GetRoleName() == role.MTF_O5 and !LocalPlayer():HasWeapon("breach_keycard_7") then
    self:SetSubMaterial(0,"models/imperator/female/no_draw")
    if LocalPlayer():GTeam() == TEAM_GRU and !GetGlobalBool("Evacuation") then return end
    if LocalPlayer():GetPos():Distance(self:GetPos()) < 400 and LocalPlayer():GTeam() != TEAM_SPEC then
    outline.Add(self,Color(255,255,255),2)
    end
    --end
end

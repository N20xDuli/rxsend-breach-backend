include('shared.lua')

ENT.AutomaticFrameAdvance = true
--[[
function ENT:Think()

	self:NextThink( CurTime() )
	return true
end]]

function ENT:Draw()
	self:DrawModel()
	--self:SetSubMaterial(3,"models/ogrx/props/gru_heli/mi8_body2_no")
	self:SetSubMaterial(3,"models/imperator/female/no_draw")
	--self:SetSubMaterial(6,"models/imperator/female/no_draw")
	--self:SetSubMaterial(7,"models/imperator/female/no_draw")
	--self:SetSubMaterial(8,"models/imperator/female/no_draw")
	--self:SetSubMaterial(9,"models/imperator/female/no_draw")
	--self:SetSubMaterial(10,"models/imperator/female/no_draw")
	--self:SetSubMaterial(11,"models/imperator/female/no_draw")
	--self:SetSubMaterial(12,"models/imperator/female/no_draw")
--self:SetSubMaterial(13,"models/imperator/female/no_draw")
	--self:SetSubMaterial(14,"models/imperator/female/no_draw")
	--self:SetSubMaterial(15,"models/imperator/female/no_draw")
	--self:SetSubMaterial(16,"models/imperator/female/no_draw")
end

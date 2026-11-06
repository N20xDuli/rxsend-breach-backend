AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/hunter/blocks/cube2x2x2.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType( SIMPLE_USE )
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
    end
    self.HaveCard = true
end

function ENT:Think()
	if ( SERVER ) then
		self:NextThink( CurTime() )
        return true
	end
end

function ENT:Use(a,c)
    --if a:GetRoleName() == role.MTF_O5 and self.HaveCard then
    --    a:BreachGive("breach_keycard_7")
    --    a:RXSENDNotify("l:o5_taker_can")
    --    self.HaveCard = false
    --else
        --a:RXSENDNotify("l:o5_taker_non")
    --end
end


AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/scp_documents/secret_document.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType( SIMPLE_USE )
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
    end
end
function ENT:Think()
	if ( SERVER ) then
		self:NextThink( CurTime() )
        return true
	end
end
function ENT:Use(a,c)
    if a:GTeam() == TEAM_GRU then
        SetGlobalInt("TASKS_GRU_1",GetGlobalInt("TASKS_GRU_1") + 1)
        self:Remove()
    end
end


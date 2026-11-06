AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

util.AddNetworkString("OpenSCPDocument")
util.AddNetworkString("CloseSCPDocument")

function ENT:Initialize()
    self:SetModel("models/ryanm2711/scp_documents/scp_document.mdl")
    
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    self:SetUseType(SIMPLE_USE) -- Use hook will only be called once each time

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
    end
end

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "DocumentMaterial", {
        KeyName = "documentmaterial",
        Edit = {
            type = "Combo",
            order = 1,
            text = "Select...",
            values = GetDocumentMaterialNames()
        }
    })

    self:SetDocumentMaterial("orientation_document.png")
end

function ENT:Use(activator, caller)
    activator:SetNWBool("opened_scp_document", true)
    activator:Freeze(true)

    net.Start("OpenSCPDocument")
        net.WriteEntity(self)
        net.WriteString(self:GetDocumentMaterial())
    net.Send(activator)
end

net.Receive("CloseSCPDocument", function(len, ply)
    ply:Freeze(false)
    ply:SetNWBool("opened_scp_document", false)
end)
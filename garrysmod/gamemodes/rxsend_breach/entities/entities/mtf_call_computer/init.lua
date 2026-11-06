AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("Cogitator_StartMinigame")
util.AddNetworkString("Cogitator_EndMinigame")
util.AddNetworkString("Cogitator_UpdateSettings")

function ENT:Initialize()
    self:SetModel("models/dizcordum/wh/props3/wk_cogitator_three_comp.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    self.InUseBy = nil 
    
    self.IsCompleted = false  
    self.IsLockedOut = false  
    
    self:SetCogText("01001011 01110101 01100010\n00100000 01110111 01100001\n01110011 00100000 01101000\n01100101 01110010 01100101")
    self:SetCogTime(40)
    self:SetCogErrors(5)
    self:SetIsSuccess(false)
    self:SetShowStatusText(true)
    self:SetLockOnSuccess(true)
    self:SetLockOnFail(false)

    local phys = self:GetPhysicsObject()
    if (IsValid(phys)) then phys:Wake() end
end

function ENT:Use(activator, caller)
    if not activator:IsPlayer() then return end
    
    if self.IsLockedOut then
        self:EmitSound("buttons/combine_button_locked.wav")
        return
    end

    if self.IsCompleted and self:GetLockOnSuccess() then
        self:EmitSound("buttons/combine_button7.wav")
        return
    end

    if IsValid(self.InUseBy) and self.InUseBy ~= activator then
        self:EmitSound("buttons/button2.wav")
        return
    end

    if activator:GetNWBool("Cogitator_IsTyping", false) then return end

    if not self.IsCompleted then
        self:SetIsSuccess(false)
    end

    self.InUseBy = activator
    activator:SetNWBool("Cogitator_IsTyping", true)
    
    net.Start("Cogitator_StartMinigame")
        net.WriteEntity(self)
    net.Send(activator)
end

function ENT:Think()
    if IsValid(self.InUseBy) then
        local dist = self:GetPos():DistToSqr(self.InUseBy:GetPos())
        if dist > (150 * 150) or not self.InUseBy:Alive() then
            net.Start("Cogitator_EndMinigame")
                net.WriteEntity(self)
                net.WriteBool(false) 
                net.WriteBool(true)  
            net.Send(self.InUseBy)
            
            self.InUseBy:SetNWBool("Cogitator_IsTyping", false)
            self.InUseBy = nil
        end
    end
    self:NextThink(CurTime() + 0.5)
    return true
end

net.Receive("Cogitator_EndMinigame", function(len, ply)
    local ent = net.ReadEntity()
    local success = net.ReadBool()
    local isForced = net.ReadBool()
    
    ply:SetNWBool("Cogitator_IsTyping", false)
    
    if IsValid(ent) and ent.InUseBy == ply then
        ent.InUseBy = nil
        
        if success then
            ent:SetIsSuccess(true)
            ent:EmitSound("buttons/bell1.wav")
            
            if ent:GetLockOnSuccess() then
                ent.IsCompleted = true
            else
                timer.Simple(3, function()
                    if IsValid(ent) then ent:SetIsSuccess(false) end
                end)
            end
        else
            ent:SetIsSuccess(false)
            
            if ent:GetLockOnFail() then
                ent.IsLockedOut = true
                ent:EmitSound("buttons/combine_button_locked.wav")
            end
        end
    end
    
    if isForced then return end

    if success then
        -- Воткните сюда логику, если хотите. Снятие безумия там, я хз
    else
        -- Воткните сюда логику, если хотите. Накидывание безумия там, я хз
    end
end)

net.Receive("Cogitator_UpdateSettings", function(len, ply)
    if not ply:IsSuperAdmin() and not ply:IsAdmin() then return end
    
    local ent = net.ReadEntity()
    local newText = net.ReadString()
    local newTime = net.ReadInt(16)
    local newErrors = net.ReadInt(8)
    
    local showText = net.ReadBool()
    local lockSuccess = net.ReadBool()
    local lockFail = net.ReadBool()
    
    if IsValid(ent) then
        ent:SetCogText(newText)
        ent:SetCogTime(newTime)
        ent:SetCogErrors(newErrors)
        
        ent:SetShowStatusText(showText)
        ent:SetLockOnSuccess(lockSuccess)
        ent:SetLockOnFail(lockFail)
        
        ent.IsCompleted = false
        ent.IsLockedOut = false
        ent:SetIsSuccess(false)
        
        ent:EmitSound("buttons/combine_button1.wav")
    end
end)
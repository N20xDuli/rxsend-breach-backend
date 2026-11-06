AddCSLuaFile()
SWEP.Base = "weapon_fbi_knife"
SWEP.PrintName = "蛇之手 M9 刺刀"
SWEP.Category = "RXSEND"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Primary = {Ammo = "none"}
SWEP.Secondary = {Ammo = "none"}
SWEP.ViewModel = "models/weapons/v_csgo_m9.mdl"
SWEP.WorldModel = "models/weapons/w_csgo_m9.mdl"
SWEP.ViewModelFOV = 65
SWEP.ViewModelFlip = false
SWEP.HoldType = "knife"
SWEP.UseHands = true
SWEP.UnDroppable = true
SWEP.droppable = false
SWEP.InvIcon = Material("nextoren/gui/icons/weapons/fbi_knife.png")

-- Keep the Breach knife's combat rules; resolve animation names on the M9 viewmodel.
-- The world model only has idle, so numeric IDs looked up there are not valid VM IDs.
function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    self:SetSkin(0)
    self.DrawSequence_ID = "draw"
    self.DrawSequence_Length = 1
    self.Primary_AttacksSequence = {"light_miss1", "light_miss2"}
    self.Primary_AttacksHitSequence = {"light_hit1", "light_hit2"}
    self.IdleAnimation = {"idle1", "idle2"}
    self.Secondary_AttackHitSequence = "heavy_hit1"
    self.Secondary_AttackSequence = "heavy_miss1"
    self.IdleDelay = CurTime() + 1
end

function SWEP:Deploy()
    local owner = self:GetOwner()
    if not IsValid(owner) then return false end
    local vm = owner:GetViewModel()
    if IsValid(vm) then
        vm:SetSkin(0)
        local seq = vm:LookupSequence("draw")
        if seq and seq >= 0 then self.DrawSequence_Length = vm:SequenceDuration(seq) end
    end
    self.IdleDelay = CurTime() + math.max(0.1, self.DrawSequence_Length - .65)
    self:PlaySequence("draw")
    return true
end

if CLIENT then
    function SWEP:PreDrawViewModel(vm)
        if IsValid(vm) then vm:SetSkin(0) end
    end

    -- This workshop world model is already authored for Source weapon attachment.
    function SWEP:DrawWorldModel()
        self:SetSkin(0)
        self:DrawModel()
    end
end

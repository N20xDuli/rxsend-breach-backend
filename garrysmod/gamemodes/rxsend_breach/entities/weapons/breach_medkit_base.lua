
SWEP.InvIcon = Material( "nextoren/gui/icons/med_1.png" )
SWEP.ProgressIcon = "nextoren/gui/icons/med_1.png"

SWEP.PrintName = "医疗包基类"

SWEP.ViewModel    = "models/cultist/items/medkit/v_medkit.mdl"
SWEP.WorldModel   = "models/cultist/items/medkit/w_medkit.mdl"

SWEP.Pos = Vector( -6, -1, -2 )
SWEP.Ang = Angle( -90, -50, 180 )

SWEP.HoldType   = "heal"
SWEP.UseHands = true

SWEP.Healing = false

SWEP.Skin = 0

SWEP.PercentHeal = .5 -- 50%

SWEP.Heal_Left = 3

function SWEP:Initialize()

  self:SetHoldType( self.HoldType )

  self:SetSkin( 0 )

end

function SWEP:Deploy()

  self.HolsterDelay = nil
  self.IdleDelay = CurTime() + 1
  self:PlaySequence( "deploy" )

  timer.Simple( .1, function()

    if ( self && self:IsValid() ) then

      self:EmitSound( "weapons/m249/handling/m249_armmovement_02.wav", 75, math.random( 100, 120 ), 1, CHAN_WEAPON )

    end

  end )

end

local function canHealPlayer(ply)
  return IsValid(ply) and ply:IsPlayer() and ply:Alive() and ply:Health() > 0
    and ply:GTeam() != TEAM_SPEC and ply:GTeam() != TEAM_SCP
    and ply:GetRoleName() != "SCP3114" and !ply.SCP035_IsWear
end

local function identity(ply)
  return {role = ply:GetRoleName(), name = ply:GetNamesurvivor(), team = ply:GTeam(),
    generation = ply.RXActionGeneration}
end

local function sameLife(ply, saved)
  return canHealPlayer(ply) and ply:GetRoleName() == saved.role
    and ply:GetNamesurvivor() == saved.name and ply:GTeam() == saved.team
    and ply.RXActionGeneration == saved.generation
end

function SWEP:MakeHealSound()
  self:StopHealSound()
  self.HealSoundTimers = {}
  local operation = self.HealOperation
  for i = 1, 3 do
    local name = "RXMedkitSound_" .. self:EntIndex() .. "_" .. i
    self.HealSoundTimers[i] = name
    timer.Create(name, 0.6 + (i - 1), 1, function()
      if IsValid(self) and self.HealOperation == operation and self:IsHealOperationValid(operation) then
        self:EmitSound("nextoren/charactersounds/start_healing.wav", 100, 100, 1.25, CHAN_WEAPON)
      end
    end)
  end
end

function SWEP:StopHealSound()
  for _, name in ipairs(self.HealSoundTimers or {}) do timer.Remove(name) end
  self.HealSoundTimers = nil
end

function SWEP:IsHealOperationValid(operation)
  return operation and self:GetOwner() == operation.owner and self.Heal_Left > 0
    and sameLife(operation.owner, operation.ownerIdentity)
    and sameLife(operation.target, operation.targetIdentity)
    and operation.owner:GetActiveWeapon() == self
    and operation.owner.ProgressBarData
    and operation.owner.ProgressBarData.stopcallback == operation.cancel
end

function SWEP:StopHealing(finished)
  local operation = self.HealOperation
  self.HealOperation = nil
  self.Healing = false
  self:StopHealSound()
  if !operation or !IsValid(operation.owner) then return end
  local owner = operation.owner
  -- Only cancel the progress/animation that this medical kit started.
  if owner.ProgressBarData and owner.ProgressBarData.stopcallback == operation.cancel then
    if !finished then owner:BrStopProgressBar() end
    owner:SetNWEntity("NTF1Entity", NULL)
    owner:StopForcedAnimation()
  end
end

function SWEP:Heal(target)
  if !SERVER then return end
  local owner = self:GetOwner()
  local patient = target or owner
  if self.Healing or self.Heal_Left <= 0 or !canHealPlayer(owner) or !canHealPlayer(patient) then return end
  if owner:GetActiveWeapon() != self or owner:IsFrozen() or owner:GetMoveType() != MOVETYPE_WALK then return end
  if owner.ProgressBarData or IsValid(owner:GetNWEntity("NTF1Entity")) then return end
  if owner:GetVelocity():LengthSqr() > 100 or patient:Health() >= patient:GetMaxHealth() then return end

  local animation = target and "l4d_Heal_Friend_Standing"
    or (owner:Crouching() and "l4d_Heal_Self_Crouching" or "l4d_Heal_Self_Standing_06")
  local sequence, healTime = owner:LookupSequence(animation)
  if sequence < 0 or !healTime or healTime <= 0 then return end
  local operation = {owner = owner, target = patient, ownerIdentity = identity(owner), targetIdentity = identity(patient)}
  operation.cancel = function()
    if self.HealOperation == operation then self:StopHealing(true) end
  end
  owner:BrProgressBar(target and ("l:medkit_healing " .. patient:GetNamesurvivor() .. "...") or "l:medkit_healing",
    healTime, self.ProgressIcon, target, false, function()
      if !IsValid(self) or self.HealOperation != operation then return end
      local valid = self:IsHealOperationValid(operation)
      self:StopHealing(true)
      if !valid then return end
      local amount = math.min(patient:GetMaxHealth() - patient:Health(), patient:GetMaxHealth() * self.PercentHeal)
      if amount <= 0 then return end
      self.Heal_Left = self.Heal_Left - 1
      owner:AddToMVP("heal", amount)
      patient:AnimatedHeal(amount)
      BREACH.Players:ChatPrint(owner, true, true,
        target and ("治疗完成，已为 " .. patient:GetNamesurvivor() .. " 恢复生命值。") or "l:medkit_heal_ended")
    end, function()
      self.HealOperation = operation
      self.Healing = true
      self:MakeHealSound()
      owner:SetNWEntity("NTF1Entity", owner)
      owner:SetForcedAnimation(animation, healTime)
    end, operation.cancel)
end

function SWEP:PrimaryAttack()

  self:SetNextPrimaryFire( CurTime() + .25 )

  if ( CLIENT or !IsValid(self:GetOwner()) ) then return end

  local current_health, max_health = self.Owner:Health(), self.Owner:GetMaxHealth()

  if ( current_health >= max_health ) then

    --BREACH.Players:ChatPrint( self.Owner, true, true, "Вы не нуждаетесь в лечении." )

  else

    self:Heal()

  end

end

local maxs = Vector( 8, 2, 18 )

function SWEP:SecondaryAttack()

  self:SetNextSecondaryFire( CurTime() + .25 )

  if ( CLIENT or !IsValid(self:GetOwner()) ) then return end

  local trace = {}
  trace.start = self.Owner:GetShootPos()
  trace.endpos = trace.start + self.Owner:GetAimVector() * 80
  trace.mask = MASK_SHOT
  trace.filter = { self, self.Owner }
  trace.maxs = maxs
  trace.mins = -maxs

  trace = util.TraceHull( trace )

  local target = trace.Entity

  if ( IsValid(target) and target:IsPlayer() && !( target:GTeam() == TEAM_SCP || target:GTeam() == TEAM_SPEC ) ) then

    self:Heal( target )

  end

end

function SWEP:Holster()

  if SERVER then self:StopHealing() end

  if ( !self.HolsterDelay ) then

    self.HolsterDelay = CurTime() + 1
    self.IdleDelay = CurTime() + 3

    self:PlaySequence( "deploy_off" )
    self:EmitSound( "weapons/m249/handling/m249_armmovement_01.wav", 75, math.random( 80, 100 ), 1, CHAN_WEAPON )

  end

  if ( ( self.HolsterDelay || 0 ) < CurTime() ) then return true end

end

function SWEP:Think()

  if ( ( self.IdleDelay || 0 ) < CurTime() && !self.IdlePlaying ) then

    self.IdlePlaying = true
    self:PlaySequence( "idle", true )

  end

  if ( SERVER ) then

    if self.HealOperation and !self:IsHealOperationValid(self.HealOperation) then self:StopHealing() end

    if ( self.Heal_Left <= 0 ) then

      if IsValid(self:GetOwner()) then self:GetOwner():SelectWeapon("br_holster") end
      self:Remove()

    end

  end

end

function SWEP:OnDrop()
  if SERVER then self:StopHealing() end
end

function SWEP:OwnerChanged()
  if SERVER then self:StopHealing() end
end

function SWEP:OnRemove()
  if SERVER then self:StopHealing() end
  if IsValid(self.WModel) then self.WModel:Remove() end
end

function SWEP:PreDrawViewModel( vm, wep, ply )

  if ( vm:GetSkin() != self.Skin ) then

    vm:SetSkin( self.Skin )

  end

end

function SWEP:CreateWorldModel()

  if ( !self.WModel ) then

    self.WModel = ClientsideModel( self.WorldModel, RENDERGROUP_OPAQUE )
    self.WModel:SetNoDraw( true )

  end

  return self.WModel

end

function SWEP:DrawWorldModel()

  local pl = self.Owner

  if ( pl && pl:IsValid() ) then

    local wm = self:CreateWorldModel()

    local bone = self.Owner:LookupBone( "ValveBiped.Bip01_R_Hand" )
    if ( !bone ) then return end

    local pos, ang = self.Owner:GetBonePosition( bone )

    if ( wm && wm:IsValid() ) then

      ang:RotateAroundAxis( ang:Right(), self.Ang.p )
      ang:RotateAroundAxis( ang:Forward(), self.Ang.y )
      ang:RotateAroundAxis( ang:Up(), self.Ang.r )

      wm:SetRenderOrigin( pos + ang:Right() * self.Pos.x + ang:Forward() * self.Pos.y + ang:Up() * self.Pos.z )
      wm:SetRenderAngles( ang )

      if ( wm:GetSkin() != self.Skin ) then

        wm:SetSkin( self.Skin )

      end

      wm:DrawModel()

    end

  else

    if ( self:GetSkin() != self.Skin ) then

      self:SetSkin( self.Skin )

    end
    self:DrawModel()

  end

end

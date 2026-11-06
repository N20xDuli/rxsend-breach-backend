if SERVER then AddCSLuaFile() end

SWEP.Base = "breach_scp_base"
SWEP.PrintName = "SCP-3114"
SWEP.Category = "收容失效 SCP"
SWEP.Spawnable = false
SWEP.WorldModel = ""
SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.DrawViewModel = true
SWEP.ViewModelFOV = 60
SWEP.UseHands = true
SWEP.HoldType = "scp3114"
SWEP.DrawCrosshair = false
SWEP.droppable = false
SWEP.Primary = {Automatic = true, Delay = 0.5, Damage = 30, Ammo = "none", ClipSize = -1, DefaultClip = -1}
SWEP.Secondary = {Automatic = false, Ammo = "none", ClipSize = -1, DefaultClip = -1}
SWEP.AbilityIcons = {
 {Name = "掐人", Description = "近距离抓住人类；开始掐人会爆皮，受伤会中断。", Cooldown = "3", CooldownTime = 0, KEY = "R", Icon = "nextoren/gui/special_abilities/scp3114_choke.png"},
 {Name = "窃皮", Description = "窃取人类尸体的外观和姓名，持续三分钟；掐人会爆皮。", Cooldown = "15", CooldownTime = 0, KEY = "RMB", Icon = "nextoren/gui/special_abilities/scp3114_skin.png"},
}

local function copyAppearance(from, to)
 to:SetModel(from:GetModel())
 to:SetSkin(from:GetSkin())
 for _, group in ipairs(from:GetBodyGroups()) do to:SetBodygroup(group.id, from:GetBodygroup(group.id)) end
 to:SetMaterial(from:GetMaterial())
 to:SetColor(from:GetColor())
 to:SetRenderMode(from:GetRenderMode())
 to:SetSubMaterial()
 for i = 0, #from:GetMaterials() - 1 do to:SetSubMaterial(i, from:GetSubMaterial(i)) end
end

local function removeMerges(ply)
 for _, ent in pairs(ply:LookupBonemerges()) do if IsValid(ent) then ent:Remove() end end
 ply.BoneMergedEnts = {}
end

local function snapshot(ply)
 local data = {model = ply:GetModel(), skin = ply:GetSkin(), groups = {}, materials = {}, merges = {},
  material = ply:GetMaterial(), color = ply:GetColor(), render = ply:GetRenderMode()}
 for _, g in ipairs(ply:GetBodyGroups()) do data.groups[g.id] = ply:GetBodygroup(g.id) end
 for i = 0, #ply:GetMaterials() - 1 do data.materials[i] = ply:GetSubMaterial(i) end
 for _, ent in pairs(ply:LookupBonemerges()) do
  if IsValid(ent) then data.merges[#data.merges + 1] = snapshot(ent) end
 end
 return data
end

local function restore(ply, data)
 removeMerges(ply)
 ply:SetModel(data.model)
 ply:SetSkin(data.skin)
 ply:SetMaterial(data.material)
 ply:SetColor(data.color)
 ply:SetRenderMode(data.render)
 ply:SetSubMaterial()
 for id, value in pairs(data.groups) do ply:SetBodygroup(id, value) end
 for id, value in pairs(data.materials) do ply:SetSubMaterial(id, value) end
 for _, merge in ipairs(data.merges) do restore(Bonemerge(merge.model, ply), merge) end
end

function SWEP:PlaySkinVoice()
 local owner=self:GetOwner()
 if not SERVER or not IsValid(owner) or (self.NextSkinVoice or 0)>CurTime() then return end
 self.NextSkinVoice=CurTime()+15
 owner:EmitSound("rxsend/scp3114/voice_"..math.random(1,3)..".wav",75,100,1)
end

function SWEP:BreakSkin()
 if not SERVER then return false end
 local owner=self:GetOwner()
 if not IsValid(owner) or not owner:Alive() or owner:GTeam()~=TEAM_SCP or owner:GetRoleName()~="SCP3114"
  or not owner:GetNWBool("SCP3114Disguised",false) then return false end
 self:CancelSkin()
 if self.Choke then self:EndChoke() end
 if self.BareAppearance then restore(owner,self.BareAppearance)
 else
  removeMerges(owner);owner:SetModel("models/rxsend/scp3114/scp3114.mdl")
  owner:SetSkin(0);owner:SetMaterial("");owner:SetSubMaterial();owner:SetColor(color_white);owner:SetRenderMode(RENDERMODE_NORMAL)
 end
 if self.BareName then owner:SetNamesurvivor(self.BareName) end
 owner.SCP3114DonorHands=nil
 owner:SetNWBool("SCP3114Disguised",false)
 owner:SetNWFloat("SCP3114SkinExpires",0)
 owner:SelectWeapon("weapon_scp_3114");owner:SetupHands()
 owner:EmitSound("rxsend/scp3114/break_skin.wav",80,100,1)
 self:PlaySkinVoice()
 local effect=EffectData();effect:SetOrigin(owner:WorldSpaceCenter());effect:SetNormal(Vector(0,0,1));effect:SetColor(BLOOD_COLOR_RED)
 util.Effect("BloodImpact",effect,true,true)
 self.BareAppearance=nil;self.BareName=nil
 return true
end

function SWEP:Initialize()
 self:SetHoldType(self.HoldType)
 self.AbilityIcons = table.Copy(self.AbilityIcons)
end

function SWEP:PlayHandAnimation(sequence)
 local owner=self:GetOwner()
 if not IsValid(owner) or not owner:GetNWBool("SCP3114Disguised",false) then return end
 local vm=owner:GetViewModel()
 if not IsValid(vm) then return end
 local id=vm:LookupSequence(sequence)
 if id and id>=0 then vm:SendViewModelMatchingSequence(id);vm:SetPlaybackRate(1) end
 self.HandIdleAt=CurTime()+0.5
end
function SWEP:UpdateDisguiseHands(force)
 local owner=self:GetOwner()
 if not SERVER or not IsValid(owner) then return end
 local show=owner:GetNWBool("SCP3114Disguised",false)==true
 if force or self.HandsVisible~=show then
  self.HandsVisible=show
  owner:DrawViewModel(show)
  if show then self:PlayHandAnimation("fists_draw") end
 end
end
function SWEP:Deploy()
 self:UpdateDisguiseHands(true)
 return true
end

function SWEP:ValidOwner()
 local owner = self:GetOwner()
 return IsValid(owner) and owner:Alive() and owner:GTeam() == TEAM_SCP and owner:GetRoleName() == "SCP3114" and owner:GetActiveWeapon() == self
end

function SWEP:TraceTarget()
 local owner = self:GetOwner()
 owner:LagCompensation(true)
 local tr = util.TraceHull({start = owner:GetShootPos(), endpos = owner:GetShootPos() + owner:GetAimVector() * 90,
  mins = Vector(-8, -10, -5), maxs = Vector(8, 10, 5), filter = owner})
 owner:LagCompensation(false)
 return tr.Entity
end

function SWEP:EndChoke()
 local state = self.Choke
 if not state then return end
 self.Choke = nil
 if state.sound then state.sound:Stop(); state.sound = nil end
 for _, ply in ipairs({state.owner, state.victim}) do
  if IsValid(ply) and ply.SCP3114Grab == self then
   ply.SCP3114Grab = nil
   ply:StopForcedAnimation()
   -- Death/role reset owns its own movement and appearance after the interruption.
   if ply:Alive() and ply:GetRoleName() == state.roles[ply] then
    ply:Freeze(false)
    ply:SetNWEntity("NTF1Entity", NULL)
    if ply == state.owner then restore(ply, state.appearance); ply:SetupHands() end
   end
  end
 end
 self.NextChoke = CurTime() + 3
 if IsValid(self) and IsValid(self:GetOwner()) then self:Cooldown(1, 3) end
end

local function animate(ply, sequence, duration)
 if ply:LookupSequence(sequence) >= 0 then ply:SetForcedAnimation(sequence, duration) end
end

function SWEP:PrimaryAttack()
 if CLIENT or not self:ValidOwner() or self.Choke or self.SkinTarget then return end
 local owner=self:GetOwner()
 if owner:IsFrozen() or owner.ForceAnimSequence or owner.SCP3114Grab then return end
 if self:GetNextPrimaryFire()>CurTime() then return end
 self:SetNextPrimaryFire(CurTime()+self.Primary.Delay)
 self:PlayHandAnimation("fists_left")
 owner:SetAnimation(PLAYER_ATTACK1)
 owner:EmitSound("rxsend/scp3114/swing_"..math.random(1,3)..".wav",70,100,1)
 local victim=self:TraceTarget()
 if not IsValid(victim) or not victim:IsPlayer() or not victim:Alive()
  or victim:GTeam()==TEAM_SCP or victim:GTeam()==TEAM_SPEC then return end
 local damage=DamageInfo()
 damage:SetAttacker(owner);damage:SetInflictor(self);damage:SetDamageType(DMG_SLASH)
 damage:SetDamage(self.Primary.Damage);damage:SetDamagePosition(victim:GetPos())
 local hit=victim:WorldSpaceCenter()
 local before=victim:Health()
 damage:SetDamagePosition(hit)
 victim:TakeDamageInfo(damage)
 if IsValid(victim) and victim:Health()<before then
  victim:EmitSound("rxsend/scp3114/slap_"..math.random(1,3)..".wav",75,100,1)
  local effect=EffectData();effect:SetOrigin(hit);effect:SetNormal(owner:GetAimVector());effect:SetColor(BLOOD_COLOR_RED)
  util.Effect("BloodImpact",effect,true,true)
  util.Decal("Blood",hit,hit+owner:GetAimVector()*48,{owner,victim})
 end
end

function SWEP:PreDrawViewModel()
 local owner=self:GetOwner()
 return not IsValid(owner) or not owner:GetNWBool("SCP3114Disguised",false)
end

function SWEP:Reload()
 if CLIENT or not self:ValidOwner() or self.Choke or self.SkinTarget then return end
 if (self.NextChoke or 0)>CurTime() then return end
 self.NextChoke = CurTime() + 0.25
 local owner, victim = self:GetOwner(), self:TraceTarget()
 if owner:IsFrozen() or owner.ForceAnimSequence or owner.SCP3114Grab then return end
 if not IsValid(victim) or not victim:IsPlayer() or not victim:Alive() or victim:GTeam() == TEAM_SCP or victim:GTeam() == TEAM_SPEC then return end
 if victim:IsFrozen() or victim.ForceAnimSequence or victim.SCP3114Grab or victim:GetMoveType() ~= MOVETYPE_WALK then return end
 self:BreakSkin()
 local state = {owner = owner, victim = victim, appearance = snapshot(owner),
  roles = {[owner] = owner:GetRoleName(), [victim] = victim:GetRoleName()}, finish = CurTime() + 5.3, loop = CurTime() + 1.3}
 self.Choke = state
 state.sound = CreateSound(victim, "rxsend/scp3114/strangle.wav")
 if state.sound then state.sound:SetSoundLevel(75); state.sound:PlayEx(1, 100) end
 owner.SCP3114Grab, victim.SCP3114Grab = self, self
 -- Borrow the 049 animation skeleton, rendering only the current 3114/disguise mesh.
 removeMerges(owner)
 owner:SetModel("models/cultist/scp/scp_049.mdl")
 owner:SetColor(Color(255, 255, 255, 0))
 owner:SetRenderMode(RENDERMODE_TRANSALPHA)
 local shell = Bonemerge(state.appearance.model, owner)
 restore(shell, state.appearance)
 local facing=(owner:GetPos()-victim:GetPos()):Angle()
 facing.p=0;facing.r=0
 victim:SetEyeAngles(facing);victim:SetAngles(facing)
 local attackerFacing=(victim:GetPos()-owner:GetPos()):Angle()
 attackerFacing.p=0;attackerFacing.r=0
 owner:SetEyeAngles(attackerFacing);owner:SetAngles(attackerFacing)
 owner:Freeze(true); victim:Freeze(true)
 owner:SetNWEntity("NTF1Entity", owner)
 victim:SetNWEntity("NTF1Entity", victim)
 animate(owner, "0_049_struggle_start", 1.3)
 animate(victim, "0_049_victum_struggle_start", 1.3)
end

function SWEP:CancelSkin()
 local body = self.SkinTarget
 if IsValid(body) and body.SCP3114SkinOwner == self then body.SCP3114SkinOwner = nil end
 self.SkinTarget = nil
 local owner = self:GetOwner()
 if body and IsValid(owner) and owner.ProgressBarData and owner.ProgressBarData.target == body then owner:BrStopProgressBar("窃取皮囊") end
end

function SWEP:ValidSkin(body)
 return self:ValidOwner() and IsValid(body) and body:GetClass() == "prop_ragdoll" and body.vtable ~= nil
  and body.__Team ~= TEAM_SCP and body.__Team ~= TEAM_SPEC and body.__Team ~= nil
  and not body.SCP3114SkinTaken and body.SCP3114SkinOwner == self
  and util.IsValidModel(body:GetModel())
  and self:GetOwner():GetPos():DistToSqr(body:GetPos()) <= 130 * 130
end

function SWEP:SecondaryAttack()
 if CLIENT or not self:ValidOwner() or self.Choke or self.SkinTarget then return end
 if self:GetOwner():GetVelocity():LengthSqr() > 100 or self:GetOwner().ProgressBarData then return end
 self:SetNextSecondaryFire(CurTime() + 0.25)
 local body = self:TraceTarget()
 if not IsValid(body) or body.SCP3114SkinOwner or body.SCP3114SkinTaken then return end
 body.SCP3114SkinOwner = self
 if not self:ValidSkin(body) then body.SCP3114SkinOwner = nil; return end
 self.SkinTarget = body
 self:GetOwner():BrProgressBar("窃取皮囊", 30, "nextoren/gui/special_abilities/scp3114_skin.png", body, false, function()
  if not IsValid(self) or self.SkinTarget ~= body or not self:ValidSkin(body) then
   if IsValid(self) then self:CancelSkin() end
   return
  end
  local owner = self:GetOwner()
  if not owner:GetNWBool("SCP3114Disguised",false) then
   self.BareAppearance=snapshot(owner);self.BareName=owner:GetNamesurvivor()
  end
  removeMerges(owner)
  copyAppearance(body, owner)
  for _, ent in pairs(body:LookupBonemerges()) do
   if IsValid(ent) then copyAppearance(ent, Bonemerge(ent:GetModel(), owner)) end
  end
  if body.__Name then owner:SetNamesurvivor(body.__Name) end
  owner.SCP3114DonorHands=body.SCP3114DonorHands and table.Copy(body.SCP3114DonorHands) or nil
  owner:SetNWBool("SCP3114Disguised", true)
  owner:SetNWFloat("SCP3114SkinExpires",CurTime()+180)
  BREACH.SCP3114.TakeDisguiseItems(owner, body)
  owner:SelectWeapon("weapon_scp_3114")
  body.SCP3114SkinTaken = true
  self:CancelSkin()
  -- Consume the body after its appearance/items have been copied.
  for _,merge in pairs(body:LookupBonemerges()) do if IsValid(merge) then merge:Remove() end end
  body:Remove()
  owner:SetupHands()
  self:UpdateDisguiseHands(true)
  owner:EmitSound("rxsend/scp3114/equip_skin.wav", 75, 100, 1)
  timer.Simple(5.7,function()
   if IsValid(self) and IsValid(owner) and owner:Alive() and owner:GTeam()==TEAM_SCP
    and owner:GetRoleName()=="SCP3114" and owner:GetNWBool("SCP3114Disguised",false) then self:PlaySkinVoice() end
  end)
  self:SetNextSecondaryFire(CurTime() + 15)
  self:Cooldown(2, 15)
 end, nil, function() if IsValid(self) then self:CancelSkin() end end)
end

function SWEP:Think()
 if CLIENT then return end
 self:UpdateDisguiseHands()
 if self.HandIdleAt and CurTime()>=self.HandIdleAt then
  self:PlayHandAnimation("fists_idle_01")
  self.HandIdleAt=nil
 end
 if self.SkinTarget and not self:ValidSkin(self.SkinTarget) then self:CancelSkin() end
 local state = self.Choke
 if not state then return end
 local owner, victim = state.owner, state.victim
 if not self:ValidOwner() or not IsValid(victim) or not victim:Alive() or victim:GetRoleName() ~= state.roles[victim]
  or victim:GTeam() == TEAM_SCP or victim:GTeam() == TEAM_SPEC or owner:GetPos():DistToSqr(victim:GetPos()) > 130 * 130 then self:EndChoke(); return end
 if state.loop and CurTime() >= state.loop then
  state.loop = nil
  animate(owner, "0_049_struggle_loop", 4)
  animate(victim, "0_049_victum_struggle_loop", 4)
 end
 if CurTime() >= state.finish then
  self:EndChoke()
  local damage = DamageInfo()
  damage:SetAttacker(owner); damage:SetInflictor(self)
  damage:SetDamageType(DMG_DIRECT); damage:SetDamage(100000)
  victim:TakeDamageInfo(damage)
  if IsValid(victim) and not victim:Alive() then victim:EmitSound("rxsend/scp3114/strangle_kill.wav", 75, 100, 1) end
 end
end

function SWEP:Holster()
 if SERVER then self:EndChoke(); self:CancelSkin() end
 local owner=self:GetOwner();if IsValid(owner) then owner:DrawViewModel(true) end
 return true
end
function SWEP:OnRemove() if SERVER then self:EndChoke(); self:CancelSkin() end end

if SERVER then
 -- Think on the player list: skin expires even while holding a stolen utility.
 hook.Add("Think","SCP3114SkinTimeout",function()
  for _,ply in ipairs(player.GetAll()) do
   if ply:Alive() and ply:GTeam()==TEAM_SCP and ply:GetRoleName()=="SCP3114"
    and ply:GetNWBool("SCP3114Disguised",false) and ply:GetNWFloat("SCP3114SkinExpires",0)>0
    and CurTime()>=ply:GetNWFloat("SCP3114SkinExpires",0) then
    local weapon=ply:GetWeapon("weapon_scp_3114")
    if IsValid(weapon) then weapon:BreakSkin() end
   end
  end
 end)
 hook.Add("EntityTakeDamage", "SCP3114InterruptChoke", function(ent, damage)
  if IsValid(ent.SCP3114Grab) and damage:GetDamage() > 0 then ent.SCP3114Grab:EndChoke() end
 end)
 hook.Add("PlayerDeath", "SCP3114ReleaseDeath", function(ply)
  if IsValid(ply.SCP3114Grab) then ply.SCP3114Grab:EndChoke() end
 end)
 hook.Add("PlayerDisconnected", "SCP3114ReleaseDisconnect", function(ply)
  if IsValid(ply.SCP3114Grab) then ply.SCP3114Grab:EndChoke() end
 end)
end

if CLIENT then
 hook.Add("PreDrawPlayerHands","SCP3114HideHands",function(_,_,ply)
  if IsValid(ply) and ply:GTeam()==TEAM_SCP and ply:GetRoleName()=="SCP3114" and not ply:GetNWBool("SCP3114Disguised",false) then return true end
 end)
end

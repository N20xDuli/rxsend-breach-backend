AddCSLuaFile()
SWEP.Base = "cw_base"
SWEP.PrintName = "M134 转管机枪"
SWEP.Category = "RXSEND · Nu-7"
SWEP.Author = "Viper / MW SWEPs team; CW2 adaptation"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 4
SWEP.SlotPos = 0
SWEP.ViewModel = "models/rxsend/nu7/v_m134.mdl"
SWEP.WorldModel = "models/rxsend/nu7/w_m134.mdl"
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.UseHands = false -- Nu-7 gloves and sleeves are compiled into this viewmodel.
SWEP.NormalHoldType = "crossbow"
SWEP.RunHoldType = "passive"
SWEP.FireModes = {"auto"}
SWEP.Attachments = {}
SWEP.Primary = {ClipSize = 300, DefaultClip = 300, Automatic = true, Ammo = "AR2"}
SWEP.AmmoPerShot = 3
SWEP.FireDelay = 0.13
SWEP.Shots = 3
SWEP.Damage = 28.85
SWEP.Recoil = 1.5
SWEP.SpeedDec = 90
SWEP.HipSpread = 0.08
SWEP.AimSpread = 0.007
SWEP.VelocitySensitivity = 0.1
SWEP.MaxSpreadInc = 0.6
SWEP.SpreadPerShot = 0.001
SWEP.SpreadCooldown = 0.001
SWEP.ClumpSpread = 0.06
SWEP.Chamberable = false
SWEP.CanRestOnObjects = false
SWEP.BipodInstalled = false
SWEP.DrawSpeed = 1
SWEP.DeployTime = 1.2
SWEP.HolsterTime = 0.8
SWEP.ReloadSpeed = 1
SWEP.ReloadTime = 3
SWEP.ReloadTime_Empty = 4
SWEP.ReloadHalt = 4.4 -- Full sequence duration, not only the belt insertion time.
SWEP.ReloadHalt_Empty = 5.9334
SWEP.SnapToIdlePostReload = false
SWEP.Animations = {idle = "idle", draw = "draw", fire = "fire", reload = "reload_fast", reload_empty = "reload"}
CustomizableWeaponry:addFireSound("NU7_M134_FIRE", {
    "viper/weapons/dblmg/weap_kilo121_fire_plr_01.wav",
    "viper/weapons/dblmg/weap_kilo121_fire_plr_02.wav",
    "viper/weapons/dblmg/weap_kilo121_fire_plr_03.wav"
}, 1, 110, CHAN_WEAPON)
SWEP.FireSound = "NU7_M134_FIRE"
local sounds = {start = "wfoly_plr_lm_minigun_reload_start.wav", out = "wfoly_plr_lm_minigun_reload_belt_out.wav",
    insert = "wfoly_plr_lm_minigun_reload_belt_in.wav", finish = "wfoly_plr_lm_minigun_reload_end.wav"}
for key, path in pairs(sounds) do CustomizableWeaponry:addReloadSound("NU7_M134_" .. key, "viper/weapons/dblmg/" .. path) end
SWEP.Sounds = {
    reload_fast = {{time = 0.13, sound = "NU7_M134_start"}, {time = 0.85, sound = "NU7_M134_out"},
        {time = 2.5, sound = "NU7_M134_insert"}, {time = 3, sound = "NU7_M134_finish"}},
    reload = {{time = 0.13, sound = "NU7_M134_start"}, {time = 1.5, sound = "NU7_M134_out"},
        {time = 3.5, sound = "NU7_M134_insert"}, {time = 4.5, sound = "NU7_M134_finish"}}
}
if CLIENT then
    SWEP.DrawCrosshair = false
    SWEP.CSMuzzleFlashes = true
    SWEP.AimingEnabled = false
    SWEP.SnapToGrip = false
    SWEP.MuzzleEffect = "muzzleflash_6"
    SWEP.PosBasedMuz = true
    SWEP.MuzzleAttachmentName = "muzzle"
    SWEP.MuzzleAttachment = 1
    SWEP.ShellAttachment = 2
    SWEP.ShellScale = 0.7
    SWEP.ShellPosOffset = {x = 0, y = 0, z = 0}
    SWEP.DrawTraditionalWorldModel = false
    SWEP.WM = SWEP.WorldModel
    SWEP.WMPos = Vector(15, -1, -11)
    SWEP.WMAng = Vector(0, 90, -90)
    SWEP.IronsightPos = Vector(0, 0, 0)
    SWEP.IronsightAng = Vector(0, 0, 0)
    SWEP.SprintPos = Vector(4, 1, -2)
    SWEP.SprintAng = Vector(-5, 15, 0)
    SWEP.CustomizePos = Vector(6, -2, -4)
    SWEP.CustomizeAng = Vector(20, 25, 5)
    killicon.Add("cw_nu7_m134", "vgui/entities/mg_dblmg", Color(255, 80, 0))

    function SWEP:fireAnimFunc()
        if not IsValid(self.CW_VM) then return end
        self.Nu7LastFireTime = CurTime()
        local sequence = self.CW_VM:LookupSequence(self.Animations.fire)
        if sequence < 0 then return end
        -- Keep the rotating-barrel sequence running across consecutive shots.
        if self.CW_VM:GetSequence() ~= sequence then
            self:sendWeaponAnim("fire", self.FireAnimSpeed)
        end
    end

    function SWEP:IndividualThink()
        if not self.Nu7LastFireTime or not IsValid(self.CW_VM) then return end
        if CurTime() <= self.Nu7LastFireTime + self.FireDelay + 0.08 then return end
        self.Nu7LastFireTime = nil
        -- Do not replace draw/reload animations when firing has stopped.
        local sequence = self.CW_VM:LookupSequence(self.Animations.fire)
        if sequence >= 0 and self.CW_VM:GetSequence() == sequence then
            self:sendWeaponAnim("idle")
        end
    end

end

if CLIENT then
    concommand.Add("nu7_m134_diagnose", function()
        local player = LocalPlayer()
        local weapon = IsValid(player) and player:GetActiveWeapon()
        if not IsValid(weapon) or weapon:GetClass() ~= "cw_nu7_m134" then
            print("[Nu7 M134] Equip the M134 first.")
            return
        end
        local model = weapon.ViewModel
        print("[Nu7 M134] expected", model, "valid", util.IsValidModel(model))
        for _, suffix in ipairs({".mdl", ".vvd", ".dx90.vtx"}) do
            local path = string.StripExtension(model) .. suffix
            print("[Nu7 M134] file", path, file.Exists(path, "GAME"), file.Size(path, "GAME"))
        end
        local vm = weapon.CW_VM
        print("[Nu7 M134] CW_VM", IsValid(vm) and vm:GetModel() or "missing")
        if IsValid(vm) then
            print("[Nu7 M134] bones", vm:GetBoneCount(), "muzzle", vm:LookupAttachment("muzzle"))
            for _, path in ipairs(vm:GetMaterials()) do
                local material = Material(path)
                print("[Nu7 M134] material", path, material:GetShader(), "error", material:IsError())
            end
        end
    end)
end

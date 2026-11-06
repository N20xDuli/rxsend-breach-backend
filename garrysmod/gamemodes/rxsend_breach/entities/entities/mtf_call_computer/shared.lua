ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Cogitator"
ENT.Author = "Kub"
ENT.Spawnable = true
ENT.Category = "Kub's Archive"

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "CogText")
    self:NetworkVar("Int", 0, "CogTime")
    self:NetworkVar("Int", 1, "CogErrors")
    self:NetworkVar("Bool", 0, "IsSuccess")
    self:NetworkVar("Bool", 1, "ShowStatusText")
    self:NetworkVar("Bool", 2, "LockOnSuccess")
    self:NetworkVar("Bool", 3, "LockOnFail")
end
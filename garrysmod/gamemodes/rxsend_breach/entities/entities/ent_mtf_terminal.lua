AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "MTF 特遣队呼叫终端"
ENT.Spawnable = true
ENT.Category = "收容失效 SCP"

-- 你的解包科幻电脑模型
ENT.Model = Model("models/dizcordum/wh/props3/wk_cogitator_three_comp.mdl")

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Called")
    self:NetworkVar("Bool", 1, "Hacking")
    self:NetworkVar("Int", 0, "CD")
end

function ENT:Initialize()
    self:SetModel(self.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    
    if SERVER then
        self:SetUseType(SIMPLE_USE)
    end

    self:SetCalled(false)
    self:SetHacking(false)
    self:SetCD(0)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end
end

function ENT:Use(activator, caller)
    if not caller:IsPlayer() then return end
    
    if self:GetCalled() then 
        caller:RXSENDNotify("终端已锁定：增援部队已在路上，无法再次呼叫。")
        return 
    end
    if self:GetHacking() then return end
    if self:GetCD() > CurTime() then
        caller:RXSENDNotify("通讯阵列重启中，请稍后再试。")
        return
    end

    -- 1. 检查凭证
    if not caller:HasWeapon("mtf_call_license") then
        caller:RXSENDNotify("访问拒绝：需要 [呼叫许可] 才能授权此操作！")
        return
    end

    -- 2. 检查局势条件 (调用服务端的全局函数)
    if CheckMTFCallConditions then
        local canCall, msg = CheckMTFCallConditions()
        if not canCall then
            caller:RXSENDNotify(msg)
            return
        end
    else
        caller:RXSENDNotify("[系统错误] 找不到局势检测模块！")
        return
    end

    -- 3. 开始破译读条
    self:SetHacking(true)
    
    caller:BrProgressBar("正在向基金会指挥部上传最高级别请求...", 5, "nextoren/gui/icons/hand.png", self, false, function()
        self:SetHacking(false)
        
        -- 二次校验
        if not IsValid(caller) or not caller:Alive() then return end
        local canCallFinal, _ = CheckMTFCallConditions()
        if not caller:HasWeapon("mtf_call_license") or not canCallFinal then
            caller:RXSENDNotify("呼叫中断：授权丢失或当前局势已变更。")
            return
        end

        self:SetCalled(true)
        
        -- 核心步骤：向这个摸电脑的玩家发送一条网络消息，让他打开“三选一”的 UI 菜单
        net.Start("MTF_TERMINAL_UI")
        net.Send(caller)
        
        -- (可选) 消耗凭证
        -- caller:StripWeapon("mtf_call_license")
    end)
end

if CLIENT then
    local n7_icon = Material("nextoren/gengxygao/site_19_n7.png")
    
    function ENT:Draw()
        self:DrawModel()

        local opos = self:GetPos()
        local up = self:GetUp()
        local position = opos + up * 30 
        
        local icon_color = color_white
        if self:GetCalled() then
            icon_color = Color(255, 50, 50, 150)
        elseif self:GetHacking() then
            icon_color = Color(255, 200, 0, 150 + math.sin(CurTime() * 10) * 100) 
        end

        local size = 20
        local camAngle = EyeAngles()
        camAngle:RotateAroundAxis(camAngle:Forward(), 90)
        camAngle:RotateAroundAxis(camAngle:Right(), 90)

        cam.Start3D2D(position, camAngle, 0.15)
            cam.IgnoreZ(true)
            surface.SetDrawColor(icon_color)
            surface.SetMaterial(n7_icon)
            surface.DrawTexturedRect(-(size/2), -(size/2), size, size)
            cam.IgnoreZ(false)
        cam.End3D2D()
    end
end
include("shared.lua")

local isPlaying = false
local currentEntity = nil
local currentInput = "" 
local errorCount = 0
local sessionStartTime = 0
local inputPanel = nil
local editFrame = nil 

local camStartPos = Vector(0,0,0)
local camStartAng = Angle(0,0,0)
local camProgress = 0

local matLight = Material("sprites/light_glow02_add")

local function OpenEditMenu(ent)
    if IsValid(editFrame) then editFrame:Remove() end
    
    editFrame = vgui.Create("DFrame")
    editFrame:SetSize(400, 425) 
    editFrame:SetTitle("破解终端设置")
    editFrame:Center()
    editFrame:MakePopup()
    
    local scroll = vgui.Create("DScrollPanel", editFrame)
    scroll:Dock(FILL)
    
    local lblText = scroll:Add("DLabel")
    lblText:SetText("显示文本（建议 7 行）：")
    lblText:Dock(TOP)
    lblText:DockMargin(0, 5, 0, 5)
    
    local txtEntry = scroll:Add("DTextEntry")
    txtEntry:SetMultiline(true)
    txtEntry:SetHeight(100)
    txtEntry:Dock(TOP)
    txtEntry:SetText(ent:GetCogText()) 
    
    local lblTime = scroll:Add("DLabel")
    lblTime:SetText("限时秒数（0 表示不限时）：")
    lblTime:Dock(TOP)
    lblTime:DockMargin(0, 10, 0, 5)
    
    local numTime = scroll:Add("DNumberWang")
    numTime:Dock(TOP)
    numTime:SetMinMax(0, 600) 
    numTime:SetValue(ent:GetCogTime())
    
    local lblErr = scroll:Add("DLabel")
    lblErr:SetText("允许的最大错误次数：")
    lblErr:Dock(TOP)
    lblErr:DockMargin(0, 10, 0, 5)
    
    local numErr = scroll:Add("DNumberWang")
    numErr:Dock(TOP)
    numErr:SetMinMax(1, 50)
    numErr:SetValue(ent:GetCogErrors())
    
    local checkShowText = scroll:Add("DCheckBoxLabel")
    checkShowText:SetText("在终端上方显示文本")
    checkShowText:Dock(TOP)
    checkShowText:DockMargin(0, 15, 0, 5)
    checkShowText:SetChecked(ent:GetShowStatusText())
    checkShowText:SetTextColor(Color(255,255,255))
    
    local checkLockSuccess = scroll:Add("DCheckBoxLabel")
    checkLockSuccess:SetText("成功后永久锁定")
    checkLockSuccess:Dock(TOP)
    checkLockSuccess:DockMargin(0, 5, 0, 5)
    checkLockSuccess:SetChecked(ent:GetLockOnSuccess())
    checkLockSuccess:SetTextColor(Color(255,255,255))
    
    local checkLockFail = scroll:Add("DCheckBoxLabel")
    checkLockFail:SetText("失败后永久锁定")
    checkLockFail:Dock(TOP)
    checkLockFail:DockMargin(0, 5, 0, 5)
    checkLockFail:SetChecked(ent:GetLockOnFail())
    checkLockFail:SetTextColor(Color(255,255,255))
    
    local btnSave = scroll:Add("DButton")
    btnSave:SetText("保存设置")
    btnSave:Dock(TOP)
    btnSave:DockMargin(0, 20, 0, 0)
    btnSave:SetHeight(40)
    
    btnSave.DoClick = function()
        net.Start("Cogitator_UpdateSettings")
            net.WriteEntity(ent)
            net.WriteString(txtEntry:GetValue())
            net.WriteInt(numTime:GetValue(), 16)
            net.WriteInt(numErr:GetValue(), 8)
            
            net.WriteBool(checkShowText:GetChecked())
            net.WriteBool(checkLockSuccess:GetChecked())
            net.WriteBool(checkLockFail:GetChecked())
        net.SendToServer()
        
        editFrame:Close()
    end
end

function ENT:Draw()
    self:DrawModel()
    
    local isSuccess = self:GetIsSuccess()
    local lightColor = isSuccess and Color(0, 255, 0) or Color(255, 0, 0)
    
    local lightPos = self:GetPos() + self:GetUp() * 24.5 + self:GetForward() * 9 + self:GetRight() * 10
    
    render.SetMaterial(matLight)
    render.DrawSprite(lightPos, 16, 16, lightColor)
    
    local dlight = DynamicLight(self:EntIndex())
    if (dlight) then
        dlight.pos = lightPos
        dlight.r = lightColor.r
        dlight.g = lightColor.g
        dlight.b = lightColor.b
        dlight.brightness = 2
        dlight.Decay = 1000
        dlight.Size = 64
        dlight.DieTime = CurTime() + 1
    end

    if self:GetShowStatusText() then
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), 90)
        ang:RotateAroundAxis(ang:Forward(), 90)
        
        local dist = LocalPlayer():GetPos():DistToSqr(self:GetPos())
        if dist < 250*250 then
            cam.Start3D2D(self:GetPos() + self:GetUp() * 25, ang, 0.1)
                local statusText = isSuccess and "ACCESS GRANTED" or "LOCKED"
                draw.SimpleText(statusText, "DermaLarge", 0, -50, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        end
    end
end

local function CleanUp()
    isPlaying = false
    currentEntity = nil
    
    if IsValid(inputPanel) then 
        inputPanel:Remove() 
        inputPanel = nil
    end
    
    gui.EnableScreenClicker(false)
    hook.Remove("CalcView", "Cogitator_CameraLogic")
    hook.Remove("HUDPaint", "Cogitator_UIRender")
end

local function EndSession(success, isCancel)
    if IsValid(currentEntity) then
        net.Start("Cogitator_EndMinigame")
        net.WriteEntity(currentEntity)
        net.WriteBool(success)
        net.WriteBool(isCancel or false)
        net.SendToServer()
    end
    CleanUp()
end

local function iterateUTF8(str)
    return string.gmatch(str, "([%z\1-\127\194-\244][\128-\191]*)")
end

local function CheckInput(char)
    local targetText = currentEntity:GetCogText()
    local maxErrors = currentEntity:GetCogErrors()

    local nextCharIndex = utf8.len(currentInput) + 1
    local expectedChar = utf8.sub(targetText, nextCharIndex, nextCharIndex)
    
    if char == expectedChar then
        currentInput = currentInput .. char
        surface.PlaySound("buttons/button15.wav")
        
        if currentInput == targetText then
            surface.PlaySound("buttons/bell1.wav")
            EndSession(true, false)
        end
    else
        errorCount = errorCount + 1
        surface.PlaySound("buttons/button10.wav")
        
        if errorCount >= maxErrors then
            EndSession(false, false)
        else
            local lastSpace = string.match(currentInput, ".*()[%s\n]")
            if lastSpace then
                currentInput = string.sub(currentInput, 1, lastSpace)
            else
                currentInput = ""
            end
        end
    end
end

local function CreateInputPanel()
    if IsValid(inputPanel) then inputPanel:Remove() end
    
    inputPanel = vgui.Create("DTextEntry")
    inputPanel:SetSize(ScrW(), ScrH()) 
    inputPanel:SetPos(0, 0)
    inputPanel:SetPaintBackground(false)
    inputPanel:SetTextColor(Color(0,0,0,0))
    inputPanel:SetCursor("blank")
    inputPanel:SetFont("DermaLarge") 
    inputPanel:SetUpdateOnType(true) 
    inputPanel:SetMultiline(true) 
    inputPanel:MakePopup()
    inputPanel:RequestFocus()
    
    inputPanel.OnValueChange = function(self, val)
        if not isPlaying then return end
        if val == "" then return end 

        for char in iterateUTF8(val) do
            if char ~= "\n" and char ~= "\r" then 
                CheckInput(char)
            end
        end
        
        self:SetText("") 
        self:SetCaretPos(0)
    end
    
    inputPanel.OnKeyCodeTyped = function(self, code)
        if not isPlaying then return end

        if code == KEY_TAB then
            EndSession(false, true)
        elseif code == KEY_ENTER then
            CheckInput("\n")
            self:SetText("") 
            self:SetCaretPos(0)
        end
    end
    
    inputPanel.OnLoseFocus = function(self)
        if isPlaying then 
            timer.Simple(0, function() if IsValid(self) then self:RequestFocus() end end)
        end
    end
end

local function SetupHooks()
    hook.Add("CalcView", "Cogitator_CameraLogic", function(ply, pos, angles, fov)
        if not isPlaying or not IsValid(currentEntity) then return end
        
        local targetPos = currentEntity:GetPos() + currentEntity:GetForward() * 25 + currentEntity:GetUp() * 18
        local targetAng = (currentEntity:GetPos() - targetPos):Angle()
        targetAng.p = targetAng.p - 25 
        
        camProgress = math.min(camProgress + FrameTime() * 2, 1)
        
        local smoothPos = LerpVector(math.EaseInOut(camProgress, 0, 1), camStartPos, targetPos)
        local smoothAng = LerpAngle(math.EaseInOut(camProgress, 0, 1), camStartAng, targetAng)
        
        return { origin = smoothPos, angles = smoothAng, fov = fov, drawviewer = true }
    end)
    
    hook.Add("HUDPaint", "Cogitator_UIRender", function()
        if not isPlaying then return end
        
        local w, h = ScrW(), ScrH()
        
        local timeLimit = currentEntity:GetCogTime()
        local maxErrors = currentEntity:GetCogErrors()
        local targetText = currentEntity:GetCogText()

        local timeElapsed = CurTime() - sessionStartTime
        local timeLeft = timeLimit - timeElapsed
        
        if timeLimit > 0 and timeLeft <= 0 then
            surface.PlaySound("buttons/button10.wav")
            EndSession(false, false)
            return
        end
        
        surface.SetDrawColor(0, 0, 0, 220)
        surface.DrawRect(0, 0, w, h)
        
        local errorYOffset = (timeLimit > 0) and 200 or 150 
        draw.SimpleText("Tab：退出；Enter：换行", "DermaDefault", w/2, h - 50, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("错误次数：" .. errorCount .. " / " .. maxErrors, "DermaLarge", w/2, h/2 - errorYOffset, Color(255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        if timeLimit > 0 then
            local timerFraction = math.Clamp(timeLeft / timeLimit, 0, 1)
            local barW = 400
            local barH = 10
            local barX = w/2 - barW/2
            local barY = h/2 - 150
            
            local barColor = Color(255 * (1 - timerFraction), 255 * timerFraction, 0)
            surface.SetDrawColor(50, 50, 50, 255)
            surface.DrawRect(barX, barY, barW, barH)
            surface.SetDrawColor(barColor)
            surface.DrawRect(barX, barY, barW * timerFraction, barH)
            draw.SimpleText(string.format("%.1f 秒", timeLeft), "DermaDefault", w/2, barY - 20, barColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        surface.SetFont("DermaLarge")
        local lineHeight = draw.GetFontHeight("DermaLarge") + 5
        
        local targetLines = string.Explode("\n", targetText)
        local inputLines = string.Explode("\n", currentInput)
        
        local totalTextHeight = #targetLines * lineHeight
        local startY = h/2 - totalTextHeight/2 + 50
        
        for i, line in ipairs(targetLines) do
            local lineY = startY + (i-1) * lineHeight
            local textW, _ = surface.GetTextSize(line)
            local lineX = w/2 - textW/2 
            
            draw.SimpleText(line, "DermaLarge", lineX, lineY, Color(80, 80, 80), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            local inpLine = inputLines[i] or ""
            local cursor = ""
            if i == #inputLines then
                if math.sin(CurTime() * 15) > 0 then cursor = "|" end
            end
            
            draw.SimpleText(inpLine .. cursor, "DermaLarge", lineX, lineY, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end)
end

net.Receive("Cogitator_StartMinigame", function()
    currentEntity = net.ReadEntity()
    if not IsValid(currentEntity) then return end
    
    isPlaying = true
    currentInput = ""
    errorCount = 0
    camProgress = 0
    camStartPos = LocalPlayer():EyePos()
    camStartAng = LocalPlayer():EyeAngles()
    sessionStartTime = CurTime()
    
    CreateInputPanel()
    SetupHooks()
end)

net.Receive("Cogitator_EndMinigame", function()
    local ent = net.ReadEntity() 
    local success = net.ReadBool()
    local isForced = net.ReadBool()
    
    if isForced then
        CleanUp()
        chat.AddText(Color(255,100,100), "Cogitator connection lost.")
    end
end)

CleanUp()

properties.Add( "CogitatorEdit", {
    MenuLabel = "破解终端设置",
    Order = 1000,
    MenuIcon = "icon16/cog.png",

    Filter = function( self, ent, ply )
        if not IsValid( ent ) then return false end
        if not ply:IsAdmin() then return false end
        if ent:GetClass() == "ent_cogitator" 
           or ent:GetClass() == "kub_access_cogitator" 
           or ent.PrintName == "Cogitator" then 
            return true 
        end
        return false
    end,

    Action = function( self, ent )
        OpenEditMenu(ent)
    end
} )
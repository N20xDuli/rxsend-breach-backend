include("shared.lua")

function ENT:Draw()
    self:DrawModel()
end

function ENT:ShowDocument(name)
    self.frame = vgui.Create("DPanel")
    local frame = self.frame
    frame:Dock(FILL)
    frame:MakePopup()

    function frame:Paint(w, h)
        surface.SetDrawColor(0, 0, 0, 230)
        surface.DrawRect(0, 0, w, h)
    end

    function frame:OnMouseReleased(mouseCode)
        if mouseCode == MOUSE_LEFT or mouseCode == MOUSE_RIGHT then
            self:Remove()
            RunConsoleCommand("cl_drawhud", "1")

            net.Start("CloseSCPDocument")
            net.SendToServer()
        end
    end

    RunConsoleCommand("cl_drawhud", "0")

    -- Actual document

    local page = frame:Add("DImage")
    page:Dock(FILL)

    local dockXVal, dockYVal = 600, 50
    page:DockMargin(dockXVal, dockYVal, dockXVal, dockYVal)

    page:SetImage("ryanm2711/scp_documents/" .. name)

    -- Play document pickup sound
    surface.PlaySound("ryanm2711/scp_documents/document_interact.ogg")
end

function ENT:HideDocument()
    if IsValid(self.frame) then 
        self.frame:Remove() 
        RunConsoleCommand("cl_drawhud", "1")

        net.Start("CloseSCPDocument")
        net.SendToServer()
    end
end

net.Receive("OpenSCPDocument", function()
    local document = net.ReadEntity()
    local documentMat = net.ReadString()
    
    document:ShowDocument(documentMat)
end)
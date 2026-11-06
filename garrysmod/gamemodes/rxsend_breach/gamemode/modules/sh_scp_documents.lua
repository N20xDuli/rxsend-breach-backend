local allowedExtensions = {
    [".png"] = true,
    [".vtf"] = true,
    [".jpg"] = true,
}

function GetDocumentMaterialNames()
    local files = file.Find("materials/ryanm2711/scp_documents/*_documentation*", "GAME")
    local names = {}

    for _, File in pairs(files) do
        local extension = string.sub(File, -4)
        if not allowedExtensions[extension] then continue end -- This extension is not valid

        local name = string.sub(File, 1, -5)
        names[name] = File
    end

    return names
end

local documentFileNames = {}

if SERVER then
    util.AddNetworkString("SCPDocumentFileInit")

    net.Receive("SCPDocumentFileInit", function(len, ply)
        local files = GetDocumentMaterialNames()

        net.Start("SCPDocumentFileInit") -- workaround for networking in init
            net.WriteString(util.TableToJSON(files))
        net.Send(ply)
    end)

    --[[RLib:LoadResourceFolder("materials/ryanm2711/scp_documents/")
    resource.AddFile("materials/ryanm2711/models/scp_documents/document_paper.vmt")
    resource.AddFile("models/ryanm2711/scp_documents/scp_document.mdl")
    resource.AddSingleFile("sound/ryanm2711/scp_documents/document_interact.ogg")
    resource.AddSingleFile("materials/ryanm2711/scp_documents/106_cell_documentation.jpg")
    resource.AddSingleFile("materials/ryanm2711/scp_documents/clearance_levels_documentation.jpg")
    resource.AddSingleFile("materials/ryanm2711/scp_documents/orientation_document.jpg")
    
    Gonna use workshop instead--]]
else
    hook.Add("InitPostEntity", "scp_document_file_init", function()
        net.Start("SCPDocumentFileInit") -- workaround for networking in init
        net.SendToServer()
    end)

    net.Receive("SCPDocumentFileInit", function()
        local jsonData = net.ReadString()
        local tbl = util.JSONToTable(jsonData)

        documentFileNames = tbl
    end)
end

properties.Add("documentchange", {
	MenuLabel = "更换文件", -- Name to display on the context menu
	Order = 0, -- The order to display this property relative to other properties
	MenuIcon = "icon16/page_white_edit.png", -- The icon to display next to the property

	Filter = function(self, ent, ply) -- A function that determines whether an entity is valid for this property
        return ( not ent:IsValid() or ent:GetClass() == "scp_document" or not gamemode.Call("CanProperty", ply, "documentchange", ent) and (ply:IsAdmin() or ply:IsSuperAdmin()) )
	end,

    MenuOpen = function(self, option, ent, tbl)
        local options = documentFileNames

        local submenu = option:AddSubMenu()

        ent.options = {}
        --ent.currentlySelected = "orientation_document.jpg"

        for k, v in pairs(options) do
            if ent.currentlySelected != v then
                ent.options[k] = submenu:AddOption(k, function() self:SetDocument(ent, v) end)
            end
        end
    end,
	
    Action = function(self, ent) -- The action to perform upon using the property (Clientside)
        -- Use custom func below
    end,

    SetDocument = function(self, ent, name)
        ent.currentlySelected = name

        self:MsgStart()
            net.WriteEntity(ent)
            net.WriteString(name)
        self:MsgEnd()
    end,
	
    Receive = function(self, length, ply) -- The action to perform upon using the property (Serverside)
        local document = net.ReadEntity()
        local newMaterial = net.ReadString()
        if not document:IsValid() or not ply:IsSuperAdmin() then return end

        document:SetDocumentMaterial(newMaterial)
	end 
} )
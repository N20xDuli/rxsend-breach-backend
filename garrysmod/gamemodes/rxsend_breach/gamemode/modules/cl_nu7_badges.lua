local emblem = Material("nextoren/gui/roles_icon/nu7.png", "smooth noclamp nocull")
emblem:SetInt("$nocull", 1)
local backing = CreateMaterial("scp_plus_nu7_patch_backing", "UnlitGeneric", {
    ["$basetexture"] = "vgui/white",
    ["$vertexcolor"] = "1",
    ["$nocull"] = "1",
})
local patchColor = Color(205, 209, 197)
local white = Color(255, 255, 255)

local function drawTriangles(vertices, material, color, emblemPass)
    render.SetMaterial(material)
    mesh.Begin(MATERIAL_TRIANGLES, #vertices / 3)
    for _, vertex in ipairs(vertices) do
        mesh.Position(emblemPass and vertex.emblemPos or vertex.pos)
        mesh.TexCoord(0, vertex.u, vertex.v)
        mesh.Color(color.r, color.g, color.b, 255)
        mesh.AdvanceVertex()
    end
    mesh.End()
end

-- Surface triangles keep the original skin weights and follow the animated mesh.
hook.Add("PostPlayerDraw", "Nu7_ShoulderBadges", function(ply)
    if not IsValid(ply) or not BREACH.Nu7 or not BREACH.Nu7.BadgeMeshes then return end
    local triangles = BREACH.Nu7.BadgeMeshes[string.lower(ply:GetModel() or "")]
    if not triangles then return end
    local matrices, vertices = {}, {}
    for _, triangle in ipairs(triangles) do
        for _, vertex in ipairs(triangle) do
            local pos, emblemPos = Vector(0,0,0), Vector(0,0,0)
            for _, skin in ipairs(vertex.weights) do
                local matrix = matrices[skin.bone]
                if not matrix then
                    local id = ply:LookupBone(skin.bone)
                    matrix = id and ply:GetBoneMatrix(id)
                    if not matrix then return end
                    matrices[skin.bone] = matrix
                end
                pos = pos + (matrix * skin.pos) * skin.weight
                emblemPos = emblemPos + (matrix * (skin.pos + skin.normal * 0.01)) * skin.weight
            end
            vertices[#vertices+1] = {pos=pos, emblemPos=emblemPos, u=vertex.u, v=vertex.v}
        end
    end
    drawTriangles(vertices, backing, patchColor)
    drawTriangles(vertices, emblem, white, true)
end)

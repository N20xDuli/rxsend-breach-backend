if not (BREACH and BREACH.SCP173SL) then include(engine.ActiveGamemode() .. "/gamemode/modules/sh_scp173_sl.lua") end
if SERVER then AddCSLuaFile() end
ENT.Type="anim"
ENT.Base="base_anim"
ENT.PrintName="SCP-173 排泄物"
ENT.Spawnable=false
ENT.RenderGroup=RENDERGROUP_TRANSLUCENT
local scp=BREACH.SCP173SL
if SERVER then
 function ENT:Initialize()
  self:SetModel("models/props_junk/garbage_bag001a.mdl");self:SetNoDraw(false)
  self:SetSolid(SOLID_NONE);self:SetMoveType(MOVETYPE_NONE)
  self:SetRenderMode(RENDERMODE_TRANSCOLOR);self:SetColor(Color(90,66,39,255))
  self.Expires=CurTime()+scp.Config.TantrumDuration
 end
 function ENT:OnTakeDamage(damage)
  if damage:IsDamageType(DMG_BLAST) then self:Remove() end
 end
 function ENT:Think()
  if self.Expires<=CurTime() then self:Remove();return end
  for _,ply in ipairs(ents.FindInSphere(self:GetPos(),scp.Config.TantrumRadius+40)) do
   if scp.IsEnemy(ply) and math.abs(ply:GetPos().z-self:GetPos().z)<48 then
    local delta=ply:GetPos()-self:GetPos()
    if delta.x^2+delta.y^2<=scp.Config.TantrumRadius^2 then
     local tr=util.TraceLine({start=self:GetPos()+Vector(0,0,24),endpos=ply:GetPos()+Vector(0,0,24),filter={self,ply},mask=MASK_VISIBLE})
     if not tr.Hit then ply:SetNWFloat("RX173StainedUntil",CurTime()+2) end
    end
   end
  end
  self:NextThink(CurTime()+.15);return true
 end
else
 local puddle=CreateMaterial("RX173TantrumPuddle","UnlitGeneric",{
  ["$basetexture"]="models/debug/debugwhite",["$vertexcolor"]="1",
  ["$vertexalpha"]="1",["$translucent"]="1",["$nocull"]="1"
 })
 function ENT:Initialize()
  local radius=scp.Config.TantrumRadius
  self:SetRenderBounds(Vector(-radius,-radius,-4),Vector(radius,radius,8))
 end
 function ENT:DrawTranslucent()
  render.SetMaterial(puddle)
  local point=self:GetPos()+Vector(0,0,1)
  local radius=scp.Config.TantrumRadius
  mesh.Begin(MATERIAL_TRIANGLES,48)
  for i=0,47 do
   local a=i*math.pi/24;local b=(i+1)*math.pi/24
   for _,vertex in ipairs({point,point+Vector(math.cos(a)*radius,math.sin(a)*radius,0),point+Vector(math.cos(b)*radius,math.sin(b)*radius,0)}) do
    mesh.Position(vertex);mesh.Normal(Vector(0,0,1));mesh.Color(72,43,20,155);mesh.TexCoord(0,0,0);mesh.AdvanceVertex()
   end
  end
  mesh.End()
 end
end

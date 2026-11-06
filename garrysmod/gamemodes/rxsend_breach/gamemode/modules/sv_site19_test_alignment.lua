-- Transitional repair for the locally compiled test BSP. Once recompiled with
-- the corrected VMF positions, the origin guard makes this a no-op.
local delta = Vector(221.559135437, 0, 0)
local origins = {
 [727015] = Vector(-2792,4080.5,53),
 [727025] = Vector(-2794,4138.5,63.75),
 [727028] = Vector(-2794,4024.5,63.75),
 [727019] = Vector(-2800,4080,8.5),
 [727022] = Vector(-2800,4080,24.5),
}
function BREACH_RepairSite19TestAlignment()
 if game.GetMap() ~= "rxsend_site19-1" then return end
 for _,ent in ipairs(ents.GetAll()) do
  local id = tonumber(ent:GetKeyValues().hammerid)
  local origin = origins[id]
  if origin and ent:GetPos():DistToSqr(origin) < 0.01 then
   local children = {}
   for _,child in ipairs(ent:GetChildren()) do
    children[#children+1] = {child,child:GetPos(),child:GetAngles()}
   end
   ent:SetPos(ent:GetPos()+delta)
   -- Visible door models were already moved by the user in Unity.
   for _,row in ipairs(children) do
    row[1]:SetPos(row[2]) row[1]:SetAngles(row[3])
   end
   print("[SITE19 TEST] aligned",id,ent:GetPos())
  end
 end
end
hook.Add("InitPostEntity","RXSite19TestAlignment",function()
 timer.Simple(0,BREACH_RepairSite19TestAlignment)
end)

hook.Add("PostCleanupMap", "RXSite19TestAlignment", function()
 timer.Simple(0, BREACH_RepairSite19TestAlignment)
end)

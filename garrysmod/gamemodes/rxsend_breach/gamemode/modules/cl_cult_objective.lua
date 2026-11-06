-- Ritual objectives use HUD markers rather than the legacy 3D render pass.
BREACH=BREACH or {}
local icon=Material("nextoren_hud/faction_icons/scarletspec.png","smooth")
local red=Color(244,83,96)
surface.CreateFont("RXCultObjectiveName",{font="Tahoma",size=18,weight=700,extended=true})
surface.CreateFont("RXCultObjectiveDistance",{font="Tahoma",size=15,weight=500,extended=true})
local function removeLegacyMarker()
 hook.Remove("PostDrawTranslucentRenderables","cult_draw_mark")
end
removeLegacyMarker()
hook.Add("InitPostEntity","RXCultObjectiveMarker",removeLegacyMarker)
timer.Simple(0,removeLegacyMarker)
function BREACH.ShouldShowCultObjective(ply,book)
 return IsValid(ply) and IsValid(book) and
  (ply:GTeam()==TEAM_COTSK or book:GetEnabled() or book:GetNWBool("COTSKPraying",false))
end
hook.Add("HUDPaint","RXCultObjectiveMarker",function()
 local ply=LocalPlayer()
 if not IsValid(ply) or (BREACH.IsDeploymentIntroActive and BREACH.IsDeploymentIntroActive()) then return end
 for _,book in ipairs(ents.FindByClass("ent_cult_book"))do
  if BREACH.ShouldShowCultObjective(ply,book)then
   local pos=book:GetPos()+Vector(0,0,50)
   local point=pos:ToScreen();local w,h=ScrW(),ScrH()
   local x,y=point.x,point.y
   if (pos-ply:EyePos()):Dot(ply:EyeAngles():Forward())<0 then x=w-x;y=h-y end
   local outside=x<70 or x>w-70 or y<50 or y>h-95 or not point.visible
   x=math.Clamp(x,70,w-70);y=math.Clamp(y,50,h-95)
   draw.RoundedBox(5,x-23,y-23,46,46,Color(24,8,13,210))
   if not icon:IsError()then
    surface.SetDrawColor(255,255,255,255);surface.SetMaterial(icon);surface.DrawTexturedRect(x-19,y-19,38,38)
   else draw.SimpleText("◆","RXCultObjectiveName",x,y,red,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)end
   local status=book:GetEnabled() and "仪式进行中" or (book:GetNWBool("COTSKPraying",false) and "正在开祷" or "目标祷点")
   if outside then status="▶ "..status end
   draw.SimpleTextOutlined(status,"RXCultObjectiveName",x,y+28,red,TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP,1,Color(0,0,0,230))
   draw.SimpleTextOutlined(string.format("%.0f 米",ply:GetPos():Distance(book:GetPos())*.0254),"RXCultObjectiveDistance",x,y+49,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP,1,Color(0,0,0,230))
  end
 end
end)

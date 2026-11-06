if not (BREACH and BREACH.SCP173SL) then include(engine.ActiveGamemode() .. "/gamemode/modules/sh_scp173_sl.lua") end
local scp=BREACH.SCP173SL
local cfg=scp.Config
surface.CreateFont("RX173SLStatus",{font="Microsoft YaHei",size=22,weight=650,extended=true})
local color=Color(221,204,155)
hook.Add("HUDPaint","RX173SLHUD",function()
 if BREACH.IsDeploymentIntroActive and BREACH.IsDeploymentIntroActive() then return end
 local owner=LocalPlayer();if not scp.Is173(owner) then return end
 local weapon=owner:GetActiveWeapon();if not IsValid(weapon) or weapon:GetClass()~="weapon_scp_173" then return end
 local remaining=math.max(0,weapon:GetSLBlinkStop()+cfg.BlinkCooldown*(weapon:GetSLFast() and .5 or 1)-CurTime())
 local state=weapon:GetSLWatching()>0 and "被注视 · 停止移动" or "无人注视 · 可移动"
 if weapon:GetSLFast() then state=state.."   疾速 · 无法扭脖子" end
 local y=ScrH()*.7
 draw.SimpleTextOutlined(state,"RX173SLStatus",ScrW()/2,y,color,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,color_black)
 local text=weapon:ReadyToBlink() and "眨眼就绪 · 右键选点，松开瞬移" or (remaining>0 and string.format("眨眼 %.1f 秒",remaining) or "右键：被注视时可眨眼瞬移")
 draw.SimpleTextOutlined(text,"RX173SLStatus",ScrW()/2,y+30,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,1,color_black)
end)
hook.Add("PostDrawTranslucentRenderables","RX173SLBlinkPreview",function(_,sky)
 if sky then return end
 if BREACH.IsDeploymentIntroActive and BREACH.IsDeploymentIntroActive() then return end
 local owner=LocalPlayer();if not scp.Is173(owner) or not owner:KeyDown(IN_ATTACK2) then return end
 local weapon=owner:GetActiveWeapon();if not IsValid(weapon) or weapon:GetClass()~="weapon_scp_173" then return end
 local point=scp.BlinkPosition(owner,cfg.BlinkDistance*(weapon:GetSLFast() and 1.8 or 1))
 if not point then return end
 local tint=weapon:ReadyToBlink() and Color(220,215,170,160) or Color(170,60,50,100)
 render.SetColorMaterial();render.DrawQuadEasy(point+Vector(0,0,1),Vector(0,0,1),34,34,tint,0)
 render.DrawWireframeBox(point,angle_zero,Vector(-16,-16,0),Vector(16,16,72),tint,false)
end)

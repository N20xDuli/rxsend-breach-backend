local terminal={open=false,mode=0,rows={},page=1}
local targets={};local marksmanUntil=0
local scanTargets={};local scanUntil=0
local blue=Color(91,181,255)
local text=Color(226,240,249)
function BREACH.IsNu7TerminalOpen() return terminal.open end
surface.CreateFont("NU7TerminalTitle",{font="Tahoma",size=23,weight=700,extended=true})
surface.CreateFont("NU7TerminalText",{font="Tahoma",size=17,weight=500,extended=true})
surface.CreateFont("NU7TerminalSmall",{font="Tahoma",size=14,weight=500,extended=true})

local function closeTerminal()
 terminal.open=false
 if IsValid(terminal.frame) then terminal.frame:Remove() end
 terminal.frame=nil
 gui.EnableScreenClicker(false)
end
local function request(mode)
 if (terminal.nextRequest or 0)>CurTime() then return end
 if mode<2 and LocalPlayer():GetNWFloat("Nu7ScanReady",0)>CurTime() then return end
 terminal.requestedAt=CurTime();terminal.nextRequest=CurTime()+.55;terminal.pending=mode<2
 net.Start("NU7TerminalRequest");net.WriteUInt(mode,2);net.SendToServer()
 if mode==2 then closeTerminal() end
end
net.Receive("NU7TerminalOpen",function()
 if not BREACH.Nu7.CanUseEquipment(LocalPlayer(),"commander") then return end
 terminal.open=true;terminal.opened=CurTime();terminal.page=1
 if BREACH.Abilities and IsValid(BREACH.Abilities.TipWindow) then BREACH.Abilities.TipWindow:Remove() end
 gui.EnableScreenClicker(true)
 terminal.pending=false
 BREACH.OpenNu7TerminalUI()
end)
net.Receive("NU7TerminalResult",function()
 local mode=net.ReadUInt(2);local count=net.ReadUInt(7);local rows={}
 for i=1,count do rows[i]={entity=net.ReadEntity(),pos=net.ReadVector(),name=net.ReadString(),health=net.ReadUInt(16)} end
 if not terminal.open or not BREACH.Nu7.CanUseEquipment(LocalPlayer(),"commander") then return end
 terminal.mode=mode;terminal.rows=rows;terminal.page=1;terminal.pending=false;terminal.last=CurTime()
end)
net.Receive("NU7MarksmanTargetsV2",function()
 local rows={};for i=1,net.ReadUInt(7) do rows[#rows+1]=net.ReadUInt(16) end
 targets=rows;marksmanUntil=net.ReadFloat()
end)

net.Receive("NU7ScanTargets",function()
 scanTargets={}
 for i=1,net.ReadUInt(7) do scanTargets[#scanTargets+1]=net.ReadUInt(16) end
 scanUntil=net.ReadFloat()
end)
hook.Add("PreDrawOutlines","NU7TeamScan",function()
 local ply=LocalPlayer()
 if not IsValid(ply) or not ply:Alive() or ply:GTeam()~=TEAM_NU7 then scanTargets={};scanUntil=0;return end
 if scanUntil<=CurTime() then scanTargets={};return end
 if BREACH.IsDeploymentIntroActive and BREACH.IsDeploymentIntroActive() then return end
 local visible={}
 for _,index in ipairs(scanTargets) do local ent=Entity(index);if IsValid(ent) and ent:Alive() and ent:Health()>0 then visible[#visible+1]=ent end end
 if #visible>0 then outline.Add(visible,Color(255,40,40),0) end
end)

hook.Remove("PreDrawHalos","NU7MarksmanVision")
hook.Add("PreDrawOutlines","NU7MarksmanVision",function()
 local ply=LocalPlayer()
 if not BREACH.Nu7.CanUseEquipment(ply,"marksman") or marksmanUntil<=CurTime() then return end
 if BREACH.IsDeploymentIntroActive and BREACH.IsDeploymentIntroActive() then return end
 local visible={}
 for _,index in ipairs(targets) do
  local ent=Entity(index)
  if IsValid(ent) and ent:Alive() and ply:GetPos():DistToSqr(ent:GetPos())<=BREACH.Nu7.SkillConfig.MarksmanRadius^2 then visible[#visible+1]=ent end
 end
 if #visible>0 then outline.Add(visible,blue,OUTLINE_MODE_BOTH or 0) end
end)

local buttons={{id=0,x=24,y=68,w=210,h=40,label="扫描 SCP"},{id=1,x=250,y=68,w=210,h=40,label="扫描未知人员"},
 {id=2,x=476,y=68,w=210,h=40,label="查验面前身份"},{id=3,x=710,y=17,w=30,h=30,label="×"},
 {id=4,x=530,y=420,w=86,h=28,label="上一页"},{id=5,x=632,y=420,w=86,h=28,label="下一页"}}
hook.Remove("GUIMousePressed","NU7TerminalClick")
hook.Remove("PostDrawTranslucentRenderables","NU7VirtualTerminal")

-- Actual virtual panel painter, also used by the geometry preview.
function BREACH.PaintNu7Terminal(state,ply,mx,my)
 if state.pending and CurTime()-(state.requestedAt or 0)>2 then state.pending=false end
 draw.RoundedBox(8,0,0,760,470,Color(8,18,29,240))
 surface.SetDrawColor(52,114,158,190);surface.DrawOutlinedRect(0,0,760,470,2)
 draw.SimpleText("NU-7 / 战术指挥终端","NU7TerminalTitle",24,18,text)
 draw.SimpleText("基金会 · 便携式战术终端","NU7TerminalSmall",26,46,blue)
 for _,box in ipairs(buttons) do
  local hover=mx and mx>=box.x and mx<=box.x+box.w and my>=box.y and my<=box.y+box.h
  draw.RoundedBox(3,box.x,box.y,box.w,box.h,hover and Color(43,100,139) or Color(20,46,65))
  local label=box.label
  local remaining=math.ceil(ply:GetNWFloat("Nu7ScanReady",0)-CurTime())
  if box.id<2 and remaining>0 then label=label.." ("..remaining.."s)" end
  draw.SimpleText(label,"NU7TerminalText",box.x+box.w/2,box.y+box.h/2,text,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
 end
 draw.RoundedBox(4,24,124,278,280,Color(9,28,42,230))
 surface.SetDrawColor(42,91,122,160)
 for r=32,112,40 do surface.DrawCircle(163,264,r,42,91,122,180) end
 surface.DrawLine(51,264,275,264);surface.DrawLine(163,152,163,376)
 draw.SimpleText("设施扫描","NU7TerminalSmall",42,138,blue)
 draw.SimpleText("+","NU7TerminalTitle",163,264,blue,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
 local span=1
 for _,row in ipairs(state.rows) do span=math.max(span,(row.pos-ply:GetPos()):Length2D()) end
 for _,row in ipairs(state.rows) do
  local delta=(row.pos-ply:GetPos())/span
  draw.RoundedBox(2,163+delta.x*98-3,264-delta.y*98-3,6,6,state.mode==0 and Color(247,103,92) or blue)
 end
 local title=state.mode==2 and "身份查验" or (state.mode==0 and "异常信号" or "未知单位")
 draw.SimpleText(title.." / "..#state.rows,"NU7TerminalTitle",324,128,blue)
 for i=1,6 do
  local row=state.rows[(state.page-1)*6+i]
  if row then
   local y=170+(i-1)*38
   draw.RoundedBox(3,322,y,408,33,Color(18,36,49))
   local name=state.mode==1 and row.name or GetLangRole(row.name)
   draw.SimpleText(name,"NU7TerminalText",332,y+6,text)
   draw.SimpleText(string.format("%.0f 米 · %d 生命",row.pos:Distance(ply:GetPos())*.0254,row.health),"NU7TerminalSmall",719,y+9,blue,TEXT_ALIGN_RIGHT)
  end
 end
 if #state.rows==0 then draw.SimpleText(state.mode==2 and "对准面前的人，再点击查验" or (state.last and not state.pending and "未扫描到目标" or "选择扫描模式"),"NU7TerminalText",332,185,Color(126,158,177)) end
 local status=state.pending and "扫描中…" or (state.last and (#state.rows==0 and "未扫描到目标 · 未消耗扫描冷却" or "扫描完成 · 全队标记 10 秒") or "选择扫描模式")
 draw.SimpleText(status,"NU7TerminalSmall",26,423,blue)
 draw.SimpleText("滚轮切回武器 / 点击 × 关闭","NU7TerminalSmall",26,446,Color(126,158,177))
 draw.SimpleText(string.format("%d / %d",state.page,math.max(1,math.ceil(#state.rows/6))),"NU7TerminalSmall",454,434,text)
end

function BREACH.OpenNu7TerminalUI()
 timer.Remove("Remove_Desc")
 if IsValid(BREACH_DESC_LOGO) then BREACH_DESC_LOGO:Remove() end
 if IsValid(BREACH_DESC_PANEL) then BREACH_DESC_PANEL:Remove() end
 if IsValid(terminal.frame) then terminal.frame:Remove() end
 terminal.open=true
 local scale=math.min(1,(ScrW()-40)/760,(ScrH()-40)/470)
 local frame=vgui.Create("DPanel")
 terminal.frame=frame
 frame:SetSize(math.floor(760*scale),math.floor(470*scale));frame:Center();frame:MakePopup()
 frame:SetKeyboardInputEnabled(false)
 frame.Paint=function(self)
  local mx,my=self:LocalCursorPos()
  local matrix=Matrix();matrix:Scale(Vector(scale,scale,1))
  cam.PushModelMatrix(matrix,true)
  BREACH.PaintNu7Terminal(terminal,LocalPlayer(),mx/scale,my/scale)
  cam.PopModelMatrix()
 end
 frame.OnMousePressed=function(self,key)
  if key~=MOUSE_LEFT then return end
  local x,y=self:LocalCursorPos();x=x/scale;y=y/scale
  for _,box in ipairs(buttons) do
   if x>=box.x and x<=box.x+box.w and y>=box.y and y<=box.y+box.h then
    if box.id<3 then request(box.id)
    elseif box.id==3 then closeTerminal()
    elseif box.id==4 then terminal.page=math.max(1,terminal.page-1)
    else terminal.page=math.min(math.max(1,math.ceil(#terminal.rows/6)),terminal.page+1) end
    return
   end
  end
 end
 frame.Think=function()
  local ply=LocalPlayer()
  if not IsValid(ply) then closeTerminal();return end
  local wep=ply:GetActiveWeapon()
  if not BREACH.Nu7.CanUseEquipment(ply,"commander")
   or (CurTime()>(terminal.opened or 0)+.75 and (not IsValid(wep) or wep:GetClass()~="item_nu7_terminal"))
   or (BREACH.IsDeploymentIntroActive and BREACH.IsDeploymentIntroActive()) then closeTerminal() end
 end
 frame.OnRemove=function(self)
  if terminal.frame==self then terminal.frame=nil;terminal.open=false;gui.EnableScreenClicker(false) end
 end
 return frame
end
hook.Add("PlayerButtonDown","NU7TerminalEscape",function(ply,key)
 if ply==LocalPlayer() and terminal.open and key==KEY_ESCAPE then closeTerminal() end
end)

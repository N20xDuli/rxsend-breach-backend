BREACH = BREACH or {}
BREACH.SupportSelection = BREACH.SupportSelection or {}
local UI = BREACH.SupportSelection
local C = {bg=Color(9,15,24,250), card=Color(16,27,40), edge=Color(45,65,84),
    ink=Color(234,241,247), soft=Color(188,205,220), blue=Color(97,177,248),
    green=Color(100,214,173), red=Color(232,116,119), hover=Color(23,41,59)}

function UI.RoleTable(teamID, ply)
    local names = {[TEAM_GOC]={"GOC","goc"},[TEAM_CHAOS]={"CHAOS","chaos"},
        [TEAM_USA]={"FBI","fbi"},[TEAM_NTF]={"NTF","ntf"},[TEAM_DZ]={"DZ","dz"},
        [TEAM_GRU]={"GRU","gru"},[TEAM_COTSK]={"COTSK","cotsk"}}
    local key = names[teamID]
    if teamID == TEAM_USA and BREACH:IsUiuAgent(ply:GetRoleName()) then key={"FBI_AGENTS","fbi_agents"} end
    local group = key and BREACH_ROLES[key[1]] and BREACH_ROLES[key[1]][key[2]]
    return group and group.roles
end

function UI.State(ply, entry, id)
    local count = 0
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:GetRoleName() == entry.name then count=count+1 end
    end
    local queued = (BREACH.SelectedRoles or {})[id] or 0
    if entry.name == ply:GetRoleName() then return "current", "当前角色", count, queued end
    if ply:GetNLevel() < (entry.level or 0) then return "locked", "需要等级 " .. entry.level, count, queued end
    if count + queued >= (entry.max or 0) then return "locked", "角色名额已满", count, queued end
    return "ready", "可选择", count, queued
end

local function setupModel(panel, entry, current)
    local model = current and current:GetModel() or entry.showmodel or entry.model
    if not model or not util.IsValidModel(model) then panel.MissingModel=true;return end
    panel:SetModel(model)
    local ent=panel.Entity
    if not IsValid(ent) then panel.MissingModel=true;return end
    ent:SetSkin(current and current:GetSkin() or entry.skin or 0)
    for i=0,15 do if entry["bodygroup"..i] then ent:SetBodygroup(i,entry["bodygroup"..i]) end end
    if current then
        for _, group in ipairs(current:GetBodyGroups()) do ent:SetBodygroup(group.id,current:GetBodygroup(group.id)) end
    end
    if panel.BoneMerged then
        local function merge(path) if path and util.IsValidModel(path) then panel:BoneMerged(path) end end
        merge(entry.head or (entry.usehead and "models/cultist/heads/male/male_head_1.mdl"))
        merge(entry.headgear)
    end
    local sequence=ent:LookupSequence("idle_all_01")
    if sequence<0 then sequence=ent:LookupSequence("idle") end
    if sequence>=0 then ent:ResetSequence(sequence) end
    local lo,hi=ent:OBBMins(),ent:OBBMaxs()
    local center=(lo+hi)*.5
    local extent=math.max(hi.z-lo.z,hi.x-lo.x,hi.y-lo.y,50)
    panel:SetFOV(35);panel:SetLookAt(center);panel:SetCamPos(center+Vector(extent*1.65,0,extent*.08))
    panel:SetAmbientLight(Color(125,140,156))
    panel:SetDirectionalLight(BOX_FRONT,Color(235,241,249));panel:SetDirectionalLight(BOX_RIGHT,Color(120,168,206))
    panel:SetMouseInputEnabled(false)
    panel.LayoutEntity=function(_, entity) entity:SetAngles(Angle(0,0,0)) end
    panel.RunAnimation=function() end
end

function UI.Open(teamID)
    local ply=LocalPlayer()
    if not IsValid(ply) or not ply:Alive() or ply:GTeam()~=teamID then return end
    if (BREACH.IsDeploymentIntroActive and BREACH.IsDeploymentIntroActive())
        or IsValid(ply:GetNWEntity("NTF1Entity")) then
        UI.Pending={team=teamID,role=ply:GetRoleName()}
        return
    end
    UI.Pending=nil
    if ply:GetRoleName()==role.Chaos_Demo or ply:GetRoleName()==role.GRU_Commander or ply:GetRoleName()==role.Cult_Commander then
        BREACH.Player:ChatPrint(true,true,"l:supp_pick_cant");return
    end
    local roles=UI.RoleTable(teamID,ply)
    if not roles then return end
    local entries={}
    for id, entry in ipairs(roles) do
        if id<=15 and (entry.name~=role.UIU_Clocker or ply:GetRoleName()==role.UIU_Clocker) then entries[#entries+1]={role=entry,id=id} end
    end
    if #entries==0 then return end
    local old=BREACH.Demote and BREACH.Demote.MainPanel
    if IsValid(old) then
        if IsValid(old.Disclaimer) then old.Disclaimer:Remove() end
        old:Remove()
    end
    BREACH.Demote=BREACH.Demote or {}
    local scale=math.min(1,(ScrW()-40)/1160,(ScrH()-40)/650)
    local function S(n) return math.floor(n*scale+.5) end
    for name,spec in pairs({Title={25,700},Heading={19,650},Body={18,600},Small={15,600},Code={14,600}}) do
        surface.CreateFont("RXRolePick"..name,{font="Microsoft YaHei",size=S(spec[1]),weight=spec[2],extended=true})
    end
    local function text(s,font,x,y,color,ax,ay) draw.SimpleText(s,"RXRolePick"..font,S(x),S(y),color or C.ink,ax or TEXT_ALIGN_LEFT,ay or TEXT_ALIGN_TOP) end
    local function box(x,y,w,h,color) draw.RoundedBox(S(6),S(x),S(y),S(w),S(h),color) end
    local frame=vgui.Create("DFrame");BREACH.Demote.MainPanel=frame;Select_Menu_enabled=true
    frame:SetSize(S(1160),S(650));frame:Center();frame:SetTitle("");frame:ShowCloseButton(false)
    frame:SetDraggable(false);frame:SetDeleteOnClose(true);frame:MakePopup()
    frame.DieTime=ply:GetNWFloat("RXSelectionEnds",0);if frame.DieTime<=0 then frame.DieTime=CurTime()+45 end;local originalRole=ply:GetRoleName();local page=1;local pages=math.ceil(#entries/3)
    frame.Paint=function(self,w,h)
        box(0,0,1160,650,C.bg);surface.SetDrawColor(C.edge);surface.DrawOutlinedRect(0,0,w,h,1)
        text("人员 / 职责选择","Code",24,21,C.blue)
        text("支援角色自选","Title",24,42)
        text(gteams.GetName(teamID),"Small",24,79,C.soft)
        text("剩余 "..math.max(0,math.ceil(self.DieTime-CurTime())).." 秒","Small",1004,42,C.soft,TEXT_ALIGN_RIGHT)
        text("第 "..page.." / "..pages.." 页","Small",764,79,C.soft,TEXT_ALIGN_CENTER)
        surface.SetDrawColor(C.edge);surface.DrawRect(S(24),S(104),S(1112),1)
        text("名额会随其他玩家的选择更新","Small",24,620,C.soft)
        text("ESC / 退格 关闭","Small",1136,620,C.soft,TEXT_ALIGN_RIGHT)
    end
    frame.OnKeyCodePressed=function(self,key) if key==KEY_BACKSPACE or key==KEY_ESCAPE then self:Close() end end
    frame.Think=function(self)
        if IsValid(ply) then local deadline=ply:GetNWFloat("RXSelectionEnds",0);if deadline>0 then self.DieTime=deadline end end
        if not IsValid(ply) or not ply:Alive() or ply:GTeam()~=teamID or ply:GetRoleName()~=originalRole or CurTime()>=self.DieTime then self:Close() end
    end
    frame.OnRemove=function(self)
        if BREACH.Demote.MainPanel==self then BREACH.Demote.MainPanel=nil;Select_Menu_enabled=false end
    end
    local function button(parent,x,y,w,h,label,fn)
        local b=vgui.Create("DButton",parent);b:SetPos(S(x),S(y));b:SetSize(S(w),S(h));b:SetText("")
        b.Paint=function(self) box(0,0,w,h,self:IsHovered() and C.hover or C.card);text(label,"Body",w/2,h/2,C.ink,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER) end
        b.DoClick=fn;return b
    end
    button(frame,1101,24,35,35,"×",function() frame:Close() end)
    local current={name=originalRole,model=ply:GetModel()}
    for _, entry in ipairs(roles) do if entry.name==originalRole then current=entry;break end end
    local sidebar=vgui.Create("DPanel",frame);sidebar:SetPos(S(856),S(120));sidebar:SetSize(S(280),S(478))
    sidebar.Paint=function()
        box(0,0,280,478,C.card);text("当前身份","Code",20,20,C.blue)
        text(GetLangRole(originalRole),"Body",20,49)
        text("等级 "..ply:GetNLevel(),"Small",20,376,C.soft)
        text("确认角色前可浏览全部卡片","Small",20,408,C.soft)
        text("请选择适合当前任务的角色","Small",20,433,C.soft)
    end
    local avatar=vgui.Create("DModelPanel",sidebar);avatar:SetPos(S(16),S(82));avatar:SetSize(S(248),S(275));setupModel(avatar,current,ply)
    local function choose(entry,id)
        if frame.Sent or not IsValid(frame) then return end
        local status=UI.State(ply,entry,id)
        if status=="current" then frame:Close();return end
        if status~="ready" then return end
        frame.Sent=true;net.Start("changesupport");net.WriteUInt(id,4);net.SendToServer();frame:Close()
        timer.Simple(.5,function() if IsValid(LocalPlayer()) then DrawNewRoleDesc() end end)
    end
    local content
    local function buildPage()
        if IsValid(content) then content:Remove() end
        content=vgui.Create("DPanel",frame);content:SetPos(S(24),S(120));content:SetSize(S(808),S(478));content.Paint=function() end
        for column=1,3 do
            local item=entries[(page-1)*3+column]
            if item then
                local entry,id=item.role,item.id
                local card=vgui.Create("DPanel",content);card:SetPos(S((column-1)*276),0);card:SetSize(S(256),S(478))
                card.Paint=function()
                    local state,label,count,queued=UI.State(ply,entry,id)
                    local accent=state=="locked" and C.red or state=="current" and C.green or C.blue
                    box(0,0,256,478,C.card);box(0,0,256,3,accent)
                    text(GetLangRole(entry.name),"Body",16,19)
                    text(label,"Small",16,48,accent)
                    surface.SetDrawColor(C.edge);surface.DrawRect(S(16),S(312),S(224),1)
                    text("等级要求","Small",16,330,C.soft);text(tostring(entry.level or 0),"Small",240,330,C.ink,TEXT_ALIGN_RIGHT)
                    text("生命 / 基础跑速","Small",16,356,C.soft)
                    text((entry.health or 100).." / "..math.Round(231*(entry.runspeed or 1)),"Small",240,356,C.ink,TEXT_ALIGN_RIGHT)
                    text("名额","Small",16,382,C.soft);text(count+queued.." / "..(entry.max or 0),"Small",240,382,C.ink,TEXT_ALIGN_RIGHT)
                end
                local model=vgui.Create("DModelPanel",card);model:SetPos(S(8),S(76));model:SetSize(S(240),S(228));setupModel(model,entry)
                model.PaintOver=function(_,w,h)
                    if UI.State(ply,entry,id)~="locked" then return end
                    surface.SetDrawColor(166,53,61,22);surface.DrawRect(0,0,w,h)
                    surface.SetDrawColor(211,82,91,38)
                    for d=0,w+h,S(20) do
                        surface.DrawLine(math.min(d,w),math.max(0,d-w),math.max(0,d-h),math.min(d,h))
                    end
                end
                if model.MissingModel then
                    local notice=vgui.Create("DPanel",card);notice:SetPos(S(8),S(76));notice:SetSize(S(240),S(228))
                    notice.Paint=function() text("模型资源未就绪","Small",120,114,C.soft,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER) end
                end
                local select=button(card,16,422,224,38,"",function() choose(entry,id) end)
                select.Paint=function(self)
                    local state,label=UI.State(ply,entry,id)
                    local ready=state=="ready"
                    box(0,0,224,38,ready and (self:IsHovered() and Color(57,118,172) or Color(35,84,128)) or Color(30,39,49))
                    text(state=="current" and "当前角色" or ready and "选择此角色  →" or label,"Body",112,19,ready and C.ink or C.soft,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
                end
            end
        end
    end
    button(frame,690,66,32,28,"‹",function() if page>1 then page=page-1;buildPage() end end)
    button(frame,807,66,32,28,"›",function() if page<pages then page=page+1;buildPage() end end)
    buildPage()
end

-- Selection requests can arrive while either entry card or original camera scene is active.
hook.Add("Think","RXRoleSelectionAfterEntry",function()
 local pending=UI.Pending
 if not pending then return end
 local ply=LocalPlayer()
 if not IsValid(ply) or not ply:Alive() or ply:GTeam()~=pending.team or ply:GetRoleName()~=pending.role then UI.Pending=nil;return end
 if BREACH.IsDeploymentIntroActive and BREACH.IsDeploymentIntroActive() then return end
 if IsValid(ply:GetNWEntity("NTF1Entity")) then return end
 UI.Pending=nil;UI.Open(pending.team)
end)

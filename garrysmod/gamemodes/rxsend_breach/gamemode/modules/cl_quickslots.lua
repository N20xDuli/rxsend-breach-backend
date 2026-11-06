BREACH.QuickSlots=BREACH.QuickSlots or {}
local slots=BREACH.QuickSlots
slots.bindings=slots.bindings or {}
local keys={KEY_1,KEY_2,KEY_3}
local held={}
local path="breach/quickslots.json"
local saved=util.JSONToTable(file.Read(path,"DATA") or "") or {}
for i=1,3 do
 local class=saved[tostring(i)]
 if isstring(class) and #class<=128 and class:match("^[%w_%-]+$") then slots.bindings[i]=class end
end
surface.CreateFont("BreachQuickSlotKey",{font="Tahoma",size=19,weight=700,extended=true})
surface.CreateFont("BreachQuickSlotSmall",{font="Tahoma",size=12,weight=500,extended=true})

function slots.Attach(panel,getItem)
 panel.QuickSlotItem=getItem
 panel:SetTooltip("悬停物品，按 1 / 2 / 3 绑定快捷键")
end
function slots.Bind(index,item)
 if index~=1 and index~=2 and index~=3 then return false end
 local ply=LocalPlayer()
 if not IsValid(item) or not item.IsWeapon or not item:IsWeapon() or item:GetOwner()~=ply or not ply:HasWeapon(item:GetClass()) then return false end
 local class=item:GetClass()
 for i=1,3 do if slots.bindings[i]==class then slots.bindings[i]=nil end end
 slots.bindings[index]=class
 local data={};for i=1,3 do data[tostring(i)]=slots.bindings[i] end
 file.CreateDir("breach");file.Write(path,util.TableToJSON(data))
 surface.PlaySound("buttons/button14.wav")
 return true
end
local function inventoryOpen()
 return IsEQVisible and IsEQVisible() and IsValid(BREACH.Inventory)
end
local function enabled()
 local ply=LocalPlayer()
 if not IsValid(ply) or not ply:Alive() or ply:IsTyping() or ply:IsFrozen() then return false end
 local lootOpen=inventoryOpen() and BREACH.Inventory.RXInventoryTactical and BREACH.Inventory.IsLooting
 if ply.MovementLocked and not lootOpen then return false end
 -- CW uses the number keys for attachments; leave both input paths to CW.
 local weapon=ply:GetActiveWeapon()
 if IsValid(weapon) and CW_CUSTOMIZE~=nil and weapon.dt and weapon.dt.State==CW_CUSTOMIZE then return false end
 if not CanShowEQ or not CanShowEQ() or gui.IsGameUIVisible() then return false end
 if BREACH.IsDeploymentIntroActive and BREACH.IsDeploymentIntroActive() then return false end
 if not inventoryOpen() and (vgui.CursorVisible() or IsValid(vgui.GetKeyboardFocus())) then return false end
 return true
end
function slots.Press(index)
 if not enabled() then return false end
 if inventoryOpen() then
  local panel=vgui.GetHoveredPanel()
  while IsValid(panel) and panel~=BREACH.Inventory do
   if panel.QuickSlotItem then return slots.Bind(index,panel.QuickSlotItem()) end
   panel=panel:GetParent()
  end
  return false
 end
 local class=slots.bindings[index]
 if not class then return false end
 if LocalPlayer():HasWeapon(class) then LocalPlayer():SelectWeapon(class) end
 return true
end
-- Keep saved bindings, but close transient UI on death/observer transitions.
hook.Add("Think","BreachQuickSlotLifeCycle",function()
 local ply=LocalPlayer()
 if not IsValid(ply) then return end
 if not ply:Alive() or ply:Health()<=0 or ply:GTeam()==TEAM_SPEC then
  ply.DoWeaponSwitch=nil
  if IsEQVisible and IsEQVisible() and HideEQ then HideEQ(false) end
 end
end)
-- Polling also works while the inventory's screen clicker owns keyboard focus.
hook.Add("Think","BreachQuickSlotInput",function()
 for i,key in ipairs(keys) do
  local down=input.IsKeyDown(key)
  if down and not held[i] then slots.Press(i) end
  held[i]=down
 end
end)
hook.Add("PlayerBindPress","BreachQuickSlotDefaultSelection",function(_,bind,pressed)
 if not pressed or not enabled() then return end
 local index=tonumber(bind:match("^slot([123])$"))
 if index and (inventoryOpen() or slots.bindings[index]) then return true end
end)

function slots.Paint(ply,x,y,size,gap)
 local active=IsValid(ply.DoWeaponSwitch) and ply.DoWeaponSwitch or ply:GetActiveWeapon()
 for i=1,3 do
  local left=x+(i-1)*(size+gap);local class=slots.bindings[i]
  local item=class and ply:GetWeapon(class)
  local owned=IsValid(item)
  local definition=owned and item or nil
  local selected=owned and active==item
  surface.SetDrawColor(15,19,24,owned and 210 or 150);surface.DrawRect(left,y,size,size)
  local icon=definition and definition.InvIcon
  if icon then
   surface.SetMaterial(isstring(icon) and Material(icon) or icon)
   surface.SetDrawColor(255,255,255,owned and 255 or 65);surface.DrawTexturedRect(left+4,y+4,size-8,size-8)
  elseif owned then
   draw.SimpleText(BREACH.InventoryUIText and BREACH.InventoryUIText.Name(item) or "物品","BreachQuickSlotSmall",left+size/2,y+size/2,Color(190,197,204),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
  end
  surface.SetDrawColor(selected and Color(68,134,255) or Color(222,226,231,owned and 210 or 80))
  surface.DrawOutlinedRect(left,y,size,size,selected and 3 or 1)
  draw.SimpleText(i,"BreachQuickSlotKey",left+6,y+3,Color(235,239,245),TEXT_ALIGN_LEFT)
  if owned and item.Primary and (tonumber(item.Primary.ClipSize) or 0)>0 and item:Clip1()>=0 then
   draw.SimpleText(item:Clip1(),"BreachQuickSlotSmall",left+size-6,y+size-17,Color(235,94,91),TEXT_ALIGN_RIGHT)
  end
 end
end
hook.Add("HUDPaint","BreachQuickSlotPreview",function()
 if BREACH.CombatHUD and BREACH.CombatHUD.Enabled() then return end
 local ply=LocalPlayer()
 if not IsValid(ply) or not ply:Alive() or ply:Health()<=0 or ply:GTeam()==TEAM_SPEC or not CanShowEQ() then return end
 if BREACH.IsDeploymentIntroActive and BREACH.IsDeploymentIntroActive() then return end
 local size=math.Clamp(math.floor(64*ScrH()/1080),54,72);local gap=8
 local x=ScrW()-56-size*3-gap*2;local y=ScrH()-size-18
 slots.Paint(ply,x,y,size,gap)
 if inventoryOpen() then draw.SimpleText("悬停物品 · 按 1 / 2 / 3 绑定","BreachQuickSlotSmall",x,y-18,Color(223,231,240)) end
end)

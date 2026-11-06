-- Ordinary client files are distributed by shared.lua. This optional legacy
-- live patcher is disabled by default; cold startup does not depend on it.
local syncEnabled = GetConVar("breach_legacy_client_sync") or CreateConVar(
 "breach_legacy_client_sync", "0", FCVAR_ARCHIVE, "Enable legacy live client patches (restart required).", 0, 1)
timer.Remove("RXGameplayClientFixes")
hook.Remove("PlayerInitialSpawn", "RXGameplayClientFixes")
if not syncEnabled:GetBool() then return end

local function installLegacyClientSync()
-- Reconcile these small gameplay fixes for clients after a live file update.
-- Replace closures with their original upvalues, preserving HUD/chat UI state.
local channel="RXGameplayClientFixes"
util.AddNetworkString(channel)
util.AddNetworkString(channel.."Ack")
local hud=file.Read(engine.ActiveGamemode() .. "/gamemode/modules/cl_hud_new.lua","LUA")
local chat=file.Read("chatbox/cl_chatbox.lua","LUA")
local stamina=file.Read(engine.ActiveGamemode() .. "/gamemode/modules/sh_scp3114_stamina.lua","LUA")
local slots=file.Read(engine.ActiveGamemode() .. "/gamemode/modules/cl_quickslots.lua","LUA")
assert(hud and chat and slots and stamina,"gameplay client source missing")
local inventory=assert(file.Read(engine.ActiveGamemode() .. "/gamemode/modules/sh_player.lua","LUA"),"inventory source missing")
local inventoryFirst=assert(inventory:find('local function DrawNewInventory(',1,true))
local inventoryLast=assert(inventory:find('\n--[[function DrawEQ()',inventoryFirst,true))
local inventoryFunction=inventory:sub(inventoryFirst,inventoryLast-1):gsub('^local function DrawNewInventory%(','return function(')
local layoutFirst=assert(inventory:find('surv.LayoutEntity = function(self, ent)',inventoryFirst,true))
local layoutLast=assert(inventory:find('\n\tsurv:SetCursor("arrow")',layoutFirst,true))
local inventoryLayout=inventory:sub(layoutFirst,layoutLast-1):gsub('^surv.LayoutEntity = function%(','return function(')
local showFirst=assert(inventory:find('function ShowEQ(',1,true))
local showLast=assert(inventory:find('function HideEQ(',showFirst,true))
local showFunction=inventory:sub(showFirst,showLast-1):gsub('^function ShowEQ%(','return function(')


local first=assert(hud:find('hook.Add( "HUDPaint", "Breach_HUD", function()',1,true))
local last=assert(hud:find('\nlocal offset = Vector( 0, 0, 85 )',first,true))
local hudFunction=hud:sub(first,last-1):gsub('^hook.Add%( "HUDPaint", "Breach_HUD", function%(%)','return function()'):gsub('end %)%s*$','end')
first=assert(chat:find('function LOUNGE_CHAT:OnPlayerChat(',1,true))
last=assert(chat:find('\n-- for developers.',first,true))
local chatFunction=chat:sub(first,last-1):gsub('^function LOUNGE_CHAT:OnPlayerChat%(','return function(self,')
-- Add and OnPlayerChat must share the SAME lexical con/tab cells. Copying the
-- old helper captures its old cells while the new handler resets different ones.
local helperFirst=assert(chat:find('local function Add(',1,true))
local helperLast=assert(chat:find('\nlocal mply = FindMetaTable',helperFirst,true))
local chatHelper='local con, tab = {}, {}\n'..chat:sub(helperFirst,helperLast-1)

local observer=assert(file.Read(engine.ActiveGamemode() .. "/gamemode/modules/cl_admin_observer.lua","LUA"))
local drawFirst=assert(observer:find('local function drawHelp()',1,true))
local drawLast=assert(observer:find('local funnywh = false',drawFirst,true))
local observerDraw=observer:sub(drawFirst,drawLast-1):gsub('^local function drawHelp%(','return function(')
local thinkFirst=assert(observer:find('hook.Add("Think", "FSpectate_AdminObserver", function()',1,true))
local observerThink=observer:sub(thinkFirst):gsub('^hook.Add%("Think", "FSpectate_AdminObserver", function%(%)','return function()'):gsub('end%)%s*%-%-end%s*$','end')
local nu7Source=assert(file.Read(engine.ActiveGamemode() .. "/gamemode/modules/sh_nu7.lua","LUA"))
local fFirst=assert(nu7Source:find('nu7.FoundationTeams = {',1,true))
local fLast=assert(nu7Source:find('function nu7.GetSupportCount(',fFirst,true))
local foundation='local nu7=BREACH.Nu7\n'..nu7Source:sub(fFirst,fLast-1)
local friendFirst=assert(inventory:find('local friendstable = {',1,true))
local friendLast=assert(inventory:find('local neutralstable = {',friendFirst,true))
local friendship=inventory:sub(friendFirst,friendLast-1)
local commandStaff=assert(file.Read(engine.ActiveGamemode() .. "/gamemode/modules/sh_command_staff.lua","LUA"))

local source=[=[
local function replaceClosure(old,body,prefix,replacement)
 assert(isfunction(old),"original client handler missing")
 local names,values={},{}
 for i=1,100 do
  local name,value=debug.getupvalue(old,i)
  if not name then break end
  names[i]=name
  if istable(replacement) then values[i]=replacement[name] or value else values[i]=(replacement and name=="DrawNewInventory") and replacement or value end
 end
 local factory=CompileString("return function("..table.concat(names,",")..")\n"..(prefix or "").."\n"..body.."\nend","RXGameplayClosure",false)
 assert(isfunction(factory),tostring(factory))
 return factory()(unpack(values,1,#names))
end
]=]
source=source..'\nlocal hudBody='..string.format('%q',hudFunction)..'\nlocal chatBody='..string.format('%q',chatFunction)..'\nlocal chatHelper='..string.format('%q',chatHelper)
source=source..'\nlocal inventoryBody='..string.format('%q',inventoryFunction)..'\nlocal inventoryLayoutBody='..string.format('%q',inventoryLayout)..'\nlocal showBody='..string.format('%q',showFunction)
source=source..'\n'..foundation..'\n'..friendship..'\n'..commandStaff
source=source..'\nlocal observerDrawBody='..string.format('%q',observerDraw)..'\nlocal observerThinkBody='..string.format('%q',observerThink)
source=source..[=[
for _,channel in ipairs(Radio_RandChannelList or {})do
 if channel.chan==101.1 and not table.HasValue(channel.teams,TEAM_ALPHA9)then channel.teams[#channel.teams+1]=TEAM_ALPHA9 end
end
local oldObserver=assert((hook.GetTable().Think or {}).FSpectate_AdminObserver,"observer has not initialized")
local drawHelp
for i=1,100 do local name,value=debug.getupvalue(oldObserver,i);if not name then break end;if name=="drawHelp"then drawHelp=value;break end end
assert(isfunction(drawHelp),"observer draw closure missing")
local newDraw=replaceClosure(drawHelp,observerDrawBody)
hook.Add("Think","FSpectate_AdminObserver",replaceClosure(oldObserver,observerThinkBody,nil,{drawHelp=newDraw}))
if (hook.GetTable().HUDPaint or {}).FSpectate then hook.Add("HUDPaint","FSpectate",newDraw)end
]=]
source=source..[=[
local original=assert((hook.GetTable().HUDPaint or {}).Breach_HUD,"HUD has not initialized")
assert(LOUNGE_CHAT and LOUNGE_CHAT.OnPlayerChat,"chat has not initialized")
local newHUD=replaceClosure(original,hudBody)
local newChat=replaceClosure(LOUNGE_CHAT.OnPlayerChat,chatBody,chatHelper)
hook.Add("HUDPaint","Breach_HUD",newHUD)
LOUNGE_CHAT.OnPlayerChat=newChat
local foundInventory=false
for i=1,100 do
 local name,old=debug.getupvalue(ShowEQ,i)
 if not name then break end
 if name=="DrawNewInventory" then
  local newInventory=replaceClosure(old,inventoryBody)
  ShowEQ=replaceClosure(ShowEQ,showBody,nil,newInventory)
  foundInventory=true
  break
 end
end
assert(foundInventory,"inventory closure has not initialized")
local panel=BREACH.Inventory and BREACH.Inventory.Survivor
if IsValid(panel) and IsValid(panel.Entity) then
 panel.LayoutEntity=replaceClosure(panel.LayoutEntity,inventoryLayoutBody)
 for _,name in ipairs({"l4d_idle_calm_frying_pan","idle_all_01","idle_passive","idle"}) do
  local seq=panel.Entity:LookupSequence(name)
  if seq and seq>=0 then panel.Entity:ResetSequence(seq);panel.Entity:SetCycle(0);break end
 end
end
]=]..'\n'..slots..'\n'..stamina
assert(isfunction(CompileString(hudFunction,"RXHUDSyntax",false)),"HUD closure syntax error")
assert(isfunction(CompileString(chatFunction,"RXChatSyntax",false)),"chat closure syntax error")
assert(isfunction(CompileString(inventoryFunction,"RXInventorySyntax",false)),"inventory closure syntax error")
assert(isfunction(CompileString(inventoryLayout,"RXInventoryLayoutSyntax",false)),"inventory layout syntax error")
assert(isfunction(CompileString(observerDraw,"RXObserverDrawSyntax",false)),"observer draw syntax error")
assert(isfunction(CompileString(observerThink,"RXObserverThinkSyntax",false)),"observer think syntax error")
assert(isfunction(CompileString(source,"RXGameplayPayloadSyntax",false)),"client payload syntax error")
assert(isfunction(CompileString(source,"RXFullGameplaySyntax",false)),"full payload syntax error")
source=source.."\n"..assert(file.Read(engine.ActiveGamemode() .. "/gamemode/modules/sh_ability_binding_sync.lua","LUA"))
assert(isfunction(CompileString(source,"RXBindingPayloadSyntax",false)),"binding payload syntax error")
local revision=util.CRC(source)
local packed=util.Compress(source)
assert(#packed<60000,"gameplay client patch packet too large")
local bootstrap=[=[net.Receive("RXGameplayClientFixes",function()
 local revision=net.ReadString();local size=net.ReadUInt(16);local packed=net.ReadData(size)
 local ok,err=true,""
 if BREACH.RXGameplayFixRevision~=revision then
  local source=util.Decompress(packed)
  local fn=source and CompileString(source,"RXGameplayClientFixes",false)
  if isfunction(fn)then ok,err=pcall(fn)else ok=false;err=tostring(fn)end
  if ok then BREACH.RXGameplayFixRevision=revision end
 end
 net.Start("RXGameplayClientFixesAck");net.WriteString(revision);net.WriteBool(ok);net.WriteString(ok and "" or tostring(err):sub(1,300));net.SendToServer()
end)]=]
local pending=setmetatable({},{__mode="k"})
local function send(ply)
 if not IsValid(ply) or ply:IsBot() or ply.RXGameplayFixRevision==revision then return end
 if (pending[ply] or 0)>CurTime() then return end
 pending[ply]=CurTime()+15
 ply:SendLua(bootstrap)
 timer.Simple(.3,function()
  if not IsValid(ply) then return end
  net.Start(channel);net.WriteString(revision);net.WriteUInt(#packed,16);net.WriteData(packed,#packed);net.Send(ply)
 end)
end
net.Receive(channel.."Ack",function(len,ply)
 if len>4000 or not pending[ply] then return end
 local received=net.ReadString();local ok=net.ReadBool();local err=net.ReadString()
 if received~=revision then return end
 ply.RXGameplayFixStatus={revision=received,ok=ok,error=err,time=CurTime()}
 if ok then ply.RXGameplayFixRevision=revision else ErrorNoHalt("[RX gameplay sync] "..ply:Nick()..": "..err.."\n")end
end)
hook.Add("PlayerInitialSpawn","RXGameplayClientFixes",function(ply)timer.Simple(10,function()send(ply)end)end)
timer.Create("RXGameplayClientFixes",15,0,function()for _,ply in ipairs(player.GetHumans())do send(ply)end end)
for _,ply in ipairs(player.GetHumans())do send(ply)end
BREACH.RXGameplayClientFixRevision=revision

end

local ok, err = xpcall(installLegacyClientSync, debug.traceback)
if not ok then
timer.Remove("RXGameplayClientFixes")
hook.Remove("PlayerInitialSpawn", "RXGameplayClientFixes")
 ErrorNoHalt("[RX legacy client sync] Disabled after initialization failure: " .. tostring(err) .. "\n")
end

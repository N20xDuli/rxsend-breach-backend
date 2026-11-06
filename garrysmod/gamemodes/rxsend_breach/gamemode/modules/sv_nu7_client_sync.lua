-- Ordinary client files are distributed by shared.lua. This optional legacy
-- live patcher is disabled by default; cold startup does not depend on it.
local syncEnabled = GetConVar("breach_legacy_client_sync") or CreateConVar(
 "breach_legacy_client_sync", "0", FCVAR_ARCHIVE, "Enable legacy live client patches (restart required).", 0, 1)
timer.Remove("NU7ClientSkillsSync")
BREACH.Nu7 = BREACH.Nu7 or {}
BREACH.Nu7.EnsureClientSkills = function() end
if not syncEnabled:GetBool() then return end

local function installLegacyClientSync()
-- Live servers can retain an older client Lua bundle after a hot update.
-- Reconcile the Nu-7 client module without restarting the game or resetting skills.
local nu7=BREACH.Nu7
local channel="RXNu7ClientSkills"
local ack=channel.."Ack"
util.AddNetworkString(channel)
util.AddNetworkString(ack)
AddCSLuaFile(engine.ActiveGamemode() .. "/gamemode/modules/cl_nu7_skills.lua")
local source=file.Read(engine.ActiveGamemode() .. "/gamemode/modules/cl_nu7_skills.lua","LUA")
assert(source,"Nu-7 client skill module missing")
local revision=util.CRC(source)
local packed=util.Compress(source)
assert(#packed<60000,"Nu-7 client skill module exceeds net packet limit")
local pending=setmetatable({},{__mode="k"})
local bootstrap=[[net.Receive("RXNu7ClientSkills",function()
 local revision=net.ReadString();local size=net.ReadUInt(16);local packed=net.ReadData(size)
 local hooks=hook.GetTable().PreDrawOutlines or {}
 local healthy=BREACH.Nu7ClientSkillsRevision==revision and isfunction(hooks.NU7MarksmanVision) and isfunction(net.Receivers.nu7marksmantargetsv2)
 local ok,err=true,""
 if not healthy then
  local source=util.Decompress(packed)
  local fn=source and CompileString(source,"Nu7ClientSkillsSync",false)
  if isfunction(fn)then ok,err=pcall(fn)else ok=false;err=tostring(fn or "decompression failed")end
  if ok then
   ok=isfunction((hook.GetTable().PreDrawOutlines or {}).NU7MarksmanVision) and isfunction(net.Receivers.nu7marksmantargetsv2)
   if ok then BREACH.Nu7ClientSkillsRevision=revision else err="skill receivers missing after load"end
  end
 end
 net.Start("RXNu7ClientSkillsAck");net.WriteString(revision);net.WriteBool(ok);net.WriteString(ok and "" or tostring(err):sub(1,300));net.SendToServer()
end)]]
function nu7.EnsureClientSkills(ply)
 if not IsValid(ply) or ply:IsBot() then return end
 if (pending[ply] or 0)>CurTime() then return end
 pending[ply]=CurTime()+2
 ply:SendLua(bootstrap)
 timer.Simple(.25,function()
  if not IsValid(ply) then return end
  net.Start(channel);net.WriteString(revision);net.WriteUInt(#packed,16);net.WriteData(packed,#packed);net.Send(ply)
 end)
end
net.Receive(ack,function(len,ply)
 if len>4000 or not pending[ply] then return end
 local received=net.ReadString();local ok=net.ReadBool();local err=net.ReadString()
 if received~=revision then return end
 ply.Nu7ClientSkillsSync={revision=received,ok=ok,error=err,time=CurTime()}
 if not ok then ErrorNoHalt("[NU7 client sync] "..ply:Nick()..": "..err.."\n")end
end)
-- Also recover after a reconnect or a client Lua refresh while already assigned.
timer.Create("NU7ClientSkillsSync",15,0,function()
 for _,ply in ipairs(player.GetHumans())do
  if nu7.GetMemberKey(ply) then nu7.EnsureClientSkills(ply) end
 end
end)

end

local ok, err = xpcall(installLegacyClientSync, debug.traceback)
if not ok then
timer.Remove("NU7ClientSkillsSync")
BREACH.Nu7 = BREACH.Nu7 or {}
BREACH.Nu7.EnsureClientSkills = function() end
 ErrorNoHalt("[RX legacy client sync] Disabled after initialization failure: " .. tostring(err) .. "\n")
end

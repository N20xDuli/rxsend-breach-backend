local scp = BREACH.SCP106
-- Validated against the current rxsend_site19 BSP; hull checks still run live.
scp.PocketPoints = {
 Vector(-687.7253,-11818.127,-5142.96875),Vector(-497.9037,-11797.586,-5142.96875),
 Vector(-118.486,-12547.571,-5142.96875),Vector(-100.3217,-12841.672,-5142.96875),
 Vector(-113.9187,-13329.123,-5142.96875),Vector(-103.645,-13092.123,-5142.96875),
 Vector(-86.6333,-13827.152,-5142.96875),Vector(-227.6666,-14400.031,-5142.96875),
 Vector(-84.766,-14651.493,-5142.96875),Vector(-2412.705,-15245.422,-5142.96875),
 Vector(-2601.296,-15241.071,-5142.96875),Vector(-2980.298,-15302.427,-5142.96875),
 Vector(-2980.858,-14840.368,-5142.96875),Vector(-2989.137,-14639.377,-5142.96875),
 Vector(-2984.803,-14439.339,-5142.96875),Vector(-2977.689,-14141.849,-5142.96875),
 Vector(-2977.557,-13751.570,-5142.96875),Vector(-2998.604,-13221.343,-5142.96875),
 Vector(-2876.971,-12677.793,-5142.96875),Vector(-2625.823,-11739.985,-5142.96875),
 Vector(-1072.885,-12646.639,-5142.96875),Vector(-1709.403,-13545.066,-5142.96875),
 Vector(-392.9504,-14131.324,-5142.96875)
}
function scp.SafePosition(ply, pos)
 if not isvector(pos) or not util.IsInWorld(pos) then return nil end
 local mins,maxs = Vector(-16,-16,0),Vector(16,16,72)
 if IsValid(ply) then mins,maxs = ply:OBBMins(),ply:OBBMaxs() end
 for _,height in ipairs({2,8,16,32}) do
  local candidate = pos + Vector(0,0,height)
  local tr = util.TraceHull({start=candidate,endpos=candidate,mins=mins,maxs=maxs,mask=MASK_PLAYERSOLID,filter=ply})
  if not tr.StartSolid and not tr.AllSolid and not tr.Hit then return candidate end
 end
end
function scp.PickPocketPoint(ply, away)
 if (game.GetMap() ~= "rxsend_site19" and game.GetMap() ~= "rxsend_site19-1") then return nil end
 local points = scp.PocketPoints
 local start = math.random(#points)
 for offset=0,#points-1 do
  local point = points[(start+offset-1)%#points+1]
  if not away or point:DistToSqr(away) > 1024*1024 then
   local safe = scp.SafePosition(ply,point)
   if safe then return safe end
  end
 end
end
function scp.StopSearch(ply)
 if IsValid(ply.Dimension_TouchEntity) then ply.Dimension_TouchEntity:Remove() end
 ply.Dimension_TouchEntity = nil
 if ply.RX106Captured then
  net.Start("DimensionSequence");net.WriteVector(vector_origin);net.WriteBool(false);net.Send(ply)
  if ply.StopMusic then ply:StopMusic() end
 end
 ply.RX106Captured = nil
end
function scp.Escape(ply)
 if not IsValid(ply) or not ply:Alive() or not ply.RX106Captured then return false end
 local destination = scp.SafePosition(ply,ply.RX106ReturnPosition)
 if not destination then return false end
 scp.StopSearch(ply)
 ply:SetInDimension(false);ply:SetPos(destination);ply:SetMoveType(MOVETYPE_WALK)
 ply.RX106ReturnPosition = nil;ply.Teleported = nil;ply:SetDSP(1)
 ply:ScreenFade(SCREENFADE.IN,color_white,0.5,0)
 return true
end
function scp.Cleanup(ply)
 if not IsValid(ply) then return end
 scp.StopSearch(ply)
 ply.RX106ReturnPosition = nil;ply.RX106CapturePending = nil
 ply.RX106Life = (ply.RX106Life or 0)+1
 if ply.GetInDimension then ply:SetInDimension(false) end
end
hook.Add("PlayerDeath","RX106PocketCleanup",function(ply) scp.Cleanup(ply) end)
hook.Add("PlayerDisconnected","RX106PocketCleanup",scp.Cleanup)
hook.Add("PlayerSpawn","RX106PocketCleanup",function(ply) scp.Cleanup(ply) end)
hook.Add("Think","RX106StalePocketCleanup",function()
 if (scp.NextCleanup or 0)>CurTime() then return end
 scp.NextCleanup=CurTime()+1
 for _,ply in ipairs(player.GetAll()) do
  if ply.RX106Captured and (not ply:Alive() or ply:GTeam()==TEAM_SPEC or not ply:GetInDimension()) then scp.Cleanup(ply) end
 end
end)
hook.Add("EntityTakeDamage","RX106Invulnerability",function(target,damage)
 if not scp.Is106(target) or not target:Alive() then return end
 local weapon=target:GetActiveWeapon()
 local ghost=IsValid(weapon) and weapon:GetClass()=="weapon_scp_106" and weapon:GetGhostMode()
 local pocket=target:GetInDimension() and scp.IsPocketPosition(target:GetPos())
 if ghost or pocket then damage:SetDamage(0);damage:SetDamageForce(vector_origin);return true end
 -- Apply bullet resistance at the shared damage entry, including physical bullets.
 if damage:IsBulletDamage() or damage:IsDamageType(DMG_BUCKSHOT) then damage:ScaleDamage(scp.DamageReceived) end
end)
hook.Add("RegisterSCP","RX106Register",function()
 if GetSCP("SCP106") then return end
 RegisterSCP("SCP106","models/cultist/scp/scp_106.mdl",{"weapon_scp_106"},{
  base_health=scp.Health,max_health=scp.Health,base_speed=scp.WalkSpeed,run_speed=scp.WalkSpeed,max_speed=scp.WalkSpeed,
  damagemodifier=1,jump_power=200,
  scaledamage={HITGROUP_HEAD=1,HITGROUP_CHEST=1,HITGROUP_STOMACH=1,HITGROUP_LEFTARM=1,HITGROUP_RIGHTARM=1,HITGROUP_LEFTLEG=1,HITGROUP_RIGHTLEG=1,HITGROUP_GEAR=1}
 },{},nil,function(ply)
  ply:SetSlowWalkSpeed(80);ply:SetCustomCollisionCheck(true)
  local spawn=scp.SafePosition(ply,Vector(7083.23,4222.746,-447.96875))
  if spawn then ply:SetPos(spawn) end
  if ply.RXSENDNotify then ply:RXSENDNotify("SCP-106：左键捕获，R 幽灵模式，T 进入口袋空间，H 返回，J 黑潮。") end
 end)
end)

util.AddNetworkString("RX106AnimationCamera")
function scp.PlayAnimation(ply, sequence, duration, ...)
 local result=ply:SetForcedAnimation(sequence,duration,...)
 net.Start("RX106AnimationCamera");net.WriteFloat(duration);net.Send(ply)
 return result
end

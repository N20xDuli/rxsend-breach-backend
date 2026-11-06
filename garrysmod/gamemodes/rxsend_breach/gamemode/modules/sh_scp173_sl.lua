-- Gameplay reference: local SL 14.2.7 Scp173* subroutines.
BREACH=BREACH or {}
BREACH.SCP173SL=BREACH.SCP173SL or {}
local scp=BREACH.SCP173SL
scp.Config={Health=2000,BallisticDamageReceived=.3,Speed=250,FastSpeed=450,Meter=1/.0254,
 BlinkDistance=8/.0254,BlinkCooldown=3,Sustain=2,FastCooldown=40,FastStareLimit=10,
 SnapDistance=1.5/.0254,KillRadius=math.sqrt(1.66)/.0254,TantrumCooldown=30,
 TantrumDuration=180,TantrumRadius=75,StainedSpeed=.8}
function scp.Is173(ply)
 return IsValid(ply) and ply:IsPlayer() and ply:Alive() and ply:GetRoleName()=="SCP173"
end
function scp.IsEnemy(ply)
 return IsValid(ply) and ply:IsPlayer() and ply:Alive() and ply:GTeam()~=TEAM_SPEC and ply:GTeam()~=TEAM_SCP
end
function scp.ChangeObservers(state,count,now)
 if count==state.observers then return false end
 if state.observers==0 and state.sustainEnd~=-1 and state.sustainEnd<=now then
  state.stopTime=now;state.cooldown=scp.Config.BlinkCooldown
 end
 state.observers=count;state.sustainEnd=count>0 and -1 or now+scp.Config.Sustain
 return true
end
function scp.BlinkReady(state,now,fast)
 return (state.sustainEnd==-1 or state.sustainEnd>now)
  and state.stopTime+state.cooldown*(fast and .5 or 1)<=now
end
-- Both prediction and authority use the same obstacle/floor/standing-hull checks.
function scp.BlinkPosition(ply,range)
 local function filter(ent) return ent~=ply and not ent:IsPlayer() end
 local eye=ply:GetShootPos()
 local ray=util.TraceHull({start=eye,endpos=eye+ply:GetAimVector()*range,
  mins=Vector(-1,-1,-1),maxs=Vector(1,1,1),filter=filter,mask=MASK_PLAYERSOLID})
 if ray.StartSolid then return nil end
 local pilot=ray.HitPos+(ray.Hit and ray.HitNormal*24 or vector_origin)
 local floor=util.TraceLine({start=pilot+Vector(0,0,8),endpos=pilot-Vector(0,0,144),filter=filter,mask=MASK_PLAYERSOLID})
 if not floor.Hit or floor.StartSolid or floor.HitNormal.z<.15 then return nil end
 local point=floor.HitPos+Vector(0,0,2)
 if SERVER and not util.IsInWorld(point) then return nil end
 if point:DistToSqr(ply:GetPos())>(range+32)^2 then return nil end
 local hull=util.TraceHull({start=point,endpos=point,mins=Vector(-16,-16,0),maxs=Vector(16,16,72),filter=filter,mask=MASK_PLAYERSOLID})
 if hull.StartSolid or hull.AllSolid or hull.Hit then return nil end
 local path=util.TraceHull({start=ply:GetPos()+Vector(0,0,2),endpos=point,mins=Vector(-14,-14,0),maxs=Vector(14,14,68),filter=filter,mask=MASK_PLAYERSOLID})
 if path.StartSolid or path.AllSolid or path.Hit then return nil end
 return point
end
hook.Add("SetupMove","RX173SLMovement",function(ply,mv)
 if scp.Is173(ply) then
  local weapon=ply:GetActiveWeapon()
  if IsValid(weapon) and weapon:GetClass()=="weapon_scp_173" and weapon:GetSLWatching()>0 then
   mv:SetForwardSpeed(0);mv:SetSideSpeed(0);mv:SetUpSpeed(0)
   mv:SetMaxSpeed(0);mv:SetMaxClientSpeed(0)
   mv:SetVelocity(Vector(0,0,math.min(mv:GetVelocity().z,0)))
   mv:SetButtons(bit.band(mv:GetButtons(),bit.bnot(IN_JUMP)))
  end
 elseif scp.IsEnemy(ply) and ply:GetNWFloat("RX173StainedUntil",0)>CurTime() then
  local speed=ply:GetWalkSpeed()*scp.Config.StainedSpeed
  mv:SetMaxSpeed(math.min(mv:GetMaxSpeed(),speed));mv:SetMaxClientSpeed(math.min(mv:GetMaxClientSpeed(),speed))
  mv:SetButtons(bit.band(mv:GetButtons(),bit.bnot(IN_SPEED)))
 end
end)

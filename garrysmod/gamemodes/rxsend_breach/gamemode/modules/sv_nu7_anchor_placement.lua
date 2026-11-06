local nu7=BREACH.Nu7

-- Use standing-height horizontal candidates instead of projecting from wherever
-- the player happens to be looking. Keep path and volume checks for walls/props.
function nu7.FindAnchorPosition(ply)
 local facing=ply:GetAimVector()
 facing=Vector(facing.x,facing.y,0)
 if facing:LengthSqr()<.01 then facing=Angle(0,ply:EyeAngles().y,0):Forward() end
 facing:Normalize()
 local side=Vector(-facing.y,facing.x,0)
 local base=ply:GetPos()
 local candidates={facing*64,facing*48,facing*80,facing*64+side*32,facing*64-side*32}
 local foundFloor=false
 for _,offset in ipairs(candidates) do
  local above=base+offset+Vector(0,0,48)
  local path=util.TraceLine({start=base+Vector(0,0,24),endpos=base+offset+Vector(0,0,24),filter=ply,mask=MASK_SOLID})
  if not path.Hit and not path.StartSolid then
   local ground=util.TraceLine({start=above,endpos=base+offset-Vector(0,0,96),filter=player.GetAll(),mask=MASK_SOLID})
   if ground.Hit and not ground.HitSky and not ground.StartSolid and ground.HitNormal.z>=.65 then
    foundFloor=true
    local pos=ground.HitPos+Vector(0,0,3)
    local clear=util.TraceHull({start=pos,endpos=pos,mins=Vector(-16,-16,0),maxs=Vector(16,16,38),filter=ply,mask=MASK_SOLID})
    if not clear.Hit and not clear.StartSolid then return pos end
   end
  end
 end
 return nil,foundFloor and "这里没有足够空间放置稳定锚。" or "需要在面前的平整地面上放置。"
end

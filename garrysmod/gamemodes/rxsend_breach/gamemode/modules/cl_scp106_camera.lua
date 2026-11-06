local untilTime=0
net.Receive("RX106AnimationCamera",function()
 untilTime=CurTime()+math.max(0,net.ReadFloat())
end)
hook.Add("CalcView","RX106AnimationCamera",function(ply,pos,angles,fov)
 if not IsValid(ply) or not ply:Alive() or ply:GetRoleName()~="SCP106" or CurTime()>=untilTime then return end
 local tr=util.TraceHull({start=pos,endpos=pos-angles:Forward()*110+Vector(0,0,15),
  mins=Vector(-4,-4,-4),maxs=Vector(4,4,4),filter=ply,mask=MASK_VISIBLE})
 return {origin=tr.HitPos,angles=angles,fov=fov,drawviewer=true}
end,HOOK_HIGH or -1)

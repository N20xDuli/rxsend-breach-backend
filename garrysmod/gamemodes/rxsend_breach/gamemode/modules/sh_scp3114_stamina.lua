-- Keep sprint speed; SCP-3114 does not consume or exhaust human stamina.
BREACH.SCP3114Stamina=BREACH.SCP3114Stamina or {}
local stamina=BREACH.SCP3114Stamina
function stamina.Install()
 if not isfunction(Sprint) or Sprint==stamina.wrapper then return end
 local original=Sprint
 stamina.wrapper=function(ply,mv)
  if IsValid(ply) and ply:GetRoleName()=="SCP3114" then
   ply.Stamina=nil
   ply.exhausted=nil
   ply.LastSysTime=nil
   return
  end
  return original(ply,mv)
 end
 Sprint=stamina.wrapper
end
stamina.Install()
hook.Add("InitPostEntity","SCP3114InfiniteStamina",stamina.Install)

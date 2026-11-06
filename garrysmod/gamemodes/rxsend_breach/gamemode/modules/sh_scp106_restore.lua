BREACH = BREACH or {}
BREACH.SCP106 = BREACH.SCP106 or {}
local scp = BREACH.SCP106
scp.Health = 2500
scp.DamageReceived = 0.6
scp.WalkSpeed = 125
scp.GhostSpeed = 220
scp.Cooldowns = {3, 15, 10}
function scp.Is106(ply)
 return IsValid(ply) and ply:IsPlayer() and ply:GetRoleName() == "SCP106"
end
function scp.IsPocketPosition(pos)
 return (game.GetMap() == "rxsend_site19" or game.GetMap() == "rxsend_site19-1") and pos.x >= -3100 and pos.x <= 100
  and pos.y >= -15500 and pos.y <= -11500 and pos.z >= -5300 and pos.z <= -4500
end

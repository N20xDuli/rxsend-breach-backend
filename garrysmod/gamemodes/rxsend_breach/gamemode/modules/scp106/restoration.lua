-- Loaded after the legacy weapon, retaining its HUD, sounds and visual effects.
local scp=BREACH.SCP106
for i,cooldown in ipairs(scp.Cooldowns) do SWEP.AbilityIcons[i].Cooldown=cooldown end
SWEP.AbilityIcons[1].Name="幽灵模式"
SWEP.AbilityIcons[2].Name="口袋空间"
SWEP.AbilityIcons[3].Name="黑潮"
function scp.InstallInput()
 hook.Add("PlayerButtonDown","SCP106_DimensionTeleport",function(ply,key)
  if not scp.Is106(ply) or not ply:Alive() then return end
  local weapon=ply:GetActiveWeapon()
  if not IsValid(weapon) or weapon:GetClass()~="weapon_scp_106" or weapon.RX106Transition then return end
  local id=key==KEY_T and 2 or key==KEY_J and 3 or key==KEY_H and 2
  if not id or key==KEY_H and not ply:GetInDimension() then return end
  local ability=weapon.AbilityIcons[id]
  if not ability or ability.Forbidden or (ability.CooldownTime or 0)>CurTime() then return end
  if CLIENT then ability.CooldownTime=CurTime()+ability.Cooldown;return end
  local used
  if key==KEY_J then used=weapon:DistantAttack() else used=weapon:OwnerTeleport(false,key==KEY_H) end
  if used then ability.CooldownTime=CurTime()+ability.Cooldown end
 end)
end
if SERVER then
 include(engine.ActiveGamemode() .. "/gamemode/modules/scp106/server.lua")
else
 hook.Add("PreDrawOutlines","RX106PocketVision",function()
  local ply=LocalPlayer()
  if not scp.Is106(ply) or not ply:Alive() or not ply:GetInDimension() then return end
  local targets={}
  for _,target in ipairs(player.GetAll()) do
   if target~=ply and target:Alive() and target:GTeam()~=TEAM_SPEC and target:GetInDimension() then targets[#targets+1]=target end
  end
  if #targets>0 then outline.Add(targets,color_white,OUTLINE_MODE_BOTH) end
 end)
end
local oldDeploy=SWEP.Deploy
function SWEP:Deploy()
 local result=oldDeploy(self);scp.InstallInput();return result
end

scp.InstallInput()

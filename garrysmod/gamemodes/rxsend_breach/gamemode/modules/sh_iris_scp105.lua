-- Appearance-only, administrator-spawned SCP-105 "Iris" role.
-- No automatic assignment, support wave, equipment or ability registration.
BREACH = BREACH or {}
BREACH.Iris = BREACH.Iris or {}
local faction = BREACH.Iris
faction.Category = 'MTF-Alpha9-"最后的希望"'
faction.BaseModel = 'models/special_agent_thompson/iris.mdl'
faction.Model = 'models/special_agent_thompson/iris_female_v1.mdl'
faction.Workshop = '3814632544'
faction.Variants = {
 {name='SCP-105 鸢尾'},
}

player_manager.AddValidModel('rx_iris_scp105', faction.Model)

function faction.Register()
 if not BREACH.Alpha9 then return false end
 faction.EnsureTeam = BREACH.Alpha9.EnsureTeam
 return BREACH.Alpha9.RegisterRole('iris', {
  name='SCP-105 鸢尾', team=TEAM_ALPHA9, model=faction.Model, showmodel=faction.Model,
  genders={true}, weapons={}, ammo={}, armor=0, health=100, walkspeed=1, runspeed=1, jumppower=1,
  tasks='', level=0, usehead=false, randomizehead=false, randomizeface=false,
  damage_modifiers={HITGROUP_HEAD=1,HITGROUP_CHEST=1,HITGROUP_STOMACH=1,
   HITGROUP_LEFTARM=1,HITGROUP_RIGHTARM=1,HITGROUP_LEFTLEG=1,HITGROUP_RIGHTLEG=1,HITGROUP_GEAR=1},
 })
end
faction.Register()
hook.Add('InitPostEntity', 'RXIrisRoles', function() faction.Register() end)

if SERVER then
 resource.AddWorkshop(faction.Workshop)
 -- The combined RXSend pack includes textures and the female-animation model.

else
 function faction.EnsureResources()
  if file.Exists(faction.Model,'GAME') then
   faction.ModelsMounted=true
   faction.ModelError=nil
   return
  end
  local localAssets = GetConVar("rx_local_assets")
  if localAssets and localAssets:GetBool() then
   faction.ModelsMounted=false
   faction.ModelError="Local development assets missing; verify the local resource bridge and restart Garry's Mod. Workshop downloads are disabled."
   return
  end
  if faction.DownloadPending then return end
  faction.DownloadPending=true
  steamworks.DownloadUGC(faction.Workshop,function(path)
   faction.DownloadPending=false
   if not path then faction.ModelError='Workshop download failed';return end
   local mounted=game.MountGMA(path)
   faction.ModelsMounted=mounted and file.Exists(faction.Model,'GAME') or false
   faction.ModelError=faction.ModelsMounted and nil or 'Workshop mount failed'
  end)
 end
 faction.EnsureResources()
end

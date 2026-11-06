-- Admin-spawnable NSO appearances. This category is deliberately separate from
-- BREACH_ROLES.GOC, so ordinary GOC support selection never picks these roles.
BREACH = BREACH or {}
BREACH.GOCTheory = BREACH.GOCTheory or {}
local squad = BREACH.GOCTheory
squad.Category = 'GOC“理论抹除”小组'
squad.Body = 'models/cultist/nso/nso.mdl'
squad.Hands = 'models/cultist/humans/goc/hands/c_arms_goc.mdl'
squad.Workshop = '3814632544'
squad.Variants = {
 {name = squad.Category .. ' · I', helmet = 'models/cultist/nso/helmet/blacktou.mdl'},
 {name = squad.Category .. ' · II', helmet = 'models/cultist/nso/helmet/quanban.mdl'},
}

player_manager.AddValidModel('rx_goc_theory_erasure', squad.Body)
player_manager.AddValidHands('rx_goc_theory_erasure', squad.Hands, 0, '00000000')

function squad.Register()
 local base = BREACH_ROLES and BREACH_ROLES.GOC and BREACH_ROLES.GOC.goc
 if not base or not base.roles or not base.roles[1] then return false end
 local entries = {}
 for _,variant in ipairs(squad.Variants) do
  local entry = table.Copy(base.roles[1])
  entry.name, entry.team = variant.name, TEAM_GOC
  entry.model, entry.showmodel, entry.headgear = squad.Body, squad.Body, variant.helmet
  entry.weapons, entry.ammo, entry.armor = {}, {}, 0
  entry.keycard, entry.ability, entry.ability_max = nil, nil, nil
  entry.head, entry.headgearrandom, entry.random_accessories = nil, nil, nil
  entry.female_head, entry.female_headgear, entry.premium_female = nil, nil, nil
  entry.usehead, entry.randomizehead, entry.randomizeface = false, false, false
  entry.tasks, entry.level, entry.max = '', 0, nil
  for id=0,9 do entry['bodygroup'..id]=0 end
  entries[#entries+1]=entry
 end
 BREACH_ROLES[squad.Category] = {theory = {name=squad.Category, color=base.color, roles=entries}}
 local command = ULib and ULib.cmds and ULib.cmds.translatedCmds and ULib.cmds.translatedCmds['ulx dev_force_spawn']
 for _,arg in ipairs(command and command.args or {}) do
  if arg.hint == 'class name' and istable(arg.completes) then
   for _,variant in ipairs(squad.Variants) do
    if not table.HasValue(arg.completes,variant.name) then arg.completes[#arg.completes+1]=variant.name end
   end
   table.sort(arg.completes)
  end
 end
 return true
end
squad.Register()
hook.Add('InitPostEntity', 'RXGOCTheoryRoles', function() squad.Register() end)

if SERVER then
 resource.AddWorkshop(squad.Workshop)
else
 function squad.EnsureResources()
  if file.Exists(squad.Body,'GAME') then squad.ModelsMounted=true return end
  local localAssets = GetConVar("rx_local_assets")
  if localAssets and localAssets:GetBool() then
   squad.ModelsMounted=false
   squad.ModelError="Local development assets missing; verify the local resource bridge and restart Garry's Mod. Workshop downloads are disabled."
   return
  end
  if squad.DownloadPending then return end
  squad.DownloadPending=true
  steamworks.DownloadUGC(squad.Workshop,function(path)
   squad.DownloadPending=false
   if not path then squad.ModelError='Workshop download failed';return end
   local mounted=game.MountGMA(path)
   squad.ModelsMounted=mounted and file.Exists(squad.Body,'GAME') or false
   squad.ModelError=squad.ModelsMounted and nil or 'Workshop mount failed'
  end)
 end
 squad.EnsureResources()
end

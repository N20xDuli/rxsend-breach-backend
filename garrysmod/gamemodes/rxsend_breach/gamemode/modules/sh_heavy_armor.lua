-- Heavy-role armor balance. Absolute targets keep role reloads idempotent.
BREACH=BREACH or {}
BREACH.HeavyArmor=BREACH.HeavyArmor or {}
local policy=BREACH.HeavyArmor
policy.Targets={MTF_Jag=150,Goc_Jag=150,Chaos_Jugg=230,GRU_Jugg=150,NU7_Heavy=750}
function policy.Apply()
 local changed={}
 if not BREACH_ROLES or not role then return changed end
 for _,faction in pairs(BREACH_ROLES)do
  for _,group in pairs(faction)do
   if istable(group) and istable(group.roles)then
    for _,entry in ipairs(group.roles)do
     for key,armor in pairs(policy.Targets)do
      if role[key] and entry.name==role[key]then
       changed[key]={before=entry.armor or 0,after=armor};entry.armor=armor
      end
     end
    end
   end
  end
 end
 return changed
end

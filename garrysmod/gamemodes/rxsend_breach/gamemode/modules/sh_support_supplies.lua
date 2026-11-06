-- Supply adjustments belong here, rather than in the legacy role tables.
BREACH=BREACH or {}
BREACH.SupportSupplies=BREACH.SupportSupplies or {}
local supplies=BREACH.SupportSupplies
supplies.ExtraAmmo=500
function supplies.IsAgent(name)
 return name==role.UIU_Agent or name==role.UIU_Agent_Commander or name==role.UIU_Agent_Sniper
  or name==role.UIU_Agent_Specialist or name==role.UIU_Agent_Information
end
function supplies.Prepare(source)
 if not source or source.SupportSuppliesPrepared or not (source.team==TEAM_NU7 or supplies.IsAgent(source.name)) then return source end
 local result=table.Copy(source)
 result.weapons=result.weapons or {}
 if supplies.IsAgent(result.name) and not table.HasValue(result.weapons,"item_medkit_3") then
  result.weapons[#result.weapons+1]="item_medkit_3"
 end
 local totals={}
 for _,entry in ipairs(result.ammo or {}) do totals[entry[1]]=tonumber(entry[2]) or 0 end
 local handled={}
 result.ammo={}
 for _,class in ipairs(result.weapons) do
  local weapon=weapons.GetStored(class)
  local clip=weapon and weapon.Primary and tonumber(weapon.Primary.ClipSize) or 0
  local ammo=weapon and weapon.Primary and weapon.Primary.Ammo
  if (string.sub(class,1,2)=="cw" or (weapon and weapon.CW20Weapon)) and clip>1 and ammo and ammo~="none" and not string.find(class,"nade",1,true) and not handled[class] then
   handled[class]=true
   result.ammo[#result.ammo+1]={class,math.max(totals[class] or clip,clip)+supplies.ExtraAmmo}
   totals[class]=nil
  end
 end
 -- Preserve grenades and any separately configured ammunition unchanged.
 for class,total in pairs(totals) do result.ammo[#result.ammo+1]={class,total} end
 result.SupportSuppliesPrepared=true
 return result
end

if SERVER then
 function supplies.ApplyAmmo(ply,prepared)
  if not prepared.SupportSuppliesPrepared then return end
  local reserves={}
  for _,entry in ipairs(prepared.ammo or {}) do
   local weapon=ply:GetWeapon(entry[1])
   if IsValid(weapon) and weapon:GetPrimaryAmmoType()>=0 then
    local id=weapon:GetPrimaryAmmoType()
    reserves[id]=(reserves[id] or 0)+math.max(0,entry[2]-weapon:Clip1())
   end
  end
  -- GiveAmmo respects engine carry caps (HAB uses 420 for some calibres).
  -- Set the explicit role reserve so the requested extra 500 is actually granted.
  for id,amount in pairs(reserves) do ply:SetAmmo(amount,id) end
 end
end

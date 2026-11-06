-- Engine ammo types must be registered during Initialize on both realms.
hook.Add("Initialize", "RX_SCP127TeethAmmo", function()
    game.AddAmmoType({name = "SCP127Teeth", dmgtype = DMG_BULLET})
end)

if CLIENT then language.Add("SCP127Teeth_ammo", "牙齿弹药") end

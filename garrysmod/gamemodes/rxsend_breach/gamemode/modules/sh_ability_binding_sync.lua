-- Synchronize the skill binding independently of the legacy settings snapshot.
BREACH = BREACH or {}
BREACH.AbilityBinding = BREACH.AbilityBinding or {}
local binding = BREACH.AbilityBinding
local channel = "RXAbilityBindingSync"
local requestCode = 65535

if SERVER then
    AddCSLuaFile()
    util.AddNetworkString(channel)

    function binding.Request(ply)
        if not IsValid(ply) or ply:IsBot() then return end
        net.Start(channel)
        net.WriteUInt(requestCode, 16)
        net.Send(ply)
    end

    net.Receive(channel, function(bits, ply)
        if bits ~= 16 or not IsValid(ply) or ply:IsBot() then return end
        local key = net.ReadUInt(16)
        if key < KEY_NONE or key > MOUSE_LAST then return end
        if (ply.RXAbilityBindingNext or 0) > CurTime() then return end
        ply.RXAbilityBindingNext = CurTime() + 0.25
        ply.specialability = key
        net.Start(channel)
        net.WriteUInt(key, 16)
        net.Send(ply)
    end)

    hook.Add("PlayerInitialSpawn", "RXAbilityBindingSync", function(ply)
        timer.Simple(2, function() binding.Request(ply) end)
    end)
    timer.Create("RXAbilityBindingRepair", 15, 0, function()
        for _, ply in ipairs(player.GetHumans()) do
            if ply.specialability == nil then binding.Request(ply) end
        end
    end)
    for _, ply in ipairs(player.GetHumans()) do binding.Request(ply) end
else
    function binding.Sync(force)
        local config = GetConVar("breach_config_useability")
        if not config or not IsValid(LocalPlayer()) then return end
        local key = config:GetInt()
        if key < KEY_NONE or key > MOUSE_LAST then return end
        if not force and binding.acknowledged == key then return end
        if (binding.nextSend or 0) > RealTime() then return end
        binding.nextSend = RealTime() + 0.5
        net.Start(channel)
        net.WriteUInt(key, 16)
        net.SendToServer()
    end

    net.Receive(channel, function()
        local key = net.ReadUInt(16)
        if key == requestCode then
            binding.acknowledged = nil
            binding.Sync(true)
        else
            binding.acknowledged = key
        end
    end)
    cvars.AddChangeCallback("breach_config_useability", function()
        binding.acknowledged = nil
        binding.Sync(true)
    end, "RXAbilityBindingSync")
    hook.Add("InitPostEntity", "RXAbilityBindingSync", function() binding.Sync(true) end)
    timer.Simple(0, function() binding.Sync(true) end)
    timer.Create("RXAbilityBindingSync", 5, 0, function() binding.Sync(false) end)
end

BREACH=BREACH or {}
function BREACH.SetDCellDoors(open)
    if (game.GetMap()~="rxsend_site19" and game.GetMap()~="rxsend_site19-1") then return end
    for _,ent in ipairs(ents.FindByName("cell_door_*")) do
        if IsValid(ent) and ent:GetClass()=="func_door" then ent:Fire(open and "Open" or "Close","",0) end
    end
end
hook.Add("InitPostEntity","RXDCellsInitialClosed",function()
    timer.Simple(1,function() if not gamestarted then BREACH.SetDCellDoors(false) end end)
end)
hook.Add("BreachPreround","RXDCellsPreroundClosed",function() BREACH.SetDCellDoors(false) end)

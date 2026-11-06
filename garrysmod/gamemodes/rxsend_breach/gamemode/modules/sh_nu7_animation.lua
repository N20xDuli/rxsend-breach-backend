-- Nu-7 uses the same run definitions as Chaos, resolved on its own model.
BREACH = BREACH or {}
BREACH.Nu7RunAnimation = BREACH.Nu7RunAnimation or {}
local animation = BREACH.Nu7RunAnimation

function animation.Prepare(ply, hold)
    if not IsValid(ply) or ply:GTeam() ~= TEAM_NU7 or not hold then return false end
    local source = BREACH.AnimationTable and BREACH.AnimationTable.Soldiers
    local definition = source and (source['run_' .. hold] or source[hold .. '_run'])
    local safeName, runName
    if isstring(definition) then
        safeName, runName = definition, definition
    elseif istable(definition) then
        safeName, runName = definition[1], definition[2] or definition[1]
    else
        return false
    end
    if not isstring(safeName) or not isstring(runName) then return false end
    local t = ply:GetTable()
    local model = ply:GetModel()
    if t.RXNu7RunModel == model and t.RXNu7RunHold == hold
        and t.RXNu7SafeRun == t.SafeRun and t.RXNu7Run == t.Run then return true end
    local safe = ply:LookupSequence(safeName)
    local run = ply:LookupSequence(runName)
    if not safe or safe < 0 or not run or run < 0 then return false end
    t.SafeRun, t.Run = safe, run
    t.RXNu7RunModel, t.RXNu7RunHold = model, hold
    t.RXNu7SafeRun, t.RXNu7Run = safe, run
    t.GestureAnimationRun = nil
    return true
end

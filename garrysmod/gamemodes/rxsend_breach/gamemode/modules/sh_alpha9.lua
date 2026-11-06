-- Shared Alpha-9 roster. Roles are added by their own modules.
BREACH = BREACH or {}
BREACH.Alpha9 = BREACH.Alpha9 or {}
local faction = BREACH.Alpha9
faction.Key = 'ALPHA9'
faction.Category = 'MTF-Alpha9-"最后的希望"'
faction.Team = TEAM_ALPHA9
faction.Color = Color(226, 140, 66)
faction.Roles = faction.Roles or {}

function faction.EnsureTeam()
    if not gteams or not gteams.SetUp then return false end
    for _, entry in pairs(gteams.Teams or {}) do
        if entry.index == faction.Team then
            if entry.name == 'SCP-105 · Alpha-9' or entry.name == 'Alpha-9' then entry.name = faction.Category end
            if entry.name ~= faction.Category then
                ErrorNoHalt('[Alpha-9] Team ID conflict\n')
                return false
            end
            entry.color = faction.Color
            return true
        end
    end
    gteams.SetUp(faction.Team, faction.Category, faction.Color)
    return true
end

function faction.Register()
    if not BREACH_ROLES or not faction.EnsureTeam() then return false end
    local ids, entries = {}, {}
    for id in pairs(faction.Roles) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do entries[#entries + 1] = faction.Roles[id] end
    BREACH_ROLES[faction.Key] = {alpha9 = {name = faction.Category, color = faction.Color, roles = entries}}
    -- Remove only the old, single-Iris category during a live reload.
    local legacy = BREACH_ROLES['SCP-105 · Alpha-9']
    local old = legacy and legacy.appearance and legacy.appearance.roles
    if old and #old == 1 and old[1].model == 'models/special_agent_thompson/iris.mdl' then
        BREACH_ROLES['SCP-105 · Alpha-9'] = nil
    end
    local cmds = ULib and ULib.cmds and ULib.cmds.translatedCmds
    local command = cmds and cmds['ulx dev_force_spawn']
    for _, arg in ipairs(command and command.args or {}) do
        if arg.hint == 'class name' and istable(arg.completes) then
            for _, entry in ipairs(entries) do
                if not table.HasValue(arg.completes, entry.name) then arg.completes[#arg.completes + 1] = entry.name end
            end
            table.sort(arg.completes)
        end
    end
    return true
end

function faction.RegisterRole(id, definition)
    definition.team = faction.Team
    faction.Roles[id] = definition
    return faction.Register()
end

faction.EnsureTeam()
faction.Register()
hook.Add('InitPostEntity', 'RXAlpha9Roster', function() faction.Register() end)

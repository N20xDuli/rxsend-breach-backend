-- Site19-1: moved reader props still operate the original permission-checked button.
-- Keep this separate from the generic keycard / PlayerUse implementation.
local readers = {}
local button
local oldButtonPos = Vector(-2792, 4080.5, 53)

function BREACH_RepairSite19CardReaders()
 readers = {}
 button = nil
 if game.GetMap() ~= "rxsend_site19-1" then return end
 if BREACH_RepairSite19TestAlignment then BREACH_RepairSite19TestAlignment() end
 for _, ent in ipairs(ents.GetAll()) do
  local id = tonumber(ent:GetKeyValues().hammerid)
  if id == 727015 and ent:GetClass() == "func_button" then button = ent end
  if (id == 727167 or id == 727171) and ent:GetClass() == "prop_dynamic" then
   readers[#readers + 1] = ent
  end
 end
 if not IsValid(button) then return end
 -- PlayerUse matches permissions by exact button position. Moving just the
 -- brush without this update would silently bypass the configured card levels.
 for _, rows in ipairs({BUTTONS or {}, MAPBUTTONS or {}}) do
  for _, row in pairs(rows) do
   if row.pos and row.pos:DistToSqr(oldButtonPos) < 0.01 then
    row.pos = button:GetPos()
   end
  end
 end
end

hook.Add("FindUseEntity", "RXSite19MovedReaders", function(ply)
 if game.GetMap() ~= "rxsend_site19-1" or not IsValid(button) then return end
 local start = ply:GetShootPos()
 local ray = ply:GetAimVector() * 85
 local best, distance
 for _, reader in ipairs(readers) do
  if IsValid(reader) then
   local hit = util.IntersectRayWithOBB(start, ray, reader:GetPos(), reader:GetAngles(),
    reader:OBBMins() - Vector(2, 2, 2), reader:OBBMaxs() + Vector(2, 2, 2))
   if hit then
    local d = start:DistToSqr(hit)
    local tr = util.TraceLine({start = start, endpos = hit, filter = {ply, reader}})
    if (not tr.Hit or tr.HitPos:DistToSqr(hit) <= 4) and (not distance or d < distance) then
     best, distance = button, d
    end
   end
  end
 end
 -- Return the real func_button, so GM:PlayerUse checks the held card and the
 -- original OnPressed outputs run. Never Fire/Toggle a door directly here.
 return best
end)

local function refresh()
 timer.Simple(0, BREACH_RepairSite19CardReaders)
end
hook.Add("InitPostEntity", "RXSite19MovedReaders", refresh)
hook.Add("PostCleanupMap", "RXSite19MovedReaders", refresh)

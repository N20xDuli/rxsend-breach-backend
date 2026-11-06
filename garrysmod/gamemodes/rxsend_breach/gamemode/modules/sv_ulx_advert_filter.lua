-- Skip empty ULX adverts and its missing-text placeholder without touching valid announcements.
if not ulx or not isfunction(ulx.addAdvert) then return end
local placeholder="NO TEXT SUPPLIED FOR THIS ADVERT"
local function hidden(message)
 return not isstring(message) or string.Trim(message)=="" or string.Trim(message)==placeholder
end
ulx.RXOriginalAddAdvert=ulx.RXOriginalAddAdvert or ulx.addAdvert
function ulx.addAdvert(message,...)
 if hidden(message) then return false end
 return ulx.RXOriginalAddAdvert(message,...)
end
local removed=0
for group,rows in pairs(ulx.adverts or {})do
 for i=#rows,1,-1 do
  if hidden(rows[i].message) then table.remove(rows,i);removed=removed+1;rows.removed_last=true end
 end
 if #rows==0 then timer.Remove("ULXAdvert"..type(group)..group) end
end
BREACH=BREACH or {};BREACH.HiddenEmptyAdverts=removed

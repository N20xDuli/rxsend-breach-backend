-- Text radio is independent of the microphone switch and voice transmission rank.
BREACH=BREACH or {}
BREACH.RadioText=BREACH.RadioText or {}
local radioText=BREACH.RadioText
local squelch="nextoren/weapons/radio/squelch.ogg"
local function getRadio(ply)
 if not IsValid(ply) or not ply:IsPlayer() then return end
 local radio=ply:GetWeapon("item_radio")
 if IsValid(radio) and radio:GetOwner()==ply then return radio end
end
function radioText.Handle(ply,msg)
 if ply:IsFrozen() then return "" end
 local command,body=string.match(string.Trim(msg),"^([!/]%a+)%s*(.*)$")
 if not command or string.lower(command)~="!r" and string.lower(command)~="/r" then return end
 if not ply:Alive() or ply:GTeam()==TEAM_SPEC or ply:GTeam()==TEAM_SCP then return "" end
 local radio=getRadio(ply)
 if not radio then ply:RXSENDNotify("l:no_radio");return "" end
 body=string.Trim(body)
 if body=="" then ply:RXSENDNotify("l:no_text_radio");return "" end
 local channel=math.Round(radio:GetRadioFrequency()*10)
 local name=ply:GetNamesurvivor()
 local function deliver(target)
  target:RXSENDNotify(Color(0,0,255),"l:radio_in_chat",Color(0,255,0)," ["..name.."] ",color_white,"<\"",body,"\">")
 end
 -- The sender gets confirmation even when their receiver is muted.
 deliver(ply)
 ply:EmitSound("^"..squelch,76,100,2)
 for _,listener in ipairs(player.GetAll()) do
  if listener~=ply and listener:Alive() and listener:GTeam()~=TEAM_SPEC and listener:GTeam()~=TEAM_SCP then
   local receiver=getRadio(listener)
   if receiver and not receiver:GetRadioMuted() and math.Round(receiver:GetRadioFrequency()*10)==channel then
    net.Start("ForcePlaySound");net.WriteString(squelch);net.Send(listener)
    deliver(listener)
   end
  end
 end
 return ""
end
hook.Add("PlayerSay","Shaky_Radio",radioText.Handle)

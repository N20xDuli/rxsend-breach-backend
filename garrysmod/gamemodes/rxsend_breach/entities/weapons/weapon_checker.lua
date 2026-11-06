
AddCSLuaFile()

if ( CLIENT ) then

	SWEP.InvIcon = Material( "nextoren/gui/icons/player_check.png" )

end

SWEP.ViewModelFOV	= 70
SWEP.ViewModelFlip	= false
SWEP.ViewModel		= ""
SWEP.WorldModel		= ""
SWEP.PrintName		= "身份检查"
SWEP.Slot			= 1
SWEP.SlotPos		= 1
SWEP.DrawAmmo		= false
SWEP.DrawCrosshair	= true
SWEP.HoldType		= "normal"
SWEP.Spawnable		= false
SWEP.AdminSpawnable	= false

SWEP.UnDroppable				= true

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Ammo			=  "none"
SWEP.Primary.Automatic		= false

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Ammo			=  "none"
SWEP.Secondary.Automatic	=  false
SWEP.UseHands = true

SWEP.Pos = Vector( 1, 3, -2 )
SWEP.Ang = Angle( 240, -90, 240 )

function SWEP:Deploy()

  if ( SERVER ) then

    self.Owner:DrawWorldModel( false )

  end

  self.Owner:DrawViewModel( false )

end

SWEP.AlreadyChecked = {}

local Phrases = {

  [ TEAM_CLASSD ] = "不在人员名单上他是'D级'人员",
  [ TEAM_GOC ] = "不在人员名单上他是'D级'人员",
  [ TEAM_SCI ] = "在人员名单上他是'科学家'人员",
  [ TEAM_SPECIAL ] = "在人员名单上他是'科学家'人员",
  [ TEAM_DZ ] = "不在人员名单他来自'其他'势力",
  [ TEAM_USA ] = "在人员名单上他是'科学家'人员",
  [ TEAM_CHAOS ] = "不在人员名单他来自'其他'势力",
  [ TEAM_SECURITY ] = "在人员名单上他是'安全部门'人员",
  [ TEAM_QRT ] = "在人员名单上他是'快速反应小队'人员",
  [ TEAM_NU7 ] = "在人员名单上他是'基金会其他部队'人员",
  [ TEAM_NTF ] = "在人员名单上他是'基金会其他部队'人员",
  [ TEAM_GUARD ] = "在人员名单上他是'设施武装'人员",
  [ TEAM_OSN ] = "在人员名单上他是'特种部队'人员"

}
-- The portable terminal reports through the existing chat notification channel.
local function terminalFailure(self,owner,message)
 if self.Nu7Terminal then owner:RXSENDNotify("[身份查验] "..message) end
 return false
end
local function reportCheck(self,owner,message)
 if not self.Nu7Terminal then owner.BypassMute=true;owner:ConCommand("say "..message);return end
 local nearby={owner}
 for _,p in ipairs(player.GetAll()) do
  if p~=owner and p:Alive() and p:GetPos():DistToSqr(owner:GetPos())<=750^2 then nearby[#nearby+1]=p end
 end
 BREACH.Players:ChatPrint(nearby,false,false,Color(91,181,255),"[身份查验] ",color_white,owner:Nick().."："..message)
end
function SWEP:PrimaryAttack()
 if CLIENT then return end
 local owner=self.Owner
 if not IsValid(owner) then return end
 local target=owner:GetEyeTrace().Entity
 if not IsValid(target) or not target:IsPlayer() or not target:Alive() then return terminalFailure(self,owner,"请对准存活的人员。") end
 if target:GTeam()==TEAM_SCP or target:GTeam()==TEAM_SPEC then return terminalFailure(self,owner,"该目标无法进行人员身份查验。") end
 if owner:GetPos():DistToSqr(target:GetPos())>150^2 then return terminalFailure(self,owner,"距离过远，请靠近目标（约 3.8 米内）。") end
 if owner.ProgressBarData then return terminalFailure(self,owner,"已有操作正在进行，请完成后再查验。") end
 self.AlreadyChecked=self.AlreadyChecked or {}
 local function phrase() return Phrases[target:GTeam()] or "不在人员名单，他来自其他势力" end
 for _,entry in ipairs(self.AlreadyChecked) do
  if entry.name==target:GetNamesurvivor() then
   reportCheck(self,owner,"我已经查过这个人了，他 "..entry.phrase.."。")
   return
  end
 end
 owner:BrProgressBar("l:checking_class",4,"nextoren/gui/icons/player_check.png",target,true,function()
  if not IsValid(owner) or not owner:Alive() or not IsValid(target) or not target:Alive()
   or owner:GetEyeTrace().Entity~=target or owner:GetPos():DistToSqr(target:GetPos())>150^2 then return terminalFailure(self,owner,"查验中断，请保持对准目标并重新查验。") end
  local teamID=target:GTeam()
  if teamID==TEAM_CLASSD or teamID==TEAM_CHAOS or teamID==TEAM_DZ or teamID==TEAM_USA then owner:AddToStatistics("l:checker_bonus",100) end
  local result=phrase()
  self.AlreadyChecked[#self.AlreadyChecked+1]={name=target:GetNamesurvivor(),phrase=result}
  reportCheck(self,owner,"这个人 "..result.."。")
  if teamID==TEAM_GOC or teamID==TEAM_CHAOS or teamID==TEAM_DZ then owner:CompleteAchievement("mtfagent") end
 end,nil,function() terminalFailure(self,owner,"查验中断，请保持对准目标并重新查验。") end)
 return true
end

function SWEP:CanPrimaryAttack()

  return true

end

function SWEP:CanSecondaryAttack()

  return false

end

function SWEP:Think() end

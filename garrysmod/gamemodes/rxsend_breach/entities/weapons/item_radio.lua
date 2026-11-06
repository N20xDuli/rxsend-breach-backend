AddCSLuaFile()

local function normalizeFrequency(value)
 if not isnumber(value) or value ~= value or math.abs(value) == math.huge then return end
 return math.Clamp(math.Round(value, 1), 100.1, 999.9)
end

function SWEP:GetRadioFrequency()
 return normalizeFrequency(self:GetFrequency()) or 100.1
end

function SWEP:SetRadioFrequency(value)
 local frequency = normalizeFrequency(value)
 if not frequency then return false end
 self:SetFrequency(frequency)
 self.Channel = frequency
 return true
end

if SERVER then
 util.AddNetworkString("SetFrequency")
 util.AddNetworkString("RadioHooks")
 util.AddNetworkString("GetRadioChannel")
 net.Receive("SetFrequency", function(_, ply)
  local radio, frequency = net.ReadEntity(), normalizeFrequency(net.ReadFloat())
  if not IsValid(ply) or not ply:Alive() or not IsValid(radio) or not frequency then return end
  if radio:GetClass() ~= "item_radio" or radio:GetOwner() ~= ply or ply:GetActiveWeapon() ~= radio then return end
  if (radio.NextFrequencyChange or 0) > CurTime() then return end
  radio.NextFrequencyChange = CurTime() + .08
  radio:SetRadioFrequency(frequency)
  radio:SetKeyRedact(false)
 end)
 util.AddNetworkString("RXRadioControl")
 -- Read physical keys on the client; validate and change state only on the server.
 hook.Remove("PlayerButtonDown", "Radio_TriggerOn")
 net.Receive("RXRadioControl", function(_, ply)
  local mute = net.ReadBool()
  if not IsValid(ply) or not ply:Alive() or ply:GTeam()==TEAM_SPEC or ply:GTeam()==TEAM_SCP then return end
  local radio=ply:GetWeapon("item_radio")
  if not IsValid(radio) or radio:GetOwner()~=ply then return end
  if mute then radio:ToggleRadioMute() else radio:SecondaryAttack() end
 end)
else
 hook.Add("PlayerButtonDown", "Radio_TriggerOn", function(ply,key)
  if ply~=LocalPlayer() or not IsFirstTimePredicted() or gui.IsGameUIVisible() then return end
  if IsValid(vgui.GetKeyboardFocus()) then return end
  if not ply:Alive() or ply:GTeam()==TEAM_SPEC or ply:GTeam()==TEAM_SCP then return end
  local radio=ply:GetWeapon("item_radio");if not IsValid(radio) then return end
  local cvar=GetConVar("breach_config_radio_mute")
  local muteKey=cvar and cvar:GetInt() or KEY_H
  local mute=muteKey>0 and key==muteKey
  if not mute and key~=KEY_G then return end
  if (radio.NextControlKey or 0)>CurTime() then return end
  radio.NextControlKey=CurTime()+.5
  net.Start("RXRadioControl");net.WriteBool(mute);net.SendToServer()
 end)
 local colors = {bg=Color(12,19,27,235), edge=Color(55,76,94,220), text=Color(235,243,247), muted=Color(137,158,174), on=Color(83,214,181), off=Color(112,125,137), blue=Color(105,179,239)}
 surface.CreateFont("RXRadioLabel", {font="Tahoma",size=14,weight=600,extended=true})
 surface.CreateFont("RXRadioHint", {font="Tahoma",size=13,weight=500,extended=true})
 surface.CreateFont("RXRadioFrequency", {font="Tahoma",size=36,weight=700,extended=true})
 surface.CreateFont("RXRadioScreen", {font="Tahoma",size=30,weight=700,extended=true})
 surface.CreateFont("RXRadioCompact", {font="Tahoma",size=24,weight=600,extended=true})
 local function requestFrequency(radio, value)
  local frequency=normalizeFrequency(value)
  if not IsValid(radio) or not frequency then return false end
  net.Start("SetFrequency"); net.WriteEntity(radio); net.WriteFloat(frequency); net.SendToServer()
  return true
 end
 net.Receive("SetFrequency", function()
  local radio, frequency=net.ReadEntity(), normalizeFrequency(net.ReadFloat())
  -- The replicated Frequency is authoritative even if this legacy packet arrives before the entity.
  if IsValid(radio) and radio:GetClass()=="item_radio" and frequency then radio.Channel=frequency end
 end)
 net.Receive("GetRadioChannel",function() net.ReadFloat() end)
 net.Receive("RadioHooks",function() end)

 hook.Add("CreateMove","RadioFrequencyChanger",function(cmd)
  local ply=LocalPlayer();if not IsValid(ply) or not ply:Alive() then return end
  local radio=ply:GetActiveWeapon()
  if not IsValid(radio) or radio:GetClass()~="item_radio" or not radio:GetRedacting() then return end
  local wheel=cmd:GetMouseWheel();if wheel==0 then return end
  -- Consume the wheel in tuning mode so the inventory cannot switch weapons.
  cmd:SetMouseWheel(0)
  if (radio.NextClientTune or 0)>CurTime() then return end
  radio.NextClientTune=CurTime()+.12
  requestFrequency(radio,radio:GetRadioFrequency()+(wheel>0 and .1 or -.1))
 end)

 hook.Add("HUDPaintBackground","Radio_HUD",function()
  local ply=LocalPlayer()
  if not IsValid(ply) or not ply:Alive() or ply:GTeam()==TEAM_SPEC then return end
  if BREACH and BREACH.IsDeploymentIntroActive and BREACH.IsDeploymentIntroActive() then return end
  local radio=ply:GetWeapon("item_radio");if not IsValid(radio) then return end
  local w,h=210,126;local x=ScrW()-w-24;local y=math.max(24,ScrH()-h-100)
  local canTransmit=BREACH.CanRadioTransmit(ply)
  local enabled=radio:GetEnabled() and canTransmit;local tuning=radio:GetRedacting()
  local active=ply:GetActiveWeapon()==radio
  local muted=radio:GetRadioMuted()
  local accent=muted and colors.off or (tuning and colors.blue or colors.on)
  draw.RoundedBox(5,x,y,w,70,colors.bg)
  local function control(row,key,label,highlight)
   local cy=y+7+(row-1)*20
   local ink=highlight and colors.blue or colors.muted
   draw.RoundedBox(2,x+8,cy,30,16,colors.edge)
   draw.RoundedBox(2,x+9,cy+1,28,14,Color(18,28,38))
   draw.SimpleText(key,"RXRadioHint",x+23,cy+8,ink,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
   draw.SimpleText(label,"RXRadioHint",x+46,cy+8,ink,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
  end
  control(1,"G",not canTransmit and "基金会仅高官可以开启" or (enabled and "关闭麦克风" or "打开麦克风"),false)
  local muteConfig=GetConVar("breach_config_radio_mute")
  local muteKey=muteConfig and muteConfig:GetInt() or KEY_H
  local muteLabel=string.upper(input.GetKeyName(muteKey) or "--")
  muteLabel=muteLabel:gsub("MOUSE", "M")
  control(2,muteLabel,muted and "解除静音" or "静音对讲机",false)
  control(3,"R",tuning and "完成调频" or "调频",active and tuning)
  -- Compact, separately framed switch and LCD inspired by the reference terminal.
  draw.RoundedBox(2,x+28,y+76,w-28,50,colors.edge)
  draw.RoundedBox(2,x+29,y+77,w-30,48,Color(24,34,44,225))
  draw.RoundedBox(2,x,y+76,24,24,colors.edge)
  draw.RoundedBox(2,x+1,y+77,22,22,colors.bg)
  draw.SimpleText("G","RXRadioHint",x+12,y+88,colors.muted,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
  draw.SimpleText(tuning and "调频中" or (muted and "静音" or (not canTransmit and "仅接收" or (enabled and "打开" or "关闭 · 仍接收"))),"RXRadioLabel",x+119,y+89,accent,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
  surface.SetDrawColor(colors.edge);surface.DrawRect(x+29,y+100,w-30,1)
  draw.SimpleText(string.format("%.1f",radio:GetRadioFrequency()),"RXRadioCompact",x+119,y+112,colors.text,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
 end)
 SWEP.BounceWeaponIcon=false
 SWEP.InvIcon=Material("nextoren/gui/icons/radio.png")
 function SWEP:PostDrawViewModel(vm)
  local bone=vm:LookupBone("ValveBiped.Bip01_R_Hand");if not bone then return end
  local pos,ang=vm:GetBonePosition(bone);if not pos or not ang then return end
  local screen=pos+ang:Forward()*4.9+ang:Right()*2.66+ang:Up()*-2.89
  ang:RotateAroundAxis(ang:Right(),191);ang:RotateAroundAxis(ang:Up(),-3.1);ang:RotateAroundAxis(ang:Forward(),90)
  cam.Start3D2D(screen,ang,.01)
   draw.RoundedBox(3,0,0,145,58,Color(11,25,34))
   draw.SimpleText(self:GetRadioMuted() and "静音" or string.format("%.1f",self:GetRadioFrequency()),"RXRadioScreen",72,30,self:GetRadioMuted() and colors.muted or colors.on,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
  cam.End3D2D()
 end
end

SWEP.ViewModelFOV	= 62
SWEP.ViewModelFlip	= false
SWEP.ViewModel		= "models/cultist/items/danradio/c_radio.mdl"
SWEP.WorldModel		= "models/cultist/items/danradio/w_radio.mdl"
SWEP.PrintName		= "对讲机"
SWEP.Slot			= 1
SWEP.SlotPos		= 1
SWEP.DrawAmmo		= false
SWEP.DrawCrosshair	= false
SWEP.HoldType		= "items"
SWEP.Spawnable		= false
SWEP.AdminSpawnable	= false

SWEP.droppable				= true

SWEP.Equipableitem 		= true

SWEP.UseHands = true

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Ammo			=  "none"
SWEP.Primary.Automatic		= false

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Ammo			=  "none"
SWEP.Secondary.Automatic	=  false

SWEP.Channel = 100.1
SWEP.Enabled = false

SWEP.Skin = 0

SWEP.Pos = Vector( 2, 4, 2 )
SWEP.Ang = Angle( 0, 90, 0 )

sound.Add( {

	name = "radio.toggle",
	channel = CHAN_WEAPON,
	pitch = { 100, 105 },
	volume = .35,
	sound = "weapons/radio/radio_on.wav"

} )

function SWEP:SetupDataTables()
 self:NetworkVar("Bool",0,"Enabled")
 self:NetworkVar("Bool",1,"Redacting")
 self:NetworkVar("Bool",2,"KeyRedact")
 self:NetworkVar("Bool",3,"RadioMuted")
 self:NetworkVar("Float",0,"Frequency")
 self:NetworkVarNotify("Frequency",function(radio,_,old,new)
  radio.Channel=math.Round(new,1)
 end)
 if SERVER then
  self:SetEnabled(false);self:SetKeyRedact(false);self:SetRedacting(false)
  self:SetRadioMuted(false)
  self:SetRadioFrequency(100.1)
 end
end

function SWEP:CreateWorldModel()

	if ( !self.WModel ) then

		self.WModel = ClientsideModel( self.WorldModel, RENDERGROUP_OPAQUE )
		self.WModel:SetNoDraw( true )

	end

	return self.WModel

end

function SWEP:DrawWorldModel()

	local pl = self:GetOwner()

	if ( pl && pl:IsValid() ) then

		local bone = self.Owner:LookupBone( "ValveBiped.Bip01_R_Hand" )
		if ( !bone ) then return end

		local wm = self:CreateWorldModel()
		local pos, ang = self.Owner:GetBonePosition( bone )

		if ( wm && wm:IsValid() ) then

			ang:RotateAroundAxis( ang:Right(), self.Ang.p )
			ang:RotateAroundAxis( ang:Forward(), self.Ang.y )
			ang:RotateAroundAxis( ang:Up(), self.Ang.r )

			wm:SetRenderOrigin( pos + ang:Right() * self.Pos.x + ang:Forward() * self.Pos.y + ang:Up() * self.Pos.z )
			wm:SetRenderAngles( ang )
			wm:DrawModel()

		end

	else

		self:SetRenderOrigin( nil )
		self:SetRenderAngles( nil )
		self:DrawModel()

	end

end

function SWEP:Holster()


	if ( IsFirstTimePredicted() ) then

		self:SetKeyRedact( false )
		self:SetRedacting( false )

	end

	return true

end

function SWEP:PlaySequence( seq_id)

	self.IdlePlaying = false

	local owner = self:GetOwner()
	if not IsValid(owner) then return end
	local vm = owner:GetViewModel()
	if not IsValid(vm) then return end

	if ( isstring( seq_id ) ) then

		seq_id = vm:LookupSequence( seq_id )

	end

	if not isnumber(seq_id) or seq_id < 0 then return end
	vm:ResetSequence( seq_id )
	vm:SetPlaybackRate( 1.0 )
	vm:SetCycle( 0 )

end

function SWEP:Equip( new_owner )

	net.Start( "RadioHooks" )
	net.Send( new_owner )

end

function SWEP:Deploy()

	self.IdleDelay = CurTime() + 1.2

	self:PlaySequence( "draw" )

	if ( self:GetSkin() != 0 ) then

		self:SetSkin( 0 )

	end

	return true

end

function SWEP:Initialize()

	self:SetHoldType( self.HoldType )

end

function SWEP:Think()

 if SERVER and self:GetEnabled() and not BREACH.CanRadioTransmit(self:GetOwner()) then
  self:SetEnabled(false)
 end

	if ( !self:GetRedacting() && !self.IdlePlaying && ( self.IdleDelay || 0 ) < CurTime() ) then

		self.IdlePlaying = true
		self:PlaySequence( "idle", true )

	end

end

function SWEP:ToggleRadioMute()
 if not SERVER or (self.NextMuteSwitch or 0)>CurTime() then return end
 self.NextMuteSwitch=CurTime()+.5
 self:SetRadioMuted(not self:GetRadioMuted())
end

function SWEP:PrimaryAttack()
end

function SWEP:Reload()

	if ( ( self.NextCheck || 0 ) > CurTime() ) then return end

	if ( !self:GetRedacting() ) then

		self.NextCheck = CurTime() + 1
		self.IdleDelay = CurTime() + 1

		self:SetRedacting( true )

		if ( CLIENT ) then

			BREACH.Player:ChatPrint( true, true, "滚轮调整频率，按 R 完成；静音按键可在设置中修改。" )

		end

		self:PlaySequence( "use" )

	else

		self.NextCheck = CurTime() + 1
		self.IdleDelay = CurTime() + 3

		self:SetRedacting( false )

		self:PlaySequence( "unuse" )

	end

end

function SWEP:SecondaryAttack()

 if SERVER then
  if (self.NextMicSwitch or 0)>CurTime() then return end
  self.NextMicSwitch=CurTime()+.5
 end
 self:SetNextSecondaryFire(CurTime()+.5)

	if ( SERVER ) then

		if ( !self:GetEnabled() ) then

   local owner = self:GetOwner()
   if not BREACH.CanRadioTransmit(owner) then
    if IsValid(owner) then owner:ChatPrint("基金会仅高官可以开启") end
    return
   end

			self.Owner:EmitSound( "radio.toggle" )

		end

		self:SetEnabled( !self:GetEnabled() )

	end

end

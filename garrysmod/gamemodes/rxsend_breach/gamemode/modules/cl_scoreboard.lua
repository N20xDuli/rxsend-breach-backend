-- Presentation only: retain the original spectator / arena / superadmin visibility rule.
BREACH.ScoreboardUI = BREACH.ScoreboardUI or {}
local S = BREACH.ScoreboardUI
S.Colors = {background = Color(17, 19, 20, 248), panel = Color(23, 26, 27),
  row = Color(30, 33, 34), hover = Color(41, 45, 45), line = Color(63, 68, 67),
  text = Color(224, 227, 220), muted = Color(155, 163, 158), accent = Color(161, 178, 148),
  danger = Color(215, 139, 130)}
local C = S.Colors

function S.CanView(ply)
  return IsValid(ply) and (ply:IsSuperAdmin() or ply:GTeam() == TEAM_SPEC or ply:GTeam() == TEAM_ARENA)
end

function S.VoiceState(ply)
  if not IsValid(ply) then return nil end
  local own = ply == LocalPlayer()
  local muted = not own and ply:IsMuted()
  local speaking = ply:IsSpeaking()
  return {own = own, muted = muted, speaking = speaking,
    tooltip = own and "你的语音" or (muted and "取消静音" or "静音这名玩家")}
end

-- Draw the speaker directly so both states remain visible without icon16 assets.
function S.PaintVoice(button, w, h, state)
  if not state then return end
  if not state.own and button:IsHovered() then draw.RoundedBox(0, 0, 0, w, h, C.hover) end
  local color = state.muted and C.danger or (state.speaking and C.accent or C.text)
  local size = math.min(w, h)
  local x, y = (w - size) / 2, (h - size) / 2
  local function line(x1, y1, x2, y2)
    surface.DrawLine(x + x1 * size, y + y1 * size, x + x2 * size, y + y2 * size)
  end
  surface.SetDrawColor(color)
  surface.DrawRect(x + .16 * size, y + .38 * size, .18 * size, .25 * size)
  line(.34, .38, .53, .22) line(.53, .22, .53, .78) line(.53, .78, .34, .63)
  if state.muted then
    line(.65, .35, .88, .66) line(.65, .66, .88, .35)
  else
    line(.65, .35, .74, .5) line(.74, .5, .65, .66)
    line(.76, .23, .91, .5) line(.91, .5, .76, .78)
  end
end

function S.Layout(width, height, contentHeight)
  local w, h = width or ScrW(), height or ScrH()
  local scale = math.Clamp(math.min(w / 1920, h / 1080), 0.7, 1.6)
  return {scale = scale, width = math.min(1120 * scale, w - 48),
    height = math.Clamp((contentHeight or 0) + 154 * scale, 340 * scale, h * 0.82),
    margin = 24 * scale, header = 112 * scale, footer = 42 * scale,
    row = math.Round(44 * scale), group = math.Round(34 * scale), scroll = math.Round(12 * scale)}
end

local function scoreFonts()
  local scale = S.Layout().scale
  for name, size in pairs({Title = 28, Body = 18, Small = 14, Group = 16}) do
    surface.CreateFont("RXScore" .. name, {font = "Microsoft YaHei", size = math.Round(size * scale),
      weight = name == "Title" and 600 or 500, extended = true, antialias = true})
  end
  SB_ROW_HEIGHT = S.Layout().row
end
scoreFonts()
hook.Add("OnScreenSizeChanged", "RXScoreboardFonts", function()
  scoreFonts()
  if IsValid(sboard_panel) then sboard_panel:UpdateScoreboard(true) end
end)

local function fit(text, font, width)
  text = utf8.force(tostring(text or ""))
  surface.SetFont(font)
  if surface.GetTextSize(text) <= width then return text end
  for length = utf8.len(text) - 1, 1, -1 do
    local short = utf8.sub(text, 1, length) .. "…"
    if surface.GetTextSize(short) <= width then return short end
  end
  return ""
end

local function setLabel(label, font, color)
  label:SetFont(font)
  label:SetTextColor(color or C.text)
end

local surface = surface
local draw = draw
local math = math
local string = string
local vgui = vgui


RanksIcons = {}
RanksIcons[ "owner" ] = "icon16/key.png"
RanksIcons[ "founder" ] = "icon16/key.png"
RanksIcons[ "admin" ] = "icon16/shield.png"

GROUP_COUNT = 3

local PANEL = {}

--include( "team_score.lua" )
function ScoreGroup( p )

  if ( !IsValid( p ) ) then return -999 end

  local teamn = p:GTeam()

  return teamn

end

function PaintVBar(vbar)
  vbar:SetHideButtons(true)
  vbar.Paint = function(self, w, h) draw.RoundedBox(0, 0, 0, w, h, C.panel) end
  vbar.btnGrip.Paint = function(self, w, h)
    draw.RoundedBox(0, 3, 0, w - 6, h, self:IsHovered() and C.accent or C.line)
  end
end

function PANEL:Init()
  self.hostdesc = vgui.Create("DLabel", self)
  self.hostname = vgui.Create("DLabel", self)
  self.version = vgui.Create("DLabel", self)
  self.names = vgui.Create("DLabel", self)
  self.roles = vgui.Create("DLabel", self)
  self.footer = vgui.Create("DLabel", self)
  self.names:SetText("玩家")
  self.roles:SetText("当前身份")
  self.hostname:SetText("在线玩家")
  self.version:SetText("")
  self.footer:SetText("按住计分板按键查看  ·  右键玩家打开操作  ·  点击声音图标静音")
  self.ply_frame = vgui.Create("BrPlayerFrame", self)
  self.ply_groups = {}
  self.cols = {}
  self:AddColumn("延迟", nil, 78)
  self:AddColumn("等级", nil, 78)
  self:AddColumn("成就", nil, 78)
  hook.Call("BrScoreboardColumns", nil, self)
  self:ApplySchemeSettings()
  self:UpdateScoreboard(true)
  self:StartUpdateTimer()
  self:SetKeyboardInputEnabled(false)
end

function PANEL:AddColumn( label, func, width )

  self.cols = self.cols || {}
  local lbl = vgui.Create( "DLabel", self )
  lbl:SetText( label )
  lbl.IsHeading = true
  lbl.Width = width || 50

  table.insert( self.cols, lbl )

  return lbl
end

function PANEL:CreateScoreGroup( team_data )

  if ( !team_data || !team_data.index || !team_data.color ) then return end

  local GroupPos = team_data.index

  if ( ValidPanel( self.ply_groups[ GroupPos ] ) ) then return self.ply_groups[ GroupPos ] end

  local GroupColor = team_data.color
  GroupColor = Color( GroupColor.r, GroupColor.g, GroupColor.b, 50 )

  local t = vgui.Create( "BrScoreGroup", self.ply_frame:GetCanvas() )
  t:SetGroupInfo( BREACH.TranslateNonPrefixedString( team_data.name ), GroupColor, GroupPos )

  self.ply_groups[ GroupPos ] = t

  return t

end

function PANEL:StartUpdateTimer()
  timer.Create("BrScoreboardUpdate", 0.25, 0, function()
    if not IsValid(self) then timer.Remove("BrScoreboardUpdate") return end
    if not self:IsVisible() then return end
    if not S.CanView(LocalPlayer()) then GAMEMODE:ScoreboardHide() return end
    self:UpdateScoreboard()
  end)
end

function PANEL:OnRemove()
  timer.Remove("BrScoreboardUpdate")
  if self == sboard_panel then
    GAMEMODE.ShowScoreboard = false
    if not (BREACH.RoleInfo and BREACH.RoleInfo.IsOpen and BREACH.RoleInfo.IsOpen()) then
      gui.EnableScreenClicker(false)
    end
  end
end

function PANEL:Think()
  -- A role transition must not leave privileged rows visible for even one frame.
  if self:IsVisible() and (not S.CanView(LocalPlayer()) or gui.IsGameUIVisible()) then GAMEMODE:ScoreboardHide() end
end

function PANEL:Paint(w, h)
  draw.RoundedBox(0, 0, 0, w, h, C.background)
  surface.SetDrawColor(C.line)
  surface.DrawOutlinedRect(0, 0, w, h, 1)
  local l = S.Layout()
  surface.DrawLine(l.margin, l.header - 8 * l.scale, w - l.margin, l.header - 8 * l.scale)
  surface.DrawLine(l.margin, h - l.footer, w - l.margin, h - l.footer)
end

function PANEL:PerformLayout()
  local l = S.Layout()
  local scale, margin = l.scale, l.margin
  self.ply_frame:SetWide(l.width - margin * 2)
  local gy, laidOut = 0, {}
  for _, data in ipairs(gteams.Teams) do
    local index = data.index
    if not laidOut[index] then
      laidOut[index] = true
      local group = self.ply_groups[index]
      if IsValid(group) then
        group:SetVisible(group:HasRows())
        if group:HasRows() then
          group:SetWide(self.ply_frame:GetWide() - l.scroll)
          group:PerformLayout()
          group:SetPos(0, gy)
          gy = gy + group:GetTall() + 10 * scale
        end
      end
    end
  end
  l = S.Layout(nil, nil, gy)
  self:SetSize(l.width, l.height)
  self:SetPos((ScrW() - l.width) / 2, (ScrH() - l.height) / 2)
  self.ply_frame:SetPos(margin, l.header)
  self.ply_frame:SetTall(l.height - l.header - l.footer - 10 * scale)
  self.ply_frame:GetCanvas():SetTall(gy)
  self.ply_frame:SetScroll(gy > self.ply_frame:GetTall())
  self.ply_frame:PerformLayout()
  self.hostname:SetPos(margin, 18 * scale)
  self.hostname:SetSize(l.width - margin * 2, 36 * scale)
  self.hostdesc:SetPos(margin, 57 * scale)
  self.hostdesc:SetSize(l.width - margin * 2, 22 * scale)
  self.hostdesc:SetText("收容突破  /  " .. #player.GetAll() .. " 人在线  /  距离重启 " .. GetGlobalInt("RoundUntilRestart", 1) .. " 回合")
  self.version:SetVisible(false)
  self.names:SetPos(margin + 12 * scale, 84 * scale)
  self.names:SetSize(150 * scale, 22 * scale)
  local cx = l.width - margin - l.scroll - 44 * scale
  for _, column in ipairs(self.cols) do
    local width = column.Width * scale
    column:SetSize(width, 22 * scale)
    column:SetPos(cx - width, 84 * scale)
    column:SetContentAlignment(5)
    cx = cx - width
  end
  self.roles:SetPos(cx - 230 * scale, 84 * scale)
  self.roles:SetSize(218 * scale, 22 * scale)
  local key = input.LookupBinding("+showscores")
  local keyName = key and string.upper(key) or "未绑定"
  if BREACH.CombatHUD and BREACH.CombatHUD.Binding then keyName = BREACH.CombatHUD.Binding("+showscores") end
  self.footer:SetText("按住 [" .. keyName .. "] 查看  ·  右键玩家打开操作  ·  点击声音图标静音")
  self.footer:SetPos(margin, l.height - l.footer + 10 * scale)
  self.footer:SetSize(l.width - margin * 2, 24 * scale)
end

function PANEL:ApplySchemeSettings()
  setLabel(self.hostname, "RXScoreTitle")
  for _, label in ipairs({self.hostdesc, self.names, self.roles, self.footer, self.version}) do
    setLabel(label, "RXScoreSmall", C.muted)
  end
  for _, column in ipairs(self.cols) do setLabel(column, "RXScoreSmall", C.muted) end
end

function PANEL:UpdateScoreboard( force )

  if ( !force && !self:IsVisible() ) then return end

  local updated_groups = {}

  for _, v in ipairs( gteams.Teams ) do

    local GroupPos = v.index

    if ( updated_groups[ GroupPos ] ) then continue end
    updated_groups[ GroupPos ] = true

    local GroupColor = v.color
    GroupColor = Color(v.color.r, v.color.g, v.color.b, 50)

    if ( !ValidPanel( self.ply_groups[ GroupPos ] ) ) then

      self:CreateScoreGroup( v )

    else

      self.ply_groups[ GroupPos ]:SetGroupInfo( BREACH.TranslateNonPrefixedString(v.name), GroupColor, GroupPos )

    end

  end

  for _, p in ipairs( player.GetAll() ) do

    if ( p && p:IsValid() ) then

      --if p:IsSuperAdmin() and !LocalPlayer():IsAdmin() then continue end

      local group = ScoreGroup( p )

      if ( ValidPanel( self.ply_groups[ group ] ) && !self.ply_groups[ group ]:HasPlayerRow( p ) ) then

        self.ply_groups[ group ]:AddPlayerRow( p )

      end

    end

  end

  for _, group in pairs( self.ply_groups ) do

    if ( ValidPanel( group ) ) then

      group:SetVisible( group:HasRows() )
      group:UpdatePlayerData()

    end

  end

  self:PerformLayout()

end
vgui.Register( "BrScoreboard", PANEL, "Panel" )

local PANEL = {}

function PANEL:Init()

  self.pnlCanvas = vgui.Create( "Panel", self )
  self.YOffset = 0

  self.scroll = vgui.Create( "DVScrollBar", self )

  PaintVBar( self.scroll )

end

function PANEL:GetCanvas() return self.pnlCanvas end

function PANEL:OnMouseWheeled( dlta )

  self.scroll:AddScroll( dlta * -2 )

  self:InvalidateLayout()

end

function PANEL:SetScroll( st )

  self.scroll:SetEnabled( st )

end

function PANEL:PerformLayout()

  self.pnlCanvas:SetVisible( self:IsVisible() )

  self.scroll:SetPos(self:GetWide() - S.Layout().scroll, 0)
  self.scroll:SetSize(S.Layout().scroll, self:GetTall())

  local was_on = self.scroll.Enabled
  self.scroll:SetUp( self:GetTall(), self.pnlCanvas:GetTall() )
  self.scroll:SetEnabled( was_on )

  self.YOffset = self.scroll:GetOffset()

  self.pnlCanvas:SetPos( 0, self.YOffset )
  self.pnlCanvas:SetSize(self:GetWide() - S.Layout().scroll, self.pnlCanvas:GetTall())

end
vgui.Register( "BrPlayerFrame", PANEL, "Panel" )


local table = table
local surface = surface
local draw = draw
local math = math
local team = team

GM = GM || GAMEMODE

--include( "main_score.lua" )

local namecolor = {

  admin = Color( 220, 180, 0, 255 )

}

sboard_panel = sboard_panel || nil

local function ScoreboardRemove()

  if IsValid(sboard_panel) then

    sboard_panel:Remove()
    sboard_panel = nil

  end

end

function GM:ScoreboardCreate()

  ScoreboardRemove()

  sboard_panel = vgui.Create( "BrScoreboard" )

end

function GM:ScoreboardShow()
  if not S.CanView(LocalPlayer()) then return end
  if BREACH.RoleInfo and BREACH.RoleInfo.Close then BREACH.RoleInfo.Close() end
  self:ScoreboardCreate()
  self.ShowScoreboard = true
  sboard_panel:SetVisible(true)
  sboard_panel:UpdateScoreboard(true)
  sboard_panel:StartUpdateTimer()
  gui.EnableScreenClicker(true)
end

function GM:ScoreboardHide()
  self.ShowScoreboard = false
  if IsValid(sboard_panel) then sboard_panel:SetVisible(false) end
  timer.Remove("BrScoreboardUpdate")
  if not (BREACH.RoleInfo and BREACH.RoleInfo.IsOpen and BREACH.RoleInfo.IsOpen()) then
    gui.EnableScreenClicker(false)
  end
end

function GM:GetScoreboardPanel()

  return sboard_panel

end

function GM:HUDDrawScoreBoard() end

function GM:BRScoreboardColorForPlayer( ply )

  if ( !IsValid( ply ) ) then return namecolor.default end

  return namecolor.default

end


--include( "info_score.lua" )

SB_ROW_HEIGHT = S.Layout().row

local PANEL = {}

function PANEL:Init()

  self.info = nil

  self.open = false

  self.cols = {}
  self:AddColumn("延迟", function(ply) return tostring(ply:Ping()) .. " 毫秒" end, 78)
  self:AddColumn("等级", function(ply) return ply.GetNLevel and ply:GetNLevel() or 0 end, 78)
  self:AddColumn("成就", function(ply) return ply.GetAchievementsNum and ply:GetAchievementsNum() or 0 end, 78)

  hook.Call( "BrScoreboardColumns", nil, self )

  for _, c in ipairs( self.cols ) do

    c:SetMouseInputEnabled( false )

  end

  self.tag = vgui.Create( "DLabel", self )
  self.tag:SetText( "" )
  self.tag:SetMouseInputEnabled( false )

  self.rank = vgui.Create( "DImage", self )
  self.rank:SetSize( 16, 16 )

  --self.rank:SetImage( "nextoren_hud/scoreboard/user.png" )
 -- self.rank:SetImage(BREACH.FLAGS[ply:GetNWString("country", "RU")])

  self.avatar = vgui.Create( "AvatarImage", self )
  self.avatar:SetSize( SB_ROW_HEIGHT, SB_ROW_HEIGHT )
  self.avatar:SetMouseInputEnabled( false )

  --[[self.avatar_layout = vgui.Create( "DImage", self.avatar )
  self.avatar_layout:SetSize( SB_ROW_HEIGHT, SB_ROW_HEIGHT )
  self.avatar_layout:SetText( "" )
  self.avatar_layout:SetMouseInputEnabled( false )
  self.avatar_layout:SetImage( "passjj.png" )]]

  self.title = vgui.Create( "DLabel", self )
  self.title:SetMouseInputEnabled( false )

  self.nick = vgui.Create( "DLabel", self )
  self.nick:SetMouseInputEnabled( false )

  self.voice = vgui.Create("DButton", self)
  self.voice:SetText("")
  self.voice.Paint = function(button, w, h)
    S.PaintVoice(button, w, h, S.VoiceState(self.Player))
  end

  self:SetCursor( "hand" )

end

function PANEL:AddColumn( label, func, width )

  self.cols = self.cols || {}
  local lbl = vgui.Create( "DLabel", self )
  lbl.GetPlayerText = func
  lbl.IsHeading = false
  lbl.Width = width || 50

  table.insert( self.cols, lbl )

  return lbl
end

local namecolor = {

  default = C.text,
  admin = Color( 220, 180, 0, 225 ),
  dev = Color( 100, 240, 105, 255 )

}

local function ColorForPlayer( ply )

  if ( ply && ply:IsValid() ) then

    --if ply:IsSuperAdmin() then return Color(0,255,255) end

    if ply:GetFriendStatus() == "friend" then return C.accent end

    local c = hook.Call( "BRScoreboardColorForPlayer", GM, ply )

    if ( c && istable( c ) && c.r && c.b && c.g && c.a ) then

      return c

    end

  end

  return namecolor.default

end

BREACH.FLAGS = BREACH.FLAGS || {}

function PrecacheAllFlags()

  local materials = file.Find("materials/flags16/*", "GAME")

  for _, v in pairs(materials) do
    local name = string.upper(string.StripExtension(v))
    BREACH.FLAGS[name] = "flags16/"..v
  end

end

hook.Add("InitPostEntity", "precache_flags", function()
  PrecacheAllFlags()
end)

function PANEL:Paint(w, h)
  if not IsValid(self.Player) then return end
  draw.RoundedBox(0, 0, 0, w, h, self:IsHovered() and C.hover or C.row)
  if self.Player == LocalPlayer() then
    surface.SetDrawColor(C.accent)
    surface.DrawRect(0, 0, 3 * S.Layout().scale, h)
  end
  return true
end

function PANEL:SetPlayer( ply )

  self.Player = ply
  self.avatar:SetPlayer( ply )

  if ( !self.info ) then

    --local g = ScoreGroup( ply )

    --[[self.info = vgui.Create( "BrScorePlayerInfoTags", self )
    self.info:SetPlayer( ply )]]
    self:InvalidateLayout()

  else

    self.info:SetPlayer( ply )

    self:InvalidateLayout()

  end

  self.voice.DoClick = function()

    if ( ply && ply:IsValid() && ply != LocalPlayer() ) then

      ply:SetMuted( !ply:IsMuted() )
      self:UpdatePlayerData()

    end

  end

  self:UpdatePlayerData()

end

function PANEL:GetPlayer() return self.Player end

function PANEL:UpdatePlayerData()

  if ( !IsValid( self.Player ) ) then return end

  local ply = self.Player

  for i = 1, #self.cols do

    local column = self.cols[i]
    column:SetText(isfunction(column.GetPlayerText) and column.GetPlayerText(ply, column) or "")

  end

  self.RXNickname = ply:Nick()
  local character = ply:GetNamesurvivor()
  self.RXCharacter = ply:GTeam() ~= TEAM_SPEC and character ~= "none" and character or ""
  self.nick:SetTooltip(self.RXNickname)

  --print(ply:GetNWString("country"))
  --self.rank:SetImage(BREACH.FLAGS[ply:GetNWString("country")] or "nextoren_hud/scoreboard/shield.png")
  self.rank:SetImage("nextoren_hud/scoreboard/user.png")
  --print(BREACH.FLAGS[ply:GetNWString("country", "RU")])
  if ( ply:IsAdmin() and ply:GetUserGroup() != "superadmin") then

    self.rank:SetImage( "nextoren_hud/scoreboard/shield.png" )
  elseif RXSEND_YOUTUBERS and RXSEND_YOUTUBERS[ply:SteamID64()] then

    self.rank:SetImage( "icon16/user_red.png" )

  --elseif ply:IsSuperAdmin() then
  --  self.rank:SetImage( "nextoren_hud/scoreboard/user.png" )
  elseif ply:GetUserGroup() == "donator" then
    self.rank:SetImage( "icon16/ruby.png" )
  elseif ( ply:GetUserGroup() == "premium" and ply:GetNWBool("display_premium_icon", true) ) then
    self.rank:SetImage( "icon16/medal_gold_1.png" )
  end

  if ply:GetUserGroup() == "headadmin" then

    self.rank:SetImage( "icon16/shield_add.png" )
  elseif ply:GetUserGroup() == "cm" then

    self.rank:SetImage( "icon16/user_gray.png" )
  end


  self.nick:SizeToContents()
  self.nick:SetTextColor( ColorForPlayer( ply ) )

  self.RXRole = GetLangRole(ply:GetRoleName())
  self.tag:SetTooltip(self.RXRole)

  self:LayoutColumns()

  if ( self.info ) then

    self.info:UpdatePlayerData()

  end

  local voiceState = S.VoiceState(ply)
  self.voice:SetTooltip(voiceState and voiceState.tooltip or "")
  self.voice:SetCursor(ply == LocalPlayer() and "arrow" or "hand")

end

function PANEL:ApplySchemeSettings()
  for _, column in ipairs(self.cols) do setLabel(column, "RXScoreSmall") end
  setLabel(self.nick, "RXScoreBody", ColorForPlayer(self.Player))
  setLabel(self.title, "RXScoreSmall", C.muted)
  setLabel(self.tag, "RXScoreSmall", C.muted)
end

function PANEL:LayoutColumns()
  local scale = S.Layout().scale
  local cx = self:GetWide() - 44 * scale
  for _, column in ipairs(self.cols) do
    local width = column.Width * scale
    column:SetPos(cx - width, 0)
    column:SetSize(width, SB_ROW_HEIGHT)
    column:SetContentAlignment(5)
    cx = cx - width
  end
  local roleWidth = 218 * scale
  self.tag:SetPos(cx - 230 * scale, 0)
  self.tag:SetSize(roleWidth, SB_ROW_HEIGHT)
  self.tag:SetText(fit(self.RXRole, "RXScoreSmall", roleWidth))
  local nickX = 76 * scale
  local nickWidth = math.max(0, cx - 244 * scale - nickX)
  self.nick:SetText(fit(self.RXNickname, "RXScoreBody", nickWidth))
  self.nick:SetPos(nickX, self.RXCharacter ~= "" and 2 * scale or 10 * scale)
  self.nick:SetSize(nickWidth, 24 * scale)
  self.title:SetText(fit(self.RXCharacter, "RXScoreSmall", nickWidth))
  self.title:SetPos(nickX, 25 * scale)
  self.title:SetSize(nickWidth, 18 * scale)
end

function PANEL:PerformLayout()
  local scale = S.Layout().scale
  self:SetTall(SB_ROW_HEIGHT)
  self.avatar:SetPos(32 * scale, 6 * scale)
  self.avatar:SetSize(32 * scale, 32 * scale)
  self.rank:SetPos(10 * scale, 14 * scale)
  self.rank:SetSize(16 * scale, 16 * scale)
  self:LayoutColumns()
  self.voice:SetVisible(true)
  self.voice:SetSize(28 * scale, 28 * scale)
  self.voice:SetPos(self:GetWide() - 36 * scale, 8 * scale)
end

function PANEL:DoClick( x, y ) end

function PANEL:SetOpen( o )

  if ( self.open ) then

    surface.PlaySound( "ui/buttonclickrelease.wav" )

  else

    surface.PlaySound( "ui/buttonclick.wav" )

  end

  self.open = o

  if ( self.info ) then

    self.info:UpdateData()

  end

  self:PerformLayout()
  self:GetParent():PerformLayout()
  sboard_panel:PerformLayout()

end

local function styleMenu(menu)
  menu.Paint = function(self, w, h)
    draw.RoundedBox(0, 0, 0, w, h, C.background)
    surface.SetDrawColor(C.line)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
  end
  for _, option in ipairs(menu:GetCanvas():GetChildren()) do
    if option.SetTextColor then
      option:SetFont("RXScoreSmall")
      option.UpdateColours = function(self) self:SetTextStyleColor(self:IsEnabled() and C.text or C.muted) end
      option.Paint = function(self, w, h)
        if self.Hovered or self.Highlight then draw.RoundedBox(0, 0, 0, w, h, C.hover) end
        if self.GetChecked and self:GetChecked() then
          draw.SimpleText("✓", "RXScoreSmall", 13, h / 2, C.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        return false
      end
      if IsValid(option.SubMenuArrow) then
        option.SubMenuArrow.Paint = function(self, w, h)
          draw.SimpleText("›", "RXScoreBody", w / 2, h / 2, C.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
      end
      if IsValid(option.SubMenu) then styleMenu(option.SubMenu) end
    end
  end
end

function PANEL:DoRightClick()

  if not IsValid(self:GetPlayer()) or not S.CanView(LocalPlayer()) then return end
  local menu = DermaMenu( self )
  menu.Player = self:GetPlayer()

  local close = hook.Call( "BrScoreboardMenu", nil, menu )
  if ( close ) then

    menu:Remove()
    return

  end

  --[[

  local name = GAS.CountryCodes[menu.Player:GetNWString("country", "RU")]
  local country = menu:AddOption( "", function()

    SetClipboardText( GAS.CountryCodes[menu.Player:GetNWString("country", "RU")] )
    surface.PlaySound( "buttons/button9.wav" )

  end )
  country:SetIcon( "flags16/"..menu.Player:GetNWString("country", "RU")..".png" )
  country.Paint = function(self, w, h)
    draw.DrawText(name, "HUDFont", 30, 2)
  end]]

  if RXSEND_YOUTUBERS and RXSEND_YOUTUBERS[menu.Player:SteamID64()] then
    menu:AddOption( "视频频道", function()
      gui.OpenURL(RXSEND_YOUTUBERS[menu.Player:SteamID64()])
      surface.PlaySound("buttons/button9.wav")
    end):SetIcon("icon16/user_red.png")
  end

  menu:AddSpacer()

  local CopyMenu = menu:AddSubMenu( "复制" )

  CopyMenu:AddOption( menu.Player:Nick( true ), function()

    SetClipboardText( menu.Player:Nick( true ) )
    surface.PlaySound( "buttons/button9.wav" )

  end ):SetIcon( "icon16/page_copy.png" )

  CopyMenu:AddOption( "平台账号标识", function()

    SetClipboardText( menu.Player:SteamID() )
    surface.PlaySound( "buttons/button9.wav" )

  end):SetIcon( "icon16/page_copy.png" )

  CopyMenu:AddOption( "64 位平台账号标识", function()

    SetClipboardText( menu.Player:SteamID64() )
    surface.PlaySound( "buttons/button9.wav" )

  end ):SetIcon( "icon16/page_copy.png" )

  if !menu.Player:IsBot() then
    menu:AddOption( "查看成就", function()

      OpenAchievementTab(menu.Player)
      surface.PlaySound( "buttons/button9.wav" )

    end ):SetIcon( "icon16/chart_bar.png" )
  end

  menu:AddOption( "打开 Steam 社区主页", function()

    gui.OpenURL( "http://steamcommunity.com/profiles/"..menu.Player:SteamID64() )
    surface.PlaySound( "buttons/button9.wav" )

  end ):SetIcon( "icon16/world_link.png" )

  menu:AddSpacer()

  styleMenu(menu)
  menu:Open()

  local paintMenu = menu.Paint
  menu.Paint = function( self, w, h )

    if ( !GAMEMODE.ShowScoreboard ) then

      self:Remove()

    end

    paintMenu(self, w, h)

  end

end

vgui.Register( "BrScoreboardPlayerRow", PANEL, "Button" )

--include( "row_score.lua" )

local function CompareScore( pa, pb )

  if ( !ValidPanel( pa ) ) then return false end
  if ( !ValidPanel( pb ) ) then return true end

  local a = pa:GetPlayer()
  local b = pb:GetPlayer()

  if ( !IsValid( a ) ) then return false end
  if ( !IsValid( b ) ) then return true end

  if ( a:Frags() == b:Frags() ) then return a:Deaths() < b:Deaths() end

  return a:Frags() > b:Frags()

end

local PANEL = { }

function PANEL:Init()

  self.color = COLOR_WHITE

  self.rows = {}
  self.rowcount = 0

  self.rows_sorted = {}

  self.group = "spec"

end

function PANEL:SetGroupInfo( name, color, group, groupowner )

  self.name = name
  self.color = color
  self.group = group

end

function PANEL:Paint(w, h)
  local scale = S.Layout().scale
  draw.RoundedBox(0, 0, 0, w, 30 * scale, C.panel)
  surface.SetDrawColor(self.color.r, self.color.g, self.color.b, 180)
  surface.DrawRect(0, 0, 3 * scale, 30 * scale)
  draw.SimpleText(self.name, "RXScoreGroup", 12 * scale, 15 * scale, C.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
  draw.SimpleText(self.rowcount .. " 人", "RXScoreSmall", w - 12 * scale, 15 * scale, C.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

function PANEL:AddPlayerRow( ply )

  if ( !self.rows[ ply ] ) then

    local row = vgui.Create( "BrScoreboardPlayerRow", self )
    row:SetPlayer( ply )
    self.rows[ ply ] = row
    self.rowcount = table.Count( self.rows )

    self:PerformLayout()

  end

end

function PANEL:HasPlayerRow( ply )

  return self.rows[ ply ] != nil

end

function PANEL:HasRows()

  return self.rowcount > 0

end

function PANEL:UpdateSortCache()

  self.rows_sorted = {}

  for _, v in pairs( self.rows ) do

    table.insert( self.rows_sorted, v )

  end

  table.sort( self.rows_sorted, CompareScore )

end

function PANEL:UpdatePlayerData()

  local to_remove = {}

  for k, v in pairs( self.rows ) do

    if ( ValidPanel( v ) && IsValid( v:GetPlayer() ) && ScoreGroup( v:GetPlayer(), self.custgroup ) == self.group ) then

      v:UpdatePlayerData()

    else

      table.insert( to_remove, k )

    end

  end

  if ( #to_remove == 0 ) then return end

  for _, ply in pairs( to_remove ) do

    local pnl = self.rows[ ply ]

    if ( ValidPanel( pnl ) ) then

      pnl:Remove()

    end

    self.rows[ ply ] = nil

  end

  self.rowcount = table.Count( self.rows )

  self:UpdateSortCache()

  self:InvalidateLayout()

end

function PANEL:PerformLayout()
  if self.rowcount < 1 then self:SetVisible(false) return end
  local l = S.Layout()
  self:UpdateSortCache()
  local y = l.group
  for _, row in ipairs(self.rows_sorted) do
    row:SetPos(0, y)
    row:SetSize(self:GetWide(), l.row)
    row:PerformLayout()
    y = y + l.row + 2 * l.scale
  end
  self:SetTall(y)
end

vgui.Register( "BrScoreGroup", PANEL, "Panel" )

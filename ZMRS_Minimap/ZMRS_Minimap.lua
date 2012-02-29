-- Settings ---------------
local minimapPosX = 10
local minimapPosY = 10

-- Caching ---------------
local _G = getfenv(0)

-- Helper functions ---------------
local ZeroFunction = function() end

local HideFrame = function(bframe)
  bframe.Show = ZeroFunction
  bframe:Hide()
end

local PinFrame = function(parentFrame ,pinFrame, scale, anchor, anchor2, off_x, off_y)
  pinFrame:SetScale(scale)
  pinFrame:ClearAllPoints()
  pinFrame:SetPoint(anchor, parentFrame, anchor2, off_x, off_y)
end

-- Set square shape ---------------
function GetMinimapShape() return "SQUARE" end


-- Create frames ---------------
local ZMRS_Addon = CreateFrame("Frame", "ZMRS_MM", Minimap)
local LocFrame   = CreateFrame("Frame", LocFrame, UIParent)
local ClkFrame   = CreateFrame("Frame", ClkFrame, UIParent)


-- Event handling ---------------
function ZMRS_Addon:ZONE_CHANGED_NEW_AREA(self)
  SetMapToCurrentZone()
end

function ZMRS_Addon:PLAYER_LOGIN(self)

  -- Define update time in seconds
  ZMRS_Addon.interval =  0.1
  ZMRS_Addon.update   =  0.0

  -- Setup minimap frame
  Minimap:ClearAllPoints()
  Minimap:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -minimapPosX, minimapPosY)

  -- Move right bars a bit up
  MultiBarRight:SetParent(UIParent)
  MultiBarRight:ClearAllPoints()
  MultiBarRight:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -7, 170)

  -- Move GameTooltip above the minimap
  hooksecurefunc("GameTooltip_SetDefaultAnchor", function (tooltip, parent)
    GameTooltip:SetOwner(parent, "ANCHOR_NONE")
    GameTooltip:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -40, 165)
  end)

  -- Setup location frame
  LocFrame.Text = LocFrame:CreateFontString(nil, "OVERLAY")
  LocFrame.Text:SetPoint("CENTER", LocFrame)
  LocFrame.Text:SetFont("Interface\\AddOns\\ZMRS\\ZMRS_Minimap\\Res\\stat_font.ttf", 14, nil)
  LocFrame.Text:SetShadowOffset(1, -1)
  LocFrame:SetWidth(140)
  LocFrame:SetHeight(18)
  LocFrame:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, -15)

  -- Setup clock frame
  ClkFrame.Text = ClkFrame:CreateFontString(nil,"OVERLAY")
  ClkFrame.Text:SetPoint("LEFT",ClkFrame,"LEFT",1,0)
  ClkFrame.Text:SetFont("Interface\\AddOns\\ZMRS\\ZMRS_Minimap\\Res\\stat_font.ttf", 10, nil)
  ClkFrame.Text:SetShadowOffset(1, -1)
  ClkFrame.Text:SetTextColor(1, 1, 1)
  ClkFrame:SetWidth(38)
  ClkFrame:SetHeight(13)
  ClkFrame:SetScale(1.3)
  ClkFrame:SetFrameLevel(4)
  ClkFrame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 6, 7)
  ClkFrame:SetBackdrop({
    bgFile = "Interface\\AddOns\\ZMRS\\ZMRS_Minimap\\Res\\backdrop",
    insets = {left = -2, right = -2, top = -2, bottom = -2}
  })
  ClkFrame:SetFrameStrata("BACKGROUND")
  ClkFrame:SetBackdropColor(0, 0, 0, 0.9);
  ClkFrame:SetBackdropBorderColor(1, 1, 1, 1)

  -- Set mask of our minimap
  Minimap:SetMaskTexture("Interface\\AddOns\\ZMRS\\ZMRS_Minimap\\Res\\minimap_mask")

  -- Set backdrop of our minimap, and now it's look perfectly
  ZMRS_Addon:SetParent(Minimap)
  ZMRS_Addon:SetFrameLevel(1)
  ZMRS_Addon:SetBackdrop({
    bgFile = "Interface\\AddOns\\ZMRS\\ZMRS_Minimap\\Res\\backdrop",
    insets = {left = -2, right = -2, top = -2, bottom = -2}
  })
  ZMRS_Addon:SetBackdropColor(0,0,0)
  ZMRS_Addon:SetAllPoints(Minimap)

  -- Hide right gryphon
  MainMenuBarRightEndCap:Hide()

  -- Enable mouse-scrolling over minimap for changing zoom
  ZMRS_Addon:SetWidth(112)
  ZMRS_Addon:SetHeight(112)
  ZMRS_Addon:SetPoint("CENTER")
  ZMRS_Addon:SetToplevel(true)
  ZMRS_Addon:EnableMouseWheel(true)
  ZMRS_Addon:SetScript("OnMouseWheel", function(this, arg1) if arg1 > 0 then Minimap_ZoomIn() else Minimap_ZoomOut() end end)

  -- Pin some minimap buttons
  GameTimeFrame:SetFrameLevel(5)
  PinFrame(Minimap,  MiniMapTracking,         0.8, "TOPRIGHT",   "TOPRIGHT",   -50,  20)
  PinFrame(Minimap,  MiniMapBattlefieldFrame, 0.9, "BOTTOMLEFT", "BOTTOMLEFT", -3,  -3)
  PinFrame(Minimap,  MiniMapMailFrame,        1,   "TOPRIGHT",   "TOPRIGHT",   -84,  16)
  PinFrame(ClkFrame, GameTimeFrame,           0.5, "RIGHT",      "RIGHT",       10,  0)

  -- Hide some blizzard borders, buttons, etc
  local framesToHide = {
    _G["MinimapBorder"],
    _G["MinimapZoomIn"],
    _G["MinimapZoomOut"],
    _G["MinimapZoneText"],
    _G["MinimapNorthTag"],
    _G["MinimapBorderTop"],
    _G["MinimapToggleButton"],
    _G["MinimapZoneTextButton"],
    _G["MiniMapWorldMapButton"],
    _G["MiniMapMeetingStoneFrame"],
    _G["MiniMapVoiceChatFrame"],
    _G["BattlegroundShine"],
    _G["TimeManagerClockButton"],
  }
  for ndx, bframe in pairs(framesToHide) do HideFrame(bframe) end

  -- Set update
  ZMRS_Addon:SetScript("OnUpdate", function(self, elapsed)
    self.update = self.update + elapsed
    if(self.update < self.interval) then return end
    self.update = 0

    -- Set location text and color
    LocFrame.Text:SetText(GetMinimapZoneText())
    local pvpType = GetZonePVPInfo()
    if ( pvpType == "sanctuary" ) then
      LocFrame.Text:SetTextColor(0.41, 0.8, 0.94);
    elseif ( pvpType == "arena" ) then
      LocFrame.Text:SetTextColor(1.0, 0.1, 0.1);
    elseif ( pvpType == "friendly" ) then
      LocFrame.Text:SetTextColor(0.1, 1.0, 0.1);
    elseif ( pvpType == "hostile" ) then
      LocFrame.Text:SetTextColor(1.0, 0.1, 0.1);
    elseif ( pvpType == "contested" ) then
      LocFrame.Text:SetTextColor(1.0, 0.7, 0.0);
    else
      LocFrame.Text:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
    end

    -- Set clock text
    ClkFrame.Text:SetText(strsub(date(), -8, -4))
  end)

  -- Force update
  ZMRS_Addon:ZONE_CHANGED_NEW_AREA()
end


-- Event setup ---------------
ZMRS_Addon:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
ZMRS_Addon:RegisterEvent("PLAYER_LOGIN")
ZMRS_Addon:RegisterEvent("ZONE_CHANGED_NEW_AREA")

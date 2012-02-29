--------------------------------
-- (( Check oUF is loaded )) ---
--------------------------------

local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, "ZMRS_UnitFrames was unable to locate oUF install.")

--------------------------
-- (( CONFIGURATION )) ---
--------------------------
--- You can edit this  ---
--------------------------

local SkullComboPoints = true
local playerCastBar_x  = 0
local playerCastBar_y  = -138
local targetCastBar_x  = 11
local targetCastBar_y  = -106
local focusCastBar_x   = 30
local focusCastBar_y   = 300

---------------------
--- END OF CONFIG ---
---------------------
-- (( VARIABLES )) --
---------------------

local _TEXTURE = [[Interface\AddOns\ZMRS\ZMRS_UnitFrames\Res\HalF]]
local _FONT    = [[Interface\Addons\ZMRS\ZMRS_UnitFrames\Res\Calibri.ttf]]
local _COMBO   = [[Interface\Addons\ZMRS\ZMRS_UnitFrames\Res\cbp]]

---------------------------------
-- (( CUSTOM COLORS & STUFF )) --
---------------------------------

local colors = setmetatable({
  power = setmetatable({
    ['MANA'] = {.34,.56,.88},
    ['RAGE'] = {.79,.27,.31},
    ['ENERGY'] = {.92,.94,.24},
    ['RUNIC_POWER'] = {0, .82, 1},
  }, {__index = oUF.colors.power}),
}, {__index = oUF.colors})

local function Hex(r, g, b)
  if type(r) == 'table' then
    if r.r then r, g, b = r.r, r.g, r.b else r, g, b = unpack(r) end
  end
  return string.format('|cff%02x%02x%02x', r*255, g*255, b*255)
end

----------------
-- (( MENU )) --
----------------

local menu = function(self)
  local unit = self.unit:sub(1, -2)
  local cunit = self.unit:gsub('^%l', string.upper)

  if(cunit == 'Vehicle') then
    cunit = 'Pet'
  end

  if(unit == 'party' or unit == 'partypet') then
    ToggleDropDownMenu(1, nil, _G['PartyMemberFrame'..self.id..'DropDown'], 'cursor', 0, 0)
  elseif(_G[cunit..'FrameDropDown']) then
    ToggleDropDownMenu(1, nil, _G[cunit..'FrameDropDown'], 'cursor', 0, 0)
  end
end

-----------------------
-- (( CUSTOM TAGS )) --
-----------------------

oUF.Tags['zmrs:namecolor'] = function(unit)
  local _, x = oUF.Tags.class(unit)
  if UnitIsPlayer(unit) then
    return x and Hex(RAID_CLASS_COLORS[x])
  else
    r, g, b, _ = UnitSelectionColor(unit)
    return string.format('|cff%02x%02x%02x', r*255, g*255, b*255)
  end
end
oUF.TagEvents['zmrs:namecolor'] = 'UNIT_NAME_UPDATE UNIT_TARGET'

oUF.Tags['zmrs:gradientcolor'] = function(unit)
  r, g, b = oUF.ColorGradient(oUF.Tags.curhp(unit) / oUF.Tags.maxhp(unit), 1, 0, 0, 1, 1, 0, 0, 1, 0)
  return string.format('|cff%02x%02x%02x', r*255, g*255, b*255)
end
oUF.TagEvents['zmrs:gradientcolor'] = oUF.TagEvents.curhp

oUF.Tags['zmrs:missinghp'] = function(unit)
  miss = oUF.Tags.maxhp(unit) - oUF.Tags.curhp(unit)
  if miss > 0 then
    return string.format('|cffff3c00-%d|r', miss)
  else
    return ''
  end
end
oUF.TagEvents['zmrs:missinghp'] = oUF.TagEvents.missinghp

------------------------
-- (( UPDATE FUNCS )) --
------------------------

local PostUpdateHealth = function(health, unit, min, max)
  local self = health:GetParent()
  if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
    self:SetBackdropBorderColor(.3, .3, .3)
  else
    local r, g, b = UnitSelectionColor(unit)
    self:SetBackdropBorderColor(r, g, b)
  end

  if(UnitIsDead(unit)) then
    health:SetValue(0)
    health.value:SetText('Dead')
  elseif(UnitIsGhost(unit)) then
    health:SetValue(0)
    health.value:SetText('Ghost')
  elseif(not UnitIsConnected(unit)) then
    health.value:SetText('Offline')
  else
    health.value:SetFormattedText('%s/%s', min, max)
  end
end

local function UpdateMasterLooter(self)
  self.MasterLooter:ClearAllPoints()
  if((UnitInParty(self.unit) or UnitInRaid(self.unit)) and UnitIsPartyLeader(self.unit)) then
    self.MasterLooter:SetPoint('RIGHT', self.Leader, 'LEFT')
  else
    self.MasterLooter:SetPoint('BOTTOM', self.Health, 'TOPRIGHT', 0, 11)
  end
end

local function UpdateNameOnCombos(self)
  if self.unit ~= 'target' then return end

  if(GetComboPoints('player', self.unit) ~= 0) then
    self.Name:Hide()
  else
    self.Name:Show()
  end
end

-------------------------
-- (( ICONS TEXTURE )) --
-------------------------

local function PostCreateAuraIcon(self, button, icons)
  icons.showDebuffType = true
  button.cd:SetReverse()
  button.cd:SetPoint('TOPLEFT', button, 'TOPLEFT', 2, -2)
  button.cd:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -2, 1)

  button.overlay:SetTexture([=[Interface\Addons\ZMRS\ZMRS_UnitFrames\Res\border]=])
  button.overlay:SetTexCoord(0, 1, 0, 1)
  button.overlay.Hide = function(self) self:SetVertexColor(0.25, 0.25, 0.25) end
end

------------------
-- (( LAYOUT )) --
------------------

local Shared = function(self, unit, isSingle)
  self.menu = menu

  self:SetScript('OnEnter', UnitFrame_OnEnter)
  self:SetScript('OnLeave', UnitFrame_OnLeave)

  self:RegisterForClicks('AnyDown')
  --self:SetAttribute('*type2', 'menu')

  -- Enable our colors
  self.colors = colors

  ------------------
  -- ( BACKDROP ) --
  ------------------
  self:SetBackdrop({
    bgFile = 'Interface\\Tooltips\\UI-Tooltip-Background', tile = true, tileSize = 16,
    --edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border', edgeSize = 16,
    insets = {left = -1, right = -1, top = -1, bottom = -2.5},
  })
  self:SetBackdropColor(0,0,0,.59)

  --------------
  -- ( BARS ) --
  --------------

  blanksp = CreateFrame('StatusBar')
  blanksp:SetHeight(44/3)
  blanksp:SetParent(self)
  blanksp:SetPoint('TOP')
  blanksp:SetPoint('LEFT', self, 'LEFT', 0, 0)
  blanksp:SetPoint('RIGHT')

  self.Health = CreateFrame('StatusBar')
  self.Health:SetHeight(44/3 + 1.2)
  self.Health:SetStatusBarTexture(_TEXTURE)
  self.Health:SetParent(self)
  self.Health:SetPoint('TOP', blanksp, 'BOTTOM')
  self.Health:SetPoint('LEFT', self, 'LEFT', 0, 0)
  self.Health:SetPoint('RIGHT')

  self.Health.bg = self.Health:CreateTexture(nil, 'BORDER')
  self.Health.bg:SetAllPoints(self.Health)
  self.Health.bg:SetTexture(_TEXTURE)
  self.Health.bg:SetAlpha(0.18)

  self.Health.value = self.Health:CreateFontString(nil, 'OVERLAY')
  self.Health.value:SetFont(_FONT, 10, 'NONE')
  self.Health.value:SetTextColor(1, 1, 1)
  self.Health.value:SetShadowOffset(1, -1)

  self.Health.colorClass        = false
  self.Health.colorReaction     = false
  self.Health.colorDisconnected = true
  self.Health.colorTapping      = true
  self.Health.colorSmooth       = true
  self.Health.frequentUpdates   = true
  self.Health.PostUpdate        = PostUpdateHealth

  missing = self.Health:CreateFontString(nil, 'OVERLAY')
  missing:SetFont(_FONT, 10, 'NONE')
  missing:SetJustifyH('RIGHT')
  missing:SetShadowOffset(1, -1)
  self:Tag(missing, '[dead][offline][zmrs:missinghp]')

  perc = blanksp:CreateFontString(nil, 'OVERLAY')
  perc:SetJustifyH('RIGHT')
  perc:SetFont(_FONT, 10, 'NONE')
  perc:SetShadowOffset(1, -1)
  self:Tag(perc, '[zmrs:gradientcolor][perhp]%|r')

  self.Power = CreateFrame('StatusBar')
  self.Power:SetHeight(44/3 - 1.5)
  self.Power:SetStatusBarTexture(_TEXTURE)
  self.Power:SetParent(self)
  self.Power:SetPoint('LEFT', self, 'LEFT', 0, 0)
  self.Power:SetPoint('RIGHT')
  self.Power:SetPoint('TOP', self.Health, 'BOTTOM', 0, -1.1)

  self.Power.bg = self.Power:CreateTexture(nil, 'BORDER')
  self.Power.bg:SetAllPoints(self.Power)
  self.Power.bg:SetTexture(_TEXTURE)
  self.Power.bg:SetAlpha(0.18)

  power = self.Power:CreateFontString(nil, 'OVERLAY')
  power:SetFont(_FONT, 9, 'NONE')
  power:SetTextColor(1 ,1 ,1)
  power:SetShadowOffset(1, -1)

  self.Power.colorTapping      = false
  self.Power.colorDisconnected = false
  self.Power.colorClass        = false
  self.Power.colorPower        = true
  self.Power.frequentUpdates   = true
  self:Tag(power, '[curpp]/[maxpp]')

  name = blanksp:CreateFontString(nil, 'OVERLAY')
  name:SetPoint('LEFT', blanksp, 'LEFT', 0, 0)
  name:SetJustifyH('LEFT')
  name:SetFont(_FONT, 12, 'NONE')
  name:SetShadowOffset(1, -1)
  self:Tag(name, unit == 'target' and '[level][shortclassification] [zmrs:namecolor][name]|r' or '[zmrs:namecolor][name]|r')
  self.Name = name

  self.Leader = self.Health:CreateTexture(nil, 'OVERLAY')
  self.Leader:SetPoint('BOTTOM', self.Health, 'TOPRIGHT', 0, 11)
  self.Leader:SetHeight(12)
  self.Leader:SetWidth(12)

  self.MasterLooter = self.Health:CreateTexture(nil, 'OVERLAY')
  self.MasterLooter:SetPoint('RIGHT', self.Leader, 'LEFT')
  self.MasterLooter:SetHeight(12)
  self.MasterLooter:SetWidth(12)

  --table.insert(self.__elements, UpdateMasterLooter)
  --self:RegisterEvent('PARTY_LOOT_METHOD_CHANGED', UpdateMasterLooter)
  --self:RegisterEvent('PARTY_MEMBERS_CHANGED', UpdateMasterLooter)
  --self:RegisterEvent('PARTY_LEADER_CHANGED', UpdateMasterLooter)
  --self:RegisterEvent('UNIT_COMBO_POINTS', UpdateNameOnCombos)

  if unit == 'target' then
    self.RaidIcon = self.Health:CreateTexture(nil, 'OVERLAY')
    self.RaidIcon:SetHeight(32)
    self.RaidIcon:SetWidth(32)
    self.RaidIcon:SetPoint('LEFT', self, 'RIGHT', 5, 0)
    self.RaidIcon:SetTexture('Interface\\TargetingFrame\\UI-RaidTargetingIcons')
  end

  --------------------------
  -- ( FRAME ATTRIBUTES ) --
  --------------------------
  if unit == 'player' or unit == 'target' then
    self:SetSize(186, 44)
  end

  self.PostCreateAuraIcon = PostCreateAuraIcon
  --self.DisallowVehicleSwap = true

  if unit == 'player' or unit == 'target' then
    self.Name:SetPoint('LEFT', blanksp, 'LEFT', 2, 0)
    self.Name:SetHeight(14)
    self.Name:SetWidth(130)

    self.Health.value:SetPoint('LEFT', 4, 0)
    self.Health.value:Show()
    perc:SetPoint('RIGHT', blanksp, 'RIGHT', -3, 0)
    missing:SetPoint('RIGHT', self.Health, 'RIGHT', -3, 0)
    power:SetPoint('LEFT', 4, 0)
  end

  -- Experience bar. Depends on oUF_Experience
  if IsAddOnLoaded('oUF_Experience') and unit == 'player' then
    self.Experience = CreateFrame('StatusBar', nil, self)
    self.Experience:SetParent(UIParent)
    self.Experience:SetPoint('BOTTOM', self, 'TOP', 0, 4)
    self.Experience:SetStatusBarTexture(_TEXTURE)
    self.Experience:SetBackdrop{
      bgFile = 'Interface\\Tooltips\\UI-Tooltip-Background', tile = true, tileSize = 16,
      insets = {left = -1, right = -1, top = -1.5, bottom = -1.5},
    }
    self.Experience:SetBackdropColor(0, 0, 0, .59)
    self.Experience:SetWidth(186)
    self.Experience:SetHeight(10)
    self.Experience:SetStatusBarColor(26/255, 195/255, 197/255)

    self.Experience.MouseOver = false
    self.Experience.Tooltip = false

    self.Experience.Text = self.Experience:CreateFontString(nil, 'OVERLAY')
    self.Experience.Text:SetFont(_FONT, 9, 'NONE')
    self.Experience.Text:SetTextColor(1, 1, 1)
    self.Experience.Text:SetShadowOffset(1, -1)
    self.Experience.Text:SetPoint('CENTER', self.Experience, 'CENTER', 0, 0)

    self.Experience.PostUpdate = function(self, event, unit, bar, min, max)
      self.Experience.Text:SetFormattedText('%d / %d (%.1f %%)', min, max, min/max*100)
    end
  end

  -- Reputation bar. Depends on oUF_Reputation
  if IsAddOnLoaded('oUF_Reputation') and unit == 'player' and UnitLevel(unit) == MAX_PLAYER_LEVEL then
    self.Reputation = CreateFrame('StatusBar', nil, self)
    self.Reputation:SetParent(UIParent)
    self.Reputation:SetPoint('BOTTOM', self, 'TOP', 0, 4)
    self.Reputation:SetStatusBarTexture(_TEXTURE)
    self.Reputation:SetBackdrop{
      bgFile = 'Interface\\Tooltips\\UI-Tooltip-Background', tile = true, tileSize = 16,
      insets = {left = -1, right = -1, top = -1.5, bottom = -1.5},
    }
    self.Reputation:SetBackdropColor(0, 0, 0 ,.59)
    self.Reputation:SetWidth(186)
    self.Reputation:SetHeight(10)
    self.Reputation:SetStatusBarColor(26/255, 195/255, 197/255)

    self.Reputation.MouseOver = false
    self.Reputation.Tooltip = false

    self.Reputation.Text = self.Reputation:CreateFontString(nil, 'OVERLAY')
    self.Reputation.Text:SetFont(_FONT, 10, 'NONE')
    self.Reputation.Text:SetTextColor(1, 1, 1)
    self.Reputation.Text:SetShadowOffset(1, -1)
    self.Reputation.Text:SetPoint('CENTER', self.Reputation, 'CENTER', 0, 0)

    --self.Reputation.PostUpdate = function(self, event, unit, bar, min, max, value, name, id)
    --  self.Reputation.Text:SetFormattedText('%d / %d', value - min, max - min)
    --end
  end

  if unit == 'target' then
    if SkullComboPoints then

      -- Combo Points's code is taken from Caellian's
      self.CPoints = {}
      self.CPoints.unit = 'player'
      for i = 1, 5 do
        self.CPoints[i] = blanksp:CreateTexture(nil, 'OVERLAY')
        self.CPoints[i]:SetHeight(14)
        self.CPoints[i]:SetWidth(14)
        self.CPoints[i]:SetTexture(_COMBO)
        if(i==1) then
          self.CPoints[i]:SetPoint('LEFT', blanksp, 'LEFT', 2, 2)
          self.CPoints[i]:SetVertexColor(72/255, 208/255, 91/255)
        else
          self.CPoints[i]:SetPoint('LEFT', self.CPoints[i-1], 'RIGHT', 1)
        end
      end

      self.CPoints[2]:SetVertexColor(72/255, 208/255, 91/255)
      self.CPoints[3]:SetVertexColor(245/255, 195/255, 15/255)
      self.CPoints[4]:SetVertexColor(245/255, 195/255, 15/255)
      self.CPoints[5]:SetVertexColor(238/255, 32/255, 36/255)
    else
      -- p3lim's
      self.CPoints = self:CreateFontString(nil, 'OVERLAY')
      self.CPoints:SetFont(_FONT, 24, 'NONE')
      self.CPoints:SetPoint('LEFT', self, 'RIGHT', 5, 0)
      self.CPoints:SetTextColor(1, 1, 1)
      self.CPoints:SetJustifyH('RIGHT')
      self.CPoints.unit = 'player'

      self.RaidIcon:ClearAllPoints()
      self.RaidIcon:SetPoint('LEFT', self.CPoints, 'RIGHT', 4, 0)
      self:UnregisterEvent('UNIT_COMBO_POINTS', UpdateNameOnCombos)
    end

    missing:Hide()
    self.Health.colorClass = true

    self.Buffs = CreateFrame('Frame', nil, self)
    self.Buffs.size = 21
    self.Buffs:SetHeight(self.Buffs.size)
    self.Buffs:SetWidth(self.Buffs.size * 9)
    self.Buffs:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', -1, -4)
    self.Buffs.initialAnchor = 'TOPLEFT'
    self.Buffs['growth-y'] = 'DOWN'
    self.Buffs.num = 18
    self.Buffs.spacing = 2

    self.Debuffs = CreateFrame('Frame', nil, self)
    self.Debuffs.size = 28
    self.Debuffs:SetHeight(self.Debuffs.size)
    self.Debuffs:SetWidth(self.Debuffs.size * 6)
    self.Debuffs:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', -1, 18)
    self.Debuffs.initialAnchor = 'BOTTOMLEFT'
    self.Debuffs['growth-y'] = 'UP'
    self.Debuffs.filter = false
    self.Debuffs.onlyShowPlayer = false
    self.Debuffs.num = 34
    self.Debuffs.showDebuffType = true
    self.Debuffs.spacing = 2
  end

  if unit == 'focus' then
    self.Debuffs = CreateFrame('Frame', nil, self)
    self.Debuffs.size = 28
    self.Debuffs:SetHeight(self.Debuffs.size)
    self.Debuffs:SetWidth(self.Debuffs.size * 6)
    self.Debuffs:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', -2, -3)
    self.Debuffs.initialAnchor = 'BOTTOMLEFT'
    self.Debuffs['growth-y'] = 'DOWN'
    self.Debuffs.filter = false
    self.Debuffs.num = 15
    self.Debuffs.spacing = 1.5
  end

  if unit == 'targettarget' then
    self:SetSize(186, 10)

    blanksp:SetHeight(10)
    self.Name:ClearAllPoints()
    self.Name:SetPoint('LEFT', blanksp, 'LEFT', 1, 0)
    self.Name:SetHeight(10)
    self.Power:ClearAllPoints()
    self.Power:Hide()

    power:Hide()

    self.Health:ClearAllPoints()
    self.Health:Hide()
    self.Health.value:Hide()

    perc:Show()
    perc:SetPoint('RIGHT', blanksp, 'RIGHT', -3, 0)
    missing:Hide()
  end

  if unit == 'pet' then
    self:SetSize(20, 44)

    blanksp:Hide()
    self.Name:Hide()
    perc:Hide()
    missing:Hide()

    self.Power:ClearAllPoints()
    self.Power:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, 0)
    self.Power:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', 0, -1)
    self.Power:SetHeight(45)
    self.Power:SetWidth(5)
    self.Power:SetOrientation('VERTICAL')

    self.Health:ClearAllPoints()
    self.Health:SetPoint('TOPLEFT', self.Power, 'TOPRIGHT', 1, 0)
    self.Health:SetPoint('BOTTOMLEFT', self.Power, 'BOTTOMRIGHT', 1, 0)
    self.Health:SetHeight(45)
    self.Health:SetWidth(14)
    self.Health:SetOrientation('VERTICAL')
  end

  if unit == 'focus' then
    self:SetSize(130, 28)

    -- blanksp:Hide()
    -- self.Name:Hide()
    -- perc:Hide()
    missing:Hide()

    self.Leader:ClearAllPoints()
    self.MasterLooter:ClearAllPoints()

    self.Health:ClearAllPoints()
    self.Health:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, 0)
    self.Health:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 0, 0)
    self.Health:SetHeight(16)
    self.Health.colorClass = true

    self.Power:ClearAllPoints()
    self.Power:SetPoint('TOPLEFT', self.Health, 'BOTTOMLEFT', 0, -1)
    self.Power:SetPoint('TOPRIGHT', self.Health, 'BOTTOMRIGHT', 0, -1)
    self.Power:SetHeight(11)
  end

  if unit == 'player' then
    perc:Hide()
  end

  -------------------
  -- ( CAST BARS ) --
  -------------------

  if(unit == 'player' or unit == 'target' or unit == 'focus') then
    self.Castbar = CreateFrame('StatusBar', nil, self)
    self.Castbar:SetStatusBarTexture(_TEXTURE)

    if(unit == 'player') then
      self.Castbar:SetStatusBarColor(72/255, 208/255, 91/255)

      self.Castbar:SetHeight(20)
      self.Castbar:SetWidth(224)

      self.Castbar:SetBackdrop({
        bgFile = 'Interface\ChatFrame\ChatFrameBackground',
        insets = {top = -3, left = -3, bottom = -3, right = -3}
      })

      self.Castbar.SafeZone = self.Castbar:CreateTexture(nil, 'ARTWORK')
      self.Castbar.SafeZone:SetTexture(_TEXTURE)
      self.Castbar.SafeZone:SetVertexColor(.75, .10, .10, .6)
      --self.Castbar.SafeZone:SetVertexColor(46/255, 0, 0, .6)
      self.Castbar.SafeZone:SetPoint('TOPRIGHT')
      self.Castbar.SafeZone:SetPoint('BOTTOMRIGHT')

      self.Castbar.Text = self.Castbar:CreateFontString(nil, 'OVERLAY')
      self.Castbar.Text:SetPoint('LEFT', self.Castbar, 2, 0)
      self.Castbar.Text:SetFont(_FONT, 13, 'NONE')
      self.Castbar.Text:SetShadowOffset(1, -1)
      self.Castbar.Text:SetTextColor(1, 1, 1)
      self.Castbar.Text:SetJustifyH('LEFT')

      self.Castbar:SetPoint('CENTER', UIParent, 'CENTER', playerCastBar_x, playerCastBar_y)

    elseif (unit == 'target') then

      self.Castbar:SetStatusBarColor(0.73, 0.1, 0.1)
      self.Castbar:SetHeight(24)
      self.Castbar:SetWidth(200)

      self.Castbar:SetBackdrop({
        bgFile = 'Interface\ChatFrame\ChatFrameBackground',
        insets = {top = -3, left = -30, bottom = -3, right = -3}
      })

      self.Castbar.Icon = self.Castbar:CreateTexture(nil, 'OVERLAY')
      self.Castbar.Icon:SetPoint('RIGHT', self.Castbar, 'LEFT', -1, 0)
      self.Castbar.Icon:SetHeight(24)
      self.Castbar.Icon:SetWidth(24)
      self.Castbar.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

      self.Castbar.Text = self.Castbar:CreateFontString(nil, 'OVERLAY')
      self.Castbar.Text:SetPoint('LEFT', self.Castbar, 2, 0)
      self.Castbar.Text:SetFont(_FONT, 13, 'NONE')
      self.Castbar.Text:SetShadowOffset(1, -1)
      self.Castbar.Text:SetTextColor(1, 1, 1)
      self.Castbar.Text:SetJustifyH('LEFT')

      self.PostCastStart = function(_, event, unit, name, rank, text, castid, notInterruptible)
        if notInterruptible then
          self.Castbar:SetStatusBarColor(150/255, 0.1, 150/255)
        end
      end

      self.PostChannelStart = function(_, event, unit, name, rank, text, notInterruptible)
        if notInterruptible then
          self.Castbar:SetStatusBarColor(150/255, 0.1, 150/255)
        end
      end

      self.Castbar:SetPoint('CENTER', UIParent, 'CENTER', targetCastBar_x, targetCastBar_y)

    else
      self.Castbar:SetStatusBarColor(33/255, 172/255, 224/255)
      self.Castbar:SetHeight(36)
      self.Castbar:SetWidth(450)

      self.Castbar:SetBackdrop({
        bgFile = 'Interface\ChatFrame\ChatFrameBackground',
        insets = {top = -3, left = -30, bottom = -3, right = -3}
      })

      self.Castbar.Icon = self.Castbar:CreateTexture(nil, 'OVERLAY')
      self.Castbar.Icon:SetPoint('RIGHT', self.Castbar, 'LEFT', 0, 0)
      self.Castbar.Icon:SetHeight(36)
      self.Castbar.Icon:SetWidth(36)
      self.Castbar.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

      self.Castbar.Text = self.Castbar:CreateFontString(nil, 'OVERLAY')
      self.Castbar.Text:SetPoint('CENTER', self.Castbar, 2, 0)
      self.Castbar.Text:SetFont(_FONT, 16, 'NONE')
      self.Castbar.Text:SetShadowOffset(1, -1)
      self.Castbar.Text:SetTextColor(1, 1, 1)
      self.Castbar.Text:SetJustifyH('LEFT')

      self.Castbar:SetPoint('CENTER', UIParent, 'CENTER', focusCastBar_x, focusCastBar_y)
    end

    self.Castbar:SetBackdropColor(0, 0, 0, 0.7)
    self.Castbar.bg = self.Castbar:CreateTexture(nil, 'BORDER')
    self.Castbar.bg:SetAllPoints(self.Castbar)
    self.Castbar.bg:SetTexture(0, 0, 0, 0.8)

    self.Castbar.CustomTimeText = function(self, duration)
      if self.casting then
        self.Time:SetFormattedText('%.1f / %.1f', duration, self.max)
      elseif self.channeling then
        self.Time:SetFormattedText('%.1f', duration)
      end
    end

    self.Castbar.Time = self.Castbar:CreateFontString(nil, 'OVERLAY')
    self.Castbar.Time:SetPoint('RIGHT', self.Castbar, -2, 0)
    self.Castbar.Time:SetFont(_FONT, 12, 'NONE')
    self.Castbar.Time:SetTextColor(1, 1, 1)
    self.Castbar.Time:SetJustifyH('RIGHT')
  end
end

oUF:RegisterStyle('ZMRS', Shared)

-- A small helper to change the style into a unit specific, if it exists
local spawnHelper = function(self, unit, ...)
  self:SetActiveStyle('ZMRS')
  local object = self:Spawn(unit)
  object:SetPoint(...)
  return object
end

oUF:Factory(function(self)
  spawnHelper(self, 'player', 'CENTER', -230, -140)
  spawnHelper(self, 'pet', 'CENTER', -338, -140)
  spawnHelper(self, 'target', 'CENTER', 230, -140)
  spawnHelper(self, 'targettarget', 'CENTER', 230, -108)
  spawnHelper(self, 'focus', 'CENTER', 403, -74)
end)

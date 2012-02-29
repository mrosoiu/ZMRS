-- Caching ---------------
local _G = getfenv(0)

-- Hijack default behaviour ---------------
--BUFF_FLASH_TIME_ON  = 0.8
--BUFF_FLASH_TIME_OFF = 0.8
--BUFF_MIN_ALPHA      = 0.3
--BUFFS_PER_ROW       = 15
--BUFF_MAX_DISPLAY    = 60
BUFFS_PER_ROW = 20;

BuffButton_UpdateAnchors = function(buttonName, index)
  local buff = _G[buttonName..index];

  if (index > 1) and (mod(index, BUFFS_PER_ROW) == 1) then

    -- New row
    if ( index == BUFFS_PER_ROW+1 ) then
      buff:SetPoint("TOP", TempEnchant1, "BOTTOM", 0, -BUFF_ROW_SPACING)
    else
      buff:SetPoint("TOP", _G[buttonName..(index-BUFFS_PER_ROW)], "BOTTOM", 0, -BUFF_ROW_SPACING)
    end
  elseif index == 1 then
    buff:SetPoint("LEFT", TempEnchant1, "RIGHT", 5, 0)
  else
    buff:SetPoint("LEFT", _G[buttonName..(index-1)], "RIGHT", 5, 0)
  end
end

DebuffButton_UpdateAnchors = function(buttonName, index)
  local buff = _G[buttonName..index];
  buff:SetScale(2);

  -- Position debuffs
  if(index == 1) then

    -- First debuff
    buff:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -5, -5)
  else
    -- All other are aligned to the left
    buff:SetPoint("RIGHT", _G[buttonName..(index-1)], "LEFT", -5, 0)
  end
end

function BuffFrame_UpdateAllBuffAnchors()
  for i = 1, BUFF_ACTUAL_DISPLAY do
    BuffButton_UpdateAnchors("BuffButton", i)
  end
end

BuffFrame:SetScale(0.9)
TemporaryEnchantFrame:SetScale(0.9)


-- Events ---------------
local ZMRS_Addon = CreateFrame("Frame")

function ZMRS_Addon:PLAYER_ENTERING_WORLD(self, event, ...)
  TempEnchant1:ClearAllPoints()
  TempEnchant1:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 5, -5)
  TempEnchant1.SetPoint = function() end
  ZMRS_Addon:RunThroughIcons()
end

function ZMRS_Addon:UNIT_AURA(self, event, unit, ...)
    if(unit == PlayerFrame.unit) then
      ZMRS_Addon:RunThroughIcons()
    end
end

function ZMRS_Addon:RunThroughIcons()
  local i = 1
  while _G["BuffButton"..i] do
    ZMRS_Addon:CheckGloss("BuffButton"..i, 1)
    i = i + 1
  end

  i = 1
  while _G["DebuffButton"..i] do
    ZMRS_Addon:CheckGloss("DebuffButton"..i, 2)
    i = i + 1
  end

  i = 1
  while _G["TempEnchant"..i] do
    ZMRS_Addon:CheckGloss("TempEnchant"..i, 3)
    i = i + 1
  end
end

function ZMRS_Addon:CheckGloss(name,icontype)
  local b  = _G[name.."Border"]
  local i  = _G[name.."Icon"]
  local f  = _G[name]
  local c  = _G[name.."Gloss"]
  local ff = _G[name.."Duration"]

  ff:SetFont(NAMEPLATE_FONT, 10, nil)
  ff:ClearAllPoints()
  ff:SetPoint("TOP", f, "BOTTOM", 0, 0)

  if not c then
    local fg = CreateFrame("Frame", name.."Gloss", f)
    fg:SetAllPoints(f)

    local t = f:CreateTexture(name.."GlossTexture", "ARTWORK")
    t:SetTexture("Interface\\AddOns\\ZZMRS\\ZMRS_Buffs\\Textures\\gloss.tga")
    t:SetPoint("TOPLEFT", fg, "TOPLEFT", -0, 0)
    t:SetPoint("BOTTOMRIGHT", fg, "BOTTOMRIGHT", 0, -0)

    i:SetTexCoord(0.1,0.9,0.1,0.9)
    i:SetPoint("TOPLEFT", fg, "TOPLEFT", 2, -2)
    i:SetPoint("BOTTOMRIGHT", fg, "BOTTOMRIGHT", -2, 2)
  end

  local tex = _G[name.."GlossTexture"]

  if icontype == 2 and b then
    local red, green, blue = b:GetVertexColor();
    tex:SetTexture("Interface\\AddOns\\ZMRS\\ZMRS_Buffs\\Textures\\grey.tga")
    tex:SetVertexColor(red, green, blue)
  else
    tex:SetTexture("Interface\\AddOns\\ZMRS\\ZMRS_Buffs\\Textures\\gloss.tga")
    tex:SetVertexColor(1, 1, 1)
  end

  if b then b:SetAlpha(0) end
end

xxxSecondsToTimeAbbrev = function(time)
  local hr, m, s, text
  if time <= 0 then
    text = ""
  elseif(time < 3600 and time > 60) then
    hr = floor(time / 3600)
    m = floor(mod(time, 3600) / 60 + 1)
    text = format("%dm", m)
  elseif time < 60 then
    m = floor(time / 60)
    s = mod(time, 60)
    text = (m == 0 and format("%ds", s))
  else
    hr = floor(time / 3600 + 1)
    text = format("%dh", hr)
  end
  return text
end

ZMRS_Addon:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
ZMRS_Addon:RegisterEvent("PLAYER_ENTERING_WORLD");
ZMRS_Addon:RegisterEvent("UNIT_AURA");

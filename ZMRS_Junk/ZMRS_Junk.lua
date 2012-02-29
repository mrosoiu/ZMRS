local ZMRS_Addon = CreateFrame("Button" , "SellGreyBtn" , MerchantFrame, "UIPanelButtonTemplate")
ZMRS_Addon:SetText("Sell junk")
ZMRS_Addon:SetWidth(90)
ZMRS_Addon:SetHeight(21)
ZMRS_Addon:SetPoint("TopRight", -43, -43 )
ZMRS_Addon:RegisterForClicks("AnyUp")

-- Helper functions
local function GetJunkSellPrice(bag, slot)
  local itemLink = GetContainerItemLink(bag, slot)
  if (not itemLink) then return 0 end
  _, _, itemRarity, _, _, _, _, _, _, _, itemSellPrice = GetItemInfo(itemLink)
  if (0 ~= itemRarity) then return 0 end
  return itemSellPrice
end

local function GetAllJunkSellPrice()
  local total = 0
  for bag = 0,4 do
    if (GetContainerNumSlots(bag)) then
      for slot = 1,GetContainerNumSlots(bag) do
        local itemSellPrice = GetJunkSellPrice(bag, slot)
        if (itemSellPrice > 0) then
          _, itemCount = GetContainerItemInfo(bag, slot)
          total = total + GetJunkSellPrice(bag, slot) * itemCount
        end
      end
    end
  end
  return total
end

-- OnShow
ZMRS_Addon:SetScript("OnShow", function()
  if (0 == GetAllJunkSellPrice()) then
    ZMRS_Addon:Disable()
  else
    ZMRS_Addon:Enable()
  end
end)

-- OnEnter
ZMRS_Addon:SetScript("OnEnter", function()
  local total = GetAllJunkSellPrice()

  GameTooltip:SetOwner(ZMRS_Addon, "ANCHOR_RIGHT", 0, -32)
  GameTooltip:SetText("Sell your junk")
  if total > 0 then
    --GameTooltip:AddLine("You will profit", 1, 1, 1)
    SetTooltipMoney(GameTooltip, total, null, "You will profit:     ")
    GameTooltip:Show()
  end
end)

-- OnClick
ZMRS_Addon:SetScript("OnClick", function()
  local total = 0
  for bag = 0,4 do
    if (GetContainerNumSlots(bag)) then
      for slot = 1,GetContainerNumSlots(bag) do
        local itemSellPrice = GetJunkSellPrice(bag, slot)
        if (itemSellPrice > 0) then
          _, itemCount = GetContainerItemInfo(bag, slot)
          DEFAULT_CHAT_FRAME:AddMessage("|cff4fff4fZMRS_Junk|r: " .. (itemCount > 1 and itemCount .. "x" or "") .. GetContainerItemLink(bag, slot) .. " for " .. GetCoinTextureString(itemSellPrice * itemCount))
          total = total + itemSellPrice * itemCount
          UseContainerItem(bag, slot)
        end
      end
    end
  end
  DEFAULT_CHAT_FRAME:AddMessage("|cff4fff4f---------------------------------------------------------------------------------|r")
  DEFAULT_CHAT_FRAME:AddMessage("|cff4fff4fZMRS_Junk|r: Total profit: " .. GetCoinTextureString(total))
  GameTooltip:Hide()
  ZMRS_Addon:Disable()
end)

-- OnLeave
ZMRS_Addon:SetScript("OnLeave", function()
  GameTooltip:Hide()
end)
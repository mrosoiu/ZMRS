local ZMRS_Addon = CreateFrame("Frame")
local lastGUID = nil
local lastTime = nil

-- Helper functions ---------------
function ZMRS_Addon:WriteLn(text)
  DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff66c8ffZMRS_MinimapPing: |r%s", text))
end

-- Events ---------------
function ZMRS_Addon:MINIMAP_PING(self, ...)
  local nowTime = GetTime()
  local nowGUID = select(1, ...)
  
  if nowGUID ~= lastGUID or lastTime == nil or (nowTime - lastTime) >= 5 then
    ZMRS_Addon:WriteLn("Minimap ping from: " .. UnitName(nowGUID));
    lastGUID = nowGUID
    lastTime = nowTime
  end
end

ZMRS_Addon:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
ZMRS_Addon:RegisterEvent("MINIMAP_PING")

local ZMRS_Addon = CreateFrame("Frame")

local raidMembersCount = 0
local currentDialog = nil

-- Static dialogs ---------------
StaticPopupDialogs["ZMRS_ENABLE_LOGGING"] = {
  text = "%s\n\nDo you want to enable combat log?",
  button1 = "Enable",
  button2 = "Cancel",
  OnAccept = function() ZMRS_Addon:EnableCombatLog() end,
  OnHide = function() currentDialog = nil end,
  timeout = 0,
  whileDead = 1,
  hideOnEscape = 1
}

StaticPopupDialogs["ZMRS_DISABLE_LOGGING"] = {
  text = "%s\n\nDo you want to disable combat log?",
  button1 = "Disable",
  button2 = "Cancel",
  OnAccept = function() ZMRS_Addon:DisableCombatLog() end,
  OnHide = function() currentDialog = nil end,
  timeout = 0,
  whileDead = 1,
  hideOnEscape = 1
}

-- Helper functions ---------------
function ZMRS_Addon:EnableCombatLog()
  if LoggingCombat() then
    ZMRS_Addon:WriteLn("Combat log is already |cff00ff00enabled|r.")
  else
    LoggingCombat(true)
    ZMRS_Addon:WriteLn("Combat log is now |cff00ff00enabled|r.")
  end
end

function ZMRS_Addon:DisableCombatLog()
  if not LoggingCombat() then
    ZMRS_Addon:WriteLn("Combat log is already |cffff0000disabled|r.")
  else
    LoggingCombat(false)
    ZMRS_Addon:WriteLn("Combat log is now |cffff0000disabled|r.")
  end
end

function ZMRS_Addon:ShowDialog(dialogName, dialogText)
  if(currentDialog ~= nil) then StaticPopup_Hide(currentDialog) end
  currentDialog = dialogName;
  StaticPopup_Show(dialogName, dialogText)
end

function ZMRS_Addon:WriteLn(text)
  DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff66c8ffZMRS_CombatLog: |r%s", text))
end

-- Events ---------------
function ZMRS_Addon:PLAYER_ENTERING_WORLD()
  local inInstance, instanceType = IsInInstance()

  -- If enter world in raid instance in raid group; probably /reload ui
  if(inInstance == 1 and instanceType == "raid" and GetNumRaidMembers() > 0) then
    -- Ask to enable logging
    if not LoggingCombat() then ZMRS_Addon:ShowDialog("ZMRS_ENABLE_LOGGING", "You entered a raid instance.") end
  else
    -- Auto-disable logging
    if LoggingCombat() then ZMRS_Addon:DisableCombatLog() end
  end
end

function ZMRS_Addon:PLAYER_LOGOUT()
  -- Auto-disable logging
  if LoggingCombat() then ZMRS_Addon:DisableCombatLog() end
end

function ZMRS_Addon:ZONE_CHANGED_NEW_AREA()
  local inInstance, instanceType = IsInInstance()

  -- Entering raid instance in raid group
  if(inInstance == 1 and instanceType == "raid" and GetNumRaidMembers() > 0) then
    -- Ask to enable logging
    if not LoggingCombat() then ZMRS_Addon:ShowDialog("ZMRS_ENABLE_LOGGING", "You entered a raid instance.") end
  end

  -- If not in raid instance and combat log is enabled; check if in city
  if(not inInstance and LoggingCombat())then
    SetMapToCurrentZone()

    -- Check if in Dalaran
    if GetCurrentMapContinent() == 4 then
      local map = GetMapInfo()
      if map == "Dalaran" then ZMRS_Addon:ShowDialog("ZMRS_DISABLE_LOGGING", "You are in Dalaran.") end
    end
  end
end

function ZMRS_Addon:RAID_ROSTER_UPDATE()
  local n = GetNumRaidMembers();

  -- If combat log is enabled; check if ppl start leaving or raid is disbanded
  if LoggingCombat() then

    -- If raid group disbanded; ask to disable
    if(n < 2) then ZMRS_Addon:ShowDialog("ZMRS_DISABLE_LOGGING", "Your raid is disbanded.") end

    -- If one player left raid group; possible raid disband soon; ask to disable
    if(n < raidMembersCount) then ZMRS_Addon:ShowDialog("ZMRS_DISABLE_LOGGING", "Seems like your raid group is disbanding.") end
  end

  -- Update raidMembersCount
  raidMembersCount = n
end

-- Slash command ---------------
SlashCmdList["ZMRS_CL"] = function(item)
  if(item == "on") then
    ZMRS_Addon:EnableCombatLog()
  elseif(item == "off") then
    ZMRS_Addon:DisableCombatLog()
  else
    if LoggingCombat() then
      ZMRS_Addon:WriteLn("Combat log is currently |cff00ff00enabled|r.")
    else
      ZMRS_Addon:WriteLn("Combat log is currently |cffff0000disabled|r.")
    end
    DEFAULT_CHAT_FRAME:AddMessage("/|cff4fff4fmrs_cl |cff1eff00on |r- |cff4fff4fto enable combat log|r")
    DEFAULT_CHAT_FRAME:AddMessage("/|cff4fff4fmrs_cl |cff1eff00off |r- |cff4fff4fto disable combat log|r")
  end
end
SLASH_ZMRS_CL1 = "/mrs_cl"

ZMRS_Addon:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
ZMRS_Addon:RegisterEvent("PLAYER_ENTERING_WORLD")
ZMRS_Addon:RegisterEvent("PLAYER_LOGOUT")
ZMRS_Addon:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ZMRS_Addon:RegisterEvent("RAID_ROSTER_UPDATE")

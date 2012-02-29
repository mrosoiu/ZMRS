local ZMRS_Addon = CreateFrame("Frame")
local rezzEmotes = {

  -- Funny
  "Using a Booterang.",
  "Reduce. Reuse. Recycle.",
  "Unbowed. Unbent. Unbroken.",
  "You were not prepared.",                                         -- Illidan Stormrage

  -- I rule
  "Witness the power of the Ori!",                                  -- Stargate
  "I have Supercow powers.",                                        -- Debian's APT system

  -- Misc
  "For we are many.",                                               -- Legion
  "Reality... unwoven.",                                            -- Anomalus
  "You have been weighted and found... wanting.",                   -- Val'kyr twins

  -- Insults
  "Unworthy.",
  "You tried your best. And failed. Good job.",
  "You failed at life. Literally.",
  "You 0, Monster 1.",
  "Sucks to be you.",
}

local rezzEmotesLen = #rezzEmotes
local last1, last2, last3, last4, last5 = 0, 0, 0, 0, 0

-- Caching
local _Random     = math.random
local _Bband      = bit.band
local _Select     = select
local _Emote      = SendChatMessage
local _SpellName  = GetSpellInfo
local _SpellLink  = GetSpellLink

-- Get player class
local _, playerClass = UnitClass("Player")

-- Get localized names of spells
local _rezzSpellName      = nil
local _crezzSpellName     = nil
local _heroismSpellName   = nil
local _bloodlustSpellName = nil
local _manaTideSpellName  = nil
local _tauntSpellID       = nil
local _aoeTauntSpellID    = nil
local _ccSpellID          = {}

if playerClass == "PRIEST" then
  _rezzSpellName      = _SpellName(2006)  -- Resurrection
  _ccSpellID[9484]    = true              -- Shackle Undead

elseif playerClass == "PALADIN" then
  _rezzSpellName      = _SpellName(7328)  -- Redemption
  _tauntSpellID       = 62124             -- Hand of Reckoning
  _aoeTauntSpellID    = 31789             -- Righteous Defense
  _ccSpellID[20066]   = true              -- Repentance

elseif playerClass == "DRUID" then
  _rezzSpellName      = _SpellName(50769) -- Revive
  _crezzSpellName     = _SpellName(20484) -- Rebirth
  _tauntSpellID       = 6795              -- Growl
  _aoeTauntSpellID    = 5209              -- Challenging Roar
  _ccSpellID[2637]    = true              -- Hibernate
  _ccSpellID[339]     = true              -- Entangling Roots

elseif playerClass == "SHAMAN" then
  _rezzSpellName      = _SpellName(2008 ) -- Ancestral Spirit
  _tauntSpellID       = 73684             -- Unleash Earth
  _heroismSpellName   = _SpellName(32182) -- Heroism
  _bloodlustSpellName = _SpellName(2825)  -- Bloodlust
  _manaTideSpellName  = _SpellName(39609) -- Mana Tide Totem
  _ccSpellID[51514]   = true              -- Hex
  _ccSpellID[76780]   = true              -- Bind Elemental

elseif playerClass == "WARRIOR" then
  _tauntSpellID       = 355               -- Taunt
  _aoeTauntSpellID    = 1161              -- Challenging Shout

elseif playerClass == "DEATHNIGHT" then
  _tauntSpellID       = 56222             -- Dark Command

elseif playerClass == "MAGE" then
  _ccSpellID[118]     = true              -- Polymorph
  _ccSpellID[61305]   = true              -- Polymorph (Black Cat)
  _ccSpellID[28272]   = true              -- Polymorph (Pig)
  _ccSpellID[61721]   = true              -- Polymorph (Rabbit)
  _ccSpellID[61780]   = true              -- Polymorph (Turkey)
  _ccSpellID[28271]   = true              -- Polymorph (Turtle)

elseif playerClass == "ROGUE" then
  _ccSpellID[6770]    = true              -- Sap

elseif playerClass == "WARLOCK" then
  _ccSpellID[710]     = true              -- Banish
  _ccSpellID[1098]    = true              -- Enslave Demon

elseif playerClass == "HUNTER" then
  _ccSpellID[19386]   = true              -- Wyvern Sting
end

-- Helper funtions
function _UnitName(unitName)
  uName = string.match(unitName, "^[^-]*") or "NoName"
  return uName
end

-- Event handling
function ZMRS_Addon:COMBAT_LOG_EVENT_UNFILTERED(self, timestamp, eventName, hideCaster, sourceGUID, sourceName, sourceFlags, sourceFlags2, destGUID, destName, destFlags, destFlags2, ...)
  if _Bband(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= COMBATLOG_OBJECT_AFFILIATION_MINE then return end

  -- Get Spell ID
  local spellID = _Select(1, ...)
  if spellID == nil then return end

  -- Event: Taunt
  if spellID == _tauntSpellID then
    if eventName == "SPELL_CAST_SUCCESS" then
      _Emote(" taunted " .. destName, "EMOTE")
      return
    end

    if eventName == "SPELL_MISSED" then
      if _Select(4, ...) == "IMMUNE" then
        _Emote(": " .. destName .. " is immune to taunt!", "EMOTE")
      else
        _Emote("failed to taunt " .. destName .. ". Spell missed.", "EMOTE")
      end
      return
    end
  end

  -- Event: AoE Taunt
  if spellID == _aoeTauntSpellID then
    if eventName == "SPELL_CAST_SUCCESS" then
      _Emote("taunted all nearby enemies", "EMOTE")
      return
    end
  end

  -- Event: Intrerupt
  if eventName == "SPELL_INTERRUPT" then
    _Emote("interrupted " .. destName .. "'s " .. _SpellLink(tonumber(_Select(4, ...), 10)), "EMOTE")
    return
  end

  -- Event: Purge & Cleanse
  if eventName == "SPELL_DISPEL" or eventType == "SPELL_STOLEN" then
    if _Bband(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0 then
      _Emote("purged " .. destName .. "'s " .. _SpellLink(tonumber(_Select(4, ...), 10)), "EMOTE")
    else
      _Emote("cleansed " .. destName .. "'s " .. _SpellLink(tonumber(_Select(4, ...), 10)), "EMOTE")
    end
    return
  end

  -- Event: Spell Reflect
  if eventName == "SPELL_MISSED" then
    local missReason = _Select(4, ...)
    if missReason == "REFLECT" then
      _Emote("reflected " .. _SpellLink(tonumber(spellID), 10) .. " back to " .. destName, "EMOTE")
      return
    end
  end

  -- Event: CC
  if _ccSpellID[spellID] == true then

    -- CC success
    if eventName == "SPELL_AURA_APPLIED" then
      _Emote("CC'ed " .. destName, "EMOTE")
      return
    end

    -- CC missed
    if eventName == "SPELL_MISSED" then
      _Emote("failed to CC " .. destName, "EMOTE")
      return
    end

    -- CC removed
    if eventName == "SPELL_AURA_REMOVED" then
      _Emote(": CC faded from " .. destName, "EMOTE")
      return
    end
  end
end

function ZMRS_Addon:UNIT_SPELLCAST_SUCCEEDED(self, unitID, spellName, spellRank)
  if unitID ~= "player" then return end

  if spellName == _heroismSpellName or spellName == _bloodlustSpellName then
    _Emote(": Heroism! NUUUUUKE!", "EMOTE")
    return
  end

  if spellName == _manaTideSpellName then
    _Emote("dropped Mana Tide Totem.", "EMOTE")
    return
  end
end

function ZMRS_Addon:UNIT_SPELLCAST_SENT(self, unitID, spellName, spellRank, unitName)
  if unitID ~= "player" then return end

  -- Rezz
  if spellName == _rezzSpellName then
    local n = 0
    while true do
      n = _Random(rezzEmotesLen)
      if n ~= last1 and n ~= last2 and n ~= last3 and n ~= last4 and n ~= last5 then
        do break end
      end
    end

    _Emote("is rezzing " .. _UnitName(unitName) .. ": " .. rezzEmotes[n], "EMOTE")
    last5 = last4;
    last4 = last3
    last3 = last2
    last2 = last1
    last1 = n
    return
  end

  -- Combat
  if spellName == _crezzSpellName then
    _Emote("is combat rezzing " .. _UnitName(unitName), "EMOTE")
    return
  end
end

ZMRS_Addon:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
ZMRS_Addon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
ZMRS_Addon:RegisterEvent("UNIT_SPELLCAST_SENT")
ZMRS_Addon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
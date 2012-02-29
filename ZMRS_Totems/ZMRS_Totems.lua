-- Hijack TotemFrame's position ---------------
TotemFrame:SetParent(UIParent)
TotemFrame:ClearAllPoints()
TotemFrame:SetPoint("CENTER", UIParent, "CENTER", -202, -115)

-- Change totems order ---------------
TOTEM_PRIORITIES = {
  FIRE_TOTEM_SLOT,
  AIR_TOTEM_SLOT,
  EARTH_TOTEM_SLOT,
  WATER_TOTEM_SLOT
}

-- Hide totem frame buttons shadow ---------------
getglobal("TotemFrameTotem1Background"):SetAlpha(0)
getglobal("TotemFrameTotem2Background"):SetAlpha(0)
getglobal("TotemFrameTotem3Background"):SetAlpha(0)
getglobal("TotemFrameTotem4Background"):SetAlpha(0)

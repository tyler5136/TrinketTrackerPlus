local addonName, TT = ...

function TT.IsOnUseTrinket(slotID)
  local itemID = GetInventoryItemID("player", slotID)
  if not itemID then return false end

  for _, blacklistedID in ipairs(TTDB.blacklistedTrinkets) do
    if itemID == blacklistedID then
      return false
    end
  end

  local spellName, spellID = GetItemSpell(itemID)
  if spellName then
    return true
  end

  return false
end

function TT.UpdateTrinket(frame, slotID)
  local itemTexture = GetInventoryItemTexture("player", slotID)
  if itemTexture then
    local itemID = GetInventoryItemID("player", slotID)
    if itemID then
      for _, blacklistedID in ipairs(TTDB.blacklistedTrinkets) do
        if itemID == blacklistedID then
          frame:Hide()
          return
        end
      end
    end

    if TTDB.onlyShowOnUseTrinkets then
      if not TT.IsOnUseTrinket(slotID) then
        frame:Hide()
        return
      end
    end

    if TTDB.onlyShowInCombat and not UnitAffectingCombat("player") then
      frame:Hide()
      return
    end

    frame.icon:SetTexture(itemTexture)

    local start, duration = GetInventoryItemCooldown("player", slotID)
    if start and duration then
      frame.cooldown:SetCooldown(start, duration)

      local minCD = TTDB.alertMinCD or 30
      local remaining = (start > 0 and duration > 0) and (start + duration - GetTime()) or 0
      local onCD = remaining > 0.1 and duration >= minCD

      if frame._ttWasOnCD and not onCD and (frame._ttLastDuration or 0) >= minCD then
        if TT.FireAlert then TT.FireAlert(frame) end
        if TTDB.combatAlert and UnitAffectingCombat("player") then
          frame._ttCombatGlow = true
        end
      end
      frame._ttWasOnCD = onCD
      if onCD then
        frame._ttLastDuration = duration
        if frame._ttCombatGlow then
          if TT.HideAlertGlow then TT.HideAlertGlow(frame) end
          frame._ttCombatGlow = nil
        end
      elseif TTDB.combatAlert and UnitAffectingCombat("player") and frame._ttCombatGlow then
        if TT.ShowAlertGlow then TT.ShowAlertGlow(frame) end
      end
    end

    frame:Show()
  else
    if TT.HideAlertGlow then TT.HideAlertGlow(frame) end
    frame._ttWasOnCD = nil
    frame:Hide()
  end
end

function TT.UpdateTrinkets()
  TT.UpdateTrinket(TT.trinket1, 13)
  TT.UpdateTrinket(TT.trinket2, 14)
  TT.UpdateTrinketLayout()
  TT.UpdateSizes()
end

function TT.UpdateSizes()
  local size = TTDB.iconSize
  TT.trinket1:SetSize(size, size)
  TT.trinket2:SetSize(size, size)
end


function TT.UpdateTrinketLayout()
  local visible1 = TT.trinket1:IsShown()
  local visible2 = TT.trinket2:IsShown()

  if visible1 and not visible2 then
    TT.trinket1:ClearAllPoints()
    TT.trinket1:SetPoint("CENTER", TT.container, "CENTER", 0, 0)
  elseif visible2 and not visible1 then
    TT.trinket2:ClearAllPoints()
    TT.trinket2:SetPoint("CENTER", TT.container, "CENTER", 0, 0)
  elseif visible1 and visible2 then
    if TTDB.layout == "vertical" then
      TT.trinket1:ClearAllPoints()
      TT.trinket1:SetPoint("TOP", TT.container, "TOP", 0, -5)
      TT.trinket2:ClearAllPoints()
      TT.trinket2:SetPoint("TOP", TT.trinket1, "BOTTOM", 0, -5)
    else
      TT.trinket2:ClearAllPoints()
      TT.trinket2:SetPoint("LEFT", TT.container, "LEFT", 5, 0)
      TT.trinket1:ClearAllPoints()
      TT.trinket1:SetPoint("LEFT", TT.trinket2, "RIGHT", 5, 0)
    end
  end
  TT.UpdateSizes()
end

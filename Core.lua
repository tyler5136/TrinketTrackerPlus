TTDB = TTDB or {}
TTDB.iconSize = TTDB.iconSize or 44
TTDB.layout = TTDB.layout or "vertical"
TTDB.onlyShowInCombat = TTDB.onlyShowInCombat or false
TTDB.blacklistedTrinkets = TTDB.blacklistedTrinkets or {}
TTDB.onlyShowOnUseTrinkets = TTDB.onlyShowOnUseTrinkets ~= nil
and TTDB.onlyShowOnUseTrinkets or true

-- Alert defaults
TTDB.alertGlow  = TTDB.alertGlow  or "proc"    -- none | proc | pixel | autocast | gold | blue | red
TTDB.alertSound = TTDB.alertSound or "tts"     -- none | tts | alarm | raidwarning | readycheck | auction | ping
TTDB.alertMinCD = TTDB.alertMinCD or 30
if TTDB.combatAlert == nil then TTDB.combatAlert = false end

-- Well it's the default blacklist :) (Will be updated when new trinkets comes out) [Midnight] --
local defaultBlacklist = {
  193718, -- Emerald Coach's [Dungeon]
  248583, -- Drums of Renewed Bonds [Delve]
}

local addonName, TT = ...

-- Trinkets --

TT.container = CreateFrame("Frame", "Trinkets", UIParent)
TT.container:SetSize(110, 110)
TT.container:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
TT.container:SetClampedToScreen(true)

TT.trinket1 = CreateFrame("Frame", nil, TT.container)
TT.trinket1:SetSize(44, 44)
TT.trinket1:SetPoint("TOP", TT.container, "TOP", 0, 0)
TT.trinket1.icon = TT.trinket1:CreateTexture(nil, "ARTWORK")
TT.trinket1.icon:SetAllPoints()
TT.trinket1.cooldown = CreateFrame("Cooldown", nil, TT.trinket1, "CooldownFrameTemplate")
TT.trinket1.cooldown:SetAllPoints()

TT.trinket2 = CreateFrame("Frame", nil, TT.container)
TT.trinket2:SetSize(44, 44)
TT.trinket2:SetPoint("TOP", TT.trinket1, "BOTTOM", 0, 0)
TT.trinket2.icon = TT.trinket2:CreateTexture(nil, "ARTWORK")
TT.trinket2.icon:SetAllPoints()
TT.trinket2.cooldown = CreateFrame("Cooldown", nil, TT.trinket2, "CooldownFrameTemplate")
TT.trinket2.cooldown:SetAllPoints()

-- Tooltip on hover
local function AttachTooltip(frame, slotID)
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        if UnitAffectingCombat("player") then return end
        if not GetInventoryItemID("player", slotID) then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetInventoryItem("player", slotID)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
AttachTooltip(TT.trinket1, 13)
AttachTooltip(TT.trinket2, 14)

-- If the tooltip is showing on a trinket icon when combat starts, hide it.
local tooltipCombatFrame = CreateFrame("Frame")
tooltipCombatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
tooltipCombatFrame:SetScript("OnEvent", function()
    local owner = GameTooltip:GetOwner()
    if owner == TT.trinket1 or owner == TT.trinket2 then
        GameTooltip:Hide()
    end
end)

-- =========================================================================
-- Alert module
-- =========================================================================

local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)

-- Fallback solid-color pulse (used when LCG isn't loaded, and for the "gold/blue/red" options)
local function MakePulse(frame, r, g, b)
    if frame._ttPulse then
        frame._ttPulse.tex:SetColorTexture(r, g, b, 0.7)
        return frame._ttPulse
    end
    local tex = frame:CreateTexture(nil, "OVERLAY")
    tex:SetPoint("TOPLEFT", frame, "TOPLEFT", -8, 8)
    tex:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 8, -8)
    tex:SetColorTexture(r, g, b, 0.7)
    tex:SetBlendMode("ADD")
    tex:Hide()
    local ag = tex:CreateAnimationGroup()
    local a1 = ag:CreateAnimation("Alpha")
    a1:SetFromAlpha(0.9); a1:SetToAlpha(0.1); a1:SetDuration(0.5)
    ag:SetLooping("BOUNCE")
    frame._ttPulse = { tex = tex, ag = ag }
    return frame._ttPulse
end

local function StopPulse(frame)
    if frame._ttPulse then
        frame._ttPulse.ag:Stop()
        frame._ttPulse.tex:Hide()
    end
end

TT.glowHandlers = {
    none = {
        show = function(_) end,
        hide = function(_) end,
    },
    -- Blizzard proc ring (LibCustomGlow ButtonGlow — the rotating ring ElvUI uses)
    proc = {
        show = function(frame)
            if LCG then LCG.ButtonGlow_Start(frame, nil, 0.25) end
        end,
        hide = function(frame)
            if LCG then LCG.ButtonGlow_Stop(frame) end
        end,
    },
    pixel = {
        show = function(frame)
            if LCG then LCG.PixelGlow_Start(frame, {0.2, 0.6, 1, 1}, 8, 0.25, nil, 2, 0, 0, false, "tt") end
        end,
        hide = function(frame)
            if LCG then LCG.PixelGlow_Stop(frame, "tt") end
        end,
    },
    autocast = {
        show = function(frame)
            if LCG then LCG.AutoCastGlow_Start(frame, {1, 0.9, 0.3, 1}, 6, 0.125, 1, 0, 0, "tt") end
        end,
        hide = function(frame)
            if LCG then LCG.AutoCastGlow_Stop(frame, "tt") end
        end,
    },
    gold = {
        show = function(frame) local p = MakePulse(frame, 1, 0.82, 0.2); p.tex:Show(); p.ag:Play() end,
        hide = StopPulse,
    },
    blue = {
        show = function(frame) local p = MakePulse(frame, 0.2, 0.6, 1); p.tex:Show(); p.ag:Play() end,
        hide = StopPulse,
    },
    red = {
        show = function(frame) local p = MakePulse(frame, 1, 0.2, 0.2); p.tex:Show(); p.ag:Play() end,
        hide = StopPulse,
    },
}

-- Listen for Blizzard's own TTS failure signal so we only warn when it's real.
local ttsFailFrame = CreateFrame("Frame")
ttsFailFrame:RegisterEvent("VOICE_CHAT_TTS_PLAYBACK_FAILED")
ttsFailFrame:SetScript("OnEvent", function(_, event, status)
    if not TT._ttsLastFiredAt or (GetTime() - TT._ttsLastFiredAt) > 2 then return end
    if TT._ttsWarned then return end
    TT._ttsWarned = true
    print("|cff00d9ff[Trinket Tracker]|r TTS failed (status: " .. tostring(status) .. "). Try: /console textToSpeech 1  (or check Options for Text to Speech / Speech). This warning will not repeat this session.")
end)

-- Resolve a usable TTS voice ID, preferring character/account-level default
local function GetTTSVoiceID()
    if C_TTSSettings and C_TTSSettings.GetVoiceOptionID and Enum and Enum.TtsVoiceType then
        local id = C_TTSSettings.GetVoiceOptionID(Enum.TtsVoiceType.Standard)
        if id then return id end
    end
    if C_VoiceChat and C_VoiceChat.GetTtsVoices then
        local voices = C_VoiceChat.GetTtsVoices()
        if voices and voices[1] then return voices[1].voiceID end
    end
    return 0
end

TT.soundHandlers = {
    none        = function() end,
    tts         = function()
        if not (C_VoiceChat and C_VoiceChat.SpeakText) then
            PlaySound(SOUNDKIT.ALARM_CLOCK_WARNING_3)
            return
        end
        local voiceID = GetTTSVoiceID()
        TT._ttsLastFiredAt = GetTime()
        -- 12.0 signature: SpeakText(voiceID, text, rate, volume, overlap)
        local ok, err = pcall(C_VoiceChat.SpeakText, voiceID, "Trinket Ready", 0, 100, true)
        if not ok then
            print("|cff00d9ff[Trinket Tracker]|r TTS error: " .. tostring(err) .. " - falling back to alarm.")
            PlaySound(SOUNDKIT.ALARM_CLOCK_WARNING_3)
        end
    end,
    alarm       = function() PlaySound(SOUNDKIT.ALARM_CLOCK_WARNING_3) end,
    raidwarning = function() PlaySound(SOUNDKIT.RAID_WARNING) end,
    readycheck  = function() PlaySound(SOUNDKIT.READY_CHECK) end,
    auction     = function() PlaySound(SOUNDKIT.AUCTION_WINDOW_OPEN) end,
    ping        = function() PlaySound(SOUNDKIT.MAP_PING) end,
}

function TT.ShowAlertGlow(frame)
    local handler = TT.glowHandlers[TTDB.alertGlow] or TT.glowHandlers.none
    handler.show(frame)
end

function TT.HideAlertGlow(frame)
    for _, handler in pairs(TT.glowHandlers) do
        handler.hide(frame)
    end
end

function TT.PlayAlertSound()
    local handler = TT.soundHandlers[TTDB.alertSound] or TT.soundHandlers.none
    handler()
end

function TT.FireAlert(frame)
    TT.PlayAlertSound()
    TT.ShowAlertGlow(frame)
end

-- Fire combat-entry alert: sound once, persistent glow on each ready trinket.
function TT.FireCombatAlert()
    if not TTDB.combatAlert then return end
    local fired = false
    for _, frame in ipairs({ TT.trinket1, TT.trinket2 }) do
        if frame:IsShown() then
            local slotID = (frame == TT.trinket1) and 13 or 14
            local start, duration = GetInventoryItemCooldown("player", slotID)
            local ready = not (start and duration and start > 0 and duration > 0
                and (start + duration - GetTime()) > 0.1)
            if ready then
                TT.ShowAlertGlow(frame)
                frame._ttCombatGlow = true
                fired = true
            end
        end
    end
    if fired then TT.PlayAlertSound() end
end

function TT.TestAlert()
    print("|cff00d9ff[Trinket Tracker]|r Test alert fired (glow=" .. tostring(TTDB.alertGlow) .. ", sound=" .. tostring(TTDB.alertSound) .. ")")
    local v1, v2 = TT.trinket1:IsShown(), TT.trinket2:IsShown()
    if not v1 and not v2 then
        print("|cff00d9ff[Trinket Tracker]|r Note: no trinket frames are visible - glow has nothing to anchor to. Equip a trinket or disable 'Only show On-Use/In Combat'.")
    end
    TT.FireAlert(TT.trinket1)
    TT.FireAlert(TT.trinket2)
    C_Timer.After(4, function()
        TT.HideAlertGlow(TT.trinket1)
        TT.HideAlertGlow(TT.trinket2)
    end)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
eventFrame:SetScript("OnEvent", function(self, event, ...)
  if event == "UNIT_SPELLCAST_SUCCEEDED" then
    TT.HideAlertGlow(TT.trinket1)
    TT.HideAlertGlow(TT.trinket2)
    TT.trinket1._ttCombatGlow = nil
    TT.trinket2._ttCombatGlow = nil
    C_Timer.After(0.1, TT.UpdateTrinkets)
    return
  end

  if event == "PLAYER_LOGIN" then

    -- Merge Loop
    for _, defaultID in ipairs(defaultBlacklist) do
      local found = false
      for _, userID in ipairs(TTDB.blacklistedTrinkets) do
        if userID == defaultID then
          found = true
          break
        end
      end
      if not found then
        table.insert(TTDB.blacklistedTrinkets, defaultID)
      end
    end

    -- LibEditMode --

    local LEM = LibStub('LibEditMode')

    if LEM then
      local function onPositionChanged(frame, layoutName, point, x, y)
        if not TTDB.layouts then
          TTDB.layouts = {}
        end
        if not TTDB.layouts[layoutName] then
          TTDB.layouts[layoutName] = {}
        end
        TTDB.layouts[layoutName].point = point
        TTDB.layouts[layoutName].x = x
        TTDB.layouts[layoutName].y = y
      end

      local defaultPosition = {
        point = "CENTER",
        x = 0,
        y = 0,
      }

      LEM:RegisterCallback('layout', function(layoutName)
        if not TTDB.layouts then
          TTDB.layouts = {}
        end
        if not TTDB.layouts[layoutName] then
          TTDB.layouts[layoutName] = {point = "CENTER", x = 0, y = 0}
        end

        TT.container:ClearAllPoints()
        TT.container:SetPoint(TTDB.layouts[layoutName].point or "CENTER",
        UIParent,
        TTDB.layouts[layoutName].point or "CENTER",
        TTDB.layouts[layoutName].x or 0,
        TTDB.layouts[layoutName].y or 0)
      end)
      LEM:AddFrame(TT.container, onPositionChanged, defaultPosition)

      -- Edit Mode settings panel
      local glowValues = { { text = "None", value = "none" } }
      if LCG then
        table.insert(glowValues, { text = "Blizzard Proc Ring", value = "proc"     })
        table.insert(glowValues, { text = "Pixel Glow",         value = "pixel"    })
        table.insert(glowValues, { text = "Autocast Shine",     value = "autocast" })
      end
      table.insert(glowValues, { text = "Gold Pulse", value = "gold" })
      table.insert(glowValues, { text = "Blue Pulse", value = "blue" })
      table.insert(glowValues, { text = "Red Pulse",  value = "red"  })

      -- If the saved glow type needs LCG but LCG isn't here, fall back gracefully
      if not LCG and (TTDB.alertGlow == "proc" or TTDB.alertGlow == "pixel" or TTDB.alertGlow == "autocast") then
        TTDB.alertGlow = "blue"
      end
      local soundValues = {
        { text = "None",                 value = "none"        },
        { text = "TTS: Trinket Ready",   value = "tts"         },
        { text = "Alarm",                value = "alarm"       },
        { text = "Raid Warning",         value = "raidwarning" },
        { text = "Ready Check",          value = "readycheck"  },
        { text = "Auction Open (ding)",  value = "auction"     },
        { text = "Map Ping",             value = "ping"        },
      }

      LEM:AddFrameSettings(TT.container, {
        {
          kind = LEM.SettingType.Dropdown,
          name = "Visual Alert",
          get  = function() return TTDB.alertGlow end,
          set  = function(_, value) TTDB.alertGlow = value end,
          values = glowValues,
          default = "proc",
        },
        {
          kind = LEM.SettingType.Dropdown,
          name = "Sound Alert",
          get  = function() return TTDB.alertSound end,
          set  = function(_, value) TTDB.alertSound = value end,
          values = soundValues,
          default = "tts",
        },
        {
          kind = LEM.SettingType.Slider,
          name = "Min Cooldown (s)",
          get  = function() return TTDB.alertMinCD end,
          set  = function(_, value) TTDB.alertMinCD = value end,
          minValue = 0, maxValue = 300, valueStep = 5,
          default = 30,
          formatter = function(v) return v .. "s" end,
        },
        {
          kind = LEM.SettingType.Checkbox,
          name = "Alert on combat entry",
          get  = function() return TTDB.combatAlert end,
          set  = function(_, value) TTDB.combatAlert = value end,
          default = false,
        },
      })

      LEM:AddFrameSettingsButtons(TT.container, {
        {
          text = "Test Alert",
          click = function() TT.TestAlert() end,
        },
      })
    end

  elseif event == "PLAYER_ENTERING_WORLD" then
    TT.UpdateTrinketLayout()
    TT.UpdateSizes()
    if TT.MSQ_Group then
      TT.MSQ_Group:ReSkin()
    end
    C_Timer.After(0.5, TT.UpdateTrinkets)

  elseif event == "PLAYER_REGEN_DISABLED" then
    TT.UpdateTrinkets()
    TT.FireCombatAlert()

  elseif event == "PLAYER_REGEN_ENABLED" then
    -- Combat ended - clear any persistent combat-mode glows.
    for _, frame in ipairs({ TT.trinket1, TT.trinket2 }) do
      if frame._ttCombatGlow then
        TT.HideAlertGlow(frame)
        frame._ttCombatGlow = nil
      end
    end
    TT.UpdateTrinkets()

  elseif event == "PLAYER_EQUIPMENT_CHANGED"
    or event == "BAG_UPDATE_COOLDOWN" then
    TT.UpdateTrinkets()
  end
end)

-- Added Masque Support --

local function GetMasqueData(button)
  return {
    Icon = button.icon,
    Cooldown = button.cooldown,
    Border = button.border,
    Count = button.count,
  }
end

local Masque = LibStub("Masque", true)
if Masque then
  TT.MSQ_Group = Masque:Group("Trinket Tracker")
  TT.MSQ_Group:AddButton(TT.trinket1, GetMasqueData(TT.trinket1))
  TT.MSQ_Group:AddButton(TT.trinket2, GetMasqueData(TT.trinket2))
  TT.MSQ_Group:RegisterCallback(function()
    TT.UpdateTrinketLayout()
    TT.UpdateSizes()
  end)
end

-- Periodic check so the ready transition fires promptly even if no event hits.
C_Timer.NewTicker(0.5, function()
  if TT.UpdateTrinkets then TT.UpdateTrinkets() end
end)

## [1.9.2] - 2026-04-22

### Added
- Item tooltip on hover for each trinket icon. Tooltip is suppressed
  while in combat, and is force-hidden if combat begins while a trinket
  tooltip is currently showing.

## [1.9.1] - 2026-04-22

### Added
- "Alert on combat entry" Edit Mode checkbox (off by default). When enabled,
  entering combat with a ready trinket fires the configured sound and a
  persistent glow that stays on the icon until the trinket is used or
  combat ends. Re-arms on each new combat entry.
- Combat-mode glow also engages on a ready transition that occurs while
  in combat (mid-fight CD reset), so the icon stays lit until use.

## [1.9.0] - 2026-04-22

### Added
- Ready-alert system: plays a sound and/or glow on trinket icons when a trinket comes off cooldown.
- Edit Mode settings panel on the Trinkets frame (dropdowns + slider + Test Alert button).
- Visual Alert options: Blizzard Proc Ring, Pixel Glow, Autocast Shine (via LibCustomGlow when available), plus Gold / Blue / Red solid-color pulses as fallback.
- Sound Alert options: TTS "Trinket Ready", Alarm, Raid Warning, Ready Check, Auction Open, Map Ping (all via SOUNDKIT IDs).
- Min Cooldown slider to filter out short CDs from alert firing (default 30s).
- Auto-clears glow on trinket use (UNIT_SPELLCAST_SUCCEEDED) and on unequip.
- TTS failure detection via VOICE_CHAT_TTS_PLAYBACK_FAILED event, with one-time session warning.

### Changed
- First-load does not false-fire: initial cooldown state seeds silently.

## [1.8.1] - 2026-04-19

### Changed
- updated .toc to add 12.0.5.
- Set default blacklist to current expansion trinkets.

### Removed
- Removed SavedVariablesPerCharacter

## [1.8] - 2026-04-05

### Added
- Added a table to global functions and names, for practice and precaution if the project grows
- Re-added the trinket "So'leahs Secret Technique" to the default blacklist
- Made the default blacklist forced and it will get updated every reload as it is now.

### Changed 
- Changed the structure of the DB to not use "_initialized" block as it can reset blacklists.

### Removed
- Removed redundant code and reworked some structural debt

## [1.7] - 2026-04-03
### Added
- Added the trinket "Drum of Renewed Bonds" to the default blacklist

### Fixed 
- The size fix earlier broke the cooldown swipe/numbers, that is now Fixed

### Removed
- Removed the trinket "So'leahs Secret Technique" from the default blacklist 

## [1.6] - 2026-04-03
### Changed
- Fixed issues with the size after a reload/relog 

## [1.5] - 2026-03-15
### Added
- Masque support

### Changed
- The sizes on the size slider to better handle Masque

### Removed
- Bloated code

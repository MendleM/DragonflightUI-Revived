# Changelog

DragonflightUI Revived — the community-maintained continuation of
DragonflightUI Classic, picking up after upstream's last release (v0.40.3,
May 2026). Current builds report version `0.44.0`.

Everything before v0.40.3 is in
[upstream's releases](https://github.com/Karl-HeinzSchneider/WoW-DragonflightUI/releases).

## 0.44.0 — The Definitive Refactor & Stability Overhaul (26 August 2026)

Complete stability and architecture overhaul: permanent decoupling from Blizzard Edit Mode, combat reload visual preservation, robust TBC totem positioning, solid ChatFrame anchoring, and instant live Darkmode switching.

**Highlights** — login Lua errors fixed at the cause (#26, #28) · party frame taint seed found and removed · genuinely decoupled from Blizzard EditMode · bag row spacing and keyring position stable at last (#30) · seamless combat reload holder positioning · TBC/Era chat frame permanence · Shaman totem anchoring · live Darkmode toggle without /reload · actionbar dividers restricted to main bar

### Core & Architecture
- **Login Lua errors fixed at the cause (Issues #26, #28):** `EditModeManagerFrame:UpdateLayoutInfo` is Blizzard's setter behind `EDIT_MODE_LAYOUTS_UPDATED` and takes the layout table as its first argument. This addon called it with no argument, which set `layoutInfo` to `nil` and then threw on the next line inside a `pcall`, so nothing was ever reported. For the rest of the session Blizzard's edit mode had no layout: `IsInitialized()` answered false, `GetDefaultAnchor` failed through `PlayerFrame_ResetPosition`, and `SetToLayoutAnchor` failed through `UIParent_ManageFramePositions` on every reposition and every action bar transition.
- **Decoupled from Blizzard EditMode:** permanently suppressed Blizzard's EditModeManager through Blizzard's own `BlockEnteringEditMode` gate, and stopped replacing Blizzard functions altogether. The chat window now uses `hooksecurefunc`; the one remaining exception, on the background action bars, is documented in place with the reason it cannot be a hook.
- **Settings moved out of Blizzard's layout:** five settings used to be written to Blizzard's server-side layout on every login. Four are now applied directly to the frame, the way Blizzard's own appliers do it, and stored in the DragonflightUI profile. The fifth drives which party frame system Blizzard shows and is documented as unavoidable. No anchor pointing at a DragonflightUI frame is ever written again — that was what left the interface broken with the addon disabled.
- **Leftover `DragonflightUI_Layout` (Issue #27):** a version up to and including `cda4133` created a character-specific Blizzard edit mode layout and made it active. Edit mode layouts live on Blizzard's server, so it outlived the code that made it. The addon now detects it, explains once how to remove it, and offers an opt-out; `/df layoutnotice` brings the message back. Stale anchors inside it are cleaned up automatically, once per character, using Blizzard's own `ResetToDefaultPosition` semantics rather than repointing everything at `UIParent`.
- **LibEditModeOverride removed:** it was loaded on all six flavours and never called once. Two comments claiming the addon wrote layouts through it were wrong and have been corrected.
- **Version.API Refactoring:** streamlined universal expansion detection across Era, TBC, Wrath, Cata, and MoP with automatic capability mirroring (`DF.Caps`).
- **Combat Reload Banner:** silenced on-screen reload state banner to preserve a clean UI during in-combat reloads.
- **Post-Combat Recovery:** reduced post-combat reapply delay to 100ms for immediate UI responsiveness.
- **Under the Hood:** Escape closes our windows again without taking keyboard focus. Stopped leaking generic names into `_G` — sixteen earlier in the cycle, and since then four option-builder helpers plus two frames that shipped under the placeholder names `sss` and `**`.

### Chat
- **TBC & Era Chat Permanence:** decoupled `ChatFrame1` from Blizzard's EditModeManager and legacy position manager. The chat window stays firmly anchored through loading screens, reloads, and window resizing without disappearing.

### Unit Frames & Party / Raid
- **Party & Raid Frame Toggle (Issue #14):** Fixed "Use Raid-Style Party Frames" (Gruppen wie Schlachtzug anzeigen) to switch immediately and live between portrait party frames and compact raid frames without requiring a `/reload`. The DragonflightUI database is the single source of truth and the sync to Blizzard is one-way, through Blizzard's own `OnSystemSettingChange`.
- **Party frame blocked actions, fixed at the seed:** this addon wrote `PartyFrame.system` and `PartyFrame.systemIndex`. Those are the two fields Blizzard uses to identify a registered edit mode system, and it reads them inside `secureexecuterange` on every `UseRaidStylePartyFrames()` call — which both party visibility paths ask. Writing them from addon code made them insecure for the session, and the taint travelled through `UpdateRaidAndPartyFrames` → `UpdatePartyFrames` → `UpdateMember` into the pooled members' `unit`, `buffs` and `debuffs`. Neither field was ever read by this addon; they only existed for a helper that no longer exists.
- **Removed the workaround that caused it:** Blizzard's `EditModeManagerFrame:UseRaidStylePartyFrames` was being replaced outright, and reinstalled on every `ADDON_LOADED`, so Blizzard's own visibility checks ran addon code on a protected path. It had been added one commit after the `UpdateLayoutInfo` bug above broke the real accessor — a workaround for a symptom whose cause is now fixed.
- **Party Frame Positioning & Fonts:** Unified party member names and health/mana status text typography to FRIZQT outline font, and anchored the pooled modern `PartyFrame` container directly to `DragonflightUIPartyMoveFrame`.
- **Edit Mode Party Preview:** Dynamic preview switching between 4 portrait party member frames and 5 compact raid member boxes based on the active raid-style party frame setting.
- **Shaman Totem Bar:** dynamic `HasTotemBar` detection and anchored positioning to prevent active totem icons from snapping below player frame.
- **Combat Reload Visuals:** early holder pre-positioning and immediate visual skinning prevent visual snapping when reloading during combat.
- **Pet Frame Anchoring:** locked `PetFrame` to `DragonflightUIPetFrame` and suppressed Blizzard's position manager to prevent the unit frame from jumping to default coordinates when summoning a pet.
- **TBC:** the pet frame is back. It was saved to the layout and then never actually placed.
- **Focus Target & Faction Icons:** focus target frame restored on TBC and MoP; target faction icon alignment fixed on Era.
- **Target of Target:** eliminated reload errors during combat when target-of-target is not yet built.

### Action Bars
- **Pet Bar Sizing & Centering (Issue #13):** standardized default button scale to 0.8 (36px), removed legacy fixed 30px sizing loop, and centered icon art to prevent undersized pet action buttons.
- **SpellBook & Pet Action Taint:** neutralized Blizzard's default `UpdateShownButtons` and `SetShowGrid` on background bars to eliminate `ADDON BLOCKED` errors when opening the spellbook, leveling up, or casting pet abilities.
- **Pet Bar Clickability:** disabled mouse interception on replaced Blizzard container frames and updated secure frame templates so pet action buttons are immediately clickable upon login.
- **Bar Dividers:** fixed rendering condition so dividers only appear on Action Bar 1 when background border art is active, removing stray lines from Action Bars 2–8.
- **Art Cleanup:** eliminated legacy Blizzard gryphons and duplicate visual layers on TBC.
- **Scaling & Alignment:** corrected Action Bar 1 scaling and in-combat alignment for backpack and bag bar slots.
- **Flyout Direction:** choosing *Up* works properly.
- **MoP:** the latency indicator sits on the bottom edge of the game menu button instead of in the middle of it.
- **Keyring (Cata & MoP):** suppressed phantom keyring button on Cataclysm and MoP while preserving full display and styling on Classic Era, TBC, and Wrath.
- **Reputation Bar:** unchecking "Show as experience bar" (Als Erfahrungsleiste anzeigen) now properly hides the reputation text immediately without requiring a /reload.
- **FPS Frame (Issue #16):** prevented duplicate FPS/latency frame creation during initialization, resolving ghost/duplicate FPS overlays when moving the frame in Edit Mode.
- **MoP Bag Counter:** fixed free bag slots counter placement and text sizing inside the backpack button.
- **Bag row spacing (Issue #30):** `BagsBarMixin:Layout` re-anchors all five buttons from `bagPadding`, which is 5, so the row spread out and bag 1 lost the 12px gap it needs for the expand arrow. Three things ran it. The first mouseover after login, because `OnCursorChanged` calls `SetExpandBarAuto` on every `CURSOR_CHANGED` and the initial `nil` → `false` counts as a change. Every reload, through `EventUtil.ContinueOnVariablesLoaded` at `VARIABLES_LOADED`. And every collapse or expand, because `KeyringMixin:OnShow` is `self:GetParent():Layout()`. Hooking `BagsBar.Layout` cannot catch any of it: `RegisterCallback` and `GenerateClosure` both captured the function value at load, so replacing the table field is invisible to the caller. The hook now sits on `MainMenuBarBagManager:OnExpandBarChanged`, which is called through a live table lookup, with `PLAYER_ENTERING_WORLD` covering the load-time pass.
- **Keyring position (Issue #30):** the keyring was shown from inside the loop that shows the bags, so `KeyringMixin:OnShow` ran Blizzard's layout on the first pass with only bag 1 visible. `Layout` chains only the buttons visible at that moment, so it built keyring → bag 1 → backpack and left the other three on stale anchors, stranding the keyring in the middle of the row. It is now shown after the bags.
- **Bag row in combat (Issue #30):** none of these buttons are protected, so the blanket combat guard added earlier in this cycle was wrong in both directions: it let Blizzard's layout through and blocked the correction, leaving the row scrambled after a mid-fight collapse or reload. Each button is now asked with `IsProtected` instead, and the retry is driven by what the anchoring reports rather than by the combat flag — which matters because `PLAYER_REGEN_ENABLED` fires while `UnitAffectingCombat` is still set.
- **Keyring spacing (Issue #30):** the gap to the last bag was never an anchor problem. `BagsBarMixin:Layout` runs `UpdateOrientation` on every registered bag button, and for the keyring that is `self:SetSize(self.initialWidth, self.initialHeight)` — dimensions captured in `KeyringMixin:OnLoad`, before this addon restyles the button into a 30x30 disc. Measured, that is 18x39 against the bags' 30x30. The artwork is 30.5px and centred on the frame, so on the narrower frame it overhung roughly six pixels each side and crowded the neighbouring bag. The size is now reasserted alongside the anchors.
- **Keyring scale (Issue #30):** the keyring scales with the bag row instead of staying at full size.
- **New: `/df log bagtrace`:** logs every `SetPoint`, `Show` and `Hide` on the bag row with the caller's stack and the combat state, and `/df log bagtrace state` prints what the layout is computed from — Blizzard's padding and expand flags, the saved collapsed state, and each button's anchor, visibility and protected status. All of the above was found with it after three fixes aimed at guessed callers had failed.

### Professions
- **Skill rank text restored (Issue #29):** the number on the profession rank bar was being created on the bar's parent frame, which puts it behind the bar's own fill texture — a child frame draws above every draw layer of its parent, `OVERLAY` included. The bar was fully drawn and the text was underneath it. It now lives on the bar itself.
- **Beast Training:** restored Beast Training (Wildtierausbildung) and CraftFrame support for Hunter pets in Classic Era, Season of Discovery, and TBC with spellbook tab scanning, training points counter, and legacy craft frame suppression.
- **MoP & Cataclysm Crash Fix:** included `LibTradeSkillRecipes` in MoP and Cata TOC files and hardened mixins to prevent startup errors and restore the Dragonflight UI profession window.

### Dark Mode
- **Live Toggle:** Dark Mode can now be toggled on and off live with immediate color and saturation restoration without requiring `/reload`.
- **Dynamic State Lookup:** unit frame hooks, action bar buttons, and flyouts dynamically fetch active settings to avoid stale styling closures.
- **Party Member Borders:** the golden party border now goes dark with every other unit frame. Dark Mode was walking `PartyMemberFrame1` through `4`, globals that do not exist on Era 1.15.9, TBC 2.5.6 and MoP 5.5.4 where the member frames come out of `PartyFrame.PartyMemberFramePool` — so the loop found nothing and failed quietly. The border also survives a roster change now, which previously restored the golden art.

### Nameplates
- Fixed an error that could repeat hundreds of times in a session from querying a nameplate's parent when the element was not a frame. Reported with Plater.

## 0.43.0 — Party frames and professions (13 August 2026)

Party frames stay put in combat, the profession window behaves, and TBC starts
up again.

**Highlights** — party frames survive combat · one profession window, and you
can move it · TBC: fixed a crash on startup · Hide Clock finally sticks

### Party frames

- Members no longer vanish, or collapse to a single member, when combat starts.
  This addon was applying Blizzard's edit mode layout at login, which tainted
  the party frames for the rest of the session

### Profession window

- Tradeskills open one window instead of two. Blizzard's was left sitting behind
  ours unless you happened to have BlizzMove installed. Enchanting still shows
  Blizzard's craft window, because the **Enchant** button lives on it
- Drag it by its header, and it stays where you put it
- No more empty profession window at every login
- The profession icon fills its ring instead of sitting inside a border

### Edit mode

- New setting: **Disable Blizzard's Edit Mode**, on by default. Saving in
  Blizzard's writes its whole layout over this one, so the game's own ways in
  are switched off
- **Rotate Minimap** survives a reload. It was written somewhere the game
  overwrites every time it applies its layout

### Unit frames

- Stopped tainting the target frame's debuff buttons, a long-standing source of
  blocked actions
- **TBC:** fixed a flood of `Invalid frame handle` errors during combat

### Minimap

- **Hide Clock** stays hidden after a reload or relog

### Castbar

- **TBC:** fixed an error on startup when the target frame had not been placed
  yet

### Character pane

- Tab labels are vertically centred again, in both the selected and unselected
  tab
- The pane was building itself out of the game's script budget and getting cut
  off partway, which left it half-made

### Action bars

- The keyring stays on the end of the bag bar instead of wandering in among the
  bags when the bag menu is opened and closed

### Tooltips

- Fixed the tooltip body flickering on and off while you hover it. Blizzard put
  its own backdrop back on every refresh and ours took it away again

### Under the hood

- Removed leftover debug messages that printed to chat
- The addon no longer writes a performance log to your SavedVariables every
  session

## 0.42.0 — Fixes from the field (30 July 2026)

### Loot rolls

- Hovering **Need**, **Greed** or **Pass** names who chose it again
- The count is back on each button; an empty Pass reads `0`
- The line under the item name no longer repeats those numbers — it shows how
  many have yet to answer, then the winner
- The settings preview shows a live roll, tooltips included

### Request Stop / vehicle exit button

- Sits above the top action bar, flush with the left edge, at button size, with
  the same frame as every other button
- Glows while it can actually be clicked — it had no usable-or-not look at all
- Can be turned off, and previewed from the settings without catching a flight

### Action bars

- Scrolling bar 1 no longer cycles through bars already on screen. This only
  ever worked on TBC
- The page number no longer sits offset on the first render
- **Pet Bar** works as an anchor — it pointed at a frame that does not exist

### Unit frames

- Fixed a burst of Lua errors at login, from the player, target, pet and
  secondary resource frames
- Health and mana numbers show on party frames with **Status Text** on

### Edit mode

- **Use Raid-Style Party Frames** works, and stays put. The toggle wrote a
  setting the game no longer reads, and Blizzard's own checkbox was being undone
  on the next reload or dungeon

### Compatibility

- Fixed an error at login with **Clique**, which was also costing Clique its
  party frame mouse handling

### Buffs

- The settings page now says plainly that the game's **Consolidate Buffs**
  option cannot reach DragonflightUI's buff frame

### Elsewhere

- The Discord button opens this project's server, not the original author's
- BuyMeACoffee removed — it collected for upstream

### For bug reports

- The version number is real; reports no longer read `@project-version@`
- New `/df log watch` — run it, reproduce the problem, run it again. It reports
  what moved and opens a window to copy
- One less source of taint errors carrying DragonflightUI's name

## 0.41.2 — Bug reports, answered (27 July 2026)

### Blue shamans (new)

- New setting under Misc → Utility → **Class Colors**. Era gives shamans the
  paladin's pink; this makes them TBC's blue
- Off by default. Nameplates and default chat stay pink — the game colours
  those, not us

### Target frame combat glow

- The glow traces the frame now instead of sitting beside it, and turns the ring
  red rather than hiding behind it
- Target, focus, boss frames and the edit mode preview each get their own

### Action bars

- Fixed placing and moving spells with **Always show action bar** off (TBC)
- Fixed stack counts left behind on a slot you dragged an item out of
- Fixed the green equipped border staying on a trinket after you unequip it
- Fixed a renamed macro keeping its old name
- Scrolling the main bar skips bars already on screen again
- **Paging**: *Smart* only differs from *Default* on druids, and now says so

### Unit frames

- Fixed an invisible frame eating clicks around the target, target-of-target,
  pet and focus frames after opening edit mode
- Fixed party frame settings only applying when someone joined or left the group
- Fixed party members vanishing when combat started
- XP bar text is centred again when rested XP is showing

### Edit mode

- The *Empty* placeholder keeps the frame's shape — no more oversized box over a
  narrow bar

### Elsewhere

- Fixed guild and community list avatars not loading
- Fixed the blank gap where an out-of-range player's name goes in tooltips
- Aimed Shot shows a cast bar

### For bug reports

- `/df log blockers` — what is taking mouse input at a spot
- `/df log tot` — why the target-of-target frame is hidden
- Keybinding under **DragonflightUI → Debug** captures whatever is under the
  cursor, with a window to copy it out of
- Repeated log lines are counted, not repeated

## 0.41.1 — Revived (26 July 2026)

### Undo and redo in edit mode (new)

- Ctrl+Z (Cmd+Z on a Mac) undoes, Ctrl+Y or Ctrl+Shift+Z redoes, while the edit
  mode panel is open
- Covers everything you change there — dragging a frame, a slider, a dropdown —
  and a small note on screen names what it just put back
- History lasts for as long as edit mode is open

### Bars that stand on their own (new)

- New **Stand On Its Own** checkbox at the top of each bar's Position settings.
  On, it moves alone; off, it goes back to moving with the frames it was
  attached to
- Neither switch moves anything on screen — things stay exactly where they are,
  they just stop travelling together
- By default the main action bar is stuck to the reputation bar, which is stuck
  to the XP bar, so dragging the XP bar dragged all three. Tick it on the XP bar
  and it moves alone

### Movable windows (new)

- The character pane, trade window, inspect, quest log, spellbook and talent
  window can be dragged by their title bar, and stay where you put them
- Settings → Misc → **Movable Windows**, with a Reset button that hands every
  window back to the game's own placement
- Windows you never move are left exactly where the game puts them. A window
  only stops taking part in the game's window arranging once you have moved it
  — which is also what lets it stay open alongside the others, so the character
  pane and trade window can finally sit side by side

### Errors and combat blocks

- Fixed the "Invalid frame handle" error thrown every time you entered combat.
  It also meant frames that were meant to fade in combat silently never did
- Fixed the error when casting certain spells
- Fixed the error when using a consumable in combat
- Fixed "action blocked" spam when hovering or clicking your action bars mid-fight
- Fixed the stutter caused by `#showtooltip [@mouseover]` macros. An earlier
  attempt at this broke casting and was pulled; it is back now without that
  side effect

### Action bars vanishing

- Fixed every bar disappearing after anchoring the XP bar to an action bar.
  Anchoring one to the other closed a loop, and the error took the rest of the
  setup with it
- An anchor choice that would form a loop is now refused politely: the frame
  anchors to the screen and says so once, instead of erroring on every settings
  change
- **MoP:** fixed having no action bars at all, while the options still showed
  them as on
- **MoP:** fixed an error on every drag in edit mode
- **MoP:** fixed the focus target frame being resized unexpectedly, and the
  warning it logged on every layout update

### Action bars

- Action buttons stuck greyed out until you moused over them
- Bars 6–8 unresponsive on TBC and refusing dragged spells
- Micro menu and bag bar: hide, transparency and mouseover settings now
  actually apply
- The bag bar's expand arrow does something

### Party frames

- Class colour and gradient options work on the new party frames
- Health bars no longer stuck washed-out, and no longer dimmed by Blizzard
  over the top of our styling
- Correct power bar art
- Frame art sits behind the bars instead of over them
- Names truncate before the role icon and stay on one line
- Debuff row moved off the power bar
- Status text sized to fit the bar
- Party frames have their own settings page, edit mode entry and move handle
- Our styling can no longer break Blizzard's own party frame update loop

### Loot rolls

- Rebuilt on retail's actual loot roll frame
- Retail need/greed/pass icons instead of the classic dice and coin
- Preview button and real customization options in settings
- The preview shows a full drop, with working tooltips over it
- Adjustable gap between stacked rolls
- Fixed the restyle aborting partway, which was also taking the whole UI
  module down with it

### Edit mode

- Fixed the unit frames being shoved around when you open Blizzard's own Edit
  Mode. They stayed wrong until you next left combat
- Fixed frames disappearing when you left edit mode and only returning after
  a reload
- Fixed frames resetting to the wrong position after login or a loading screen
- Leaving edit mode only hides frames that exist purely to be dragged
- Frames with nothing to show get a labelled placeholder you can grab
- Only one edit mode open at a time — opening Blizzard's closes ours, and the
  other way round
- Closing edit mode during combat no longer makes it reopen by itself when the
  fight ends

### Nameplates

- Nameplate style is a real setting, and applies live without a reload
- Fixed a second level number appearing on styles that already have one
- Fixed level placement so it matches each style

### Chat

- The chat window can be selected and moved in DFUI's edit mode
- Chat no longer stretched or shunted around by Blizzard's edit mode
- Fixed tabs past the first rendering shifted upward when chat sits at the
  bottom of the screen
- An undocked tab can no longer be dragged off the screen and lost
- The combat log's filter bar no longer covers your other chat tabs

### Character pane

- The Dragonflight paperdoll artwork shows only on the Character tab, instead
  of bleeding onto Reputation, Skills and Pet
- The border around the model area is treated as paperdoll art too, so it no
  longer floats behind the skill list

### Reloading in combat

- One clear message instead of several, and everything the fight blocked is
  re-applied once combat ends
- An on-screen panel explains why the UI looks half-built, rather than a chat
  line that is easy to miss mid-pull

### Settings and reporting

- Bug reports show a real version number instead of `@project-version@`
- Turned-off features are marked "(off)" and can be switched back on from
  their own page, instead of being dead greyed-out entries
- The quest tracker can be disabled without disabling the whole Minimap module
- The settings window can be dragged by its header
- New `/df log` debug log, which records errors and blocked actions to disk so
  bug reports can include a real log

## 0.41.0 — Classic Era 1.15.9 support (22–25 July 2026)

The 1.15.9 patch replaced the Classic Era interface with a backport of the
modern one — Blizzard Edit Mode, retail-style action bars, pooled party
frames — which broke most of the addon. This update is the overhaul for it,
and also adds support for TBC 2.5.6 and MoP 5.5.4.

### Loading and stability

- The addon no longer half-loads and gives up partway through login
- The interface no longer visibly builds itself piece by piece for a second
  after you log in
- Reloading mid-fight finishes the job the moment combat ends, instead of
  leaving the UI half native
- Fixed the quest tracker freezing the game
- Fixed a wave of errors from interface pieces the patch removed

### Action bars

- Page arrows on the main bar work again, cycle all 6 pages, and keep working
  in combat
- The page number next to them updates again
- Shift-scrolling to change pages no longer strobes between two pages
- Keybinds on bars 6–8 fired nothing
- Bars 6–8 showed every spell twice
- Bar backgrounds were missing entirely
- Empty slots show while you are dragging a spell, and a vacated slot updates
  immediately
- Added the retail main bar frame, with an adjustable darkness setting for the
  fill behind the buttons
- Pet bar restored to its proper size, with correct highlight, active and
  autocast art
- The taxi and vehicle exit button uses the retail round arrow and sits at the
  end of the main bar instead of floating mid-screen
- Micro menu and bag bar line up with each other properly
- Fixed the garbled guild button and the stray green square in the micro menu

### Raid and hover performance

- Fixed the big one: frame skips and stutter when moving the mouse across raid
  frames
- Buff timers no longer churn the garbage collector every frame
- The character stats panel no longer listens to events for every unit in the
  world
- Keeps Questie's raid safeguards working when the client cuts its startup
  short, a major source of raid frame drops

### Nameplates (new)

- New Nameplates module: Dragonflight-styled enemy plates, outlined names and
  class-coloured enemy players

### Party and unit frames

- Full Dragonflight restyle for the new pooled party frames, including
  portraits, role icons and frame art
- Pet buffs and pet happiness restored
- Fixed the target frame's reaction-coloured bar hanging around
- Unit frame positions survive Blizzard's layout applications

### Character pane

- Retail Dragonflight pane background, and the plates framing your gear
  columns
- Restored the slot frame art and the border around the model
- Weapon row centred properly, with the ammo slot and arrow placed correctly
  for classes that use one

### Loot rolls

- Rebuilt on the real Dragonflight loot roll, replacing the classic-looking
  one
- Live tally of what everyone has picked while the roll is running
- Winner announced when it resolves

### Buffs

- Buff and debuff timers keep their real remaining time across a reload,
  instead of restarting at full
- Fixed doubled buffs

### Minimap and misc

- Minimap sits in the corner at a sane default size
- XP bar tooltip works again

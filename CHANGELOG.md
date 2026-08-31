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
- Fixed the login Lua errors in Issues #26 and #28, at the cause: a Blizzard setter was being called with no argument, which erased Blizzard's edit mode layout for the rest of the session.
- Genuinely decoupled from Blizzard's Edit Mode: it stays blocked, no Blizzard function is replaced any more, and settings live in this addon's own profile instead of Blizzard's layout.
- Leftover `DragonflightUI_Layout` (Issue #27): a one-time notice explains how to remove it, with an opt-out; `/df layoutnotice` brings it back. Stale anchors inside it are cleaned up automatically.
- `LibEditModeOverride` removed - loaded on every flavour, never called.
- Streamlined expansion detection across Era, TBC, Wrath, Cata and MoP.
- Silenced the on-screen combat reload banner and sped up post-combat recovery to 100ms.
- Escape closes our windows again without stealing keyboard focus. Stopped leaking generic names into `_G`.

### Chat
- TBC & Era: the chat window stays anchored through loading screens, reloads and resizing without disappearing.

### Unit Frames & Party / Raid
- Raid frames are configurable from DragonflightUI at last - raid size, frame width and height, group split, border, sort order, template, opacity, icon size - under Unitframes ▸ Raid Frame and in this addon's own edit mode, with a preview. No more disabling the addon to reach Blizzard's Edit Mode.
- Raid frames appear in an actual raid, and the raid settings now survive a reload.
- Raid frame settings also apply to raid-style party frames, which Blizzard keeps as a separate system.
- Fixed "Use Raid-Style Party Frames" (Issue #14) switching immediately and living through a `/reload`.
- Found and removed the party frame taint seed - two fields this addon wrote onto Blizzard's `PartyFrame` that Blizzard itself reads on every visibility check.
- Party member names and health/mana text unified to the FRIZQT outline font.
- Shaman totem bar anchors correctly instead of snapping below the player frame.
- Pet frame no longer jumps to default coordinates when summoning a pet.
- TBC: the pet frame is back after being saved to the layout but never placed.
- Focus target frame restored on TBC and MoP, and no longer errors on layout updates (Issues #19, #33); target faction icon fixed on Era.
- Fixed a combat reload error from target-of-target not being built yet.

### Action Bars
- Pet bar buttons resized to their correct scale and centred (Issue #13).
- Fixed `ADDON BLOCKED` errors on spellbook open, levelling up and pet casts.
- Pet action buttons are clickable immediately on login.
- Bar dividers now only appear on Action Bar 1, not 2-8.
- Removed legacy Blizzard gryphon art and duplicate visuals on TBC.
- Fixed Action Bar 1 scaling and in-combat alignment.
- Flyout direction *Up* works properly.
- MoP: the latency indicator sits correctly on the game menu button.
- Keyring suppressed on Cata and MoP, kept on Era, TBC and Wrath.
- Unchecking "Show as experience bar" hides the reputation text immediately.
- Fixed duplicate FPS/latency frames (Issue #16).
- MoP: fixed the bag counter's placement and text size.
- Bag row spacing (Issue #30): the bags no longer drift apart on their own - on login, on collapse and expand, and after a reload, in combat included.
- Keyring position (Issue #30): stays at the end of the row instead of landing in the middle of the bags.
- Keyring spacing (Issue #30): sits at the correct distance from the last bag instead of overlapping it.
- Keyring scale (Issue #30): scales with the rest of the bag row.
- New: `/df log bagtrace` for tracing bag row and keyring issues.

### Professions
- Skill rank text is visible again (Issue #29) - it was drawn behind the bar's own fill texture.
- Restored Beast Training and CraftFrame support for Hunter pets on Era, Season of Discovery and TBC.
- Fixed a MoP and Cataclysm startup crash in the profession window.

### Dark Mode
- Live toggle: switch Dark Mode on and off without a `/reload`.
- Party member borders go dark with every other unit frame, and stay dark through a roster change.

### Nameplates
- Fixed a repeating error from querying a nameplate's parent when it was not a frame. Reported with Plater.

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

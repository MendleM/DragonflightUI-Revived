# Changelog

DragonflightUI Revived — the community-maintained continuation of
DragonflightUI Classic, picking up after upstream's last release (v0.40.3,
May 2026). Current builds report version `0.41.0-revived2`.

Everything before v0.40.3 is in
[upstream's releases](https://github.com/Karl-HeinzSchneider/WoW-DragonflightUI/releases).

## Revived 2 (27 July 2026)

### Blue shamans (new)

- Vanilla gave shamans the paladin's pink, to the third decimal — the game's own
  colour file puts both at `0.96, 0.55, 0.73`. It was never ambiguous at the
  time, because shamans were Horde and paladins Alliance and the two could never
  see each other. On Era they are still identical, which now reads as a bug
- Settings → Misc → Utility → **Class Colors → Blue Shamans** draws them in the
  blue TBC gave them, everywhere DragonflightUI colours by class — unit frames,
  tooltips, loot rolls, the friends list
- Off by default, and greyed out with an explanation on any client whose shamans
  already have a colour of their own
- Nameplates and the default chat are coloured by the game rather than by us, so
  those stay pink. If you run a class colour addon, this setting steps aside and
  lets it decide

### The target frame lights up in combat

- The in-combat glow traces the frame now instead of sitting near it: it is
  built from the frame's own art at the same cut and size, so it follows the
  outline exactly, including the bulge around the portrait
- The red ring replaces the gold one rather than hiding behind it
- Each frame keeps its own glow — the target, the focus, every boss frame and
  the edit mode preview no longer borrow the first one's position and shape

### Action bars

- Fixed being unable to place or move spells on a bar with **Always show action
  bar** turned off. The drag grid appeared and was taken away again in the same
  breath, so there was nothing to drop onto. TBC only, which is what made it
  hard to pin down
- Fixed a stack count left behind on the slot an item was dragged out of — "80
  charges" still showing on an empty button
- Fixed the green *equipped* border staying on a trinket after you took it off.
  Swapping two trinkets left both looking equipped
- Fixed a renamed macro keeping its old name on the button
- Scrolling the main bar skips bars that are already on screen again, the way
  the game intends. It had started cycling all six pages, which laid a second
  copy of a bar you could already see over the one you were using. Hide a bar
  and its page returns to the cycle by itself
- The **Paging** setting now says outright that *Smart* differs from *Default*
  only for druids — on every other class the two are identical

### Unit frames

- Fixed an invisible frame that swallowed clicks where the target,
  target-of-target, pet and focus frames sit. Opening edit mode once — changing
  nothing — left their holders on screen and taking mouse input, so right-drag
  to turn the camera stopped working anywhere near them until a reload
- Fixed party frame settings not applying. Health and power bar changes, Class
  Color included, only appeared when somebody joined or left the group
- Fixed party members vanishing the moment a fight started and coming back when
  it ended
- The XP bar text is centred on the bar again. It never quite was, but rested XP
  makes the line long enough to notice it drifting right

### Edit mode

- The placeholder drawn for a frame with nothing to show keeps that frame's
  shape now. A stance bar stacked into a column was being handed a box five
  times wider than the bar it stood for

### Elsewhere

- Fixed guild and community list avatars silently failing to load. Nobody
  reported this one — it turned up in a log sent in for something else
- Fixed a blank gap where an out-of-range or offline player's name should be in
  the tooltip
- Aimed Shot gets a cast bar. The client does not report it the way it reports
  every other cast, so it is filled in from the cast being sent

### For bug reports

- `/df log blockers` lists everything taking mouse input over a spot — for
  "something invisible here is eating my clicks", which hovering cannot answer
- `/df log tot` reports every condition the game uses to decide whether the
  target-of-target frame should be visible, and says which one is failing
- A keybinding under **DragonflightUI → Debug** captures whatever is under the
  cursor, and a window opens to copy any of it out of for pasting into a report
- Repeated log lines are counted rather than repeated, so one noisy problem no
  longer buries everything else
- Builds installed from source now report their version with `-dev` on the end,
  so a checkout of main can be told apart from a packaged release

## Revived (26 July 2026)

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

## Classic Era 1.15.9 support (22–25 July 2026)

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

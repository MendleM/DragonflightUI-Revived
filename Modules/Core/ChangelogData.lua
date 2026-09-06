local addonName, addonTable = ...;
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

-- The release notes shown by the What's New window, mirroring CHANGELOG.md.
--
-- Kept as data rather than parsed from the file at runtime, because an addon
-- cannot read its own files. When CHANGELOG.md gains an entry, add it here too;
-- the top entry is the one a player sees after updating.
--
-- The top entry's `version` is what decides whether the window opens by itself:
-- adding notes is what makes them appear. Keep it matching the TOC's Version
-- anyway - they describe the same release - and a mismatch is written to the
-- debug log at login, readable with /df log version before packaging.
--
-- Keep the bullets to a line each. These are read in a window in the middle of
-- a game, not a post-mortem: what changed, not why it broke.
--
-- Versions are plain x.y.z and nothing else. The earlier "0.41.0-revived1" and
-- "Revived 2" tried to make the version carry the fact that the project has new
-- maintainers, which it announced once and then repeated forever, and left the
-- number unable to say the only thing a version is for: which build is newer.
-- The `title` is where a release gets a name, and it should describe the
-- release rather than number it - "Revived" was the launch, "Revived 2" was
-- just the one after it.
DF.ChangelogData = {
    {
        version = '0.45.2',
        title = 'Player Totem Frame Toggle',
        date = '6 September 2026',
        intro = 'Added a clean activation toggle for the Player Totem Frame in settings and Edit Mode, allowing the frame to be hidden without reloading.',
        sections = {
            {
                title = 'Highlights',
                items = {
                    'Player Totem Frame can now be toggled on/off under /df -> Unitframes -> Player Totem Frame and in HUD Edit Mode.',
                    'Re-enabling the frame immediately restores and updates active totems without requiring a /reload.'
                }
            }, {
                title = 'Unit Frames',
                items = {
                    'Added an Active toggle (activate) to the Player Totem Frame submodule, providing a clean way to hide or disable the totem frame without relying on heavy secure state handlers.',
                    'When toggling the frame back on, Blizzard\'s TotemFrame is immediately shown and refreshed via TotemFrame_Update() so existing active totems appear right away.',
                    'Fixed a minor naming error in Edit Mode options where the Totem Frame reset preset was labelled as \'Pet\'.'
                }
            }
        }
    }, {
        version = '0.45.1',
        title = 'Party Health Bars',
        date = '6 September 2026',
        intro = 'Follow-up to 0.45.0: the party health bars keep their colour and their number without being hovered, and a preset Edit Mode layout no longer taints the party frames on every login.',
        sections = {
            {
                title = 'Highlights',
                items = {
                    'Party health bars stay class-coloured instead of snapping back to green.',
                    'The health number no longer trails the target frame by a tick.',
                    'No more taint on the party frames while you are on one of Blizzard\'s preset layouts.'
                }
            }, {
                title = 'Unit Frames',
                items = {
                    'Fixed the party health bars falling back to Blizzard\'s green, and the health number lagging behind - both had the same cause. These bars carry frequentUpdates, so UNIT_HEALTH is never registered on them: Blizzard polls them through UnitFrameHealthBar_OnUpdate, which calls SetValue, which fires OnValueChanged, and that is where the green is set. The repaint that replaced lockColor in 0.45.0 was hooked to UnitFrameHealthBar_Update instead, which barely runs for these frames - measured in a group: 21 green writes from the poll against 4 repaints from the hook. Hooking OnValueChanged sorts out the colour and the readout in one place.',
                    'The bar art is only re-assigned when it actually changes, instead of on every value change.'
                }
            }, {
                title = 'Edit Mode',
                items = {
                    'Fixed the party frames being tainted at every login while a preset layout is active. The raid settings were mirrored onto the party system unconditionally, and that runs Blizzard\'s applier - which rebuilds PartyFrame.settingMap from addon code, the table Blizzard reads on every ShouldShow, so on every group event. It only ever showed on presets: a layout of your own already holds the values and the applier is skipped, while on a preset nothing can be stored and it ran every single time. The mirror now runs only while raid-style party frames are actually up.'
                }
            }, {
                title = 'Debugging',
                items = {
                    '/df log party reports the bar repaint path, the raid-style setting across all five places it passes through, and the live state of a member\'s bars - colour against the wanted colour, art, fill level against real health, and the fields that gate Blizzard\'s health poll.'
                }
            }
        }
    }, {
        version = '0.45.0',
        title = 'Party Frames in Combat & a Quiet Startup',
        date = '2 September 2026',
        intro = 'The party frames no longer break when someone levels up mid-fight, the chat spam and frame drop at the end of a fight are gone, and the leftover Edit Mode layout is cleaned up without anyone having to do it by hand.',
        sections = {
            {
                title = 'Highlights',
                items = {
                    'Party frames survive a group member levelling up, or an invite, in combat.',
                    '"Show party as raid" works at all now. It takes effect on the next reload and asks for one when you switch it.',
                    'A tick that disagrees with your Edit Mode layout is corrected instead of lying to you.',
                    'No more "combat ended - finishing setup" after a group invite, and no frame drop with it.',
                    'Leftover DragonflightUI_Layout is renamed and reused, or removed - the delete-it-yourself popup is gone.',
                    'The raid-style party frame setting is stored where the game can apply it itself.',
                    'Party members get their class colour as soon as the game knows it, instead of staying white.',
                    'Disabling the Action Bar module in settings no longer blocks mouse clicks across the screen.'
                }
            }, {
                title = 'Action Bars',
                items = {
                    'Fixed mouse clicks being blocked across the screen when the Action Bar module was disabled in settings.',
                    'Micro menu and bag bar holder frames no longer span full-screen and are properly hidden when deactivated.'
                }
            }, {
                title = 'Unit Frames',
                items = {
                    'Fixed "Show party as raid" doing nothing at all. The value was stored by reading it back off Blizzard\'s system frame first, which is only correct after Blizzard\'s own setter has run - and on this path that setter is deliberately never run. So the old value was stored as if it were the new one, every time. The layout kept saying 0 no matter what the checkbox said, and the reload had nothing to apply.',
                    'The switch no longer runs Blizzard\'s appliers. Flipping it used to call EditModeManagerFrame:UpdateSystem and six more Blizzard functions to make the change visible at once. That ran every applier the system has, from our execution, which tainted settingMap, systemInfo and dirtySettings on PartyFrame, optionTable on all ten compact frames and member.unit on all four pooled ones - and it applied the OLD value, because it reads the layout and not our profile.',
                    'The checkbox now describes what the frames are doing. If the two disagree - which everyone carries forward who ticked the box on an older build - the tick is moved to match the layout and you are told once per character. The layout wins, because it is what the game applies and also where Blizzard\'s own Edit Mode writes this setting.',
                    'Fixed the third cause of the blocked actions: the health and mana readouts inside the party bars. On 1.15.9 no unit frame ships a TextString, so this addon supplied one - which is what made the numbers appear, and a taint seed. Blizzard reads self.TextString at the end of every health and power update, so currValue, disconnected and finally member.unit were written insecure by Blizzard\'s own code as a result. The strings are ours now and kept off the bars; Status Text and all its display modes still work, mouseover included.',
                    'Fixed the second cause of those blocked actions, the one that outlived the fix below. The party health and power bars carried lockColor, Blizzard\'s own opt-out for re-tinting a bar - and setting it writes a field onto a protected frame that Blizzard reads back on every health and power event. That read handed our taint to Blizzard, and the member.unit written next carried the blame. It hit all four pooled member frames, in use or not, which is why it only ever showed on the portrait-style party frames and never on the raid-style ones. Colour and power art are re-asserted with a hook now, and nothing of this addon is left on the frame.',
                    'Fixed the blocked actions on the party frames. Flipping the raid-style switch ran Blizzard\'s own applier for it, and that one reaches into both party displays at once - member.unit on the portrait frames, optionTable on the compact ones. Run from addon code those fields stay tainted for the rest of the session, and the next invite or level-up in combat had its SetAttribute, Hide and SetShown refused. The setting is stored now and the game applies it while loading, which is the only way it can be done safely.',
                    'The switch therefore needs a reload to take effect, and asks for one when you change it. Every other setting still applies immediately.',
                    'DragonflightUI never reloads the interface on its own any more: reload() is a protected call and the client refuses it in combat.',
                    'The raid appliers only run inside an actual raid now. Outside one they had nothing to arrange and only seeded that taint.',
                    'Raid-style party frames keep their size again: the raid settings are mirrored onto the party system, which is where CompactUnitFrame reads them from.',
                    'Role icons are restyled after Blizzard\'s own update instead of during it.',
                    'Party members are recoloured once their class information arrives.',
                    'Edit Mode settings that already match are no longer re-applied.'
                }
            }, {
                title = 'Edit Mode',
                items = {
                    'The raid-style party frame setting cannot be stored in a preset layout, so DragonflightUI adds DFUI_Revived_Layout - a copy of the active layout - and switches to it. From then on the game applies the setting itself and this addon never touches it. If you already use a layout of your own, nothing is added.',
                    'Leftover DragonflightUI_Layout (Issue #27) is repaired, renamed to DFUI_Revived_Layout and reused where a layout is needed, or deleted where it is not. The popup explaining how to delete it by hand, and /df layoutnotice, are gone.',
                    'New: /df layoutretry, for when adding that layout did not work the first time.'
                }
            }, {
                title = 'Core & Architecture',
                items = {
                    'Deferring routine work is separated from recovering a reload that happened mid-fight. A group invite during combat used to queue as unfinished setup, announce itself twice in chat and re-apply the settings of every module once combat dropped - actionbars, bags, unit frames, minimap, chat, tooltips. That was the lag spike at the end of a fight.',
                    'A roster change outside a raid now does nothing at all rather than being deferred and then doing nothing.',
                    'Messages about something that cannot be acted on are said once per character instead of at every login.',
                    'Two "already hooked" markers this addon wrote onto Blizzard\'s frames now live in our own table. They only ever answered a question about us, and any field of ours on a frame Blizzard reads is a taint seed waiting for the read.',
                    'Failures while saving an Edit Mode layout are reported instead of swallowed by a pcall.'
                }
            }
        }
    },
    {
        version = '0.44.3',
        title = 'Action Bar Usability & Consumable Fixes',
        date = '1 September 2026',
        intro = 'Fixes for action bar empty consumable items displaying as usable on login.',
        sections = {
            {
                title = 'Highlights',
                items = {
                    'Action Bars: fixed empty consumables (count = 0) displaying as colored/usable on login.',
                    'Action Bars: hooked button usability, update, and count functions for real-time state sync.'
                }
            }, {
                title = 'Action Bars',
                items = {
                    'Fixed empty consumables (count = 0) displaying as colored on login instead of grayed out.',
                    'Hooked UpdateUsable, Update, and UpdateCount on action buttons alongside bag update events for real-time usability sync.'
                }
            }
        }
    },
    {
        version = '0.44.2',
        title = 'Stance Bar Fixes & In-Combat Protection',
        date = '1 September 2026',
        intro = 'Targeted fixes for the Stance Bar (shapeshift bar) and in-combat reload stability.',
        sections = {
            {
                title = 'Highlights',
                items = {
                    'Stance Bar: fixed ADDON_ACTION_BLOCKED taint errors in combat.',
                    'Stance Bar: fixed flickering and disappearing buttons during action bar updates.',
                    'Stance Bar: corrected stance button reparenting and scaling.',
                    'Raid Frames: protected in-combat /reload from CompactPartyFrame SetSize blocked actions.'
                }
            }, {
                title = 'Action Bars & Stance Bar',
                items = {
                    'Fixed stance buttons disappearing on macro hover and spell casts by routing UpdateGridState to UpdateButtonState.',
                    'Corrected button reparenting so StanceButton1..10 are parented to DragonflightUIStancebar.',
                    'Silenced Blizzard background StanceBar frame events to prevent SetShownBase taint errors.'
                }
            }, {
                title = 'Unit Frames',
                items = {
                    'Deferred RaidFlowWatcher settings and container updates during combat to avoid mid-fight SetSize errors.'
                }
            }
        }
    },
    {
        version = '0.44.0 / 0.44.1',
        title = 'The Definitive Refactor & Stability Overhaul',
        date = '26 August - 31 August 2026',
        intro = 'Complete stability overhaul: permanent decoupling from Blizzard Edit Mode, combat reload visual preservation, robust TBC totem positioning, solid ChatFrame anchoring, and instant live Darkmode switching.',
        sections = {
            {
                title = 'Highlights',
                items = {
                    'Login Lua errors are gone (Issues #26, #28).',
                    'Party frame blocked actions: found and removed the taint seed.',
                    'Decoupled from Blizzard EditMode for real.',
                    'Raid frames are configurable from DragonflightUI, with a preview.',
                    'Seamless combat reloads, no visual snapping.',
                    'Chat frame anchored permanently on TBC and Era.',
                    'Totem bar fix for Shamans.',
                    'Darkmode toggle: switch on and off live, no reload required.',
                    'Action bar dividers fixed to only appear on the main bar.'
                }
            }, {
                title = 'Core & Architecture',
                items = {
                    'Fixed the cause of the login errors in Issues #26 and #28.',
                    'Edit mode settings live in the DragonflightUI profile now, not in Blizzard\'s server-side layout.',
                    'No Blizzard function is replaced any more.',
                    'Leftover DragonflightUI_Layout (Issue #27): a one-time notice explains how to remove it. /df layoutnotice brings it back.',
                    'LibEditModeOverride is no longer shipped.',
                    'Streamlined expansion detection across Era, TBC, Wrath, Cata and MoP.',
                    'Removed the on-screen combat reload banner and sped up post-combat recovery.',
                    'Stopped leaking helper and debug names into the global namespace.'
                }
            }, {
                title = 'Chat',
                items = {
                    'TBC & Era: the chat window keeps its position through loading screens and reloads without disappearing.'
                }
            }, {
                title = 'Unit frames & Party / Raid',
                items = {
                    'Raid frames configurable here at last: raid size, frame width and height, group split, border, sort order, template, opacity and icon size now sit under Unitframes > Raid Frame and in the edit mode, with a preview.',
                    'Party & Raid Frame Toggle (Issue #14): switches immediately and lives through a /reload.',
                    'Party frame blocked actions fixed at the source - two fields this addon wrote onto Blizzard\'s PartyFrame.',
                    'Party member names and health/mana text unified to the FRIZQT outline font.',
                    'Shaman totem bar anchors correctly instead of snapping below the player frame.',
                    'Pet frame no longer jumps to default coordinates when summoning a pet.',
                    'Raid frames appear in an actual raid, and the raid settings survive a reload.',
                    'Raid frame settings also apply to raid-style party frames.',
                    'The raid frame placeholder matches the frames, and the raid grows right and down instead of outwards.',
                    'Focus target is visible on TBC and MoP, and no longer errors on layout updates.',
                    'Era: faction icon sits on target frame properly.',
                    'No more error when reloading during combat from target-of-target not being built yet.'
                }
            }, {
                title = 'Action bars',
                items = {
                    'Pet bar sizing standardized, fixing undersized buttons (Issue #13).',
                    'Fixed ADDON BLOCKED errors on spellbook open and pet casts.',
                    'Pet buttons are clickable on login.',
                    'Bar dividers restricted to Action Bar 1.',
                    'Removed legacy Blizzard gryphon art on TBC.',
                    'Fixed Action Bar 1 scaling and in-combat alignment.',
                    'Flyout Direction: choosing Up works properly.',
                    'MoP: the latency indicator sits correctly on the game menu button.',
                    'Keyring suppressed on Cata and MoP, kept on Era, TBC and Wrath.',
                    'Unchecking "Show as experience bar" hides the reputation text immediately.',
                    'Fixed duplicate FPS/latency frames (Issue #16).',
                    'MoP: fixed the bag counter\'s positioning and text size.',
                    'Bag row spacing (Issue #30): the bags no longer drift apart on their own.',
                    'Keyring position (Issue #30): stays at the end of the row.',
                    'Keyring spacing (Issue #30): sits at the correct distance from the last bag.',
                    'Keyring scale (Issue #30): scales with the rest of the bag row.'
                }
            }, {
                title = 'Professions',
                items = {
                    'Skill rank text is visible again (Issue #29).',
                    'Restored Beast Training and CraftFrame support for Hunter pets on Era, Season of Discovery and TBC.',
                    'Fixed a MoP and Cataclysm startup crash in the profession window.'
                }
            }, {
                title = 'Dark Mode',
                items = {
                    'Live toggle: switch Dark Mode on and off without a /reload.',
                    'Party member borders go dark like every other unit frame, and stay dark through a roster change.'
                }
            }, {
                title = 'Nameplates',
                items = {
                    'Fixed a repeating error from querying a nameplate\'s parent when it was not a frame. Reported with Plater.'
                }
            }
        }
    }, {
        version = '0.43.0',
        title = 'Party frames and professions',
        date = '13 August 2026',
        intro = 'Party frames stay put in combat, the profession window behaves, and TBC starts up again.',
        sections = {
            {
                title = 'Highlights',
                items = {
                    'Party frames survive combat.',
                    'One profession window, and you can move it.',
                    'TBC: fixed a crash on startup.',
                    'Hide Clock finally sticks.'
                }
            }, {
                title = 'Party frames',
                items = {
                    'Members no longer vanish, or collapse to a single member, when combat starts. This addon was applying Blizzard\'s edit mode layout at login, which tainted the party frames for the rest of the session.'
                }
            }, {
                title = 'Profession window',
                items = {
                    'Tradeskills open one window instead of two. Blizzard\'s was left sitting behind ours unless you happened to have BlizzMove installed. Enchanting still shows Blizzard\'s craft window, because the Enchant button lives on it.',
                    'Drag it by its header, and it stays where you put it.',
                    'No more empty profession window at every login.',
                    'The profession icon fills its ring instead of sitting inside a border.'
                }
            }, {
                title = 'Edit mode',
                items = {
                    'New setting: Disable Blizzard\'s Edit Mode, on by default. Saving in Blizzard\'s writes its whole layout over this one, so the game\'s own ways in are switched off.',
                    'Rotate Minimap survives a reload - it was written somewhere the game overwrites on every layout.'
                }
            }, {
                title = 'Unit frames',
                items = {
                    'Stopped tainting the target frame\'s debuff buttons, a long-standing source of blocked actions.',
                    'TBC: fixed a flood of Invalid frame handle errors during combat.'
                }
            }, {
                title = 'Minimap',
                items = {'Hide Clock stays hidden after a reload or relog.'}
            }, {
                title = 'Castbar',
                items = {'TBC: fixed an error on startup when the target frame had not been placed yet.'}
            }, {
                title = 'Character pane',
                items = {
                    'Tab labels are vertically centred again, in both the selected and unselected tab.',
                    'The pane was building itself out of the game\'s script budget and getting cut off partway, leaving it half-made.'
                }
            }, {
                title = 'Action bars',
                items = {'The keyring stays on the end of the bag bar instead of wandering in among the bags.'}
            }, {
                title = 'Tooltips',
                items = {'Fixed the tooltip body flickering on and off while you hover it.'}
            }, {
                title = 'Under the hood',
                items = {
                    'Removed leftover debug messages that printed to chat.',
                    'The addon no longer writes a performance log to your SavedVariables every session.'
                }
            }
        }
    }, {
        version = '0.42.0',
        title = 'Fixes from the field',
        date = '30 July 2026',
        intro = 'Everything reported since the last CurseForge build, fixed.',
        sections = {
            {
                title = 'Loot rolls',
                items = {
                    'Hovering Need, Greed or Pass names who chose it again.',
                    'The count is back on each button; an empty Pass reads 0.',
                    'The line under the item name shows how many have yet to answer, then the winner - it no longer repeats those numbers.',
                    'The settings preview shows a live roll, tooltips included.'
                }
            }, {
                title = 'Request Stop button',
                items = {
                    'Sits above the top action bar, flush left, at button size, with the same frame as every other button.',
                    'Glows while it can actually be clicked - it had no usable-or-not look at all.',
                    'Can be turned off, and previewed from the settings without catching a flight.'
                }
            }, {
                title = 'Action bars',
                items = {
                    'Scrolling bar 1 no longer cycles through bars already on screen. This only ever worked on TBC.',
                    'The page number no longer sits offset on the first render.',
                    'Pet Bar works as an anchor - it pointed at a frame that does not exist.'
                }
            }, {
                title = 'Unit frames',
                items = {
                    'Fixed a burst of Lua errors at login, from the player, target, pet and secondary resource frames.',
                    'Health and mana numbers show on party frames with Status Text on.'
                }
            }, {
                title = 'Edit mode',
                items = {
                    'Use Raid-Style Party Frames works again, and stays put after a reload or a dungeon.'
                }
            }, {
                title = 'Elsewhere',
                items = {
                    'Fixed an error at login with Clique, which was also costing Clique its party frame mouse handling.',
                    'The buff settings page says plainly that the game\'s Consolidate Buffs option cannot reach our buff frame.',
                    'The Discord button opens this project\'s server, not the original author\'s.'
                }
            }, {
                title = 'For bug reports',
                items = {
                    'The version number is real - reports no longer read @project-version@.',
                    'New /df log watch: run it, reproduce the problem, run it again. It reports what moved and opens a window to copy.'
                }
            }
        }
    }, {
        version = '0.41.2',
        title = 'Bug reports, answered',
        date = '27 July 2026',
        intro = 'A week of bug reports from the Discord, answered.',
        sections = {
            {
                title = 'Blue shamans',
                new = true,
                items = {
                    'New setting under Misc > Utility > Class Colors. Era gives shamans the paladin\'s pink; this makes them TBC\'s blue.',
                    'Off by default. Nameplates and default chat stay pink - the game colours those, not us.'
                }
            }, {
                title = 'Target frame combat glow',
                items = {
                    'The glow traces the frame now instead of sitting beside it, and turns the ring red rather than hiding behind it.',
                    'Target, focus, boss frames and the edit mode preview each get their own.'
                }
            }, {
                title = 'Action bars',
                items = {
                    'Fixed placing and moving spells with Always show action bar off (TBC).',
                    'Fixed stack counts left behind on a slot you dragged an item out of.',
                    'Fixed the green equipped border staying on a trinket after you unequip it.',
                    'Fixed a renamed macro keeping its old name.',
                    'Scrolling the main bar skips bars already on screen again.',
                    'Paging: Smart only differs from Default on druids, and now says so.'
                }
            }, {
                title = 'Unit frames',
                items = {
                    'Fixed an invisible frame eating clicks around the target, target-of-target, pet and focus frames after opening edit mode.',
                    'Fixed party frame settings only applying when someone joined or left the group.',
                    'Fixed party members vanishing when combat started.',
                    'XP bar text is centred again when rested XP is showing.'
                }
            }, {
                title = 'Edit mode',
                items = {
                    'The Empty placeholder keeps the frame\'s shape - no more oversized box over a narrow bar.'
                }
            }, {
                title = 'Elsewhere',
                items = {
                    'Fixed guild and community list avatars not loading.',
                    'Fixed the blank gap where an out-of-range player\'s name goes in tooltips.',
                    'Aimed Shot shows a cast bar.'
                }
            }, {
                title = 'For bug reports',
                items = {
                    '/df log blockers - what is taking mouse input at a spot.',
                    '/df log tot - why the target-of-target frame is hidden.',
                    'Keybinding under DragonflightUI > Debug captures whatever is under the cursor, with a window to copy it out of.',
                    'Repeated log lines are counted, not repeated.'
                }
            }
        }
    }, {
        version = '0.41.1',
        title = 'Revived',
        date = '26 July 2026',
        intro = 'The community-maintained continuation of DragonflightUI Classic, picking up where the original left off.',
        sections = {
            {
                title = 'Undo and redo in edit mode',
                new = true,
                items = {
                    'Ctrl+Z (Cmd+Z on a Mac) undoes, Ctrl+Y or Ctrl+Shift+Z redoes, while the edit mode panel is open.',
                    'Covers everything you change there - dragging a frame, a slider, a dropdown - and a small note names what it just put back.',
                    'The history lasts for as long as edit mode is open.'
                }
            }, {
                title = 'Bars that stand on their own',
                new = true,
                items = {
                    'New Stand On Its Own checkbox at the top of each bar\'s Position settings.',
                    'On, it moves alone. Off, it goes back to moving with the frames it was attached to.',
                    'Neither switch moves anything on screen - things stay where they are, they just stop travelling together.',
                    'By default the main action bar is stuck to the reputation bar, which is stuck to the XP bar, so dragging the XP bar dragged all three. Tick it on the XP bar and it moves alone.'
                }
            }, {
                title = 'Movable windows',
                new = true,
                items = {
                    'The character pane, trade window, inspect, quest log, spellbook and talent window can be dragged by their title bar, and stay where you put them.',
                    'Settings > Misc > Movable Windows, with a Reset button that hands every window back to the game.',
                    'Windows you never move are left exactly where the game puts them. Moving one is also what lets it stay open alongside the others, so the character pane and trade window can finally sit side by side.'
                }
            }, {
                title = 'Errors and combat blocks',
                items = {
                    'Fixed the "Invalid frame handle" error thrown every time you entered combat. It also meant frames meant to fade in combat silently never did.',
                    'Fixed the error when casting certain spells, and when using a consumable in combat.',
                    'Fixed "action blocked" spam when hovering or clicking your action bars mid-fight.',
                    'Fixed the stutter caused by #showtooltip [@mouseover] macros.'
                }
            }, {
                title = 'Action bars vanishing',
                items = {
                    'Fixed every bar disappearing after anchoring the XP bar to an action bar.',
                    'An anchor choice that would form a loop is now refused politely, instead of erroring on every settings change.',
                    'MoP: fixed having no action bars at all while the options still showed them as on.',
                    'MoP: fixed an error on every drag in edit mode.',
                    'MoP: fixed the focus target frame being resized unexpectedly.'
                }
            }, {
                title = 'Edit mode',
                items = {
                    'Fixed the unit frames being shoved around when you open Blizzard\'s own Edit Mode.',
                    'Fixed frames disappearing when you left edit mode and only returning after a reload.',
                    'Frames with nothing to show get a labelled placeholder you can actually grab.',
                    'Frames can be dragged straight away instead of needing a click to select first, with live coordinates while you drag.',
                    'Only one edit mode open at a time - opening Blizzard\'s closes ours, and the other way round.'
                }
            }, {
                title = 'Party frames',
                items = {
                    'Class colour and gradient options work on the new party frames.',
                    'Health bars no longer stuck washed-out, and correct power bar art.',
                    'Names truncate before the role icon and stay on one line.',
                    'Party frames have their own settings page, edit mode entry and move handle.'
                }
            }, {
                title = 'Loot rolls',
                items = {
                    'Rebuilt on retail\'s actual loot roll frame, with retail need, greed and pass icons.',
                    'Preview button and real customization options in settings.',
                    'Adjustable gap between stacked rolls.'
                }
            }, {
                title = 'Chat',
                items = {
                    'The chat window can be selected and moved in DragonflightUI\'s edit mode.',
                    'Fixed tabs past the first rendering shifted upward when chat sits at the bottom of the screen.',
                    'An undocked tab can no longer be dragged off the screen and lost.',
                    'The combat log\'s filter bar no longer covers your other chat tabs.'
                }
            }, {
                title = 'Elsewhere',
                items = {
                    'The Dragonflight paperdoll artwork shows only on the Character tab, instead of bleeding onto Reputation, Skills and Pet.',
                    'Turned-off features are marked (off) and can be switched back on from their own page.',
                    'The quest tracker can be disabled without disabling the whole Minimap module.',
                    'Bug reports show a real version number.',
                    'New /df log debug log, so bug reports can carry a real log.'
                }
            }
        }
    }, {
        version = '0.41.0',
        title = 'Classic Era 1.15.9 support',
        date = '22-25 July 2026',
        intro = 'Patch 1.15.9 replaced the Classic Era interface with a backport of the modern one, which broke most of the addon. This is the overhaul for it, and adds TBC 2.5.6 and MoP 5.5.4 support.',
        sections = {
            {
                title = 'Loading and stability',
                items = {
                    'The addon no longer half-loads and gives up partway through login.',
                    'The interface no longer visibly builds itself piece by piece after you log in.',
                    'Reloading mid-fight finishes the job the moment combat ends.',
                    'Fixed the quest tracker freezing the game.'
                }
            }, {
                title = 'Action bars',
                items = {
                    'Page arrows work again, cycle all 6 pages, and keep working in combat.',
                    'Shift-scrolling to change pages no longer strobes between two pages.',
                    'Keybinds on bars 6-8 fired nothing; bars 6-8 showed every spell twice.',
                    'Bar backgrounds were missing entirely.',
                    'Added the retail main bar frame, with an adjustable fill behind the buttons.',
                    'Pet bar restored to its proper size, with correct highlight and autocast art.'
                }
            }, {
                title = 'Raid and hover performance',
                items = {
                    'Fixed the big one: frame skips and stutter when moving the mouse across raid frames.',
                    'Buff timers no longer churn the garbage collector every frame.',
                    'Keeps Questie\'s raid safeguards working when the client cuts its startup short.'
                }
            }, {
                title = 'Nameplates',
                new = true,
                items = {'Dragonflight-styled enemy plates, outlined names and class-coloured enemy players.'}
            }, {
                title = 'Frames and art',
                items = {
                    'Full Dragonflight restyle for the new pooled party frames.',
                    'Retail Dragonflight character pane background, slot art and model border.',
                    'Pet buffs and pet happiness restored.',
                    'Buff and debuff timers keep their real remaining time across a reload.',
                    'Minimap sits in the corner at a sane default size.'
                }
            }
        }
    }
}
